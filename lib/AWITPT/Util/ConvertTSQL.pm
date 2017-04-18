# TSQL conversion
# Copyright (C) 2016-2017, AllWorldIT
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

AWITPT::Util::ConvertTSQL - TSQL conversion

=head1 SYNOPSIS

	#
	# This class is only meant to be inherited
	#

=head1 DESCRIPTION

The AWITPT::Object class provides a basic abstraction layer to Perl objects.

=cut


package AWITPT::Util::ConvertTSQL;

use strict;
use warnings;

use AWITPT::Object 1.01;
use parent -norequire, 'AWITPT::Object';


our $VERSION = 1.01;



=head1 METHODS

C<AWITPT::Util::ConvertTSQL> provides the below methods.

=cut



=head2 convert

	$tsql->convert("CREATE @PREFIX@table ( ....... );";

The C<convert> method is called to convert a piece of TSQL into the format we're working with.

=over

=back

=cut

# Convert a TSQL line into the current format
sub convert
{
	my ($self,$line) = @_;


	# Loop with the expressions
	while ((my $macro, my $value) = each %{$self->{'expressions'}}) {
		$line =~ s/$macro/$value/g;
	}

	return $line;
}



=head2 substitute

	# Example using ->substitute in config()
	sub config
	{
		my ($self,@params) = @_;

		$self->substitute('@SERIAL_TYPE@','SERIAL');

		return $self;
	}

The C<substitute> method is called to create a substitution of a macro into a piece of text, used when converting TSQL into various
other DB formats.

=over

=back

=cut

# Substitute macro into something
sub substitute
{
	my ($self,$macro,$value) = @_;


	$self->{'expressions'}->{$macro} = $value;

	return $self;
}



#
# INTERNAL METHODS BELOW
#



=head2 _config

	sub _config
	{
		my ($self,@params) = @_;

		$self->substitute('@TEST@','ABCD');

		return $self;
	}

The C<_config> method is called during initialization to setup regular expressions. The @params comes from the C<new>->() call.

=over

=back

=cut

# Configure the conversion expressions
sub _config
{
	my ($self,@params) = @_;


	$self->substitute('@PREFIX@',$self->{'prefix'});

	return $self;
}



=head2 _init

The C<_init> method is called during class instantiation before its returned from the new() method. In this case we initialize
the regular expression property.

=over

=back

=cut

# Initialize internals of the object
sub _init
{
	my ($self,@params) = @_;


	# Call parent initialization
	$self->SUPER::_init(@params);

	# If we have uneven number of params, the first will be our sub-class
	if (@params % 2) {
		my $subClass = shift(@params);
		my $newClassPM = "AWITPT/Util/ConvertTSQL/$subClass.pm";
		my $newClass = "AWITPT::Util::ConvertTSQL::$subClass";

		# Try load the new class
		# uncoverable branch true
		eval {
			require $newClassPM;
		};
		# Check if the eval succeeded
		if ($@) {
			warn "AWITPT::Util::ConvertTSQL::$subClass could not be loaded: $@";
			return;
		};

		# Import methods
		$newClass->import();

		# Instantiate the new class and replace $self
		return $newClass->new(@params);
	}

	# Grab parameter list
	my %params = (@params);

	# Populate internal properties
	$self->{'prefix'} = $params{'prefix'} // "";
	$self->{'expressions'} = { };

	return $self->_config();
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
