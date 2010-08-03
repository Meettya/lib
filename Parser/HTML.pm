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

sub ParseHTML{
	my ( $self, $data_in ) = ( @_ );

	my $encode =  &$get_encode( $data_in ); 
	$data_in = decode( $encode , $data_in ); 
	
	my $tree = HTML::TreeBuilder::XPath->new();
	$tree->parse_content( $data_in );

     
	my $p = $tree->findnodes_as_string( 
     '//div[@class="vvodka"]/descendant-or-self::* | //div[@class="vvodka"]/following-sibling::* ');
     
	$tree->delete();
     
	return $p;
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