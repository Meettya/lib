#!/opt/local/bin/perl -w

use strict;
use lib qw(../);

use Test::More qw(no_plan);

use_ok( 'Filter::Url', qw(new) );
use_ok( 'Store::Local', qw(new) );

# делаем путь к базе независимым от точки запуска теста
( my $db_path = $INC{'Store/Local.pm'} ) =~ s/Local\.pm$// ;
my $db_name = $db_path.'t/test02.db' ;

my $table_name = 'url_list';


# ага, вот этот тест ОЧЕНЬ нужен, если не хочешь получить 
# непонятные ошибки в 'simply unique' и 'save'
ok ( !( -e $db_name && -f _ && -s _ ), 'DB not exists');
	
my $store = new_ok( 'Store::Local' =>
			[{ database =>  $db_name, table => $table_name }] );

$store->init();			

# сам себе адаптер, по сути - коллбек-функция хранилища
my $filter = new_ok( 'Filter::Url' => [{ 'storehouse' => $store,
			'do_save' => sub{ shift->saveList( @_ ) },
			'do_get_unique' => sub{ shift->getUniqueList( @_ ) }
}] );

my @list_test = qw( one two three two );
my $unique_test = [qw( one two three )];


my $unique_list = $filter->getUniqueURL(\@list_test);

is_deeply( $unique_list, $unique_test, "simply unique" );
 				
ok( $filter->saveProcessedURL($unique_list), "save" );

is_deeply( $filter->getUniqueURL( ['four', @list_test] ),
							['four'], "saved unique check" );

# YES! we are kill db after test! Live fast die young !!!
`rm $db_name` if ( -e $db_name && -f _ && -s _ );


__END__

в общем тут все просто - пишем тест, который проверяет работоспостобность фильтра И локального хранилища. Может не слишком наглядно, зато экспа в совмещении и использование IOC, вероятно.

Итого, что у нас тут получилось: 
	проверка фильтра с использованием локального хранилища удалась на славу.
	потребовался адаптер для совмещения интерфейсов хранилища и фильтра, т.к.  методы были созданы с разными именами специально для принятия решения в таком вот неудобном случае.
	
	Наверное адаптер должен быть вынесен в отдельный класс, только не совсем понятно, к какому классу он должен относится. С одной стороны - это обертка к хранилищу, с другой - она нужна ДЛЯ фильтра. Похоже пихать ее надо в фильтр, подумать.
	
	Вынес к фильтру.
	
	ХА! прописав соответствие коллбеков вызовам интерфейса сделал ненужным наличие адаптора!