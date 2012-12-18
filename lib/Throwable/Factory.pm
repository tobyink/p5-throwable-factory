use 5.008;
use strict;
use warnings;

use Moo 1.000006 ();
use MooX::Struct 0.008 ();
use Throwable::Error 0.200000 ();

{
	package Throwable::Factory;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_02';

	use MooX::Struct -retain,
		Base => [
			-class   => \'Throwable::Factory::Struct',
			-extends => ['Throwable::Factory::Base'],
			-with    => ['Throwable', 'StackTrace::Auto'],
			'$message',
		],
	;
	
	sub import
	{
		my $class  = shift() . '::Struct';
		unshift @_, $class;
		goto \&MooX::Struct::import;
	}
	
	Base;
}

{
	package Throwable::Factory::Base;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_02';
	
	use Data::Dumper ();
	use Moo;
	use namespace::clean;
	extends 'MooX::Struct';
	
	sub description { 'Generic exception' }
	sub error       { shift->message }
	sub package     { shift->stack_trace->frame(0)->package }
	sub file        { shift->stack_trace->frame(0)->filename }
	sub line        { shift->stack_trace->frame(0)->line }
	
	sub BUILDARGS
	{
		my $class = shift;
		return +{} unless @_;
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
	our $VERSION   = '0.000_02';
	
	use Moo;
	use Carp;
	use namespace::clean;
	extends 'MooX::Struct::Processor';
	
	has '+base' => (
		default => sub { Throwable::Factory::Base },
	);

	# Kinda ugly hack. MooX::Struct can't cope with inheriting
	# fields from the default base class.
	sub process_method
	{
		my ($self, $klass, $name, $coderef) = @_;
		if ($name eq 'FIELDS')
		{
			my @FIELDS = $coderef->();
			unshift @FIELDS, 'message' unless @FIELDS && $FIELDS[0] eq 'message';
			$coderef = sub { @FIELDS };
		}
		return $self->SUPER::process_method($klass, $name, $coderef);
	}
	
	# Allow make_sub to accept Exception::Class-like hashrefs.
	sub make_sub
	{
		my ($self, $name, $proto) = @_;
		if (ref $proto eq 'HASH')
		{
			my %proto = %$proto;
			$proto = [];
			
			if (defined $proto{isa}) {
				my $isa = delete $proto{isa};
				push @$proto, -extends => [$isa];
			}
			if (defined $proto{description}) {
				my $desc = delete $proto{description};
				push @$proto, description => sub { $desc };
			}
			if (defined $proto{fields}) {
				my $fields = delete $proto{fields};
				push @$proto, ref $fields ? @$fields : $fields;
			}
			
			if (keys %proto) {
				croak sprintf(
					"Exception::Class-style %s option not supported",
					join('/', sort keys %proto),
				);
			}
		}
		return $self->SUPER::make_sub($name, $proto);
	}
}

1;

__END__

=head1 NAME

Throwable::Factory - lightweight Moo-based exception class factory

=head1 SYNOPSIS

	use Throwable::Factory
		GeneralException => undef,
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

C<Throwable::Factory> is an L<Exception::Class>-like exception factory
using L<MooX::Struct>.

All exception classes built using C<Throwable::Factory> are L<MooX::Struct>
structs, but will automatically include a C<message> attribute, will compose
the L<Throwable> and L<StackTrace::Auto> roles, and contain the following
convenience methods:

=over

=item C<error>

Read-only alias for the C<message> attribute/field.

=item C<package>

Get the package for the first frame on the stack trace.

=item C<file>

Get the file name for the first frame on the stack trace.

=item C<line>

Get the line number for the first frame on the stack trace.

=back

They provide a C<BUILDARGS> method which means that if their constructor
is called with an odd number of arguments, the first is taken to be the
message, and the rest named parameters.

Additionally, the factory can be called with Exception::Class-like hashrefs
to describe the exception classes. The following two definitions are
equivalent:

	# MooX::Struct-style
	use Throwable::Factory FooBar => [
		-extends => ['Foo'],
		qw( foo bar ),
	];
	
	# Exception::Class-style
	use Throwable::Factory FooBar => {
		isa    => 'Foo',
		fields => [qw( foo bar )],
	};

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Throwable-Factory>.

=head1 SEE ALSO

Exceptions built by this factory inherit from L<MooX::Struct> and compose
the L<Throwable> and L<StackTrace::Auto> roles.

This factory is inspired by L<Exception::Class>, and for simple uses should
be roughly compatible.

Use L<Try::Tiny> or L<TryCatch> if you need a try/catch mechanism.

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

