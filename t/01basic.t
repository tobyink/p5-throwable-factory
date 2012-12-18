=head1 PURPOSE

Basic usage of Throwable::Factory to define some exception classes, throw
and catch them.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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
	ok($e->line);
};

done_testing();
