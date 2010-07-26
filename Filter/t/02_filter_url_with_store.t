#!/opt/local/bin/perl -w

use strict;

use Data::Dumper;

use Test::More qw(no_plan);

use lib qw(../);




my $filter = new_ok( 'Filter::Url' => [{ 'storehouse' => MockStore->new() }] );



__END__

в общем тут все просто - пишем тест, который проверяет работоспостобность фильтра И локального хранилища. Может не слишком наглядно, зато экспа в совмещении и использование IOC, вероятно.
