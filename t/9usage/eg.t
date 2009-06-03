#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;
use Test::Output;

plan qw/no_plan/;

use App::ForExample;
use Path::Class;

sub run_for_example (@) {
    App::ForExample->new->run([ @_ ]);
}

sub run_build (@) {
    run_for_example @_, qw# --home /home/rob/develop/App-ForExample/Eg --hostname eg.localhost --package Eg #
}

sub stdout_same_as (&$;$) {
    my $run = shift;
    my $file = file shift;
    my $explain = shift;

    stdout_is { $run->() } scalar $file->slurp, $explain;
}

my $fastcgi_socket = '127.0.0.1:45450';

stdout_same_as { run_build qw# catalyst/fastcgi apache2 dynamic # } 't/assets/apache2/fastcgi-dynamic';
stdout_same_as { run_build qw# catalyst/fastcgi apache2 standalone --no-bundle # } 't/assets/apache2/fastcgi-standalone';
stdout_same_as { run_build qw# catalyst/fastcgi apache2 standalone --no-bundle --fastcgi-socket #, $fastcgi_socket } 't/assets/apache2/fastcgi-standalone-host-port';
stdout_same_as { run_build qw# catalyst/fastcgi apache2 static # } 't/assets/apache2/fastcgi-static';
stdout_same_as { run_build qw# catalyst/mod_perl # } 't/assets/apache2/mod_perl';
stdout_same_as { run_build qw# catalyst/fastcgi nginx --no-bundle # } 't/assets/nginx/standalone';
stdout_same_as { run_build qw# catalyst/fastcgi nginx --no-bundle --fastcgi-socket #, $fastcgi_socket } 't/assets/nginx/standalone-host-port';
stdout_same_as { run_build qw# catalyst/fastcgi lighttpd standalone --no-bundle # } 't/assets/lighttpd/standalone';
stdout_same_as { run_build qw# catalyst/fastcgi lighttpd standalone --no-bundle --fastcgi-socket #, $fastcgi_socket } 't/assets/lighttpd/standalone-host-port';
stdout_same_as { run_build qw# catalyst/fastcgi lighttpd static --no-bundle --fastcgi-socket /tmp/lighttpd-eg.socket # } 't/assets/lighttpd/static';
stdout_same_as { run_build qw# catalyst/fastcgi start-stop --fastcgi-pid-file eg-fastcgi.pid # } 't/assets/fastcgi-start-stop';
stdout_same_as { run_build qw# catalyst/fastcgi start-stop --fastcgi-pid-file eg-fastcgi-host-port.pid --fastcgi-socket #, $fastcgi_socket } 't/assets/fastcgi-start-stop-host-port';
stdout_same_as { run_build qw# catalyst/fastcgi monit --fastcgi-pid-file eg-fastcgi.pid # } 't/assets/fastcgi-monit';
stdout_same_as { run_build qw# catalyst/fastcgi monit --fastcgi-pid-file eg-fastcgi-host-port.pid # } 't/assets/fastcgi-monit-host-port';
stdout_same_as { run_for_example qw# monit --home /home/rob/monit # } 't/assets/monit';

#$BUILD catalyst/fastcgi/monit --fastcgi-pid-file "eg-fastcgi.pid"
#$BUILD catalyst/fastcgi/monit --fastcgi-pid-file "eg-fastcgi-host-port.pid"
