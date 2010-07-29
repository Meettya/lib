#!/opt/local/bin/perl -w

use strict;
use lib qw(../);

use Test::More qw(no_plan);

use_ok( 'WWW::Leech', qw(new) );

my $leech = new_ok( 'WWW::Leech' => [{ 'agent_shuffle' => 1}] );

# делаем путь к файлам независимым от точки запуска теста
( my $file_path = $INC{'WWW/Leech.pm'} ) =~ s/Leech\.pm$// ;
# генерируем 2 ссылки
my ( $file_name1, $file_name2 ) = 
			map { $_ = 'file://'.$ENV{PWD}.'/'.$file_path."t/example$_.txt" } (1..2) ;


my $data1 = $leech->suck( $file_name1 );
my $data2 = $leech->suck( $file_name1, $file_name2 );

subtest 'Data loading' => sub {	
	plan tests => 3;
	is( $data1->{$file_name1}{data}, "1\n2\n3\n4\n5", "file 1 data compare" );
	is( $data2->{$file_name1}{data}, "1\n2\n3\n4\n5", "file 2 data 1 compare" );
	is( $data2->{$file_name2}{data}, "a\nb\nc\nd\ne\nf", "file 2 data 2 compare" );

};

undef $data1;
undef $data2;

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
		ok ( my $data1 = $leech->suck( $host->[0], $host->[1] ), 'Loading ok!');
		is_deeply ( $data1->{$host->[0]}{status}, [200], 'Loading: status ok' );
		unlike ( $data1->{$host->[1]}{data} , qr/^$/, 'Loading: data ok' );
		unlike ( $data1->{$host->[0]}{header}, qr/^$/, 'Loading: header ok' );
		
    }



__END__

что здесь НЕ проверяется.
не проверяется agent_shuffle - ИМХО оно должно работать
Все остальное тестится на локали и в сетевом варианте.