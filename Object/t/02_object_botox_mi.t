#!/opt/local/bin/perl -w

use strict;
use lib qw(../);

use Test::More qw( no_plan );

my $baz = main::new_ok( 'Children' => [], 'Object' );

my $test_prop = {
	'prop3_1' => 'last value',
	'prop2_2' => 'lastmost',
	'prop1_2' => 'end of the road',
	'prop2_1' => 33,
	'prop1_1' => '3.14',
	'prop3_2' => 'trololo'
};

subtest 'Data matching' => sub {	
	plan tests => 6;
	map{ is( $test_prop->{$_}, $baz->$_(), "Prop: $_ match!" ) } keys %$test_prop;
};

ok( $baz->prop1_1('pi') && 'pi' eq $baz->prop1_1(), 
			'RW-prop inheritance worked');
ok( !eval{ $baz->prop2_1(44) } && $@ && $baz->prop2_1 == 33, 
			"RO-prop inheritance worked");

1;

{ package First;	
	use Object::Botox qw(new);
	sub _prototype_{	
				'prop1_1_ro' => 1 ,
				'prop1_2' => 'abcde'
	}	
	1;
}

{ package Second;	
	use Object::Botox qw(new);
	sub _prototype_{	
			return {'prop2_1_ro' => 33 , 'prop2_2' => 'ddfdff' };
	}	
	1;
}

{ package Third;
	use Object::Botox qw(new);
	sub _prototype_{	
			return {'prop3_1' => 3434 , 'prop3_2' => 'fddfldflk' };
	}	
	1;
}

{ package Fourth;
	use Object::Botox qw(new);
		sub _prototype_{ 'prop3_1' => 33 };
	1;
}

{ package TwoParent;
	use base qw ( First Second );
	sub _prototype_{	
			return {'prop1_1' => 3.14 , 'prop2_2' => 'tryryr' };
	}	
	1;

}

{ package OneParent;
	use base qw( Third );
	sub _prototype_{	
			return { 'prop3_2' => 'trololo' };
	}	
	1;

}

{ package Children;
	use base qw( TwoParent OneParent Fourth );
	sub _prototype_{	
			'prop1_2_ro' => 'end of the road' ,
			'prop3_1' => 'last value',
			'prop2_2_ro' => 'lastmost'
	}	
	1;

}