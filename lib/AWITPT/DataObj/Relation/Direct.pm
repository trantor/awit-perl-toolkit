# AWIT Data Object Direct Relation
# Copyright (C) 2014, AllWorldIT
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

AWITPT::DataObj::Relation::Direct - AWITPT Database Data Object Direct Relation

=head1 SYNOPSIS

	# Direct relations link directly to the properties, we first create a object
	my $obj = DataObj::Task->new();

	# Then we can then validate the property
	my $creatorID = $obj->validateCreatorID(99);

	# And set its value...
	$obj->setCreatorID($creatorID);

=head1 DESCRIPTION

The AWITPT::DataObj::Relation::Direct class provides a direct relation between DataObjs.

=cut


package AWITPT::DataObj::Relation::Direct;
use AWITPT::DataObj::Relation 1.000;
use base 'AWITPT::DataObj::Relation';

use strict;
use warnings;

our $VERSION = "1.000";


use AWITPT::DataObj;


=head1 METHODS

C<AWITPT::DataObj::Relation::Direct> provides the below methods.

=cut



# Class instantiation
sub new
{
	my ($class,@params) = @_;


	# Instantiate parent
	my $self = $class->SUPER::new(@params);

	# Setup our own properties
	$self->{'_child'} = undef;

	return $self;
}



# Autoload function to automagically handle some common things
our $AUTOLOAD;
sub AUTOLOAD
{
	my ($self,@params) = @_;
	my $function = $AUTOLOAD;


	# Don't mess with garbage collection
	return if ($function eq "DESTROY");

	# Cleanup name so we get the unqualified name
	$function =~ s/.*:://;

	# Redirect all other namespace calls to the child
	return $self->_relationChild()->$function(@params);
}



#
# INTERNALS
#



# Grab the relation child
sub _relationChild
{
	my $self = shift;


	# If we don't have a child we need to create it
	if (!defined($self->{'_child'})) {
		# Grab child class name
		my $childClassName = $self->_relationChildClass();
		# Instantiate child class
		my $child;
		eval "
			use $childClassName;
			\$child = ${childClassName}->new(DATAOBJ_LOADONIDSET);
		";
		die $@ if $@;
		# Assign instantiated child class
		$self->{'_child'} = $child;
		# Use child logging method...
		$child->_log(DATAOBJ_LOG_DEBUG,"Spawned '$childClassName' to satisfy relation requirement");
	}

	# Return the child we have or have created
	return $self->{'_child'};
}



1;
__END__

=head1 AUTHORS

Nigel Kukard E<lt>nkukard@lbsd.netE<gt>

=head1 BUGS

All bugs should be reported via the project issue tracker
L<http://gitlab.devlabs.linuxassist.net/awit-frameworks/awit-perl-toolkit/issues/>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014, AllWorldIT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<AWITPT::DataObj>, L<AWITPT::DataObj::Relation>, L<AWITPT::DataObj::Relation::Direct>, L<AWITPT::DataObj::Relation::Direct>.

=cut

