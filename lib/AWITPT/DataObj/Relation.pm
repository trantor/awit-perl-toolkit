# AWIT Data Object Relation Base Class
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

AWITPT::DataObj::Relation - AWITPT Database Data Object Relation Base Class

=head1 SYNOPSIS

	# FIXME

=head1 DESCRIPTION

The AWITPT::DataObj::Relation class provides a base class for relation classes.

=cut


package AWITPT::DataObj::Relation;
use parent 'Exporter';

use strict;
use warnings;

our $VERSION = "1.000";

our (@EXPORT,@EXPORT_OK);
@EXPORT = qw(
);
@EXPORT_OK = qw(
);


use AWITPT::DataObj;



=head1 METHODS

C<AWITPT::DataObj::Relation> provides the below methods.

=cut



=head2 new

	$relation = AWITPT::DataObj::Relation->new('My::Class');

The C<new> method is used to instantiate the object, in this case a root relation class.

=cut

# Class instantiation
sub new
{
	my ($class,$parent,$childClass) = @_;


	# Check if we firstly have a parent object
	if (!defined($parent)) {
		die "Parent object is required for DataObj::Relation";
	}

	# If there is no child class defined, we need to abort
	if (!defined($childClass)) {
		die "Child class is required for DataObj::Relation";
	}

	# These are our internal properties
	my $self = {
		'_parent' => $parent,
		'_child' => undef,
		'_child_class_name' => $childClass
	};

	# Build our class
	bless($self, $class);

	# Initialize the object
	$self->init($parent,$childClass);

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

	die "The AUTOLOAD function needs to be overridden in the child relation, called for '$function'";
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



# Grab the relation child
sub _relationChildClass
{
	my $self = shift;


	return $self->{'_child_class_name'};
}



# Return relation parent object
sub _relationParentObject
{
	my $self = shift;


	return $self->{'_parent'};
}



# We need a specialized destroyer here to dispose of the reference to the parent object as it references us too
sub DESTROY
{
	my $self = shift;


	delete($self->{'_parent'});
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

L<AWITPT::DataObj>, L<AWITPT::DataObj::Relation>, L<AWITPT::DataObj::Relation::List>.

=cut
