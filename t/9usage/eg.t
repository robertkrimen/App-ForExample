
HOST_PORT_SOCKET="127.0.0.1:45450"

$BUILD catalyst/fastcgi apache2 dynamic > t/assets/apache2/fastcgi-dynamic
$BUILD catalyst/fastcgi --no-bundle apache2 standalone > t/assets/apache2/fastcgi-standalone
$BUILD catalyst/fastcgi --no-bundle --fastcgi-socket $HOST_PORT_SOCKET apache2 standalone > t/assets/apache2/fastcgi-standalone-host-port
$BUILD catalyst/fastcgi apache2 static > t/assets/apache2/fastcgi-static
$BUILD catalyst/mod_perl > t/assets/apache2/mod_perl
$BUILD catalyst/fastcgi --no-bundle nginx > t/assets/nginx/standalone
$BUILD catalyst/fastcgi --no-bundle --fastcgi-socket $HOST_PORT_SOCKET nginx > t/assets/nginx/standalone-host-port
$BUILD catalyst/fastcgi --no-bundle lighttpd standalone > t/assets/lighttpd/standalone
$BUILD catalyst/fastcgi --no-bundle --fastcgi-socket $HOST_PORT_SOCKET lighttpd standalone > t/assets/lighttpd/standalone-host-port
$BUILD catalyst/fastcgi --fastcgi-socket /tmp/lighttpd-eg.socket lighttpd static > t/assets/lighttpd/static
$BUILD catalyst/fastcgi/start-stop --fastcgi-pid-file "eg-fastcgi.pid" > t/assets/fastcgi-start-stop
$BUILD catalyst/fastcgi/start-stop --fastcgi-pid-file "eg-fastcgi-host-port.pid" --fastcgi-socket $HOST_PORT_SOCKET > t/assets/fastcgi-start-stop-host-port
$BUILD catalyst/fastcgi/monit --fastcgi-pid-file "eg-fastcgi.pid"
$BUILD catalyst/fastcgi/monit --fastcgi-pid-file "eg-fastcgi-host-port.pid"
