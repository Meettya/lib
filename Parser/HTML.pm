package Parser::HTML;

use strict;
use warnings;
use utf8;

use Encode qw(decode);
use autouse 'Carp' => qw(carp croak);

use Encode::Detect::Straighten qw(detect);

our $VERSION = 0.0.2;

use Object::Botox qw(new);

use HTML::TreeBuilder::XPath;

our $object_prototype = { 	
					'foo' => undef, # just mock
						};
						
my ( $get_encode );

=nb
Method:ParseHTML
   парсит ОДНУ страницу, возвращая в скаляре строку с данными (т.е. текст) 
   сам делает перекодировку в perl-utf8
Parameter:
    $data_in - страница в сырце как текст скаляра
    @xpath_string - строк(а/и) поиска
Return:
   	$result - скаляр с текстом или пустышка с типом ошибки
=cut

sub ParseHTML(@){
	my ( $result, $self, $data_in, @xpath_string ) = ( undef, @_ );

	my $encode =  &$get_encode( $data_in ); 
	
	do { return wantarray?( undef, 'encode fall' ): undef } unless $encode;
	
	$data_in = decode( $encode , $data_in ); 
	
	my $tree = HTML::TreeBuilder::XPath->new();
	
	eval {
		local $SIG{__WARN__} = sub{}; #Temporarily suppress warnings
		$tree->parse_content( $data_in );
	};
	
 	if ( $@ ){
 	    # anyway, clean up ! kill the tree !
 		$tree->delete();
		undef $tree;
 		return wantarray?( undef, 'parse fall' ): undef;
	}
	
	do{return wantarray?( undef, 'xpatch empty' ): undef} if 
			( !defined $xpath_string[0] );
	# вот тут собираем все имеющиеся у нас образцы в любом варианте вызова
	my @xpatch_all = $#xpath_string > 0 ? @xpath_string :
			ref $xpath_string[0] eq 'ARRAY' ? 
				@{$xpath_string[0]} : ( $xpath_string[0] );
	
	my @temp_result;
	
	foreach my $val ( @xpatch_all ){
			push @temp_result , $tree->findnodes_as_string( $val );
	}
	
	if ( $#temp_result > 0 ){	
			( $result ) = ( sort { length $b <=> length $a } @temp_result );
	}
	else {
		$result = $temp_result[0];
	}
	
    # anyway, clean up ! kill the tree !
	$tree->delete();
	undef $tree;
	undef @temp_result;
	
 	if ( !$result ){
		return wantarray?( undef, 'xpatch mismatch' ): undef;
	}
	else{
		return wantarray?( $result, undef ): $result;
	}
	
}


=nb
Method : get_encode
    служит для определения кодировки документа
    сначала пытаемся найти описание в теге meta простым regexp, 
    а если не помогает - идет за тяжелой артилерией в виде 
    Encode::Detect::Straighten (выпрямитель к detect)
=cut

$get_encode = sub ($){

	my %code_map = qw( x-mac-cyrillic CP1251 IBM866 CP866 );
	my $data = shift;

    $data =~ /<\s*meta[^>]+charset\s*=\s*(.+?)\s*(?:'|")[^>]+>/;

	return !$1 ? detect( $data ) : $code_map{$1} || $1;
	
};


1;
						
__END__

Так. Самое интенесное, конечно же, будет в этом модуле, посколько здесь будем пытаться парсить HTML.
Итого, мы ВЫДЕРГИВАЕМ здесь контент, а фильтр будет лишь чистить результат до более приличного состояния

Что теперь у нас тут делается - мы скармливаем модулю скаляр, получая в скаляре результат (при вызове списком - результат + ошибка )

Разбор делается HTML::TreeBuilder::XPath - не супер быстро, зато надежно и эффективно с точки зрения описания что и как нам надо найти.
Рубит вместе с будкой, т.е. дальше нужно пустить фильтр по результатам, для очистки инфы от лишнего хлама. Фильтр будем уже на регулярках писать.

ToDo - подумать куда пихнуть описания , возможно имеет смысл давать несколько шаблонов для поиска, пусть проходится по ним и возврашает что найдет ( как вариант - сравнивать длину возврата )
Как в leech перевести в виртуальный метод, а интерфейс привязать к вызову?...

Сделал проще, теперь можно отдавать несколько шаблонов, оно само вернет максимальной длины строку.