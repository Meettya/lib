#!/opt/local/bin/perl -w

use strict;
use lib qw(../);

use Test::More qw(no_plan);

use_ok( 'Filter::Url', qw(new) );

# делаем путь к базе независимым от точки запуска теста
( my $db_path = $INC{'Store/Local.pm'} ) =~ s/Local\.pm$// ;
my $db_name = $db_path.'t/spider.db' ;

my $table_name = 'url_list';

# ага, вот этот тест ОЧЕНЬ нужен, если не хочешь получить 
# непонятные ошибки в 'simply unique' и 'save'
ok ( !( -e $db_name && -f _ && -s _ ), 'DB not exists');

my $filter = new_ok( 'Filter::Url' => 
			[{ 'storehouse' => AdapterStore->new( { database =>  $db_name, 
											table => $table_name } ) }] );

my @list_test = qw(one two two three);
my $unique_test = [qw(one two three)];


my $unique_list = $filter->getUniqueURL(\@list_test);

is_deeply( $unique_list, $unique_test, "simply unique" );
 				
ok( $filter->saveProcessedURL($unique_list), "save" );

is_deeply( $filter->getUniqueURL( ['four', @list_test] ),
							['four'], "saved unique check" );


###########
# класс адаптора хранилища к фильтру

{ package AdapterStore;
	
	use Store::Local;
	
	sub new{
		my $self = shift;
		my $store = Store::Local->new( @_ );
		# yeah! need to init() DB object
		$store->init();
		return bless( { store => $store }, $self );
	}
	
	sub save{
		my $self = shift;
		return $self->{store}->saveList(@_)
	}
	
	sub get_unique{
		my $self = shift;
		return $self->{store}->getUniqueList(@_)
	}
	
	sub DESTROY{
		my $self = shift;
		my $db_name = $self->{store}->database();
		# YES! we are kill db after test! Live fast die young !!!
		`rm $db_name` if ( -e $db_name && -f _ && -s _ );
	}
	
	1;
}



__END__

в общем тут все просто - пишем тест, который проверяет работоспостобность фильтра И локального хранилища. Может не слишком наглядно, зато экспа в совмещении и использование IOC, вероятно.

Итого, что у нас тут получилось: 
	проверка фильтра с использованием локального хранилища удалась на славу.
	потребовался адаптер для совмещения интерфейсов хранилища и фильтра, т.к.  методы были созданы с разными именами специально для принятия решения в таком вот неудобном случае.
	
	Навреное адаптер должен быть вынесен в отдельный класс, только не совсем понятно, к какому классу он должен относится. С одной стороны - это обертка к хранилищу, с другой - она нужна ДЛЯ фильтра. Похоже пихать ее надо в фильтр, подумать.