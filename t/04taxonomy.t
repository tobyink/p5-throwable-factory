use strict;
use warnings;
use Test::More;

use Try::Tiny;
use Throwable::Factory
	A => ['-caller'],
	B => ['-environment'],
	C => ['-notimplemented'],
;

try {
	A->throw;
}
catch {
	ok( $_->DOES('Throwable::Taxonomy::Caller') );
};

try {
	B->throw;
}
catch {
	ok( $_->DOES('Throwable::Taxonomy::Environment') );
};

try {
	C->throw;
}
catch {
	ok( $_->DOES('Throwable::Taxonomy::NotImplemented') );
};

ok not eval q { use Throwable::Factory D => ['-foobar']; D(); 1 };
like $@, qr/Shortcut '-foobar' has no matches/;

{
	package Local::Error::Foobar;
	use Moo::Role;
	push @Throwable::Factory::SHORTCUTS, __PACKAGE__;
}

ok eval q { use Throwable::Factory E => ['-foobar']; E(); 1 };

{
	package Local::Error2::Foobar;
	use Moo::Role;
	push @Throwable::Factory::SHORTCUTS, __PACKAGE__;
}

ok not eval q { use Throwable::Factory F => ['-foobar']; F(); 1 };
like $@, qr/Shortcut '-foobar' has too many matches/;

done_testing;
