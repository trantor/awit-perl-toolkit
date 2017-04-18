# AWITPT DataObj backend for DBLayer
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

AWITPT::DataObj::Backend::DBLayer - AWITPT DataObj backend for DBLayer

=head1 SYNOPSIS

	#
	# Create a child class
	#
	package DataObj::myobject;

	use strict;
	use warnings;

	use AWITPT::DataObj::Backend::DBLayer 1.00;
	use parent, -norequire 'AWITPT::DataObj::Backend::DBLayer';

	our $VERSION = '1.00';

	# Return the configuration for this object
	sub config
	{
		my $config = {
			# Set table name
			'table' => "testtable",
			# Optional: set column mapping
			'table_columns' => { 'Property1' => "property_column", 'Property2' => "property_column2" },
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

The C<AWITPT::DataObj::Backend::DBLayer> class provides an abstraction layer between a data definition and the underlying database, allowing easy
access to table data. This class inherits all methods from C<AWITPT::DataObj>.

=cut


package AWITPT::DataObj::Backend::DBLayer;

use strict;
use warnings;

use AWITPT::DataObj 3.01;
use parent -norequire, 'AWITPT::DataObj';


our $VERSION = 2.01;

our (@ISA,@EXPORT,@EXPORT_OK);
@EXPORT = qw(
);
@EXPORT_OK = qw(
);


use AWITPT::Util 2.00 qw(
		hashifyLCtoMC
);
use AWITPT::DB::DBLayer;
use Data::Dumper;



=head1 METHODS

C<AWITPT::DataObj::Backend::DBLayer> provides the below manipulation methods.

=cut



=head2 config

	# Data object configuration
	sub config
	{
		retrun {
			'table' => "mytable"
			'table_columns' => { 'Property1' => "property_column", 'Property2' => "property_column2" },
			'properties' => {
				'Description' => {
					<OPTIONS>,
					<VALIDATION>,
					<RELATIONS>
				}
			}
		}
	}

See L<AWITPT::DataObj> for additional options, validation and relations.

=head3 Table Name

The table name is specified using the 'table' configuration option.

	'table' => "tableNameHere'


=head3 Table Column Mapping

Sometimes properties do not have the same column name. In this case we can specify a property to column mapping.

	'table_columns' => { 'PropertyName' => 'ColumnName' },

NB: Capitalization here is very important!

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


	# Get list of columns we need
	my @columns = $self->_tableProperties2Columns(
		$self->_propertiesWithout(DATAOBJ_PROPERTY_NOLOAD)
	);

	# Do select query
	my ($sth,$numResults) = DBSelectSearch(
		sprintf("
				SELECT
					%s
				FROM
					%s
			",
			join(',',@columns),
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
	my @records = ( );
	while (my $row = hashifyLCtoMC($sth->fetchrow_hashref(),@columns)) {
		# Translate hash from row to record
		my $data = $self->_tableRow2Record($row);
		# We use clone to clone the current child class, and reset to reset the object entirely
		my $record = $self->clone()->reset()->_loadHash($data);
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
		# Validate the ID property name
		my $IDProperty = $self->_property_id();
		if (!defined($IDProperty)) {
			# Report error and return
			$self->_error("Invalid invocation of load(), object has no property with option DATAOBJ_PROPERTY_ID");
			$self->_log(DATAOBJ_LOG_ERROR,
				"Invalid invocation of load(), object has no property with option DATAOBJ_PROPERTY_ID");
			return;
		}
		# Grab column name for the ID property
		my $IDColumn = $self->_tableProperty2Column($IDProperty);
		$matches{$IDColumn} = shift(@params);

	# More params, means we grabbing based on a "search"
	} else {
		%matches = @params;
	}

	# Build SQL statement
	my @whereItems;
	my @whereValues;
	foreach my $property (keys %matches) {
		# Grab column name
		my $column = $self->_tableProperty2Column($property);
		# Add to where arrays we'll use later
		push(@whereItems,"$column = ?");
		push(@whereValues,$matches{$property});
	}

	# Get list of columns we need
	my @columns = $self->_tableProperties2Columns(
		$self->_propertiesWithout(DATAOBJ_PROPERTY_NOLOAD)
	);

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
			join(',',@columns),
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
	my $row = hashifyLCtoMC($sth->fetchrow_hashref(),@columns);
	# Translate hash from row to record
	my $data = $self->_tableRow2Record($row);

	# Load the hash into the object
	$self->_loadHash($data);

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
	my ($self,@params) = @_;


	# We must call the parent _commit()
	$self->SUPER::commit(@params);

	# Abort if we don't have updates
	my $changed = $self->changed();
	my %data;

	# Loop with changed and add to data
	foreach my $property ($self->_propertiesWithout(DATAOBJ_PROPERTY_NOSAVE)) {
		# If its a changed item add it to the data we going to pass to the DB
		if (exists($changed->{$property})) {
			# Get column name
			my $column = $self->_tableProperty2Column($property);
			# Add property data
			$data{$column} = $changed->{$property};
			$self->_log(DATAOBJ_LOG_DEBUG2,"Property '%s' changed, column '%s' added to commit",$property,$column);
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

		# Check if we have an ID property
		if (defined(my $IDProperty = $self->_property_id())) {
			# If we do set it to $res, which is the LastID returned by the above
			$self->_set($IDProperty,$res);
		}

		$self->_log(DATAOBJ_LOG_DEBUG2,"Inserted into table '%s' row ID '%s' with: %s",$self->table(),$res,Dumper(\%data));
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

	# If we don't have any params, we are removing ourselves
	if (!@params) {
		# We can only remove ourselves if our ID is set
		my $id = $self->getID();
		if (defined($id) && $id > 0) {
			$matches{'ID'} = $self->getID();
			$removeID = 1;
		} else {
			$self->_error("Failed to remove object, no ID set");
			$self->_log(DATAOBJ_LOG_ERROR,"Failed to remove object from database, no ID is set");
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
	foreach my $property (keys %matches) {
		# Grab column name
		my $column = $self->_tableProperty2Column($property);
		# Add to where arrays we'll use later
		push(@whereItems,"$column = ?");
		push(@whereValues,$matches{$property});
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
		$self->_error("Database remove failed: %s",AWITPT::DB::DBLayer::error());
		return;
	}

	# If we should remove the ID signifying we not in the db, then do it
	if ($removeID) {
		$self->_set('ID',undef);
	}

	# Return number removed
	return $rows;
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

	# Set the table column mapping
	$self->{'_table_map_property2column'} = $config->{'table_columns'} // { };
	$self->_addInternalProperty('_table_map_property2column');

	# Create reverse mapping of table columns to property
	$self->{'_table_map_column2property'} = { };
	$self->_addInternalProperty('_table_map_column2property');
	foreach my $property ($self->_properties()) {
		my $column = $self->_tableProperty2Column($property);
		$self->{'_table_map_column2property'}->{$column} = $property;
	}

	return $self;
}



# Return table column mapping for a property
sub _tableProperty2Column
{
	my ($self,$property) = @_;


	return $self->{'_table_map_property2column'}->{$property} // $property;
}



# Return table property mapping for a column
sub _tableColumn2Property
{
	my ($self,$column) = @_;


	return $self->{'_table_map_column2property'}->{$column} // $column;
}



# Return table columns
sub _tableProperties2Columns
{
	my ($self,@properties) = @_;


	my @columns;

	# Retrieve and translate properties into columns
	foreach my $property (@properties) {
		push(@columns,$self->_tableProperty2Column($property));
	}

	return @columns;
}



# Return row from a record
sub _tableRecord2Row
{
	my ($self,$record) = @_;


	my $row = { };

	# Re-key the hash with property names
	foreach my $item (keys %{$row}) {
		my $newKey = $self->_tableProperty2Column($item);
		$row->{$newKey} = $record->{$item};
	}

	return $row;
}



# Return record from row
sub _tableRow2Record
{
	my ($self,$row) = @_;


	my $record = { };

	# Re-key the hash with property names
	foreach my $item (keys %{$row}) {
		my $newKey = $self->_tableColumn2Property($item);
		$record->{$newKey} = $row->{$item};
	}

	return $record;
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

L<AWITPT::DB::DBLayer>.

=cut
