package Filter::HTML;

use strict;
use warnings;
use utf8;

use autouse 'Carp' => qw(carp croak);

our $VERSION = 0.1.4;

use Object::Botox qw(new);

# попробуем использовать ссылку на массив правил очистки
our $object_prototype = {
				'filter' => undef, # хранилище для ссылок на правила очистки 
				'show_error' => undef, # показывать ошибки, по умолчанию НЕ ПОКАЗЫВАТЬ
				};

sub DoClearHTML(@){
	my ( $result, $self, $data_in ) = ( undef, @_ );

	foreach my $val ( @{$self->filter()} ){
		
		next unless $val->[0];
		
		local $SIG{__WARN__} = sub{} unless $self->show_error() ; #Temporarily suppress warnings		
		
		my $re = qr/$val->[0]/;
		
		# eval "\$data_in =~ s${val};"; # so, it`s ugly, dangerous and slow !		
		$data_in =~ s( $re ){ $val->[1] ? $val->[1]() : '' }geix;

		
	}
	
	return $data_in;
}



1;

__END__

Это фильтр для очистки html-куска от лишних тегов, свойств и всего прочего.