use inc::Module::Install;
name 'CPAN-Command-Repo';
all_from 'lib/CPAN/Command/Repo.pm';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
