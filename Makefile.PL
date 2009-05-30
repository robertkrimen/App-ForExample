use inc::Module::Install;

name     'App-ForExample';
all_from 'lib/App/ForExample.pm';
author   'Robert Krimen <rkrimen@cpan.org>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

