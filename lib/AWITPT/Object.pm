# AWIT Object
# Copyright (C) 2016, AllWorldIT
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

AWITPT::Object - AWITPT Object

=head1 SYNOPSIS

	#
	# Create a class
	#
	package myobject;
	use AWITPT::Object 1.00;
	use base 'AWITPT::Object';

	use strict;
	use warnings;

	our $VERSION = '1.000';

	# Create a method
	sub mymethod
	{
		return "hello world";
	}


	#
	# Use your object
	#
	my $myboject = myobject->new();


=head1 DESCRIPTION

The AWITPT::Object class provides a basic abstraction layer to Perl objects.

=cut


package AWITPT::Object;
use parent 'Exporter';

use strict;
use warnings;

our $VERSION = "1.000";

our (@EXPORT,@EXPORT_OK);
@EXPORT = qw(
);
@EXPORT_OK = qw(
);



=head1 METHODS

C<AWITPT::Object> provides the below manipulation methods.

=cut



=head2 new

	my $obj = AWITPT::Object->new(@params);

The C<new> method is used to instantiate the object.

=over

=back

=cut

# Class instantiation
sub new
{
	my ($class,@params) = @_;

	# These are our internal properties
	my $self = {
	};

	# Build our class
	bless($self, $class);

	# And initialize
	return $self->_init(@params);
}



#
# INTERNAL METHODS BELOW
#



=head2 _init

	sub _init
	{
		my ($self,@params) = @_;

		return SUPER::_init(@params);
	}

The C<_init> method is called during class instantiation before its returned from the new() method.

=over

=back

=cut

# Initialize internals of the object
sub _init
{
	my ($self,@params) = @_;


	return $self;
}



1;
__END__

=head1 AUTHORS

Nigel Kukard E<lt>nkukard@lbsd.netE<gt>

=head1 BUGS

All bugs should be reported via the project issue tracker
L<http://gitlab.devlabs.linuxassist.net/awit-frameworks/awit-perl-toolkit/issues/>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016, AllWorldIT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<AWITPT::DataObj>.

=cut
