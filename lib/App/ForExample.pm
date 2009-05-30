package App::ForExample;

use warnings;
use strict;

=head1 NAME

App::ForExample - A guide through configuration hell

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use Template;
use Carp;
use App::ForExample::ModuleEmbedCatalog;

my $tt = Template->new;
my $catalog = App::ForExample::ModuleEmbedCatalog->extract( __PACKAGE__ );

sub process ($@) {
    my $given = shift;

    my ($template);
    if ( ref $given eq 'SCALAR' ) {
        $template = $given;
    }
    else {
        $template = $catalog->{$given} or croak "Template \"$given\" does not exist in the catalog";
    }

    $tt->process( $template => { @_ } ) or croak "Error processing template \"$given\": ", $tt->error; 
}

use Getopt::Chain::Declare;

on 'catalyst/fastcgi *' => 
    [qw/ name=s home=s base=s host=s /] => sub {
    my $ctx = shift;
    
    my ($server, $server_module, $mode);
    for ( @_ ) {
        m/(apache2?)(?:=(?:mod_)?(fastcgi|fcgid))?/ and ($server, $server_module) = ($1, $2) or
        m/lighttpd/ and $server = 'lighttpd' or
        m/nginx/ and $server = 'nginx' or

        m/standalone/ and $mode = 'standalone' or
        m/static/ and $mode = 'static' or
        m/dynamic/ and $mode = 'dynamic' or

        croak "Don't understand argument $_ (@_)";
    }

    ($server, $server_module) = qw/apache2 fastcgi/ unless $server;
    ($mode) = qw/standalone/ unless $mode;

    # Catalyst name
    my $name = $ctx->option( 'name' ) || 'xyzzy';

    # Catalyst home
    my $home = $ctx->option( 'home' ) || "./$name";

    # Catalyst application base
    my $base = $ctx->option( 'base' ) || '/';
    $base =~ s/^\/+//;
    my $alias_base = $base eq '' ? '/' : "/$base/";

    # Virtual host
    my $host = $ctx->option( 'host' ) || $name;

    my %process = (
        name => $name,
        home => $home,
        base => $base,
        alias_base => $alias_base,
        host => $host,
    );

    if ( $server =~ m/^apache2?$/ ) {

        if ( $mode eq 'standalone' ) {

            # Or fastcgi_host
            my $fastcgi_socket = "/tmp/$name.socket";
            my $fastcgi_file = "/tmp/$name.fcgi";

            # TODO Error in Catalyst::Engine::FastCGI dox?

            process 'catalyst/fastcgi/apache2' => %process;
        }
        else {
            croak "Don't understand mode \"$mode\""
        }
    }
    else {
        croak "Don't understand server \"$server\""
    }

};

on qr/.*/ => undef, sub {
    my $ctx = shift;

    print <<_END_
Usage: for-example EXAMPLE

Where EXAMPLE is one of:

    catalyst/fastcgi apache2 standalone

_END_
};

no Getopt::Chain::Declare;

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-forexample at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ForExample>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ForExample


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ForExample>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ForExample>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ForExample>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ForExample/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

__PACKAGE__; # End of App::ForExample

__DATA__

catalyst/fastcgi/apache2
# vim: set ft=apache
<VirtualHost *:80>

    ServerName [% host %]
    ServerAlias www.[% host %]

    CustomLog "|/usr/sbin/cronolog /var/log/apache2/[% host %]-%Y-%m.access.log -S /var/log/apache2/[% host %].access.log" combined
    ErrorLog "|/usr/sbin/cronolog /var/log/apache2/[% host %]-%Y-%m.error.log -S /var/log/apache2/[% host %].error.log"

    FastCgiExternalServer [% fastcgi_file %] -socket [% fastcgi_socket %]
    Alias [% alias_base %] [% fastcgi_file %]/

    # Optionally, rewrite the path when accessed without a trailing slash
    RewriteRule ^/[% base %]\$ [% base %]/ [R]

     <Directory "[% home %]/root">
         Options Indexes FollowSymLinks
         AllowOverride All
         Order allow,deny
         Allow from all
     </Directory>

</VirtualHost>

# Start your fastcgi socket with the following command:
# script/[% name %]_fastcgi.pl -l [% fastcgi_socket %] -n 5
__ASSET__

