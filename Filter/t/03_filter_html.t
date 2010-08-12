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
				[{'filter' => $filter , show_error => 0 }] );

ok ( my $result = $html_cleaner->DoClearHTML( decode_utf8( $data->[0] ) ), 'Data clean ok');



print  Dumper( encode_utf8($result) );

pass('fake');