use Test::More;
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
	
	is($e->TYPE, 'MyException');
	is($e->foo,  'Hello world');
	is_deeply($e->bar, [qw( Hello world )]);
	is_deeply($e->baz, { Hello => 'World' });
	like("$e", qr{Monkey});
};

done_testing();
