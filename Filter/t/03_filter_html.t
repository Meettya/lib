#!/opt/local/bin/perl

use strict;
use warnings;
use utf8;


use lib qw(../);
use YAML;
use Data::Dumper;

use Encode qw( encode_utf8 decode_utf8 );

use Test::More qw(no_plan);

use_ok( 'Filter::HTML', qw(new) );

# делаем путь к файлам независимым от точки запуска теста
( my $file_path = $INC{'Filter/HTML.pm'} ) =~ s/HTML\.pm$// ;
my $file_name = $ENV{PWD}.'/'.$file_path.'t/html_data.yml';

ok ( my $data = YAML::LoadFile( $file_name ), 'Loading data ok');

my $filter = [

		[ '(?:<\s*br\s*/?\s*>\s*)+', sub{"\n"} ],
		[ '<\s*(/)?\s*(?:div|span)[^>]*>', sub{"<$1p>"} ],
		[ '<\s*a[^>]*href\s*=\s*(["\'])?(.+?)\1(?:>|\s+[^>]*>)',
			 sub{"<a href=\"$2\">"} ],
		# удаляем ссылкУ после последнего абзаца (удалит только последнюю)
		[ '\s*<\s*a[^>]+>(?!.*<\s*a[^>]+>).*<\s*/\s*a\s*>\s*$' ],
		
			];

my $html_cleaner = new_ok( 'Filter::HTML' => 
				[{ 'filter' => $filter , show_error => 0, clean_tail => 1 }] );

ok ( my $result = $html_cleaner->DoClearHTML( decode_utf8( $data->{raw}[0] ) ), 'Data clean worked');

subtest 'Test clean function' => sub {	
	plan tests => 3;
	
	foreach (0..2){
		my $test_str = decode_utf8( $data->{clean}[$_] );
		chomp $test_str;
		is ( $html_cleaner->DoClearHTML( decode_utf8( $data->{raw}[$_] ) ), $test_str, 'Clean matched with standart '. ( $_ + 1 )  );
	}
	
};

# ну, стоит убедится что оно не пытается распознать что-то не utf8
subtest 'Error handling' => sub {	
	plan tests => 2;
	ok ( my ( $result, $err ) = $html_cleaner->DoClearHTML( $data->{raw}[0] ),
		'Non-unf8 parse ');
	is ( $err, 'not utf8', 'Not utf8 error check');
};


# print  Dumper( encode_utf8($result) );
