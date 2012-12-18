use 5.008;
use strict;
use warnings;

use Moo 1.000006 ();
use MooX::Struct 0.008 ();
use Throwable::Error 0.200000 ();

{
	package Throwable::Factory;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';

	use MooX::Struct -retain,
		BaseClass => [
			-class  => \'Throwable::Factory::Struct',
			-with   => ['Throwable', 'StackTrace::Auto'],
			'$message',
		],
	;
	
	sub import
	{
		my $class  = shift() . '::Struct';
		unshift @_, $class;
		goto \&MooX::Struct::import;
	}
	
	BaseClass;
}

{
	package Throwable::Factory::Struct;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	
	use Data::Dumper ();
	
	sub BUILDARGS
	{
		my $class = shift;
		unshift @_, 'message' if @_ % 2 and not ref $_[0];
		$class->SUPER::BUILDARGS(@_) if @_;
	}
	
	sub TO_STRING
	{
		local $Data::Dumper::Terse = 1;
		local $Data::Dumper::Indent = 0;
		local $Data::Dumper::Useqq = 1;
		local $Data::Dumper::Deparse = 0;
		local $Data::Dumper::Quotekeys = 0;
		local $Data::Dumper::Sortkeys = 1;

		my $self = shift;
		my $str  = $self->message . "\n\n";
		
		for my $f ($self->FIELDS) {
			next if $f eq 'message';
			my $v = $self->$f;
			$str .= sprintf(
				"%-8s = %s\n",
				$f,
				ref($v) ? Data::Dumper::Dumper($v) : $v,
			);
		}
		$str .= "\n";
		$str .= $self->stack_trace->as_string;
		return $str;
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
		default => sub { Throwable::Factory::BaseClass },
	);

	# Kinda ugly hack. MooX::Struct can't cope with inheriting
	# fields from the default base class.
	sub process_method
	{
		my ($self, $klass, $name, $coderef) = @_;
		if ($name eq 'FIELDS') {
			my @FIELDS = $coderef->();
			unshift @FIELDS, 'message' unless $FIELDS[0] eq 'message';
			$coderef = sub { @FIELDS };
		}
		return $self->SUPER::process_method($klass, $name, $coderef);
	}
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

