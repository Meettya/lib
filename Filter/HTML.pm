package Filter::HTML;

use strict;
use warnings;
use utf8;

use autouse 'Carp' => qw(carp croak);

our $VERSION = 0.2.4;

use Object::Botox qw(new);

# попробуем использовать ссылку на массив правил очистки
our $object_prototype = {
				'filter' => undef, # хранилище для ссылок на правила очистки 
				'show_error' => undef, # показывать ошибки, по умолчанию НЕ ПОКАЗЫВАТЬ
				'clean_tail' => undef, # чистить в хвосте лишние пробелы
				};

sub DoClearHTML(@){
	my ( $result, $self, $data_in ) = ( undef, @_ );

	do { return wantarray ? ( undef, 'not utf8' ) : undef }
			unless utf8::is_utf8( $data_in );
	
	foreach my $val ( @{$self->filter()} ){
		
		next unless $val->[0];
		
		local $SIG{__WARN__} = sub{} unless $self->show_error() ; #Temporarily suppress warnings		
		
		my $re = qr/$val->[0]/;
		
		# eval "\$data_in =~ s${val};"; # so, it`s ugly, dangerous and slow !		
		$data_in =~ s( $re ){ $val->[1] ? $val->[1]() : '' }geix;
		
	}
	
	$data_in =~ s#\s+$## if $self->clean_tail(); # чистим хвост от мусора
	
	return $data_in;
}


1;

__END__

Это фильтр для очистки html-куска от лишних тегов, свойств и всего прочего.
Работает просто - на вход в filter даем ссылку на массив с массивом типа

	[ '(?:<\s*br\s*/?\s*>\s*)+', sub{"\n"} ]

первый элемет - регулярка (MUST), второй - ссылка на функцию на что меняем (MAY)

на выходе получаем чистый текст в utf8 варианте или ошибку, что на входе не utf8 - какой смысл пытаться что-то делать с данными, которые не будут работать с регуляркой ?
