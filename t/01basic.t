use strict;
use warnings;
use Test::More;

use Scalar::Util 'blessed';
use Throwable::Factory MyException => [qw< $foo @bar %baz >];
use Try::Tiny;

try {
	MyException->throw(
		"Test exception",
		foo => "Hello world",
		bar => [qw( Hello world )],
		baz => { Hello => 'World' },
	);
}
catch {
	my $e = shift;
	BAIL_OUT("not a blessed exception: $e") unless blessed $e;
	
	is($e->TYPE, 'MyException');
	is_deeply([$e->FIELDS], [qw( message foo bar baz )]);
	is($e->foo,  'Hello world');
	is_deeply($e->bar, [qw( Hello world )]);
	is_deeply($e->baz, { Hello => 'World' });
	like("$e", qr{^Test exception});
	is($e->package, __PACKAGE__);
	is($e->file, __FILE__);
	is($e->line, 10);
};

done_testing();
