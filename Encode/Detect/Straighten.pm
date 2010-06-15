package Encode::Detect::Straighten;

use warnings;
use strict;

our $VERSION = 0.0.1;

use Exporter 'import';
our @EXPORT = qw(detect);

use base qw(Encode::Detect::Detector);

my %code_map = qw( x-mac-cyrillic CP1251 IBM866 CP866 );

sub detect ($){

	my $enc = SUPER::detect(shift);
	return $code_map{$enc} || $enc;

}

1;

__END__

=encoding utf-8


=pod


=head1 NAME

Encode::Detect::Straighten - wrapper to Encode::Detect::Detector.

=head1 VERSION

B<$VERSION 0.0.1>

=head1 SYNOPSIS

Обертка над Encode::Detect::Detector, возвращающая "канонические" имена кодировок.

	use Encode::Detect::Straighten;
	print detect($octet); 
	# if $octet recognized as 'x-mac-cyrillic' retun replaced 'CP1251'

=head1 DESCRIPTION

Модуль Encode::Detect::Detector имеет один странный "баг" - возвращает непонятные для encode имена кодировок, например

	x-mac-cyrillic

Encode::Detect::Straighten заменят возвращаемую Detector-ом кодировку на понимаемую encode.
Экспортируется единственная функция detect, которая и проверят кодировку на необходимость замены.


=head1 AUTOR	

Meettya <L<meettya@gmail.com>>

=head1 BUGS


=head1 SEE ALSO

Lingua::DetectCharset Encode::Detect::Detector

=head1 COPYRIGHT

B<Moscow>, summer 2010

=cut