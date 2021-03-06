package WWW::Leech;

use strict;
use warnings;
use utf8;

our $VERSION = 1.4.5;
use YAML;
use WWW::Curl::Easy;
use WWW::Curl::Multi;

use autouse 'Carp' => qw(carp croak);

use Object::Botox qw(new);

sub _prototype_{ 	
				'agent_shuffle'	=> undef, 	# do shuffle useragent
					};

my $curlm = WWW::Curl::Multi->new();


my ($do_download, $get_useragent, $do_mass_download);

# конфиг берем из файлика, получая из $INC полный путь к каталогу
( my $config_path = $INC{'WWW/Leech.pm'} ) =~ s/\.pm// ;
my $config = YAML::LoadFile( $config_path.'/config.yml' );
my $agent_list = $config->{agent_list};

=pod
Method: suck
	скачивает данные
Parameter:
    $url|($url,)
    скаляр или список
Returns:
	{ url => { status, data, header } }
	хеш с данными
=cut

sub suck{
	
	my ( $self, @url ) = @_ ;

	if ( $#url == 0 ){
		return &$do_download( $self, $url[0] );
	}
	elsif ( $#url > 0 ){
		return &$do_mass_download( $self, \@url );
	}
	else {
		croak 'One link at last needed!';
	}
}


=pod
Method: $do_download
    privat-метод, осуществляющий скачивание одной ссылки или предоставляющий объект для 
    multi-метода
Parameter:
    $url
Returns:
    {}  $status -  HTTP код ответа
        $data - данные страницы
    
=cut

$do_download = sub ($$) {

	my ( $self, $url ) = ( @_ ) ;
	
	my (  $data, $header ) = ( '','' ); # so... it for fix 'Use of uninitialized value in open' bug
	
# придется перенести создание объекта в процедуру, иначе получим замыкание в Multi
	my $curl = WWW::Curl::Easy->new();

# вот сюда пишем полученные данные	
	open ( my $fh, '>', \$data );
	open ( my $fh2, '>', \$header );

	$curl->setopt(CURLOPT_URL,$url);
	$curl->setopt(CURLOPT_WRITEDATA,\$fh);
	$curl->setopt(CURLOPT_WRITEHEADER,\$fh2);
		
	#10.02.09 - добавка для вариантов с feedsportal.com, когда новости идут редиректом
	$curl->setopt(CURLOPT_FOLLOWLOCATION,1); 
	$curl->setopt(CURLOPT_MAXREDIRS,2); # ДВА! иначе получаем только редирект

	# 12.02.09 - пробуем избавится от зависаний на больших лентах типа коммерсанта
	#$curl->setopt(CURLOPT_FAILONERROR,1); # вот этим не пользуйся, или отлуп на 301 редиректе обеспечен!
	$curl->setopt(CURLOPT_NOSIGNAL,1);
	$curl->setopt(CURLOPT_CONNECTTIMEOUT,5);
	$curl->setopt(CURLOPT_TIMEOUT,20);
	
	# 07.07.09 - добавляем UserAgent чтобы нас не банили.
	$curl->setopt(CURLOPT_USERAGENT, 
		( defined $self->agent_shuffle ? &$get_useragent() : $agent_list->[0] ) );

# для мульти-интерфейса нам нужен сам объект и ссылка на typoglobe, тем и отличаем
	return ( $curl, \$data, \$header ) if wantarray;
	
    $curl->perform;
#   my $err = $curl->errbuf;
    my $info = $curl->getinfo(CURLINFO_RESPONSE_CODE);
	
	return { $url => {'status' => [$info], 'data' => $data, 'header' => $header }};
};


=nb
Method: do_mass_download
	делает множественную загрузку с использованием Curl::Multi
Parameter:
	[curl_list] - массив объектов curl::Easy
Returns:
	{url=>{status, data}} - хеш готовых значений

=cut

$do_mass_download = sub ($$) {
	my ( $self, $url_list ) = ( @_ ) ;
	my ( $result, $curl_id, $easy );
	
	foreach my $url ( @$url_list ) {
		
		my ( $curl, $data, $header ) = &$do_download( $self, $url );
		$curl->setopt( CURLOPT_PRIVATE, ++$curl_id );
		$easy->{$curl_id} = {
			'curl' => $curl, 'data' => $data, 'header' => $header }; #  ссылка на объект
		$curlm->add_handle( $curl );
	}

	while ( $curl_id ){
	
		my $active_transfers = $curlm->perform;
		if ( $active_transfers != $curl_id ) {
			while ( my ( $id ) = $curlm->info_read ) {
				if ( $id ) {
						--$curl_id;
						my $actual_easy_handle = $easy->{$id}{curl};
						my $response = $actual_easy_handle->getinfo(CURLINFO_RESPONSE_CODE);
						# точно, тут у нас была ссылка на скаляр, разыменовываем
						my $data = ${$easy->{$id}{data}};
						my $header = ${$easy->{$id}{header}};
						$result->{$url_list->[($id-1)]} = {'status' => [$response],
									'data' => $data, 'header' => $header };
												
						# вот это обязательно, а то получим перебор по памяти
						delete $easy->{$id};
				}
			}
		}
	}
	
	return $result;
};


=nb
Method:get_useragent
    возвращает произвольного агента из списка
Parameter:
    void
Returns:
    $user_agent_string - наименование агента
Basis:
     дабы нас не банили, создаем видимость многокого
=cut

$get_useragent = sub (){

	return $agent_list->[int(rand($#$agent_list))];
};


1;

__END__

=encoding utf-8

=pod

=head1 NAME

Leech - OO wrapper to Curl::Easy && Curl::Multi with auto-choose method.

=head1 SYNOPSIS

Leech простой и эффективный wrapper над Curl::Easy или Curl::Multi.

	use Leech;
	my $leech = new Leech();
	my $data = $leech->suck( 'url1', 'url2' );


=head1 DESCRIPTION

Leech создан для упрощения скачивания чего-либо из сети, в основном предназначен для массовых загрузок. Для оптимизации скорости и стабильности используется Curl::Easy или Curl::Multi, при этом интерфейс выбирается модулем самостоятельно в зависимости от количества ссылок, которые нужно обработать.

Использовать совершенно элементарно:

	use Leech;
	my $leech = new Leech();
	# and then 
	my $data = $leech->suck('url');
	# or
	my $data = $leech->suck( 'url1', 'url2' );


Модуль имеет только один метод - suck
Вызывается со скаляром или U<списоком>.
На выходе B<всегда> получаем ссылку на хеш вида 
	
	{ url => { status => '', data => '', header => '' }}


Сам модуль использует частный метод get_useragent - выбирает из списка произвольную строку идентификации агента, пользуйтесь этой фичей по собственному усмотрению.

=head1 AUTOR	

Meettya <L<meettya@gmail.com>>

=head1 BUGS

Вероятно даже в таком объеме кода могут быть баги. Пожалуйста, сообщайте мне об их наличии по указаному e-mail или любым иным способом.

=head1 SEE ALSO

Socket, LWP, Curl.

=head1 COPYRIGHT

B<Moscow>, spring 2010. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

