package App::ForExample;

use warnings;
use strict;

=head1 NAME

App::ForExample - A guide through configuration hell

=head1 VERSION

Version 0.01

=cut

# TODO --help, --host to --hostname, better start-stop, integrate fastcgi_socket, allow fastcgi_socket to be host:port, add alert e-mail to monit

our $VERSION = '0.01';

#use App::ForExample::ModuleEmbedCatalog;
use App::ForExample::Catalog;

use Template;
use Carp;
use Path::Class;

#my $catalog = App::ForExample::ModuleEmbedCatalog->extract( __PACKAGE__ );
my $catalog = App::ForExample::Catalog->catalog;
my $tt = Template->new({ BLOCKS => $catalog->{common} });

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

sub package2name ($) {
    my $package = shift;
    my $name = $package;
    $name =~ s/::/-/g;
    $name = lc $name;
    my $underscore_name = $name;
    $underscore_name =~ s/-/_/g;
    return ( $name, $underscore_name );
}

sub parse_catalyst ($) {
    my $ctx = shift;

    # Catalyst package
    my $package = $ctx->option( 'package' ) || 'Project::Xyzzy';
    my ($package_name, $underscore_name) = package2name $package;

    # Catalyst name
    my $name = $ctx->option( 'name' );
    $name = $package_name unless defined $name;

    # Catalyst home
    my $home = $ctx->option( 'home' ) || "./";
    $home = dir( $home )->absolute;

    # Catalyst application base
    my $base = $ctx->option( 'base' ) || '/';
    $base =~ s/^\/+//;
    my $alias_base = $base eq '' ? '/' : "/$base/";

    # Virtual host
    my $host = $ctx->option( 'host' ) || "$name.example.com";

    my @data;
    push @data, package => $package,
        name => $name,
        underscore_name => $underscore_name,
        home => $home,
        base => $base,
        alias_base => $alias_base,
        host => $host
    ;
    return { @data };
}

#rewrite qr#catalyst/modperl[12]?# => 'catalyst/mod_perl';
rewrite qr#catalyst/(?:mod_perl[12]|modperl[12]?)# => 'catalyst/mod_perl';

on 'catalyst/mod_perl *' => 
    [qw/ package=s name=s home=s base=s host=s /] => sub {
    my $ctx = shift;
    
    my ($server);
    for ( @_ ) {
        m/(apache2?)/ and ($server) = ($1) or

        croak "Don't understand argument $_ (@_)";
    }
    ($server) = qw/apache2/;

    my @data;
    my $catalyst_data = parse_catalyst $ctx;
    push @data, %$catalyst_data;

    if ( $server =~ m/^apache2?$/ ) {
        process 'catalyst/mod_perl/apache2' => @data;
    }
    else {
        croak "Don't understand server \"$server\""
    }

};

on 'catalyst/fastcgi *' => 
    [qw/ package=s name=s home=s base=s host=s no-monit no-start-stop /] => sub {
    my $ctx = shift;
    
    my ($server, $server_module, $mode);
    for ( @_ ) {
        m/(apache2?)(?:=(?:mod_)?(fastcgi|fcgid))?/ and ($server, $server_module) = ($1, $2) or
        m/lighttpd/ and $server = 'lighttpd' or
        m/nginx/ and $server = 'nginx' or
        m/(monit|start-stop)/ and $server = $1 or # Not really a server, but...

        m/standalone/ and $mode = 'standalone' or
        m/static/ and $mode = 'static' or
        m/dynamic/ and $mode = 'dynamic' or

        croak "Don't understand argument $_ (@_)";
    }

    ($server, $server_module) = qw/apache2 fastcgi/ unless $server;
    ($mode) = qw/standalone/ unless $mode;

    my @data;

    my $no_monit = $ctx->option( 'no-monit' );
    my $no_start_stop = $ctx->option( 'no-start-stop' );
    my $catalyst_data = parse_catalyst $ctx;
    push @data, %$catalyst_data;
    my $name = $catalyst_data->{name};

    if ( $server =~ m/^apache2?$/ ) {

        if ( $mode eq 'standalone' ) {
            # Or fastcgi_host
            my $fastcgi_socket = "/tmp/$name.socket";
            my $fastcgi_file = "/tmp/$name.fcgi";
            push @data,
                fastcgi_socket => $fastcgi_socket,
                fastcgi_file => $fastcgi_file,
            ;

            # TODO Error in Catalyst::Engine::FastCGI dox?
            process 'catalyst/fastcgi/apache2/standalone' => @data;
            unless ($no_start_stop) {
                print "---\n";
                process 'catalyst/fastcgi/start-stop' => @data;
            }
            unless ($no_monit) {
                print "---\n";
                process 'catalyst/fastcgi/monit' => @data;
            }
        }
        elsif ( $mode eq 'dynamic' ) {
            process 'catalyst/fastcgi/apache2/dynamic' => @data;
        }
        elsif ( $mode eq 'static' ) {
            process 'catalyst/fastcgi/apache2/static' => @data;
        }
        else {
            croak "Don't understand mode \"$mode\""
        }
    }
    elsif ( $server eq 'lighttpd' ) {

        if ( $mode eq 'standalone' ) {
            process 'catalyst/fastcgi/lighttpd/standalone' => @data;
            unless ($no_start_stop) {
                print "---\n";
                process 'catalyst/fastcgi/start-stop' => @data;
            }
            unless ($no_monit) {
                print "---\n";
                process 'catalyst/fastcgi/monit' => @data;
            }
        }
        elsif ( $mode eq 'static' ) {
            process 'catalyst/fastcgi/lighttpd/static' => @data;
        }
        else {
            croak "Don't understand mode \"$mode\""
        }
    }
    elsif ( $server eq 'nginx' ) {

        if ( $mode eq 'standalone' ) {
            process 'catalyst/fastcgi/nginx' => @data;
            unless ($no_start_stop) {
                print "---\n";
                process 'catalyst/fastcgi/start-stop' => @data;
            }
            unless ($no_monit) {
                print "---\n";
                process 'catalyst/fastcgi/monit' => @data;
            }
        }
        else {
            croak "Don't understand mode \"$mode\""
        }
    }
    elsif ( $server eq 'start-stop' ) {
        process 'catalyst/fastcgi/start-stop' => @data;
    }
    elsif ( $server eq 'monit' ) {
        process 'catalyst/fastcgi/monit' => @data;
    }
    else {
        croak "Don't understand server \"$server\""
    }

};

on 'monit' => 
    [qw/ home=s monit-home=s /] => sub {
    my $ctx = shift;

    my @home;
    unless ($home[0] = $ctx->option( 'monit-home' )) {
        $home[0] = $ctx->option( 'home' ) || "./";
        push @home, qw/my-monit/;
    }
    my $home = dir @home;
    $home = $home->absolute;
    process 'monit' => ( home => $home );
};

on 'help' => 
    undef, sub {

    print <<_END_;
Usage: for-example ...

Where ... can be:

    catalyst/fastcgi <http-daemon> <fastcgi-method>

        Generate a Catalyst FastCGI configuration (for the specified http-daemon and fastcgi-method)

        --package           The Catalyst package for your application (e.g. Project::Xyzzy or My::Application)
        --home              The path to your Catalyst home directory, default: . (The current directory)
        --base              The base for your application, default: / (At the root)
        --host              The hostname for your application (e.g. example.com)
        --no-monit          Do not print out a monit configuration, if applicable
        --no-start-stop     Do not print out a start/stop script, if applicable

        apache2 standalone  Apache2 with standalone FastCGI 
        apache2 static      Apache2 with static FastCGI
        apache2 dynamic     Apache2 with dynamic FastCGI

        lighttpd standalone lighttpd with dynamic FastCGI
        lighttpd static     lighttpd with static FastCGI

        nginx               nginx with standalone FastCGI (the only kind supported)

        monit               A monit configuration for a standalone FastCGI setup
        start-stop          A start-stop script for a standalone FastCGI setup
        
    catalyst/mod_perl

        Generate a mod_perl2 (for Apache2) Catalyst configuration

        See the above section on 'catalyst/fastcgi' for an option synopsis

    monit

        Generate a basic, stripped-down monit configuration suitable for a non-root user

        --home          The directory containing my-monit (<home>/my-monit)
        --monit-home    Put everything in <monit-home>, --home will be ignored

_END_
};

on qr/.*/ => undef, sub {
    my $ctx = shift;

    print <<_END_
Usage: for-example ...

Where ... can be:

    catalyst/fastcgi apache2 standalone|static|dynamic
    catalyst/fastcgi lighttpd standalone|static
    catalyst/fastcgi nginx
    catalyst/fastcgi start-stop|monit
    catalyst/mod_perl
    monit

    help

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

catalyst/fastcgi/apache2/standalone
# vim: set ft=apache
<VirtualHost *:80>

    ServerName [% host %]
    ServerAlias www.[% host %]

    CustomLog "|/usr/bin/cronolog /var/log/apache2/[% host %]-%Y-%m.access.log -S /var/log/apache2/[% host %].access.log" combined
    ErrorLog "|/usr/bin/cronolog /var/log/apache2/[% host %]-%Y-%m.error.log -S /var/log/apache2/[% host %].error.log"

    FastCgiExternalServer [% fastcgi_file %] -socket [% fastcgi_socket %]
    Alias [% alias_base %] [% fastcgi_file %]/

    # Optionally, rewrite the path when accessed without a trailing slash
    # TODO If not /
    RewriteRule ^/[% base %]\$ [% base %]/ [R]

     <Directory "[% home %]/root">
         Options Indexes FollowSymLinks
         AllowOverride All
         Order allow,deny
         Allow from all
     </Directory>

</VirtualHost>
__ASSET__

catalyst/fastcgi/start-stop
#!/bin/bash

PID_FILE="[% home %]/[% name %]-fastcgi.pid"

case "$1" in
    start)
        echo "Starting"
        [% home %]/script/[% underscore_name %]_fastcgi.pl -l [% fastcgi_socket %] -n 5 -p $PID_FILE
    ;;
    stop)
        if [ -s "$PID_FILE" ]; then
            echo "Stopping"
            PID=`cat "$PID_FILE"`
            kill -TERM $PID
        fi
    ;;
    restart)
        $0 stop
        $0 start
    ;;
    *)
        echo "Don't understand \"$1\ ($*)"
        echo "Usage: $0 start|stop|restart"
        exit -1
    ;;
esac
__ASSET__

catalyst/fastcgi/monit
check process [% name %]-fastcgi with pidfile [% home %]/[% name %]-fastcgi.pid
  start program = "[% home %]/fastcgi start"
  stop program  = "[% home %]/fastcgi stop"
__ASSET__

catalyst/fastcgi/apache2/dynamic
<VirtualHost *:80>

    ServerName [% host %]
    ServerAlias www.[% host %]

    CustomLog "|/usr/bin/cronolog /var/log/apache2/[% host %]-%Y-%m.access.log -S /var/log/apache2/[% host %].access.log" combined
    ErrorLog "|/usr/bin/cronolog /var/log/apache2/[% host %]-%Y-%m.error.log -S /var/log/apache2/[% host %].error.log"

    Alias [% alias_base %] [% home %]/script/[% name %]_fastcgi.pl

    # TODO If not /
    RewriteRule ^/[% base %]\$ [% base %]/ [R]

    <Directory "[% home %]/script">
       Options +ExecCGI
    </Directory>

    <Files [% underscore_name %]_fastcgi.pl>
       SetHandler fastcgi-script
    </Files>

</VirtualHost>
__ASSET__

catalyst/fastcgi/apache2/static
<VirtualHost *:80>

    ServerName [% host %]
    ServerAlias www.[% host %]

    CustomLog "|/usr/bin/cronolog /var/log/apache2/[% host %]-%Y-%m.access.log -S /var/log/apache2/[% host %].access.log" combined
    ErrorLog "|/usr/bin/cronolog /var/log/apache2/[% host %]-%Y-%m.error.log -S /var/log/apache2/[% host %].error.log"

    FastCgiServer [% home %]/script/[% underscore_name %]_fastcgi.pl -processes 3
    Alias [% alias_base %] [% home %]/script/[% underscore_name %]_fastcgi.pl/

    # TODO If not /
    RewriteRule ^/[% base %]\$ [% base %]/ [R]

</VirtualHost>
__ASSET__

catalyst/mod_perl/apache2
PerlSwitches -I[% home %]/lib
PerlModule [% package %]

<VirtualHost *:80>

    ServerName [% host %]
    ServerAlias www.[% host %]

    CustomLog "|/usr/bin/cronolog /var/log/apache2/[% host %]-%Y-%m.access.log -S /var/log/apache2/[% host %].access.log" combined
    ErrorLog "|/usr/bin/cronolog /var/log/apache2/[% host %]-%Y-%m.error.log -S /var/log/apache2/[% host %].error.log"

    <Location />
        SetHandler          modperl
        PerlResponseHandler [% package %]
    </Location>

</VirtualHost>
__ASSET__

catalyst/fastcgi/lighttpd/standalone
server.modules += ( "mod_fastcgi" )

$HTTP["host"] =~ "^(www.)?[% host %]" {
    fastcgi.server = (
        "" => (
            "[% name %]" => (
                "socket" => "/tmp/[% name %].socket",
                "check-local" => "disable"
            )
        )
    )
}
__ASSET__

catalyst/fastcgi/lighttpd/static
server.modules += ( "mod_fastcgi" )

$HTTP["host"] =~ "^(www.)?[% host %]" {
    fastcgi.server = (
        "" => (
            "[% name%]" => (
                "socket" => "/tmp/lighttpd-[% name %].socket",
                "check-local" => "disable",
                "bin-path" => "[% home %]/script/[% underscore_name %]_fastcgi.pl",
                "min-procs"    => 2,
                "max-procs"    => 5,
                "idle-timeout" => 20
            )
        )
    )
}
__ASSET__

catalyst/fastcgi/nginx
server {
    server_name [% host %];
    location / {
        include fastcgi_params;
        fastcgi_pass unix:/tmp/[% name %].socket;
    }
}
__ASSET__

monit
# Monit control file

set daemon 120
set logfile [% home %]/log
set pidfile [% home %]/pid
set statefile [% home %]/state

set httpd port 2822 and # This port needs to be unique on a system
    use address localhost
    allow localhost

# Put this file in [% home %]/monitrc
# Use this alias to control your monit daemon:
#
# alias 'my-monit'='monit -vc [% home %]/monitrc'
#
#   my-monit
#   my-monit start all
#   my-monit quit
#   my-monit validate
#   ...
#
__ASSET__

__END__

# Start your fastcgi socket with the following command:
# #!/bin/bash
# [% home %]/script/[% name %]_fastcgi.pl -l [% fastcgi_socket %] -n 5 -p [% home %]/[% name %]-fastcgi.pid

# Stop it with this one:
# #!/bin/bash
# kill -2 `cat [% home %]/[% name %]-fastcgi.pid`
