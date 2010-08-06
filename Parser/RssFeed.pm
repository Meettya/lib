package Parser::RssFeed;

use strict;
use warnings;
use utf8;

use Encode qw( from_to decode );
use autouse 'Carp' => qw(carp croak);
use XML::Bare;
use HTTP::Date qw( parse_date str2time );

use Encode::Detect::Straighten;

our $VERSION = 0.0.2;

use Object::Botox qw(new);


our $object_prototype = { 	
					'clean'	=> undef,	# clean qw( description pubDate )
					# pubDate - гарантирует нам, что дата будет актуальна
						};


# это объявление private-методов модуля
my ( $get_encode, $get_date, $clean_feed );

=nb
Method:ParseRSS
   парсит ОДНУ ленту, возвращая массив хешей готовой ленты
Parameter:
    $data_in - лента в сырце
Return:
   	$result - ссылка на массив хешей данных или пустышка с типом ошибки
=cut

sub ParseRSS($$){
	my ( $result, $self, $data_in ) = ( undef, @_ );
	
	#-> вот тут должна быть проверка на encode (не совсем понятно, на каких данных это можно получить, но пусть будет)
	my $encode =  &$get_encode( $data_in ); 
	do { return wantarray?( undef, 'encode fall' ): undef } unless $encode;
	$data_in = decode( $encode , $data_in ); 
	my $data;
    { 
    	local $SIG{__WARN__}=sub{}; #Temporarily suppress warnings
		my $rss_parser = XML::Bare->new( text => $data_in );
		$data = eval{ $rss_parser->parse() };
	}
  	#-> вот тут должна быть проверка на то, что парсинг прошел успешно
	do { return wantarray?( undef, 'parse fall' ): undef } if ( $@ );
	
  	$result = &$clean_feed( $self, $data );
  		
    return wantarray?( $result, undef ): $result;

}

=nb
Method:clean_feed
   компонует ЧИСТЫЕ данные, убирая все лишнее от выдачи XML::Bare.
   Кроме того может чистить поля ( $self->clean(['pubDate']) например )
Parameter:
    $feed - лента с распарсенными данными
Return:
   	$result - ссылка на массив
=cut

$clean_feed = sub ($$){

    my ( $data, $self, $feed ) = ( undef, @_ );
	
	my %settings = map { $_ , 1 } @{$self->clean()} 
			if ( ref $self->clean eq 'ARRAY' );
	

	foreach my $item (@{$feed->{rss}{channel}{item}}) {

		next unless ( defined $item->{'title'} && defined $item->{'link'});
		
		my %con;
		@con{qw( title link )} = 
					map { $_->{'value'} } @{$item}{qw( title link )};

		$con{'description'} = $item->{'description'}{'value'} || ''; 
		
		# пока примитивный фильтр, как вариант можно сделать хитрый коллбек 
		# в хитрый фильтр, если понадобится
		$con{'description'} =~ s/&lt;.+&gt;//g
			if ( defined $settings{'description'} );
			
		$con{'pubDate'} = defined $settings{'pubDate'} ? 
				&$get_date( $item->{'pubDate'}{'value'} ) :
					$item->{'pubDate'}{'value'};		
		
		$con{'category'} = $item->{'category'}{'value'} || undef ;			

		push @$data, \%con;
	}

	return $data;
};


=nb
Method : get_encode
    служит для определения кодировки документа
    сначала пытаемся найти описание в xml простым regexp, а если не помогает -
    идет за тяжелой артилерией в виде 
    Encode::Detect::Straighten (выпрямитель к detect)
=cut
$get_encode = sub ($){

    my $data = shift;
    $data =~ /^[^>]+encoding\s?=\s?('|")(.+?)\1/;
	return $2 || detect( $data );
	
};

=nb
Method: get_date
	служит для получения валидной даты из того, что идет в потоке
	а идти там может что угодно
=cut
$get_date = sub ($){

	#  to 2010-06-18 11:59:24+0400 -> to 1276847964 unix
	#  OR NOW()		
	return ( str2time( parse_date( +shift ) ) || time ); 

};


1;

__END__

Очередня попытка реинкарнации парсера RSS.
Пробуем сделать его максимально гибким, настраиваемым и простым в использовании.
**похоже будет не так просто как хотелось бы**

Настройки модуля - стандартно, в прототип.

Что нужно от этого модуля - он должен получать на входе rss-ленту (одну или несколько списком) и распарсить их, после чего должны быть возвращены обработанные данные в виде хеша { лента => данные, }

Модуль сильно связан с XML::Bare, это нормально и этого мы не меняем.
Модуль должне уметь делать перекодировку текста в требуемый и дополнять критичные для следующей логики данные "заглушками", т.е. возврат модуля должен быть лексически-безопасен.

Чего модуль не делает - он ничего не качает и ничего никуда не сохраняет.

Раз он ничего никуда не сохраняет, то и проблема ЦЕЛЕВОЙ кодировки - не его.
Для того, чтобы работать с данными, нам нужен perl-utf8, вот в него мы и перегоняем получаемые данные.
