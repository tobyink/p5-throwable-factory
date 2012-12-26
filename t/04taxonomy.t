use strict;
use warnings;
use Test::More tests => 3;

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

