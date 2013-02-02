use strictures 1;
use Test::More;
use Wikipedia::KML;
use utf8;
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



my $sortnames = [
    [ '{{sortname|Tom|Jones}}',          'Tom Jones', 'Tom Jones' ],
    [
        '{{sortname|Fábio|da Silva|Fábio Gomes da Silva|Silva, Fabio}}',
        'Fábio da Silva', 'Fábio Gomes da Silva'
    ],
];
for(@$sortnames) {
    is_deeply( 
        Wikipedia::KML::extract_sortname( $_->[0] ),
        { text => $_->[1], href => $_->[2] } 
    );
}
done_testing;
#{{sortname|Tom|Jones|dab=singer}}   Tom Jones   Jones, Tom  Tom Jones (singer)
#{{sortname|Tom|Jones|Tom Jones (singer)}}   Tom Jones   Jones, Tom  Tom Jones (singer)
#{{sortname|Fábio|da Silva}} Fábio da Silva  da Silva, Fábio Fábio da Silva
#{{sortname|Fábio|da Silva|nolink=1}}    Fábio da Silva  da Silva, Fábio (no link)
#{{sortname|Fábio|da Silva|Fábio Gomes da Silva}}    Fábio da Silva  da Silva, Fábio Fábio Gomes da Silva
#{{sortname|Fábio|da Silva||Silva, Fabio}}   Fábio da Silva  Silva, Fabio    Fábio da Silva
#{{sortname|Fábio|da Silva||Silva, Fabio|nolink=1}}  Fábio da Silva  Silva, Fabio    (no link)
