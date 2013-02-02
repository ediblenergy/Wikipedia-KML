package Wikipedia::KML;

our $VERSION = '0.000001'; # 0.0.1

$VERSION = eval $VERSION;

use strictures 1;
use IO::All;
use 5.10.0;
use Data::Dumper::Concise;
use XML::Simple;
use Geo::Coordinates::DecimalDegrees;
use Moo;
use Wikipedia::Felcher;
use Redis;
use Encode;
use Carp;

has encoding => (
    is => 'lazy',
    default => sub { Encode::find_encoding('UTF-8') }
);

has redis => (
    is => 'lazy',
);

sub _build_redis {
    Redis->new(
        host => 'localhost:6379',
        reconnect => 60,
        encoding => undef,
    );
}
my $token = 'Public\ art\ row';

has wiki_markup_file => (
    is => 'ro',
    required => 1,
);

has html => (
    is => 'lazy'
);
sub _matches {
    my $self = shift;
    my $contents = io->file($self->wiki_markup_file)->all;
    my @matches = $contents =~ 
        /(
        $token.*\v
        (?:\|.*\v)+
    )/mixg;
    return \@matches;
}

sub shiftcoords {
    return [
        dms2decimal( shift, shift, shift ),
        dms2decimal( shift, shift, shift ),
    ];
}

my $num = qr/(\-?\d+(?:\.\d+)?)/x;
my $strip_num = qr/\-?\d+(?:\.\d+)?/;
sub parse_coords_to_ll {
    my $str = shift;
    my $num = qr/\-?\d+(?:\.\d+)?/;
    ( undef, $str ) = split( /coord\|/ => $str );
    my ( $lat, $long ) = split( /N\||W\|/ => $str, 3 );
    my $la = dms2decimal( split( /\|/ => $lat ) );
    my $lo = dms2decimal( split( /\|/ => $long ) );
    $lo *= -1;    #it's west, so its negative
    return [ $la, $lo ];
}
sub parse_coords {
    my ($coords) = @_;
    my @m = $coords =~ /$num/gx;
    return unless @m;
    if ( @m == 2 ) {
        unless ( $coords =~ /\|N\| | \|W\|/x ) {
            return [ shift(@m), shift(@m) ];
        }
    }
    return parse_coords_to_ll($coords);
}

sub parse_line {
    my ($line) = @_;
    my ( $key, $value ) = $line =~ m/
    \|
    \s*
    (\w+)
    [^=]+
    \=
    \s*
    (.*)$
    /x;
    return ( $key, $value );
}
sub parse_match {
    my $text = shift;
    my @lines = split( /\v/, $text );
    my %ret;
    shift(@lines);    #get rid of "public art row" header
    for (@lines) {
        my ( $key, $value ) = parse_line($_);
        $ret{$key} = $value;
    }
    return \%ret;
}
    

sub cdata { "<![CDATA[$_[0]]]>" }
sub header {
    q[<?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://earth.google.com/kml/2.1">
    <Document>]
}
sub footer {
    q[</Document>
    </kml>]
}
sub wrap {
    my $str = <<"EOS"
    <?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://earth.google.com/kml/2.1">
        <Document>$_[0]</Document>
    </kml>
EOS
}
sub xml_out {
    XMLout( shift, 
        KeepRoot => 1, 
        NoAttr => 1, 
        NoEscape => 1 
    );
}


#my @matches = $contents =~ /$token.*?\n((^|.*)+)$[^|]/ix;
#print "$_\n\n" for @matches;
#warn Dumper \@matches;

#my $ref = {
#    Placemark => {
#        Snippet     => "snip",
#        name        => "namo",
#        Point       => { coordinates => "-75.0537,40.0264,0" },
#        description => "desc",
#    }
#};
sub get_thumb_data {
    my ( $self, $src ) = @_;
    my $thumb_data =
      { map { $self->encoding->decode($_) }
          $self->redis->hgetall( $self->encoding->encode($src) ) };
    if ( !keys(%$thumb_data) ) {
        $thumb_data = Wikipedia::Felcher->get_thumb($src);
    }
    return unless $thumb_data;
    $self->redis->hmset( map { $self->encoding->encode($_) } ( $src, %$thumb_data ) );
    return $thumb_data;
}
#      grep { defined } @$obj{qw[subject artist date location material  ]};
#    if ( keys %$thumber ) {
#        $description = "<br/>
#            <img src='$$thumber{src}' height='$$thumber{h}' width='$$thumber{w}' />
#            <br/>
#            $description";
#    }
sub get_description {
    my $obj   = shift;
    warn Dumper $obj;
    my $templ = {
        artist     => sub { linkify(shift) },
        thumb_data => sub {
            my $thumb = shift;
"<img src='$thumb->{src}' width='$thumb->{w}' height='$thumb->{h}'/>"
        },
        date     => sub { shift },
        location => sub { linkify(shift) },
        material => sub { shift },
    };
    return join "<br/>" => map {$templ->{$_}->( $obj->{$_} ) }
      grep { $templ->{$_} &&  $obj->{$_} } qw[
    thumb_data
    location
    artist
    date
    material
  ];
}
sub linkify {
    for($_[0]) {
        s/(\{\{.*?\}\})/extract_curly_wiki($1)/ge;
        s/(\[\[(.*)?\]\])/extract_wiki_link($1)/ge;
        return $_;
    }
}

#{{sortname|first|last|optional link target|optional sort key}}
sub extract_curly_wiki {
    my $txt = shift;
    my ($dat) = $txt =~ /(?:\{\{\s*)(.*)?(?:\s*\}\})/;
    return wiki_link($txt) unless $dat; #not marked up
    carp "data missing from $txt" unless $dat;
    my (undef,$first,$last,$optional_link_target) = split(/\|/, $dat);
    $optional_link_target ||= "$first $last";
    return wiki_link("$first $last", $optional_link_target);
}
sub wiki_link_sortname {
    my $txt = shift;
    my $res = extract_sortname($txt);
}
sub wiki_link {
    my ($link,$name) = @_;
    carp "link required" unless $link;
    $name ||= $link;
    $link =~ s/\s+/_/g;
    return "<a href ='http://en.wikipedia.org/wiki/$link' target='_blank'>$name</a>";
}
sub pmark {
    my ( $self, $obj ) = @_;
    my $snippet = join " " => map { "<li>" . strip_wikitext($_) . "</li>" }
      grep { defined } @$obj{qw[ location ]};
    $snippet = "<ul>$snippet</ul>";
    $obj->{thumb_data} = $self->get_thumb_data( $obj->{image} );
    return {
        Placemark => {
            Snippet => cdata($snippet),
            name    => cdata(
                strip_wikitext( $obj->{subject} ),
            ),
            description => cdata( get_description( $obj ) ),
            Point => {
                coordinates =>
                  join( ',' => ( $obj->{coords}[1], $obj->{coords}[0], 0 ) )
              }    #it's long,lat for some odd reason
        }
    };
}
sub _sculptures {
    my $self = shift;
    my @sculptures = grep { $_->{coordinates} } map { parse_match($_) } @{$self->_matches};
    return \@sculptures;
}
sub strip_wikitext {
    my $str = shift;
    $str =~ s/[^\w ()]/ /g;
    $str =~ s/\s+/ /g;
    return $str;
}
sub extract_wiki_link {
    my $txt = shift;
    my ($data) = @{ extract_wiki_links($txt) };
    return wiki_link($data->{text},$data->{href});
}
sub extract_wiki_links {
    my $txt = shift;
    my @links = $txt =~ m/\[\[(.*?)\]\]/gx;
    return [
        map {
            warn $_;
            my ( $text, $href ) = split( /\|/, $_ );
            $href ||= $text;
            $href =~ s/\s+/_/g;
            {
                text => $text,
                href => $href,
            }
        } @links
      ]
}
sub print_html {
    my $self = shift;
    local $|=1; #autoflush
    print $self->header;
    for(@{ $self->_sculptures }) {
        next unless $_->{image};
        my $cords = parse_coords( $_->{coordinates} );
        $_->{coords} = $cords;
        
        next unless $cords;
        print xml_out( $self->pmark( $_ ) );
    }
    print $self->footer;
}
1;

=head1 NAME

Wikipedia::KML - Description goes here

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

 sam@socialflow.com

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2013 the Wikipedia::KML L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
