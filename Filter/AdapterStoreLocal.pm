package Filter::AdapterStoreLocal;

use strict;
use warnings;

use Store::Local;

our $VERSION = 0.0.2;
	
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

1;

__END__

Это декоратор для Store::Local, подменяющий его интерфейс на требуемый Filter::Url.
таким образом мы можем спаривать разноинтерфейсные объекты, не внося изменений и непоняток в них, отделяя абстракцию от реализации ( кажется ).

Покрывать его тестамим смысла нет, оно тестируется тестом 02_filter...
