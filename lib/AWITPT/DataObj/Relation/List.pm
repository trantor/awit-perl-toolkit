# AWIT Data Object List Relation
# Copyright (C) 2014-2017, AllWorldIT
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

AWITPT::DataObj::Relation::List - AWITPT Database Data Object List Relation

=head1 SYNOPSIS

	# List relations are treated as lists with some accessor functions
	my $obj = DataObj::Task->new();

	# Lets create a history object...
	my $history = DataObj::Task::History->new();
	$history->setCreatorID(1);
	$history->setChanges("Hi there, test 1 2 3");

	# There are a couple of ways this can be added to the list
	$obj->relationHistory()->add($history);
	$obj->relation("History")->add('UserID' => 1, 'Changes' => "Second test");
	$obj->History->add('UserID' => 1, 'Changes' => "Third test");

=head1 DESCRIPTION

The AWITPT::DataObj::Relation::List class provides a list relation between DataObjs.

=cut


package AWITPT::DataObj::Relation::List;

use strict;
use warnings;

use AWITPT::DataObj::Relation 1.01;
use parent -norequire, 'AWITPT::DataObj::Relation';


our $VERSION = 1.01;


use AWITPT::DataObj;



=head1 METHODS

C<AWITPT::DataObj::Relation::List> provides the below methods.

=cut



=head2 _init

The C<_init> method is used internally by AWITPT::DataObj;

=cut

# Class initialization
sub _init
{
	my ($self,@params) = @_;


	# Call parent initialization
	$self->SUPER::_init(@params);

	# Initialize our child list
	$self->{'_childList'} = { };

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

	die "No such method: $AUTOLOAD";
}



=head2 add

	$obj->relationHistory()->add($history);
	$obj->relation("History")->add('UserID' => 1, 'Changes' => "Second test");
	$obj->History->add('UserID' => 1, 'Changes' => "Third test");

The C<add> method adds a child object to the list of objects in the relation.

=cut

# Add a child object
sub add
{
	my ($self,@params) = @_;


	# Check if what we have is a hashref
	if (!@params) {
		$self->_relationParentObject()->_log(DATAOBJ_LOG_ERROR,"Relation add called with no parameters");
		return;
	}

	# Check if the first object is the class we looking FOR
	while (my $item = $params[0]) {
		# Object to add
		my $obj;
		# Reference of object
		my $ref;

		# Check if we've been provided an already instantiated object
		if (ref($item) eq $self->_relationChildClass()) {
			$obj = $item;
			$ref = "$item"; # FIXME, use the ID?
		# Then check if its a hash
		} elsif (ref($item) eq "HASH") {
			# The child should be clean, so we don't need a ->reset(), we however use $item to initialize the new object
			$obj = $self->_relationChild()->clone($item);
			$ref = "$item"; # FIXME , use the ID?
		} elsif (!(@params % 2)) {
			# The child should be clean, so we don't need a ->reset(), we however use @params to initialize the new object
			$obj = $self->_relationChild()->clone(@params);
			$ref = "$item"; # FIXME, use the ID?
			# @params consumes everything, so this is our last iteration
			last;
		} else {
			$self->_relationParentObject()->_log(DATAOBJ_LOG_ERROR,"Unknown datatype encountered: %s",ref($item));
			last;
		}

		$self->_add($ref,$obj);

		shift(@params);
	}

	return $self;
}



#
# INTERNALS
#



# Do the actual internal adding of the new object to our list
sub _add
{
	my ($self,$ref,$obj) = @_;


	# Add to our child list, using the ref to prevent duplicates of objects
	$self->{'_childList'}->{$ref} = $obj;

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

Copyright (C) 2014-2017, AllWorldIT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<AWITPT::DataObj>, L<AWITPT::DataObj::Relation>, L<AWITPT::DataObj::Relation::Direct>.

=cut


