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

    ServerName xyzzy
    ServerAlias www.xyzzy

    CustomLog "|/usr/sbin/cronolog /var/log/apache2/xyzzy-%Y-%m.access.log -S /var/log/apache2/xyzzy.access.log" combined
    ErrorLog "|/usr/sbin/cronolog /var/log/apache2/xyzzy-%Y-%m.error.log -S /var/log/apache2/xyzzy.error.log"

    FastCgiExternalServer /tmp/xyzzy.fcgi -socket /tmp/xyzzy.socket
    Alias / /tmp/xyzzy.fcgi/

    # Optionally, rewrite the path when accessed without a trailing slash
    RewriteRule ^/\$ / [R]

     <Directory "./xyzzy/root">
         Options Indexes FollowSymLinks
         AllowOverride All
         Order allow,deny
         Allow from all
     </Directory>

</VirtualHost>

# Start your fastcgi socket with the following command:
# script/xyzzy_fastcgi.pl -l /tmp/xyzzy.socket -n 5
_END_

1;
