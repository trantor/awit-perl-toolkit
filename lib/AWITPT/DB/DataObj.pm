# AWIT Database Data Object
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

AWITPT::DB::DataObj - AWITPT Database Data Object

=head1 SYNOPSIS

	#
	# Create a child class
	#
	package AWITPT::DB::DataObj::myobject;
	use AWITPT::DB::DataObj 1.00;
	use parent 'AWITPT::DB::DataObj';

	use strict;
	use warnings;

	our $VERSION = '1.00';

	# Return the configuration for this object
	sub config
	{
		my $config = {
			# Set table name
			'table' => "testtable",
			# Setup our data definition
			'properties' => {
				'ID' => {
					'options' => DATAOBJ_PROPERTY_ID
				},
				'Name' => {
					'validate' => { 'type' => 'text', 'length' => 2 }
				}
			}
		};
		return $config;
	}

=head1 DESCRIPTION

The AWITPT::DB::DataObj class provides an abstraction layer between a data definition and the underlying database, allowing easy
access to table data.

=cut


package AWITPT::DB::DataObj;
use parent 'Exporter';

use AWITPT::DataObj 3.000;
use base 'AWITPT::DataObj';

use strict;
use warnings;

our $VERSION = "2.000";

our (@ISA,@EXPORT,@EXPORT_OK);
# Re-export our parents constants
@EXPORT = qw(
	DATAOBJ_LOADONIDSET

	DATAOBJ_PROPERTY_READONLY
	DATAOBJ_PROPERTY_NOLOAD
	DATAOBJ_PROPERTY_ID
	DATAOBJ_PROPERTY_NOSAVE

	DATAOBJ_RELATION_READONLY
);
@EXPORT_OK = qw(
);


use AWITPT::Util 2.00 qw(
		hashifyLCtoMC
);
use AWITPT::DB::DBLayer;
use Data::Dumper;



=head1 METHODS

C<AWITPT::DB::DataObj> provides the below manipulation methods.

=cut



=head2 config

	# Data object configuration
	sub config
	{
		retrun {
			'table' => "mytable"
			'properties' => {
				'Description' => {
					<OPTIONS>,
					<VALIDATION>,
					<RELATIONS>
				}
			}
		}
	}

See L<AWITPT::DataObj> for options, validation and relations.

=back

=cut



=head2 table

	print(STDERR "Table: ".$dataObj->table());

The C<table> method returns the data object table name.

=cut

# Return table name
sub table
{
	my $self = shift;


	return $self->{'_table'};
}



=head2 records

	my @records = $dataObj->records();

The C<records> method returns an array of data object records.

=cut

# Get records as an array of objects
sub records
{
	my $self = shift;


	# Do select query
	my ($sth,$numResults) = DBSelectSearch(
		sprintf("
				SELECT
					%s
				FROM
					%s
			",
			join(',',$self->_properties(DATAOBJ_PROPERTY_ALL ^ DATAOBJ_PROPERTY_NOLOAD)),
			$self->table()
		)
	);

	# Make sure we have a result
	if (!defined($numResults)) {
		my $error = AWITPT::DB::DBLayer::error();
		$self->_error("Database query failed: '$error'");
		$self->_log(DATAOBJ_LOG_WARNING,"Database query failed: %s",$error);
		return;
	}

	# Add each row as another record
	my @records;
	while (my $row = hashifyLCtoMC($sth->fetchrow_hashref(), $self->_properties(DATAOBJ_PROPERTY_ALL))) {
		# We use clone to clone the current child class, and reset to reset the object entirely
		my $record = $self->clone()->reset()->_loadHash($row);
		push(@records,$record);
	}

	return \@records;
}



=head2 load

	$dataObj->load($id);

	$dataObj->load('Name' => 'Joe Soap');

The C<load> method is used to load a single record from the database. It has 2 forms of invocation, either by specifying one
parameter which is assumed to be the value of the ID field, or by specifying a hash of key-value pairs.

Only the first matching record is returned, if multiple records exist the result can be any one of them being returned.

=cut

# Load Record
# - The load defaults to loading on ID, but a hash can be provided to load on various matches
sub load
{
	my ($self,@params) = @_;


	my %matches;

	# One param means that we're just grabbing an ID
	if (@params == 1) {
		$matches{'ID'} = shift(@params);
	# More params, means we grabbing based on a "search"
	} else {
		%matches = @params;
	}

	# Build SQL statement
	my @whereItems;
	my @whereValues;
	foreach my $column (keys %matches) {
		push(@whereItems,"$column = ?");
		push(@whereValues,$matches{$column});
	}

	# Do SQL select
	my $sth = DBSelect(
		sprintf('
				SELECT
					%s
				FROM
					%s
				WHERE
					%s
			',
			join(',',$self->_properties(DATAOBJ_PROPERTY_ALL ^ DATAOBJ_PROPERTY_NOLOAD)),
			$self->table(),
			join(' AND ',@whereItems)
		),
		@whereValues
	);

	# Check result
	if (!defined($sth)) {
		my $error = AWITPT::DB::DBLayer::error();
		$self->_error("Database query failed: '$error'");
		$self->_log(DATAOBJ_LOG_WARNING,"Database query failed: %s",$error);
		return;
	}

	# Grab row
	my $row = hashifyLCtoMC($sth->fetchrow_hashref(),$self->_properties(DATAOBJ_PROPERTY_ALL));

	$self->_loadHash($row);

	return $self;
}



=head2 commit

	$dataObj->commit();

The C<commit> method is used to commit the record to the database, this means updating it if it exists or inserting it if it does
not yet exist.


On success this method will return the L<AWITPT::DB::DBLayer> result for DBUpdate or DBInsert. When no data has changed a string
containing "0E0" will be returned. On error undef on will be returned.

=cut

# Commit record to database
sub commit
{
	my $self = shift;


	# Abort if we don't have updates
	my $changed = $self->changed();
	my %data;

	# Loop with changed and add to data
	foreach my $propertyName ($self->_properties(DATAOBJ_PROPERTY_ALL ^ DATAOBJ_PROPERTY_NOSAVE)) {
		# If its a changed item add it to the data we going to pass to the DB
		if (exists($changed->{$propertyName})) {
			$data{$propertyName} = $changed->{$propertyName};
		}
	}
	# If we have no values which changed, return 0E0
	if (!%data) {
		return "0E0";
	}

	# We have an ID so its an update
	my $res;
	if (my $id = $self->getID()) {

		# Update database record
		if (!defined($res = DBUpdate($self->table(),$id,%data))) {
			my $error = AWITPT::DB::DBLayer::error();
			$self->_error("Database update failed: '$error'");
			$self->_log(DATAOBJ_LOG_WARNING,"Database update failed: %s",$error);
			return;
		}

		$self->_log(DATAOBJ_LOG_DEBUG2,"Updating table '%s' row ID '%s' with: %s",$self->table(),$id,Dumper(\%data));


	# No ID means its an insert
	} else {

		# Insert database record
		if (!defined($res = DBInsert($self->table(),%data))) {
			my $error = AWITPT::DB::DBLayer::error();
			$self->_error("Database insert failed: '$error'");
			$self->_log(DATAOBJ_LOG_WARNING,"Database insert failed: %s",$error);
			return;
		}

		$self->_log(DATAOBJ_LOG_DEBUG2,"Inserting into table '%s' row ID '%s' with: %s",$self->table(),$res,Dumper(\%data));
		$self->_set('ID',$res);

	}

	return $res;
}



=head2 remove

	$dataObj->remove();

	$dataObj->remove('Name' => "Sam", 'Surname' => "Soap");

The C<remove> method is used to remove the data object from the database. The function can take an optional set of parameters which
will be used in the SQL DELETE WHERE statement instead of using the current object ID.

If no paremeters are given the current object ID is removed and the ID property removed from the data object. If a set of optional
parameters is given, the ID property is NOT removed.

=cut

# Remove Record
# - The remove defaults to removing on ID, but a hash can be provided to load on various matches
sub remove
{
	my ($self,@params) = @_;


	my %matches;

	# Are we going to remove the ID from this object at the end on success?
	my $removeID = 0;

	# If we don't have any params, we removing ourselves
	if (!@params) {
		# We can only remove ourselves if our ID is set
		my $id = $self->getID();
		if (defined($id) && $id > 0) {
			$matches{'ID'} = $self->getID();
			$removeID = 1;
		} else {
			$self->_error("Failed to remove object, no ID set");
			return;
		}

	# One param means that we're just deleting by ID
	} elsif (@params == 1) {
		$matches{'ID'} = shift(@params);

	# More params, means we grabbing based on a "search"
	} else {
		%matches = @params;
	}

	# Build SQL statement
	my @whereItems;
	my @whereValues;
	foreach my $column (keys %matches) {
		push(@whereItems,"$column = ?");
		push(@whereValues,$matches{$column});
	}

	$self->_log(DATAOBJ_LOG_DEBUG2,"Removing record from table '%s' with: %s",$self->table(),Dumper(\%matches));

	# Do SQL delete
	my $rows = DBDo(
		sprintf('
				DELETE FROM
					%s
				WHERE
					%s
			',
			$self->table(),
			join(' AND ',@whereItems)
		),
		@whereValues
	);

	# Make sure we got something back
	if (!defined($rows)) {
		$self->_error("Database remove failed: ".AWITPT::DB::DBLayer::error());
		return;
	}

	# If we should remove the ID signifying we not in the db, then do it
	if ($removeID) {
		$self->_set('ID',undef);
	}

	# Return number removed
	return $rows;
}



=head2 clone

	my $clonedObj = $dataObj->clone();

The C<clone> method returns a clone of the current object.

=cut

# Clone ourselves
sub clone
{
	my ($self,@data) = @_;


	return $self->SUPER::clone(@data);
}



#
# INTERNAL METHODS BELOW
#



# Reset internals of the object
sub _init
{
	my ($self,@params) = @_;


	# Initialize parent, VERY important
	$self->SUPER::_init(@params);

	# Grab our configuration so we can initialize our customizations
	my $config = $self->config();

	# First, lets see if we have a mandatory table to set
	if (!defined($config->{'table'})) {
		$self->_log(DATAOBJ_LOG_ERROR,"No 'table' defined!");
		return;
	}
	# Set the table name
	$self->{'_table'} = $config->{'table'};
	$self->_addInternalProperty('_table');

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

Copyright (C) 2014, AllWorldIT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<AWITPT::DB::DBLayer>.

=cut
