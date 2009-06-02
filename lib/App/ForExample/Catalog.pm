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
    ServerName [% hostname %]
    ServerAlias www.[% hostname %]

    CustomLog "|/usr/bin/cronolog /var/log/apache2/[% hostname %]-%Y-%m.access.log -S /var/log/apache2/[% hostname %].access.log" combined
    ErrorLog "|/usr/bin/cronolog /var/log/apache2/[% hostname %]-%Y-%m.error.log -S /var/log/apache2/[% hostname %].error.log"
_END_

            'catalyst/apache2/fastcgi-rewrite-rule' => <<'_END_',
    [%- IF base.length -%]
    # Optionally, rewrite the path when accessed without a trailing slash
    RewriteRule ^/[% base %]\$ [% base %]/ [R]
    [%- END -%]
_END_

        },

        'catalyst/fastcgi/apache2/static' => \<<'_END_',
# vim: set filetype=apache
<VirtualHost *:80>

[% INCLUDE "catalyst/apache2/name-alias-log" -%]

    FastCgiServer [% fastcgi_script %] -processes 3

    Alias [% alias_base %] [% fastcgi_script %]/

[% INCLUDE "catalyst/apache2/fastcgi-rewrite-rule" -%]

</VirtualHost>
_END_

        'catalyst/fastcgi/apache2/standalone' => \<<'_END_',
# vim: set filetype=apache
<VirtualHost *:80>

[% INCLUDE "catalyst/apache2/name-alias-log" -%]

    FastCgiExternalServer [% fastcgi_socket_path %] [% fastcgi_host_port ? "-host" : "-socket" %] [% fastcgi_socket %]

    Alias [% alias_base %] [% fastcgi_socket_path %]/

[% INCLUDE "catalyst/apache2/fastcgi-rewrite-rule" -%]

     <Directory "[% home %]/root">
         Options Indexes FollowSymLinks
         AllowOverride All
         Order allow,deny
         Allow from all
     </Directory>

</VirtualHost>
_END_

        'catalyst/fastcgi/apache2/dynamic' => \<<'_END_',
# vim: set filetype=apache
<VirtualHost *:80>

[% INCLUDE "catalyst/apache2/name-alias-log" -%]

    # TODO Need trailing slash?
    Alias [% alias_base %] [% fastcgi_script %]/

[% INCLUDE "catalyst/apache2/fastcgi-rewrite-rule" -%]

    <Directory "[% home %]/script">
       Options +ExecCGI
    </Directory>

    <Files "[% fastcgi_script_basename %]">
       SetHandler fastcgi-script
    </Files>

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

PID_FILE="[% fastcgi_pid_file %]"

case "$1" in
    start)
        echo "Starting"
        [% fastcgi_script %] -l [% fastcgi_socket %] -n 5 -p $PID_FILE
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
check process [% name %]-fastcgi with pidfile [% fastcgi_pid_file %]
  start program = "[% home %]/fastcgi-start-stop start"
  stop program  = "[% home %]/fastcgi-start-stop stop"
_END_

        'catalyst/fastcgi/lighttpd/standalone' => \<<'_END_',
server.modules += ( "mod_fastcgi" )

$HTTP["host"] =~ "^(www.)?[% hostname %]" {
    fastcgi.server = (
        "" => (
            "[% name %]" => (
                [% IF fastcgi_host_port %]
                "host" => "[% fastcgi_host_port.0 %]",
                "port" => [% fastcgi_host_port.1 %],
                [% ELSE %]
                "socket" => "/tmp/[% name %].socket",
                [% END %]
                "check-local" => "disable"
            )
        )
    )
}
_END_

        'catalyst/fastcgi/lighttpd/static' => \<<'_END_',
server.modules += ( "mod_fastcgi" )

$HTTP["host"] =~ "^(www.)?[% hostname %]" {
    fastcgi.server = (
        "" => (
            "[% name%]" => (
                "socket" => "[% fastcgi_socket %]",
                "check-local" => "disable",
                "bin-path" => "[% fastcgi_script %]",
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
    server_name [% hostname %];
    location / {
        include fastcgi_params;
        [% IF fastcgi_host_port %]
        fastcgi_pass [% fastcgi_socket %];
        [% ELSE %]
        fastcgi_pass unix:[% fastcgi_socket %];
        [% END %]
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
