package Filter::Url;

use strict;
use warnings;
use utf8;

our $VERSION = 0.1.4;

use Object::Botox qw(new);

our $object_prototype = {
				'storehouse' => undef, # хранилище для ссылок - ссылка на объект с методами get_unique и save внутри. По сути - абстракция над любым хранилищем
				# вот тут тоже кое-что интересное - это коллбек для функций сохранения и выборки уникальных записей.
				'save' => undef, # колбек для функции сохранения
				'get_unique' => undef, # колбек для функции выбора уникальных
				};

sub getUniqueURL($$){
	
	my ( $self, $in_urls ) = ( @_ );
		
	return undef if ( $#{$in_urls} == -1 );
	
	# жмем входяший список в уникальные
	my %seen = ();
	my @unique = grep { ! $seen{$_} ++ } @$in_urls;
	
	return $self->get_unique()->( $self->storehouse(), \@unique );
	
}

sub saveProcessedURL($$){

	my ( $self, $in_urls ) = ( @_ );
	
	return undef if ( $#{$in_urls} == -1 );

	return $self->save()->( $self->storehouse(), $in_urls );
	
}


__END__

=encoding utf-8

=pod

=head1 NAME

Filter::Url - служит для фильтрации ссылок.

=head1 SYNOPSIS

Filter::Url 

=head1 DESCRIPTION

Filter::Url решает проблему фильтрации задач, с целью исключения повторной обработки записей, идентифицируемых ссылками.

Для этого модулю требуются следуюшие методы:

	1) getUniqueURL - из списка ссылок делаем уникальный список с записями, которые еще не зафиксированы в системе.
	2) saveProcessedURL - сохраняет в системе новые ссылки, которые были обработаны.
	
т.е. при создании объекта он должен получать ссылку на хранилище и взаимодействовать с ним с использованием стандартного интерфейса, описаного в callback-функции save && get_unique.

	get_unique и save , оба получают на вход ссылку на массив
	
Таким образом можно совершенно спокойно использовать ЛЮБОЕ хранилище для ссылок, реализовав его на том, что удобнее.