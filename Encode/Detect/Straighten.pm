package Encode::Detect::Straighten;

use warnings;
use strict;

our $VERSION = 0.1.1;

use Exporter 'import';
our @EXPORT = qw(do_rectify);

my %code_map = qw( x-mac-cyrillic CP1251 IBM866 CP866 );

sub do_rectify ($){

	my $data_in = shift;
	return !defined $data_in ? undef : $code_map{$data_in} || $data_in;

}

1;

__END__

=encoding utf-8


=pod


=head1 NAME

Encode::Detect::Straighten - cleaner to Encode::Detect::Detector.

=head1 VERSION

B<$VERSION 0.1.1>

=head1 SYNOPSIS

Дополнение для Encode::Detect::Detector, возвращающее "канонические" имена кодировок.
	
	use Encode::Detect::Straighten;
	use Encode::Detect::Detector;
	print do_rectify( detect( $octet ) ); 
	# if $octet recognized as 'x-mac-cyrillic' retun replaced 'CP1251'

=head1 DESCRIPTION

Модуль Encode::Detect::Detector имеет один странный "баг" - возвращает непонятные для encode имена кодировок, например

	x-mac-cyrillic

Encode::Detect::Straighten заменят возвращаемую Detector-ом кодировку на понимаемую encode.

	CP1251

Экспортируется единственная функция do_rectify, которая и проверят кодировку на необходимость замены, возвращая "выпрямленную" по необходимости.


=head1 AUTOR	

Meettya <L<meettya@gmail.com>>

=head1 BUGS


=head1 SEE ALSO

Lingua::DetectCharset Encode::Detect::Detector

=head1 COPYRIGHT

B<Moscow>, summer 2010

=cut