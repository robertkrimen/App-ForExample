.PHONY: all test clean distclean dist build-all test-all

FOR_EXAMPLE_EG := ./script/for-example-eg
FOR_EXAMPLE := ./script/for-example

HOST_PORT_SOCKET="127.0.0.1:45450"

all: test

dist:
	rm -rf inc META.y*ml
	perl Makefile.PL
	$(MAKE) -f Makefile dist

install distclean tardist: Makefile
	$(MAKE) -f $< $@

test: Makefile
	TEST_RELEASE=1 $(MAKE) -f $< $@

Makefile: Makefile.PL
	perl $<

clean: distclean

reset: clean
	perl Makefile.PL
	$(MAKE) test

build-all:
	$(FOR_EXAMPLE_EG) catalyst/fastcgi apache2 dynamic > t/assets/apache2/fastcgi-dynamic
	$(FOR_EXAMPLE_EG) catalyst/fastcgi --bare apache2 standalone > t/assets/apache2/fastcgi-standalone
	$(FOR_EXAMPLE_EG) catalyst/fastcgi --bare --fastcgi-socket $(HOST_PORT_SOCKET) apache2 standalone > t/assets/apache2/fastcgi-standalone-host-port
	$(FOR_EXAMPLE_EG) catalyst/fastcgi apache2 static > t/assets/apache2/fastcgi-static
	$(FOR_EXAMPLE_EG) catalyst/mod_perl > t/assets/apache2/mod_perl
	$(FOR_EXAMPLE_EG) catalyst/fastcgi --bare nginx > t/assets/nginx/standalone
	$(FOR_EXAMPLE_EG) catalyst/fastcgi --bare --fastcgi-socket $(HOST_PORT_SOCKET) nginx > t/assets/nginx/standalone-host-port
	$(FOR_EXAMPLE_EG) catalyst/fastcgi --bare lighttpd standalone > t/assets/lighttpd/standalone
	$(FOR_EXAMPLE_EG) catalyst/fastcgi --bare --fastcgi-socket $(HOST_PORT_SOCKET) lighttpd standalone > t/assets/lighttpd/standalone-host-port
	$(FOR_EXAMPLE_EG) catalyst/fastcgi --fastcgi-socket /tmp/lighttpd-eg.socket lighttpd static > t/assets/lighttpd/static
	$(FOR_EXAMPLE_EG) catalyst/fastcgi/start-stop --fastcgi-pid-file "eg-fastcgi.pid" > t/assets/fastcgi-start-stop
	$(FOR_EXAMPLE_EG) catalyst/fastcgi/start-stop --fastcgi-pid-file "eg-fastcgi-host-port.pid" --fastcgi-socket $(HOST_PORT_SOCKET) > t/assets/fastcgi-start-stop-host-port
	$(FOR_EXAMPLE_EG) catalyst/fastcgi/monit --fastcgi-pid-file "eg-fastcgi.pid" > t/assets/fastcgi-monit
	$(FOR_EXAMPLE_EG) catalyst/fastcgi/monit --fastcgi-pid-file "eg-fastcgi-host-port.pid" > t/assets/fastcgi-monit-host-port
	$(FOR_EXAMPLE) monit --home /home/rob/monit > t/assets/monit
	$(FOR_EXAMPLE) -h >t/assets/help-h 2>&1
	$(FOR_EXAMPLE) --help >t/assets/help 2>&1
	cp t/assets/fastcgi-start-stop* Eg/
	cat t/assets/fastcgi-monit*

test-all:
	./script/test-all
