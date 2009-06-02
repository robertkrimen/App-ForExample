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

stdout_is( sub { run qw#catalyst/fastcgi apache2 standalone# }, <<'_END_' );
# vim: set ft=apache
<VirtualHost *:80>

    ServerName project-xyzzy.example.com
    ServerAlias www.project-xyzzy.example.com

    CustomLog "|/usr/bin/cronolog /var/log/apache2/project-xyzzy.example.com-%Y-%m.access.log -S /var/log/apache2/project-xyzzy.example.com.access.log" combined
    ErrorLog "|/usr/bin/cronolog /var/log/apache2/project-xyzzy.example.com-%Y-%m.error.log -S /var/log/apache2/project-xyzzy.example.com.error.log"

    FastCgiExternalServer /tmp/project-xyzzy.fcgi -socket /tmp/project-xyzzy.socket
    Alias  /tmp/project-xyzzy.fcgi/

    # Optionally, rewrite the path when accessed without a trailing slash
    # TODO If not /
    RewriteRule ^/\$ / [R]

     <Directory "/home/rob/develop/App-ForExample/root">
         Options Indexes FollowSymLinks
         AllowOverride All
         Order allow,deny
         Allow from all
     </Directory>

</VirtualHost>
---
#!/bin/bash

PID_FILE="/home/rob/develop/App-ForExample/project-xyzzy-fastcgi.pid"

case "$1" in
    start)
        echo "Starting"
        /home/rob/develop/App-ForExample/script/project_xyzzy_fastcgi.pl -l /tmp/project-xyzzy.socket -n 5 -p $PID_FILE
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
---
check process project-xyzzy-fastcgi with pidfile /home/rob/develop/App-ForExample/project-xyzzy-fastcgi.pid
  start program = "/home/rob/develop/App-ForExample/fastcgi start"
  stop program  = "/home/rob/develop/App-ForExample/fastcgi stop"
_END_

1;
