package WWW::RssFeed;

use strict;
use warnings;
use utf8;

our $VERSION = 1.2.1;

use Encode qw( from_to decode );
use autouse 'Carp' => qw(carp croak);
use XML::Bare;
use HTTP::Date qw( parse_date str2time );

use Object::Botox qw(new);
use Encode::Detect::Straighten;
use WWW::Leech;

# yes! we are have properies
our $object_prototype = { 	
			'parse_ro' 			=> undef,	# parse feed
			'clean' 			=> undef,	# clear qw( description pubDate )
						};

my $leech = WWW::Leech->new( agent_shuffle => 1 ); # turn ON agent_shuffle

my ( $get_feed, $get_encode, $get_date, $parse_feed, $encode_feed, $clean_feed );


=data
Структура данных в выдаче объекта

$foo->{url}{ status => [],  - стек статуса, храним историю
			 data => $ } - данные, при этом сырец хранить не надо	
=cut


=pod
Method: getFeed
	получает и обрабатывает rss-поток
in: url|(url,) 
		список с url
    
out: { url => {status, data} }
		хеш с данными

=cut

sub getFeed{
        
    my $self = shift;    
    my $raw_feed = &$get_feed(@_);
        
    foreach ( keys %$raw_feed ){

    	next unless ( $raw_feed->{$_}{status}[0] eq '200' );

    	# encoding to utf8
		&$encode_feed( $self, $raw_feed->{$_} );
    	
    	# parse
    	&$parse_feed( $self, $raw_feed->{$_} ) 
    		if ( defined $self->parse && $self->parse == 1 );

    	#clean
    	&$clean_feed( $self, $raw_feed->{$_} )
    		if ( defined $self->clean );
		

    }

    return $raw_feed;
}


=nb
Method:encode_feed
    делает перекодировку ленты
Parameter:
    $feed - сырые данные
Return:
    $feed - перекодированные данные (utf8 && flag on) 
=cut

$encode_feed = sub ($$){

    my ( $self, $feed ) = ( @_ );  
    my $encode =  &$get_encode( $feed->{data} );   
    $feed->{data} = decode( $encode, $feed->{data} );
    push @{$feed->{status}}, 'encoded';
    return $feed;
};

=nb
Method:parse_feed
    парсинг лент в хеш-структуру
Parameter:
    $feed - хеш лент с сырыми данными
Return:
    $feed - хеш лент с распарсенными данными
=cut
$parse_feed = sub ($$){

    my ( $self, $feed ) = ( @_ );    
	my $rss_parser = XML::Bare->new( text => $feed->{data} );
	my $data = $rss_parser->parse();
	if ( ref $data eq 'HASH' ){
		$feed->{data} = $data;
		push @{$feed->{status}}, 'parsed';
	}    	 	
    return $feed;
};

=nb
Method:clean_feed
   компонует ЧИСТЫЕ данные, убирая все лишнее от выдачи XML::Bare.
   Кроме того может чистить поля ( $self->clean(['pubDate']) например )
Parameter:
    $feed - хеш лент с распарсенными данными
Return:
   	$result - хеш с очищенными данными
=cut

$clean_feed = sub ($$){

    my ( $data, $self, $feed ) = ( undef, @_ );
	
	my %settings = map { $_ , 1 } @{$self->clean} 
			if ( ref $self->clean eq 'ARRAY' );
	
	# разбор для распарсенного содержимого
	if ( $feed->{status}[-1] eq 'parsed' ){
	
		foreach my $item (@{$feed->{data}{rss}{channel}{item}}) {

			next unless ( defined $item->{'title'} && defined $item->{'link'});
			
			my %con;
			@con{qw( title link )} = 
						map { $_->{'value'} } @{$item}{qw( title link )};

			$con{'description'} = $item->{'description'}{'value'} || ''; 
			$con{'description'} =~ s/&lt;.+&gt;//g
				if ( defined $settings{'description'} );
				
			$con{'pubDate'} = defined $settings{'pubDate'} ? 
					&$get_date( $item->{'pubDate'}{'value'} ) :
						$item->{'pubDate'}{'value'};		
			
			$con{'category'} = $item->{'category'}{'value'} || undef ;			
	
			push @$data, \%con;
		}
	}
	# теоретически здесь пойдет разбор непарсенного содержимого
	# но пока он мне не нужен
	
	
	if ( $#{$data} >=0 ){
		$feed->{data} = $data;
		push @{$feed->{status}}, 'cleaned';
	}
	return $feed;
};


=nb
Method : get_feed
    по сути обертка над методом Leech::suck
=cut
$get_feed = sub (@){
    return $leech->suck(@_);
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

=encoding utf-8

=pod

=head1 NAME

RssFeed - get && parse RSS feed data.

=head1 SYNOPSIS

RssFeed служит для скачивания и обработки ( парсинг, чистка ) RSS лент

	use RssFeed;
	my $feed = RssFeed->new( {'parse' => 1,  'clean' => [qw( description pubDate )] } );
	$feed->encoding( 'UTF-8' );
	my $data_feed = $feed->getFeed( $url1, $url2 );

=head1 DESCRIPTION

RssFeed создан для упрощения работы с RSS-лентами.

Использовать совершенно элементарно:

	use RssFeed;
	my $feed = RssFeed->new( {'parse' => 1,  'clean' => [qw( description pubDate )] } );
	$feed->encoding( 'UTF-8' );
	my $data_feed = $feed->getFeed( $url1, $url2 );

Модуль имеет только один метод - B<getFeed>.
Вызывается со скаляром или списком.

На выходе B<всегда> получаем ссылку на хеш вида 
	
	{ url => { status => '', data => ''}}

Состояние 	data 	- полиморф, в зависимости от настроек.
			status 	- стек статуса операций, совершенных над/с data.



=head1 AUTOR	

Meettya <L<meettya@gmail.com>>

=head1 BUGS

Вероятно даже в таком объеме кода могут быть баги. Пожалуйста, сообщайте мне об их наличии по указаному e-mail или любым иным способом.

=head1 SEE ALSO



=head1 COPYRIGHT

B<Moscow>, spring 2010. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

