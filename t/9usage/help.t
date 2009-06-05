#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use t::Test;

stdout_same_as { run_for_example_eg qw# -h # } 't/assets/help-h';
stdout_same_as { run_for_example_eg qw# help # } 't/assets/help';
