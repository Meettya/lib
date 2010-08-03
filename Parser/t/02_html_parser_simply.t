#!/opt/local/bin/perl -w

use strict;
use lib qw(../);
use utf8;

use Encode qw( encode_utf8 );

use Test::More qw(no_plan);

use_ok( 'Parser::HTML', qw(new) );

# делаем путь к файлам независимым от точки запуска теста
( my $file_path = $INC{'Parser/HTML.pm'} ) =~ s/HTML\.pm$// ;
my $file_name = $ENV{PWD}.'/'.$file_path.'t/news3.html';

my $feed_parser = new_ok( 'Parser::HTML' => 
				[] );

my $html_source;

ok( ( -e $file_name && -f _ && -s _ ), 'Exists test news1 file' );


open ( my $fh, '<', $file_name ) or die $!;
READING:{ # so, it`s to be good for any dirty things whith $-something
			local $/;
			$html_source = <$fh>;
		}

		
my $test = $feed_parser->ParseHTML( $html_source );

use Data::Dumper;

diag encode_utf8($test);
				
pass('fake');