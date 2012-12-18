use strict;
use warnings;
use Test::More;

use Try::Tiny;
use Scalar::Util 'blessed';
use Throwable::Factory
	Except1 => [qw< $foo $bar >],
	Except2 => {
		isa         => 'Except1',
		fields      => [ 'baz' ],
		description => 'Extended version of Except1',
	},
;

# Throws for unsupported Exception::Class-style options.
try {
	Throwable::Factory->import(Except3 => { huh => 123 });
}
catch {
	like $_[0], qr{^Exception::Class-style huh option not supported};
};

is_deeply(
	[ Except2->FIELDS ],
	[ qw< message foo bar baz > ]
);

try {
	Except2->throw('Test');
}
catch {
	my $e = shift;
	BAIL_OUT("not a blessed exception: $e") unless blessed $e;

	isa_ok $e, Except2;
	isa_ok $e, Except1;
	is($e->error, 'Test');
};

done_testing;
