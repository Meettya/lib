#!/opt/local/bin/perl -w

use strict;

use Test::More qw(no_plan);

use lib qw(../);

use_ok( 'Store::Local', qw(new) );
can_ok('Store::Local', qw(new saveList getUniqueList) );

my $db_name = './t/spider.db' ;
my $table_name = 'url_list';
			
my $store = new_ok( 'Store::Local' => [{ database => $db_name ,
					table => $table_name }] );

# void init test (yes, we are not check it on new() )
subtest 'Void creation' => sub {	
	plan tests => 3;
	foreach ([ undef, undef ],[ $db_name, undef ],[ undef, $table_name ]){
		my $obj = Store::Local->new({ database => $_->[0] , table => $_->[1] });
		eval{ $obj->init() };
		isnt ( $@, '');
	}	
  };

ok ( $store->init(), "init" );

ok ( $store->saveList([qw( one two three two )]), "save" );

#check getUniqueList
subtest 'Check unuque' => sub {	
	plan tests => 3;
	ok ( ! $store->getUniqueList(), "void unique" );
	ok( ! $store->getUniqueList([qw( three two )]), "list unique 1" );
	is_deeply ( $store->getUniqueList([qw( four three one )]), 
											['four'], "list unique 2" );
};

# ok, clean up after test
`rm $db_name` if ( -e $db_name && -f _ && -s _ );