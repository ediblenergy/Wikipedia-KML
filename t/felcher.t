use strictures 1;
use Test::More;
use Wikipedia::Felcher;
plan tests => 2;
my $ret = Wikipedia::Felcher->get_thumb(
    'Aero_Memorial_by_Paul_Manship,_Philadelphia_-_DSC06527.JPG');

is $ret->{w},200;# 450 * x = 200; 200/450 
is $ret->{h},int((600*(200/450)));
# 450 × 600 pixels
