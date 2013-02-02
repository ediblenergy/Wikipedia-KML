package Wikipedia::Felcher {

    use strictures 1;
    use Web::Scraper;
    use Moo;
    use URI;
    use Data::Dumper::Concise;
    use Image::Size ();
    use LWP::UserAgent;

    has thumb_width => ( 
        is => 'ro',
        default => sub { 200 },
    );

    has ua => (
        is => 'ro',
        default => sub { LWP::UserAgent->new },
    );

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

    sub get_size {
        my ($self,$src) = @_;
        warn $src;
        my $data = $self->ua->get($src)->decoded_content;
        my @size = Image::Size::imgsize( \$data );
        return [ @size ];
    }
    sub run {
        my $self   = shift;
        warn "felching ${\ $self->url }";
        my $images = scraper {
            process 'a.mw-thumbnail-link', 'images[]' =>  {
                link => '@href',
                txt => 'TEXT',
              }
        };
        my %ret;
        $ret{src} = eval { 
            my $scraped = $images->scrape( URI->new( $self->url ) ); 
            return unless $scraped && $scraped->{images}[0]{link};
            return $scraped->{images}[0]{link};
        };
        if($@) {
            warn $@;
            return;
        }
        return unless $ret{src};
        my ( $w, $h ) = @{ $self->get_size( $ret{src} ) };
        my $x =$self->thumb_width / $w;
        $h *= $x;
        $w = $self->thumb_width;
        $ret{w} = int($w);
        $ret{h} = int($h);
        return \%ret;
    }

    sub get_thumb {
        my ( $class, $fn ) = @_;
        my $felcher = $class->new( filename => $fn );
        my $ret = $felcher->run;
        return unless $ret;
        $ret->{src} =~ s|/\d+px|/200px|x;
        return $ret;
    }
    1;
}
