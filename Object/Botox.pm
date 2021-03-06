package Object::Botox;

use strict;
use warnings;

our $VERSION = 0.9.9;

use Exporter qw( import );
our @EXPORT_OK = qw( new );

use autouse 'Carp' => qw(carp croak);
use MRO::Compat qw( get_linear_isa );

my ( $create_accessor, $prototyping, $setup );

my $err_text =	[
		qq(Can`t change RO properties |%s| to |%s| in object %s from %s at %s line %d\n),
		qq(Haven`t properties |%s|, can't set to |%s| in object %s from %s at %s line %d\n),
		qq(Odd number of elements in class prototype |%s| from %s at %s line %d\n),
				];

sub new{
    my $invocant = shift;
    my $self = bless( {}, ref $invocant || $invocant ); # Object or class name 
	&$prototyping( $self );
	&$setup( $self, @_ ) if @_;
	return $self;
}

=nd
Method: :prototyping (private)
	конструирует объект по доступным прото-свойствам, 
	объявленным в нем самом или в родителях
Parameters: 
	$self - сам объект
Returns: 
	void
Explain:
	проходимся по дереву объектов, ничиная с самого объекта и
	строим по описанию прототипа все, прибавляя ко всему свойства
=cut

$prototyping = sub{
	
	my $self = shift;
	my $class_list = mro::get_linear_isa( ref $self );	
	# it`s for exist properies ( we are allow redefine, keeping highest )
	my %seen_prop;	

	foreach my $class ( @$class_list ){

		# next if haven`t prototype
		next unless ( $class->can('_prototype_') );		
		my ( $proto, @proto_list ) = $class->_prototype_();
		
		next unless ( defined $proto );
		
		# if mistyping in prototype
		while ( ref $proto ne 'HASH' && 
					( ! @proto_list || ! ( @proto_list % 2 ) ) ){
			die sprintf $err_text->[2], $class, caller(0);
		}
		
		$proto = {$proto, @proto_list} if ( @proto_list );

		# or if we are having prototype - use it !		
		for ( reverse keys %$proto ) { # anyway we are need some order, isn`t it?		
			
			my ( $field, $ro ) = /^(.+)_(r[ow])$/ ? ( $1, $2 ) : $_ ;			
			next while ( $seen_prop{$field}++ );		
			&$create_accessor( $self, $field, $ro );		
			$self->$field( $proto->{$_} );
			
		}	
	}
};

=nd
Method: :create_accessor (private)
	делает акцессоры для объекта
Parameters: 
	$class	- класс объекта
	$field	- имя свойста
	$ro		- тип свойства : [ ro|rw|undef ]
Returns: 
	void
=cut

$create_accessor = sub{
	my $class = ref shift;
	my ( $field, $ro ) = @_ ;
	
	my $slot = "$class\::$field"; 	# inject sub to invocant package space
	no strict 'refs';          		# So symbolic ref to typeglob works.
	return if ( *$slot{CODE} );		# don`t redefine ours closures
	
	*$slot = sub {					# or create closures
		my $self = shift;		
		return $self->{$slot} unless ( @_ );						
		if ( defined $ro && $ro eq 'ro' &&
			  !( caller eq ref $self || caller eq __PACKAGE__ ) ){				
					die sprintf $err_text->[0], $field, shift, ref $self, caller;
		}
		else {
			return $self->{$slot} = shift;
		}
	};	

};

=nd
Method: :setup (private)
	устанавливает свойста объекта при его создании
Parameters: 
	$self - сам объект
	@_ - свойства для установки:
		(prop1=>aaa,prop2=>bbb) AND ({prop1=>aaa,prop2=>bbb}) ARE allowed
Returns: 
	void
=cut

$setup = sub{
	my $self = shift;
	my %prop = ref $_[0] eq 'HASH' ? %{$_[0]} : @_ ; 
	
	map { $self->can( $_ ) ? $self->$_( $prop{$_} ) : 
			die sprintf $err_text->[1], $_, $prop{$_}, ref $self, caller(1) } 
					keys %prop;

};

1;


__END__

=encoding utf-8

=pod

=head1 NAME

Botox - simple implementation of Modern Object Constructor with accessor, prototyping and default-filling of inheritanced values.

=head1 VERSION

B<$VERSION 0.9.8>

=head1 SYNOPSIS

Botox предназначен для создания объектов с прототипируемыми управляемыми по доступности свойствами: write-protected или public И возможности установки этим свойствам дефолтных значений (как в прототипе, так и при создании объекта). Построение цепочки наследования производится на основе ::mro, методы и свойства переопределяются в потомке.

  package Parent;
  use Botox qw(new); # yes, we are got constructor
  
  # default properties for ANY object of `Parent` class:
  # prop1_ro ISA 'write-protected' && prop2 ISA 'public'
  # and seting default value for each other
  
  sub _prototype_{ 'prop1_ro' => 1 , 'prop2' => 'abcde' }; 
  
  # OR sub _prototype_{ return {'prop1_ro' => 1 , 'prop2' => 'abcde'} }; 


=head1 DESCRIPTION

Botox - простой абстрактный конструктор, дающий возможность создавать объекты по прототипу и управлять их свойствами: write-protected или public. Кроме того он позволяет проставить свойствам значения по умолчанию (как в прототипе, так и при создании объекта).

Класс создается так:
   
	package Parent;

	use Botox qw(new);
	sub _prototype_{ 'prop1_ro' => 1 , 'prop2' => 'abcde' };
	
	sub show_prop1{ # It`s poinlessly - indeed property IS A accessor itself
		my ( $self ) = @_;
		return $self->prop1;
	}
	
	sub set_prop1{ # It`s NEEDED for RO aka protected on write property
		my ( $self, $value ) = @_;
		$self->prop1($value);
	}
	
	sub parent_sub{ # It`s class method itself
		my $self = shift;
		return $self->prop1;
	}
	1;


Экземпляр объекта создается так:

	package Child;
	# change default value for prop1
	my $foo = new Parent( { prop1 => 888888 } );
		
	1;

Собственно, это весь код для создания экземпляра.

	use Data::Dumper;
	print Dumper($foo);
	
Даст нам 

	$VAR1 = bless( {
			'Parent::prop1' => 888888,
			'Parent::prop2' => 'abcde'
			 }, 'Parent' );


Свойства, описаные в конструкторе класса, могут наследоваться и иметь права доступа.

Право доступа указывается в имени свойства конструкцией bar + '_ro' или '_rw'(default).
Право на доступ по чтению-записи является правилом по умолчанию, таким образом  его указание не обязательно.
Напротив, ограничение прав "ro - только чтение" требует явного указания этого факта.
Далее для возможности работы с данным свойством НА ЗАПИСЬ из экземпляра объекта следует создать в классе акцессор, например:

	eval{ $foo->prop1(-23) };
	print $@."\n";
	
Даст нам что-то вроде:

	Can`t change RO properties |prop1| to |-23| in object Parent from Child at ./test_more.t line 84

Для работы с данным свойством в родительском классе у нас был создан аксессор, который и следует использовать:

	$foo->set_prop1(-23);

Создавая производный класс от родительского

	package Child;	
	use base 'Parent';

	sub _prototype_{ 
				return {'prop1' => 48,
						'prop5' => 55 , 
						'prop8_ro' => 'tetete'
						};
	};
	1;

В наследство мы получим ВСЕ методы Parent (что ожидаемо) и ВСЕ дефолтные свойства Parent (что неожиданно), и это правильная вещь.
Дефолтные значения И свойства доступа прототипа могут переопределяться в потомке, перезаписывая данные. 

	package GrandChild;

	use Data::Dumper;
	my $baz = new Child();
	
	print Dumper($baz);
	
	eval{$baz->prop8(-23)};
	print $@."\n";
	
	eval{$baz->prop1(1_000)};
	print '$baz->prop1 = '.$baz->prop1()."\n";

Даст нам вот такой вывод:

	$VAR1 = bless( {
                 'Child::prop5' => 55,
                 'Child::prop2' => 'abcde',
                 'Child::prop1' => 48,
                 'Child::prop8' => 'tetete'
               }, 'Child' );

	Can`t change RO properties |prop8| to |-23| in object Child from GrandChild at ./test_more.t line 84
	$baz->prop1 = 1000

То есть мы смогли получить новый класс Child на базе Parent со свойствами обоих классов, причем настройки верхнего уровня переопределяют родительские (включая права доступа).

Кроме того, возможна дефолтная инициализация свойств объекта:

	package GrandChild;

	use Data::Dumper;
	my $baz = new Child(prop1 => 99); # OR ({prop1 => 99}) as you wish
	
	print Dumper($baz);

Даст нам вот такой вывод:

	$VAR1 = bless( {
                 'Child::prop5' => 55,
                 'Child::prop2' => 'abcde',
                 'Child::prop1' => 99,
                 'Child::prop8' => 'tetete'
               }, 'Child' );

При создании объекта возможно задавать значения как rw так и ro свойств(что логично).
Попытка задать значение несуществующего свойства даст ошибку.

=head1 AUTOR	

Meettya <L<meettya@gmail.com>>

=head1 BUGS

Вероятно даже в таком объеме кода могут быть баги. Пожалуйста, сообщайте мне об их наличии по указаному e-mail или любым иным способом.

=head1 SEE ALSO

Moose, Mouse, Class::Accessor

=head1 COPYRIGHT

B<Moscow>, fall 2009.

=head1 LICENSE

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut
