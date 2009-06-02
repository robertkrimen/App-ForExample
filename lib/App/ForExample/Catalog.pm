package App::ForExample::Catalog;

use strict;
use warnings;

{
    my ( @catalog, $catalog );
    sub catalog {
        return $catalog ||= { @catalog };
    }
    push @catalog,

        'common' => {
            'catalyst/apache2/name-alias-log', => <<'_END_',
    ServerName [% host %]
    ServerAlias www.[% host %]

    CustomLog "|/usr/bin/cronolog /var/log/apache2/[% host %]-%Y-%m.access.log -S /var/log/apache2/[% host %].access.log" combined
    ErrorLog "|/usr/bin/cronolog /var/log/apache2/[% host %]-%Y-%m.error.log -S /var/log/apache2/[% host %].error.log"
_END_

            'catalyst/apache2/fastcgi-rewrite-rule' => <<'_END_',
    Alias [% alias_base %] [% home %]/script/[% underscore_name %]_fastcgi.pl/

    [%- IF base.length -%]
    # Optionally, rewrite the path when accessed without a trailing slash
    RewriteRule ^/[% base %]\$ [% base %]/ [R]
    [%- END -%]
_END_

        },

        'catalyst/fastcgi/apache2/static' => \<<'_END_',
<VirtualHost *:80>

[% INCLUDE "catalyst/apache2/name-alias-log" -%]

    FastCgiServer [% home %]/script/[% underscore_name %]_fastcgi.pl -processes 3
[% INCLUDE "catalyst/apache2/fastcgi-rewrite-rule" -%]

</VirtualHost>
_END_

        'catalyst/fastcgi/apache2/standalone' => \<<'_END_',
# vim: set ft=apache
<VirtualHost *:80>

[% INCLUDE "catalyst/apache2/name-alias-log" -%]

    FastCgiExternalServer [% fastcgi_file %] -socket [% fastcgi_socket %]
[% INCLUDE "catalyst/apache2/fastcgi-rewrite-rule" -%]

     <Directory "[% home %]/root">
         Options Indexes FollowSymLinks
         AllowOverride All
         Order allow,deny
         Allow from all
     </Directory>

</VirtualHost>
_END_

        'catalyst/mod_perl/apache2' => \<<'_END_',
PerlSwitches -I[% home %]/lib
PerlModule [% package %]

<VirtualHost *:80>

[% INCLUDE "catalyst/apache2/name-alias-log" -%]

    <Location />
        SetHandler          modperl
        PerlResponseHandler [% package %]
    </Location>

</VirtualHost>
_END_

        'catalyst/fastcgi/start-stop' => \<<'_END_',
#!/bin/bash
# A very basic start-stop script, see also:
# http://dev.catalystframework.org/wiki/gettingstarted/howtos/deploy/lighttpd_fastcgi

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
        sleep 2
        $0 start
    ;;
    *)
        echo "Don't understand \"$1\ ($*)"
        echo "Usage: $0 { start | stop | restart }"
        exit -1
    ;;
esac
_END_

        'catalyst/fastcgi/monit' => \<<'_END_',
check process [% name %]-fastcgi with pidfile [% home %]/[% name %]-fastcgi.pid
  start program = "[% home %]/fastcgi start"
  stop program  = "[% home %]/fastcgi stop"
_END_

        'catalyst/fastcgi/apache2/dynamic' => \<<'_END_',
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
_END_

        'catalyst/fastcgi/lighttpd/standalone' => \<<'_END_',
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
_END_

        'catalyst/fastcgi/lighttpd/static' => \<<'_END_',
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
_END_

        'catalyst/fastcgi/nginx' => \<<'_END_',
server {
    server_name [% host %];
    location / {
        include fastcgi_params;
        fastcgi_pass unix:/tmp/[% name %].socket;
    }
}
_END_

        'monit' => \<<'_END_',
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
_END_
        ;
}

1;
