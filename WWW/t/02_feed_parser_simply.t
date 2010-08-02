#!/opt/local/bin/perl -w

use strict;
use lib qw(../);
use utf8;

use Test::More qw(no_plan);

use_ok( ' WWW::FeedParser', qw(new) );

my $feed_parser = new_ok( 'WWW::FeedParser' => 
				[{ clean => ['description', 'pubDate']} ] );

# делаем путь к файлам независимым от точки запуска теста
( my $file_path = $INC{'WWW/FeedParser.pm'} ) =~ s/FeedParser\.pm$// ;
my $file_name = $ENV{PWD}.'/'.$file_path.'t/rss1.rss';

# yap! 
ok( ( -e $file_name && -f _ && -s _ ), 'Exists test rss1 file' );

my $rss_source; #  это сырая лента, пока просто читаем

open ( my $fh, '<', $file_name ) or die $!;
READING:{ # so, it`s to be good for any dirty things whith $-something
			local $/;
			$rss_source = <$fh>;
		}
close $fh;

note("Test on good file");

ok ( my ( $rss_parsed, $rss_error ) = $feed_parser->ParseRSS( $rss_source ), 'Parse RSS ok!' );
isa_ok( $rss_parsed, 'ARRAY' );
like( $rss_parsed->[1]{title}, qr/Китайцы/, 'utf8 converted ok!');

##################
note("Test on bad file - 1");

$file_name =~ s/\d\.rss$/2.rss/;
# yap! 
ok( ( -e $file_name && -f _ && -s _ ), 'Exists test rss2 file' );

open ( $fh, '<', $file_name ) or die $!;
READING:{ # so, it`s to be good for any dirty things whith $-something
			local $/;
			$rss_source = <$fh>;
		}
close $fh;

ok ( ( $rss_parsed, $rss_error ) = $feed_parser->ParseRSS( $rss_source ), 'Parse RSS ok!' );
is ( $rss_error, 'parse fall' , 'Test "Parse error" ok!' );

##################
note("Test on bad file - 2");

$file_name =~ s/\d\.rss$/3.rss/;
# yap! 
ok( ( -e $file_name && -f _ && -s _ ), 'Exists test rss3 file' );

open ( $fh, '<', $file_name ) or die $!;
READING:{ # so, it`s to be good for any dirty things whith $-something
			local $/;
			$rss_source = <$fh>;
		}
close $fh;

ok ( ( $rss_parsed, $rss_error ) = $feed_parser->ParseRSS( $rss_source ), 'Parse RSS ok!' );
unlike( $rss_parsed->[1]{title}, qr/Китайцы/, 'Test "Encode error" ok!');
