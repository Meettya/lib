#!/opt/local/bin/perl -w

use strict;

use Test::More qw(no_plan);

use lib qw(../);

use_ok( 'Filter::Url', qw(new) );
can_ok('Filter::Url', qw(new getUniqueURL saveProcessedURL) );

my $filter = new_ok( 'Filter::Url' => [{ 'storehouse' => MockStore->new() }] );

my @list_test = qw(one two two three);
my $unique_test = [qw(one two three)];



my $unique_list = $filter->getUniqueURL(\@list_test);

is_deeply( $unique_list, $unique_test, "simply unique" );
				
ok( $filter->saveProcessedURL($unique_list), "save" );

is_deeply( $filter->getUniqueURL( ['four', @list_test] ),
							['four'], "saved unique check" );



=pod
	тут у нас реализация хранилища с 2-мя методами save && get_unique
	по сути это mock-объект как оно есть
=cut

{ package MockStore;

sub new{
    return bless( { store => undef }, shift );
}

sub save{
		
		my $self = shift;
		my $urls = shift;
		my $dub_store = $self->{store};
		if ( defined $dub_store ) {
			$self->{store} = [@$dub_store, @$urls]
		}
		else {
			$self->{store} = $urls
		}
		return 1;
}

sub get_unique{
		
		my $self = shift;
		my $urls = shift;

		my $dub_store = $self->{store};
		
		return $urls if ( ! defined $dub_store || $#$dub_store == -1 );
		
		my %seen; # lookup table
		my @aonly;# answer

		# build lookup table
		@seen{@$dub_store} = ();

		foreach my $item (@$urls) {
    		push(@aonly, $item) unless exists $seen{$item};
		}
			
		return \@aonly;
}

1;

}

__END__

Вот тут немного порассуждаем на тему testability и прочего.
Если мы хотим получать объекты, которые можно тестировать, их связанность должна 
быть минимальной.
Т.е. никаких sql запросов и коннектов в фильтре.

Только фильтрация списка, для этого на вход объекта отдаем некое абстрактное "хранилище" с интерфейсом, которое как-то само реализует этот интерфейс.
Таким образом связанность практически нулевая, все зависит только от абстракции ( ну почти ), кроме того реализация тестового mock-объекта дает нам представление об интерфейсе и типе данных на входе и выходе.