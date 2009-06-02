#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;
use Test::Output;

plan qw/no_plan/;

use App::ForExample;

sub run {
    App::ForExample->new->run([ @_ ]);
}

stdout_is( sub { run qw#monit --monit-home /monit# }, <<'_END_' );
# Monit control file

set daemon 120
set logfile /monit/log
set pidfile /monit/pid
set statefile /monit/state

set httpd port 2822 and # This port needs to be unique on a system
    use address localhost
    allow localhost

# Put this file in /monit/monitrc
# Use this alias to control your monit daemon:
#
# alias 'my-monit'='monit -vc /monit/monitrc'
#
#   my-monit
#   my-monit start all
#   my-monit quit
#   my-monit validate
#   ...
#
_END_
