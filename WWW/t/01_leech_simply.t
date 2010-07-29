#!/opt/local/bin/perl -w

use strict;
use lib qw(../);

use Test::More qw(no_plan);

use_ok( 'WWW::Leech', qw(new) );

my $leech = new_ok( 'WWW::Leech' => [{ 'agent_shuffle' => 1}] );

# делаем путь к файлам независимым от точки запуска теста
( my $file_path = $INC{'WWW/Leech.pm'} ) =~ s/Leech\.pm$// ;

# генерируем 2 файла ( путь, создаем файлы, заполняем контентом ) *потом снесем
my $file_name = [ map { $_ = 'file://'.$ENV{PWD}.'/'.$file_path."t/example$_.txt" }
							(1..2) ];

my $content_file = [ "1\n2\n3\n4\n5", "a\nb\nc\nd\ne\nf" ];

foreach ( 0..1 ){
	( my $local_file_name =  $file_name->[$_] ) =~ s#^file://## ;
	open ( my $fh, '>', $local_file_name ) or die 'Cant create test file! ', $@;
	print $fh $content_file->[$_]; 
	close $fh;
} 

my $data1 = $leech->suck( $file_name->[0] );
my $data2 = $leech->suck( $file_name->[0], $file_name->[1] );

subtest 'Data loading' => sub {	
	plan tests => 3;
	is( $data1->{$file_name->[0]}{data}, $content_file->[0], "file 1 data compare" );
	is( $data2->{$file_name->[0]}{data}, $content_file->[0], "file 2 data 1 compare" );
	is( $data2->{$file_name->[1]}{data}, $content_file->[1], "file 2 data 2 compare" );
};

# убираем за собой
map{ s#^file://## ; `rm $_` if ( -e $_ && -f _ && -s _ )} ( @$file_name );

SKIP: {
 		
	use_ok( 'Net::Ping' );
	
	my $host = [ 'google.com', 'ya.ru' ];		
	my $p = new_ok( 'Net::Ping' => ["tcp", 2] );
	
	# Try connecting to the www port instead of the echo port
	$p->{port_num} = getservbyname("http", "tcp");
	
	skip "No Internet connected or [$host->[0]] down", 4 
									unless $p->ping( $host->[0] );   		
	undef $p;

	note("Ok, we are have Internet, try to download...");
	ok ( my $data1 = $leech->suck( $host->[0], $host->[1] ), 'Downloaded !');
	is_deeply ( $data1->{$host->[0]}{status},	[200],	'Download check: status' );
	unlike ( $data1->{$host->[1]}{data} ,		qr/^$/, 'Download check: data' );
	unlike ( $data1->{$host->[0]}{header},		qr/^$/, 'Download check: header' );
	
	}


__END__

что здесь НЕ проверяется.
не проверяется agent_shuffle - ИМХО оно должно работать
Все остальное тестится на локали и в сетевом варианте.