use Test::More;
use strictures 1;
use Wikipedia::KML;
plan tests => 2;
my $test = '<small>{{Coord|39.952414|-75.146301|name=Gen. McClellan}}</small>';
my $test2 = '<small>{{coord|39.9532|N|75.1636|W|region:US|name=Gen. McClellan}}</small>';
is_deeply Wikipedia::KML::parse_coords($test),[39.952414,-75.146301];
is_deeply Wikipedia::KML::parse_coords($test2),[39.9532,-75.1636];

