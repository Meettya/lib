#!/opt/local/bin/perl -w

use strict;
use lib qw(../);
use utf8;

use Encode qw( encode_utf8 );

use Test::More qw(no_plan);

use_ok( 'Parser::HTML', qw(new) );

# делаем путь к файлам независимым от точки запуска теста
( my $file_path = $INC{'Parser/HTML.pm'} ) =~ s/HTML\.pm$// ;
my $file_name = $ENV{PWD}.'/'.$file_path.'t/news1.html';

my $feed_parser = new_ok( 'Parser::HTML' => 
				[] );

my ( $html_source, $html_parsed, $html_error );

ok( ( -e $file_name && -f _ && -s _ ), 'Exists test news1 file' );


open ( my $fh, '<', $file_name ) or die $!;
READING:{ # so, it`s to be good for any dirty things whith $-something
			local $/;
			$html_source = <$fh>;
		}
	
my $xpatch_string = '//span[@class="paragraph"]/../descendant::*';		
ok( $feed_parser->ParseHTML( $html_source, $xpatch_string ), 'Parse HTML pass!' );

subtest 'Error parsing handling' => sub {	
	plan tests => 6;
	
	ok ( ( $html_parsed, $html_error ) = $feed_parser->ParseHTML( '' , $xpatch_string ), 'Empty data_in test pass!' );
	is(  $html_error, 'encode fall' , 'Test "Encode error" on empty ok!');
	
	ok ( ( $html_parsed, $html_error ) = $feed_parser->ParseHTML( $html_source ), 'Empty xpatch_string test pass!' );
	is ( $html_error, 'xpatch empty' , 'Test "Parse error on empty" ok!' );
	
	$xpatch_string = '//span[@class="fooobazzz"]/../descendant::*';	
	ok ( ( $html_parsed, $html_error ) = $feed_parser->ParseHTML( $html_source, $xpatch_string  ), 
			'Wrong xpatch_string test pass!' );
	is ( $html_error, 'xpatch mismatch' , 'Test 2 "Parse error on wrong xpatch_string" ok!' );

};

subtest 'Max length parsing handling' => sub {	
	plan tests => 4;			

	ok ( my $test1 = $feed_parser->ParseHTML( $html_source, 
	'//span[@class="paragraph"]/../descendant::*' ), "First template parse" );
	
	ok ( my $test2 = $feed_parser->ParseHTML( $html_source, 
	'//div[@class="vvodka"]/following-sibling::*' ), "Second tempale parse" );
	
	my ( $winer ) = ( sort { $b <=> $a } ( length $test2, length $test1 ) );
	
	ok ( my $test3 = $feed_parser->ParseHTML( $html_source, 
			[ '//span[@class="paragraph"]/../descendant::*',
			'//div[@class="vvodka"]/following-sibling::*' ]),
			"Both template parse");
			
	ok (  length $test3  == $winer  , "Max lenght test pass" );

};			
