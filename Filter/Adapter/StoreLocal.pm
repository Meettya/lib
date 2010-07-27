package Filter::Adapter::StoreLocal;

use strict;
use warnings;

use Store::Local;

our $VERSION = 0.0.2;
	
sub new(@){
	my $self = shift;
	my $store = Store::Local->new( @_ );
	# yeah! need to init() DB object
	$store->init();
	# да, массив! быстрее
	return bless [$store], $self;
}

sub save(@){
	shift->[0]->saveList( @_ )
}

sub get_unique(@){
	shift->[0]->getUniqueList( @_ )
}

1;

__END__

Это декоратор для Store::Local, подменяющий его интерфейс на требуемый Filter::Url.
таким образом мы можем спаривать разноинтерфейсные объекты, не внося изменений и непоняток в них, отделяя абстракцию от реализации ( кажется ).

Покрывать его тестамим смысла нет, оно тестируется тестом 02_filter...
