package Felcher {

    use strictures 1;
    use Web::Scraper;
    use Moo;
    use URI;
    use Data::Dumper::Concise;
    has prefix => (
        is      => 'ro',
        default => sub { 'http://en.wikipedia.org/wiki/File:' }
    );
    has url => (
        is      => 'lazy',
        default => sub {
            my $self = shift;
            $self->prefix . $self->filename
        }
    );
    has filename => (
        is       => 'ro',
        required => 1,
    );

    sub run {
        my $self   = shift;
        warn "felching ${\ $self->url }";
        my $images = scraper {
            process 'a.mw-thumbnail-link', 'link[]' => '@href'
        };
        my $ret;
        eval { $ret = $images->scrape( URI->new( $self->url ) ); };
        if($@) {
            warn $@;
            return;
        }
        return $ret;

    }

    sub get_thumb {
        my ( $class, $fn ) = @_;
        my $ret = $class->new( filename => $fn )->run;
        warn Dumper $ret;
        if ( $ret && $ret->{link} ) {
            my $img = $ret->{link}[0];
            return unless $img;
            $img =~ s/\d\d\dpx/200px/;
            return $img;
        }
    }
    1;
}
