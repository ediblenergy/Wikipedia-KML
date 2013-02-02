use strictures 1;
use Test::More;
use Wikipedia::KML;
use utf8;
binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";
use Encode;
my $encoding  = Encode::find_encoding("UTF-8");
my $test= '[[Logan Circle (Philadelphia)|Logan Circle]], opposite [[Franklin Institute]]';
is_deeply(Wikipedia::KML::extract_wiki_links($test),[
    { 
        text => "Logan Circle (Philadelphia)",
        href => "Logan_Circle"
    },
    {
        text => "Franklin Institute",
        href => "Franklin_Institute",
    }
]);


my $fabio = '{{sortname|Fábio|da Silva|Fábio Gomes da Silva|Silva, Fabio}}';

my $sortnames = [
    [ '{{sortname|Tom|Jones}}',"<a href ='http://en.wikipedia.org/wiki/Tom_Jones' target='_blank'>Tom Jones</a>" ],
    [
        $fabio,
        "<a href ='http://en.wikipedia.org/wiki/Fábio_da_Silva' target='_blank'>Fábio Gomes da Silva</a>"
    ],
];
for(@$sortnames) {
    is( 
        Wikipedia::KML::extract_curly_wiki( $_->[0] ),$_->[1] );
#        { text => $_->[1], href => $_->[2] } 
}
done_testing;
#{{sortname|Tom|Jones|dab=singer}}   Tom Jones   Jones, Tom  Tom Jones (singer)
#{{sortname|Tom|Jones|Tom Jones (singer)}}   Tom Jones   Jones, Tom  Tom Jones (singer)
#{{sortname|Fábio|da Silva}} Fábio da Silva  da Silva, Fábio Fábio da Silva
#{{sortname|Fábio|da Silva|nolink=1}}    Fábio da Silva  da Silva, Fábio (no link)
#{{sortname|Fábio|da Silva|Fábio Gomes da Silva}}    Fábio da Silva  da Silva, Fábio Fábio Gomes da Silva
#{{sortname|Fábio|da Silva||Silva, Fabio}}   Fábio da Silva  Silva, Fabio    Fábio da Silva
#{{sortname|Fábio|da Silva||Silva, Fabio|nolink=1}}  Fábio da Silva  Silva, Fabio    (no link)
