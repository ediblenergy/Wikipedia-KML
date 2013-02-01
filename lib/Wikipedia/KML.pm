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
#    warn $coords;
    my @m = $coords =~ /$num/gx;
    return unless @m;
    if(@m == 2) {
        return [shift(@m),shift(@m)];
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

sub pmark {
    my($self,$obj) = @_;
    warn Dumper $obj;
    my $thumber = $self->redis->get($obj->{image});
    if( !defined($thumber) ) {
        $thumber = Felcher->get_thumb( $obj->{image} );
        $self->redis->set( $obj->{image}, $thumber || 0 );
    }
    my $ret = {
        Placemark => {
            Snippet => cdata( $obj->{image} ),
            Point =>
              { coordinates => join( ',' => ( reverse(@{ $obj->{coords} }), 0 ) ) } #it's long,lat for some odd reason
        }
    };
    if ($thumber) {
        $ret->{Placemark}{description} = cdata("<img src='$thumber' />");
    }
    return $ret;
}
sub _sculptures {
    my $self = shift;
    my @sculptures = grep { $_->{coordinates} } map { parse_match($_) } @{$self->_matches};
#    for(@sculptures) {
#        warn Dumper $_;
#        $_->{image}
#        $_->{coordinates}
#        my $coords=  parse_coords( $_->{coordinates} );
#        warn Dumper $coords;
#        die "DEAD:". Dumper $_->{coordinates} if $coords and !$coords->[0];
#    }
    return \@sculptures;
}
sub print_html {
    my $self = shift;
    local $|=1; #autoflush
    print $self->header;
    for(@{ $self->_sculptures }) {
        next unless $_->{image};
        my $cords = parse_coords( $_->{coordinates} );
        next unless $cords;
        my $inp = {
            image  => $_->{image},
            coords => $cords,
          };
        print xml_out( $self->pmark( $inp ) );
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
