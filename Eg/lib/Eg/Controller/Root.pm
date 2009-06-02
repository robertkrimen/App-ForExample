package Eg::Controller::Root;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

__PACKAGE__->config->{namespace} = '';

sub index :Path :Args(0) {
    my ( $self, $ctx ) = @_;

    $ctx->response->body( <<_END_ );
<pre>
Eg - @{[ $ctx->engine ]}

@{[ join "\n", map { "$_: $ENV{$_}" } sort keys %ENV ]}
</pre>
_END_
}

sub default :Path {
    my ( $self, $ctx ) = @_;
    $ctx->response->body( 'Page not found' );
    $ctx->response->status(404);
}

sub end : ActionClass('RenderView') {}

1;
