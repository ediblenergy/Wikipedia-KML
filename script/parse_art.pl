use strictures 1;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Wikipedia::KML;
my $parser = Wikipedia::KML->new( wiki_markup_file => shift(@ARGV) );
$parser->print_html;
#use IO::All;
#use 5.10.0;
#use Data::Dumper::Concise;
#use XML::Simple;
#use Geo::Coordinates::DecimalDegrees;
#my $num = qr/(\-?\d+(?:\.\d+)?)/x;
#my $dec = qr/$num \|/x;
#my $dec3 = $dec x 3;
#sub shiftcoords {
#    return [
#        dms2decimal( shift, shift, shift ),
#        dms2decimal( shift, shift, shift ),
#    ];
#}
#sub parse_coords {
#    my $coords = shift;
#    my @m = $coords =~ /$num/gx;
#    return unless @m;
#    if(@m == 2) {
#        return [shift(@m),shift(@m)];
#    }
#    return shiftcoords(@m);
#}
#my $fn = "art.wiki";
#my $contents = io->file($fn)->all;
#my $token = 'Public\ art\ row';
#my @matches = $contents =~ 
#    /(
#    $token.*\v
#    (?:\|.*\v)+
#)/mixg;
#
#sub parse_line {
#    my $line = shift;
#    my ( $key, $value ) = $line =~ m/
#    \|
#    \s*
#    (\w+)
#    [^=]+
#    \=
#    \s*
#    (.*)$
#    /x;
#    return ( $key, $value );
#}
#sub parse_match {
#    my $text = shift;
#    my @lines = split( /\v/, $text );
#    my %ret;
#    shift(@lines);    #get rid of "public art row" header
#    for (@lines) {
#        my ( $key, $value ) = parse_line($_);
#        $ret{$key} = $value;
#    }
#    return \%ret;
#}
#    
#
#sub cdata { "<![CDATA[$_[0]]]" }
#my $ref = {
#    Placemark => {
#        Snippet     => "snip",
#        name        => "namo",
#        Point       => { coordinates => "-75.0537,40.0264,0" },
#        description => "desc",
#    }
#};
#
#my $middle = XMLout($ref,KeepRoot => 1, NoAttr => 1);
#
#sub wrap {
#my $str = <<"EOS"
#<?xml version="1.0" encoding="UTF-8"?>
#<kml xmlns="http://earth.google.com/kml/2.1">
#<Document>
#$_[0]
#</Document>
#</kml>
#EOS
#}
##my @matches = $contents =~ /$token.*?\n((^|.*)+)$[^|]/ix;
##print "$_\n\n" for @matches;
##warn Dumper \@matches;
#
#my @sculptures = grep { $_->{coordinates} } map { parse_match($_) } @matches;
#for(@sculptures) {
#    my $coords=  parse_coords( $_->{coordinates} );
#    die "DEAD:". Dumper $_->{coordinates} if $coords and !$coords->[0];
#}
##print Dumper @sculptures;
##for(@contents) {
##    next unless /$token/i;
##    say $_;
##}
##my @matches = $contents =~ /\{\{Public art row
