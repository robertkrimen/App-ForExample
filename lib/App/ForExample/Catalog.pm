package App::ForExample::Catalog;

use strict;
use warnings;

sub catalog {
    my $self = shift;
    return $self->extract( 'App::ForExample::CatalogSource' );
}

{
    my $catalog;
    sub extract {
        my $self = shift;
        my $module = shift;
        my $end = shift;

        $end = '__ASSET__' unless defined $end;
        $end = qr/^\Q$end\E$/ unless ref $end eq 'Regexp';

        eval "require $module;" or die $@;
        my $handle = "${module}::DATA";

        return $catalog ||= do {
            my %catalog;
            my ($path, $content);
            while (<$handle>) {
                if ( ! $path ) {
                    next unless m/\S/;
                    chomp; $path = $_;
                    $content = '';
                }
                elsif ( $_ =~ $end ) {
                    my $__ = $content;                                 
                    $catalog{$path} = \$__;                            
                    undef $path;                                       
                    undef $content;                                    
                }
                else {                                                 
                    $content .= $_;                                    
                }
            }
            \%catalog;
        };
    }     
}

1;

__END__

{
    my ( @catalog, $catalog );
    sub catalog {
        return $catalog ||= { @catalog };
    }
    push @catalog,

        'common' => {
            'catalyst/apache2/name-alias-log', => <<'_END_',
_END_

            'catalyst/apache2/fastcgi-rewrite-rule' => <<'_END_',
_END_

        },

        'catalyst/fastcgi/apache2/static' => \<<'_END_',
_END_

        'catalyst/fastcgi/apache2/standalone' => \<<'_END_',
_END_

        'catalyst/fastcgi/apache2/dynamic' => \<<'_END_',
_END_

        'catalyst/mod_perl/apache2' => \<<'_END_',
_END_

        'catalyst/fastcgi/start-stop' => \<<'_END_',
_END_

        'catalyst/fastcgi/monit' => \<<'_END_',
_END_

        'catalyst/fastcgi/lighttpd/standalone' => \<<'_END_',
_END_

        'catalyst/fastcgi/lighttpd/static' => \<<'_END_',
_END_

        'catalyst/fastcgi/nginx' => \<<'_END_',
_END_

        'monit' => \<<'_END_',
_END_
        ;
}

1;
