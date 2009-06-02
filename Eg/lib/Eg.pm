package Eg;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use parent qw/Catalyst/;
use Catalyst qw/-Debug
                ConfigLoader
                Static::Simple/;
our $VERSION = '0.01';

__PACKAGE__->config( name => 'Eg' );

__PACKAGE__->setup();

1;
