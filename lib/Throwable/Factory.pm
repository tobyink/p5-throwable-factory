use 5.008;
use strict;
use warnings;
use MooX::Struct 0.008 ();

{
	package Throwable::Factory;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	
	sub import
	{
		my $class  = shift() . '::Struct';
		my $import = $class->can('import');
		unshift @_, $class;
		goto $import;
	}
}

{
	package Throwable::Factory::Struct;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	
	use Moo;
	use namespace::sweep 0.006;
	extends('MooX::Struct', 'Throwable::Error');
	
	sub BUILDARGS
	{
		my $class = shift;
		unshift @_, 'message' if @_ % 2 && !ref($_[0]);
		return $class->SUPER::BUILDARGS(@_);
	}
	
	sub TO_STRING
	{
		use Data::Dumper;
		warn Dumper \@_;
		Throwable::Error::as_string(@_);
	}
}

{
	package Throwable::Factory::Struct::Processor;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	
	use Moo;
	use namespace::sweep 0.006;
	extends 'MooX::Struct::Processor';
	
	has '+base' => (
		default => sub { 'Throwable::Factory::Struct' },
	);
	
	# kinda ugly hack
	around process_method => sub
	{
		my ($orig, $self, $klass, $name, $coderef) = @_;
		if ($name eq 'FIELDS') {
			my @FIELDS = $coderef->();
			unshift @FIELDS, 'message';
			$coderef = sub { @FIELDS };
		}
		return $self->$orig($klass, $name, $coderef);
	};
}

1;

__END__

=head1 NAME

Throwable::Factory - a module that does something-or-other

=head1 SYNOPSIS

	use Throwable::Factory
		GeneralException => [],
		FileException    => [qw( $filename )],
		NetworkException => [qw( $remote_addr $remote_port )],
	;
	
	# Just a message...
	#
	GeneralException->throw("Something bad happened");
	
	# Or use named parameters...
	#
	GeneralException->throw(message => "Something awful happened");

	# The message can be a positional parameter, even while the
	# rest are named.
	#
	FileException->throw(
		"Can't open file",
		filename => '/tmp/does-not-exist.txt',
	);

	# Or, they all can be a positional using an arrayref...
	#
	NetworkException->throw(["Timed out", "11.22.33.44", 555]);

=head1 DESCRIPTION

L<Exception::Class>-like exception factory using L<Throwable::Error> and
L<MooX::Struct>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Throwable-Factory>.

=head1 SEE ALSO

Exceptions built by this factory inherit from:
L<Throwable::Error>, L<MooX::Struct>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

