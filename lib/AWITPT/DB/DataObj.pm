# AWIT Data Object
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
	use base 'AWITPT::DB::DataObj';

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

use strict;
use warnings;
use vars qw{$AUTOLOAD};

our $VERSION = "2.00";

require Exporter;
our (@ISA,@EXPORT,@EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw(
	DATAOBJ_PROPERTY_ALL
	DATAOBJ_PROPERTY_READONLY
	DATAOBJ_PROPERTY_NOLOAD
	DATAOBJ_PROPERTY_ID
	DATAOBJ_PROPERTY_NOSAVE
);
@EXPORT_OK = qw(
);

use AWITPT::Util 2.00 qw(
		hashifyLCtoMC
		prettyUndef
		isUsername
		isNumber
		isVariable
		isEmail
		isBoolean
		isDomain
);
use AWITPT::DB::DBLayer;
use Data::Dumper;


# Constant exports...
use constant {
	# Property is read only
	'DATAOBJ_PROPERTY_READONLY' => 1,
	# Property is not loaded from DB
	'DATAOBJ_PROPERTY_NOLOAD' => 2,
	# Do not save this field to DB
	'DATAOBJ_PROPERTY_NOSAVE' => 4,
	# Combination of above
	'DATAOBJ_PROPERTY_ID' => 5,

	# Match property
	'DATAOBJ_PROPERTY_ALL' => 255,

	# Debug options
	'DATAOBJ_LOG_ERROR' => 1,
	'DATAOBJ_LOG_WARNING' => 2,
	'DATAOBJ_LOG_NOTICE' => 3,
	'DATAOBJ_LOG_INFO' => 4,
	'DATAOBJ_LOG_DEBUG' => 5
};


# Module debugging
our $DEBUG = 2;



=head1 METHODS

C<AWITPT::DB::DataObj> provides the below manipulation methods.

=cut



=head2 new

	my $obj = AWITPT::DB::DataObj::myobject->new();

The C<new> method is used to instantiate the object.

=cut

# Class instantiation
sub new
{
	my $class = shift;

	# These are our internal properties
	my $self = {
	};

	# Build our class
	bless($self, $class);

	# And initialize
	$self->_init();

	return $self;
}



=head2 config

	# Data object configuration
	sub config
	{
		retrun {
			'table' => "mytable"
			'properties' => {
				'testproperty' => { ...<property data>... }
			}
		}
	}

The C<config> method is used to return configuration information for the current object, it must be overridden for each object
created and must return a hashref with the object configuration.

Each property defined supports <property data> with a number of options described below...

	'testproperty => { 'options' => OPTION1 | OPTION2 }

	OPTION                          DESCRIPTION
	------                          -----------
	DATAOBJ_PROPERTY_READONLY       Internal use, this property cannot be set
	DATAOBJ_PROPERTY_NOLOAD         This property is not loaded from the database
	DATAOBJ_PROPERTY_NOSAVE         This property is not saved to the database


Each property also supports optional validation criteria described below...

	'validate' => { 'type' => VALIDATE_TYPE, ... }

	TYPE        DESCRIPTION                  OPTION    INFO
	----        -----------                  ------    ----
	text        Validates text characters    length    Optional minimum length
	                                         regex     Optional regex,
	                                                   eg. qr ( /^ABc/ )
	username    Validate username            params    See L<AWITPT::Util> for
	                                                   options for C<isUsername>
	email       Validate email address
	boolean     Validate boolean
	domain      Validate domain
	number      Validate number              params    See L<AWITPT::Util> for
	                                                   options for C<isNumber>

	regex       Validate against a regex     regex     Mandatory regex,
	                                                   eg. qr ( /^ABc/ )

=cut

# Blank config method, this needs to be overridden for each data object
sub config
{
	my $self = shift;


	return { };
}



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



# Autoload function to automagically handle some common things
sub AUTOLOAD
{
	my ($self,@params) = @_;
	my $function = $AUTOLOAD;


	# Don't mess with garbage collection
	return if ($function eq "DESTROY");

	# Cleanup name so we get the unqualified name
	$function =~ s/.*:://;

	$self->_log(DATAOBJ_LOG_DEBUG,"Function '$function'");


=head2 get[A-Z][A-Za-z0-9]+

	$dataObj->getName();

The C<get[A-Z][A-Za-z0-9]+> method returns the value of a the property matching the regex.

=cut

	# get[A-Z]*()
	if ($function =~ /^get([A-Z][A-Za-z0-9]+)/) {
		my $propertyName = $1;

		return $self->get($propertyName,@params);


=head2 set[A-Z][A-Za-z0-9]+

	$dataObj->setName("Joe Soap");

The C<set[A-Z][A-Za-z0-9]+> method sets the value of a the property matching the regex.

=cut

	# set*()
	} elsif ($function =~ /^set([A-Z][A-Za-z0-9]+)/) {
		my $propertyName = $1;

		return $self->set($propertyName,@params);


=head2 validate[A-Z][A-Za-z0-9]+

	$dataObj->validateName("Joe Soap");

The C<validate[A-Z][A-Za-z0-9]+> method validates the value for the named property.

=cut

	# validate*()
	} elsif ($function =~ /^validate([A-Z][A-Za-z0-9]+)/) {
		my $propertyName = $1;

		return $self->validate($propertyName,@params);
	}

	die "No such method: $AUTOLOAD";
}



=head2 set

	$dataObj->set("Name","Joe Soap");

The C<set> method sets the value of a property. The method returns $self;

=cut

# Property setter
sub set
{
	my ($self,$propertyName,$value) = @_;


	# Grab property
	my $property = $self->_propertyByName($propertyName);
	if (!defined($property)) {
		$self->_log(DATAOBJ_LOG_ERROR,"Property '$propertyName' not found");
	}

	# Check its not a protected property
	if ($property->{'options'} & DATAOBJ_PROPERTY_READONLY) {
		$self->_log(DATAOBJ_LOG_ERROR,"Cannot set property '$propertyName' as its read-only");
	}

	return $self->_set($property->{'name'},$value);
}



=head2 get

	$dataObj->get("Name");

The C<get> method returns the value of a data object property.

=cut

# Get property value
sub get
{
	my ($self,$propertyName) = @_;


	# Grab property
	my $property = $self->_propertyByName($propertyName);
	if (!defined($property)) {
		$self->_log(DATAOBJ_LOG_ERROR,"Property '$propertyName' not found");
	}

	return $self->_get($property->{'name'});
}



=head2 validate

	$dataObj->validate("Name",$value,...);

The C<validate> method returns the value of a data object property. The method returns the validated value on success,
undef on failure.

The optional parameters are type specific. Currently types 'username' and 'number' accept additional parameters which match up
to the C<isUsername> and C<isNumber> L<AWITPT::Util> functions.

=cut

# Validate property value
sub validate
{
	my ($self,$propertyName,$value,@params) = @_;


	# Grab property
	my $property = $self->_propertyByName($propertyName);
	if (!defined($property)) {
		$self->_log(DATAOBJ_LOG_ERROR,"Property '$propertyName' not found");
	}

	# Check if we have validation options
	if (!defined($property->{'validate'})) {
		return $value;
	}

	# Check this is a normal variable
	if (!defined(isVariable($value))) {
		$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed variable",$propertyName);
		$self->_error("Validation of '$propertyName' failed");
		return;
	}

	# Grab validate option
	my $validated = 0;

	my $propertyValidate = $property->{'validate'};

	# Validate 'regex' type
	if ($propertyValidate->{'type'} eq "regex") {
		# Validate against a regex
		my $regex = $propertyValidate->{'regex'};
		if (!($value =~ $regex)) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed regex =~",$propertyName);
			$self->_error("Validation of '$propertyName' failed");
			return;
		}
		# Validate length
		if (defined(my $length = $propertyValidate->{'length'})) {
			if (length($value) < $length) {
				$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed regex length",$propertyName);
				$self->_error("Validation of '$propertyName' length failed");
				return;
			}
		}

		return $value;

	# Validate 'text' type
	} elsif ($propertyValidate->{'type'} eq "text") {
		# Make sure this is text
		if (!($value =~ /^[[:print:]]*$/)) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed text printable characters",$propertyName);
			$self->_error("Validation of '$propertyName' failed");
			return;
		}

		# Check if we have a regex to also match against
		if (defined(my $regex = $propertyValidate->{'regex'})) {
			# Validate against a regex
			if (!($value =~ $regex)) {
				$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed text regex =~",$propertyName);
				$self->_error("Validation of '$propertyName' failed");
				return;
			}
		}

		# Validate length
		if (defined(my $length = $propertyValidate->{'length'})) {
			if (length($value) < $length) {
				$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed length",$propertyName);
				$self->_error("Validation of '$propertyName' length failed");
				return;
			}
		}

		return $value;

	# Validate 'email' type
	} elsif ($propertyValidate->{'type'} eq "email") {
		# Validate email address
		if (!isEmail($value)) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed email",$propertyName);
			$self->_error("Validation of '$propertyName' failed");
			return;
		}

		return $value;

	# Validate 'username' type
	} elsif ($propertyValidate->{'type'} eq "username") {
		# Validate username
		if (!isUsername($value,@params)) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed username",$propertyName);
			$self->_error("Validation of '$propertyName' failed");
			return;
		}

		# Validate length
		if (defined(my $length = $propertyValidate->{'length'})) {
			if (length($value) < $length) {
				$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed username length",$propertyName);
				$self->_error("Validation of '$propertyName' length failed");
				return;
			}
		}

		return $value;

	# Validate 'boolean' type
	} elsif ($propertyValidate->{'type'} eq "boolean") {
		# Validate boolean
		if (!defined($value = isBoolean($value))) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed boolean",$propertyName);
			$self->_error("Validation of '$propertyName' failed");
			return;
		}

		return $value;

	# Validate 'domain' type
	} elsif ($propertyValidate->{'type'} eq "domain") {
		# Validate domain
		if (!defined(isDomain($value))) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed domain",$propertyName);
			$self->_error("Validation of '$propertyName' failed");
			return;
		}

		return $value;

	# Validate 'number' type
	} elsif ($propertyValidate->{'type'} eq "number") {
		# Validate username
		if (!defined($value = isNumber($value,@params))) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed number",$propertyName);
			$self->_error("Validation of '$propertyName' failed");
			return;
		}

		return $value;

	}

	return;
}



=head2 changed

	my %changed = $dataObj->changed();

The C<changed> method returns a hash containing the properties and values of each item which was changed since the last C<load> or
C<commit>.

=cut

# Return changed data
sub changed
{
	my $self = shift;


	return \%{ $self->{'_data.changed'} };
}



=head2 asHash

	my %data = $dataObj->asHash();

The C<asHash> method returns a hash containing the objects current public properties.

=cut

# Return public data for this object
sub asHash
{
	my $self = shift;


	# Build up reply
	my %data;
	foreach my $property ($self->_properties(DATAOBJ_PROPERTY_ALL)) {
		# We allow retrieval of data if the get method has been overridden
		my $method = "get$property";
		$data{$property} = $self->$method($property);
	}

	return \%data;
}



=head2 recordsAsHash

	my @records = $dataObj->recordsAsHash();

The C<recordsAsHash> method returns an array of records, each record is a hashref.

=cut

# Get records as a hash
sub recordsAsHash
{
	my ($self,@params) = @_;


	# Grab records
	my $records = $self->records(@params);

	# Build result set
	my @res;
	foreach my $record (@{$records}) {
		push(@res,$record->asHash());
	}

	return \@res;
}



=head2 recordsAsFriendlyList

	my @records = $dataObj->recordsAsFriendlyList();

The C<recordsAsFriendlyList> method returns an array of arrayrefs, each containing arrayref has the first index as the friendly
name and the second as the record ID.

The result looks like this...

	@records = (
		[ "friendly name 1", 1 ],
		[ "freindly 2" , 2 ]
	);

=cut

# Get records as a friendly list
sub recordsAsFriendlyList
{
	my ($self,@params) = @_;


	# Abort if we don't have a friendlyName() method
	if (!$self->can('friendlyName')) {
		die "Using recordsAsFriendlyList() requires the friendlyName() method to be defined";
	}

	# Grab records
	my $records = $self->records(@params);

	# Build result set
	my @res;
	foreach my $record (@{$records}) {
		push(@res,[ $record->friendlyName() => $record->getID() ]);
	}

	return \@res;
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
			$self->_tableName()
		)
	);

	# Make sure we have a result
	if (!defined($numResults)) {
		$self->_error("Database query failed: ".AWITPT::DB::DBLayer::error());
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

The C<load> method is used to load a single record from the database. It has 2 forms of invocation, either by specifying One
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
			$self->_tableName(),
			join(' AND ',@whereItems)
		),
		@whereValues
	);

	# Grab row
	my $row = hashifyLCtoMC($sth->fetchrow_hashref(),$self->_properties(DATAOBJ_PROPERTY_ALL));

	$self->_loadHash($row);

	return $self;
}



=head2 loadHash

	$dataObj->loadHash($dataHash);

The C<loadHash> method loads properties from a hashref. If the data was previously changed the changed flag is reset and the loaded
flag is applied to the property.

=cut

# Load record data from hash
# The _loadHash function uses set()
sub loadHash
{
	my ($self,$data) = @_;


	# Set properties
	foreach my $item (keys %{$data}) {
		$self->set($item,$data->{$item});
	}

	$self->_log(DATAOBJ_LOG_DEBUG,"Loaded %s properties from hash: %s", (keys %{$data}), Dumper($data));

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

	if (!%data) {
		return "0E0";
	}


	# We have an ID so its an update
	my $res;
	if (my $id = $self->getID()) {

		# Update database record
		if (!defined($res = DBUpdate($self->table(),$id,%data))) {
			$self->_error("Database update failed: ".AWITPT::DB::DBLayer::error());
			return;
		}

		$self->_log(DATAOBJ_LOG_DEBUG,"Updating table '%s' row ID '%s' with: %s",$self->table(),$id,Dumper(\%data));


	# No ID means its an insert
	} else {

		# Insert database record
		if (!defined($res = DBInsert($self->table(),%data))) {
			$self->_error("Database insert failed: ".AWITPT::DB::DBLayer::error());
			return;
		}

		$self->_log(DATAOBJ_LOG_DEBUG,"Inserting into table '%s' row ID '%s' with: %s",$self->table(),$res,Dumper(\%data));
		$self->_set('ID',$res);

	}

	return $res;
}



=head2 remove

	$dataObj->remove();

	$dataObj->remove('Name' => "Sam", 'Surname' => "Soap");

The C<remove> method is used to remove the data object from the database. The function can take an optional set of parameters
which will be used in the SQL DELETE WHERE statement instead of using the current object ID.

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

	$self->_log(DATAOBJ_LOG_DEBUG,"Removing record from table '%s' with: %s",$self->table(),Dumper(\%matches));

	# Do SQL delete
	my $rows = DBDo(
		sprintf('
				DELETE FROM
					%s
				WHERE
					%s
			',
			$self->_tableName(),
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



=head2 reset

	$dataObj->reset();

The C<reset> method clears all data and resets the object.

=cut

# Clone ourselves
sub reset
{
	my $self = shift;


	# Clear our internals
	$self->{'_data'} = { };
	$self->{'_data.loaded'} = { };
	$self->{'_data.changed'} = { };
	$self->{'_error'} = "";

	$self->_log(DATAOBJ_LOG_DEBUG,"Data reset");

	return $self;
}



=head2 clone

	my $clonedObj = $dataObj->clone();

The C<clone> method returns a clone of the current object.

=cut

# Clone ourselves
sub clone
{
	my $self = shift;


	# Setup our internals
	my $clone = {
		'_table' => $self->{'_table'},
		'_properties' => $self->{'_properties'},
		'_properties_lc' => $self->{'_properties_lc'},
		'_data' => $self->{'_data'},
		'_data.changed' => $self->{'_data'},
		'_error' => ""
	};

	# Build our clone based on the ref of the parent class
	bless($clone, ref($self));

	$self->_log(DATAOBJ_LOG_DEBUG,"Object cloned");

	return $clone;
}



=head2 log

	# Logging method override
	sub log
	{
		my ($self,$msg) = @_;
		$someLogger->log($msg);
	}

The C<log> method can be overridden to provide a custom logging.

=cut

# Default logging method which can be overridden
sub log
{
	my ($self,$level,$msg) = @_;

	print(STDERR "$msg\n");
}



=head2 error

	print(STDERR "ERROR: ".$dataObj->error()."\n");

The C<error> method is used to return the last error encountered by the data object.

=cut

# Return current object error message
sub error
{
	my $self = shift;


	my $error = $self->{'_error'};

	# Reset error
	$self->{'_error'} = "";

	# Return error
	return $error;
}



#
# INTERNAL METHODS BELOW
#



# Reset internals of the object
sub _init
{
	my $self = shift;


	# Grab our configuration
	my $config = $self->config();

	my $selfClass = ref($self);

	# First, lets see if we have a mandatory table to set
	if (!defined($config->{'table'})) {
		$self->_log(DATAOBJ_LOG_ERROR,"No 'table' defined!");
	}
	# Set the table name
	$self->{'_table'} = $config->{'table'};


	# Loop through the properties, check them and clean them up
	foreach my $propertyName (keys %{$config->{'properties'}}) {
		my $propertyConfig = $config->{'properties'}->{$propertyName};

		$self->_log(DATAOBJ_LOG_DEBUG,"Processing property '%s'",$propertyName);

		# Check format of property
		if (!($propertyName =~ /^[A-Z][A-Za-z0-9]+$/)) {
			$self->_log(DATAOBJ_LOG_ERROR,"Property '%s' has an invalid name",$propertyName);
		}

		# Check if we have options, if we don't set to 0
		# // is like ||, but // is for undefined
		$self->{'_properties'}->{$propertyName}->{'options'} = $propertyConfig->{'options'} // 0;

		# Set property
		my $property = $self->{'_properties'}->{$propertyName};

		# Check if we have validation criteria
		if (defined($propertyConfig->{'validate'})) {
			my $validateOptions = $propertyConfig->{'validate'};


			# Loop with validation options
			foreach my $validateOption (keys %{$validateOptions}) {
				# Grab the option value for easy use below
				my $validateValue = $validateOptions->{$validateOption};

				# Check validation options
				if ($validateOption eq "type") {
					# Check for valid validation types
					if (
						$validateValue ne "regex" &&
						$validateValue ne "text" &&
						$validateValue ne "email" &&
						$validateValue ne "username" &&
						$validateValue ne "boolean" &&
						$validateValue ne "domain" &&
						$validateValue ne "number"
					) {
						$self->_log(DATAOBJ_LOG_ERROR,"Property '%s' has an invalid validation type '%s'",$propertyName,
								$validateValue);
					}

					# Set type
					$property->{'validate'}->{'type'} = $validateValue;	

				} elsif ($validateOption eq "length") {
					# Length must be > 0
					if (
						$validateValue < 1
					) {
						$self->_log(DATAOBJ_LOG_ERROR,"Property '%s' has an invalid validation type '%s'",$propertyName,
								$validateValue);
					}

					# Set length
					$property->{'validate'}->{'length'} = $validateValue;	

				} elsif ($validateOption eq "params") {
					# Set params
					$property->{'validate'}->{'params'} = [ @{$validateValue} ];
				}
			}

			# Imply the regex type if we have a regex option set and no type set
			if (!defined($property->{'validate'}->{'type'}) && defined($property->{'validate'}->{'regex'})) {
				$property->{'validate'}->{'type'} = "regex";
			}

			# We must always have a type
			if (!defined($property->{'validate'}->{'type'})) {
					$self->_log(DATAOBJ_LOG_ERROR,"Property '%s' has no validation",$propertyName);
			}

			# Check that the regex type has a regex argument
			if ($property->{'validate'}->{'type'} eq "regex" && !defined($property->{'validate'}->{'regex'})) {
					$self->_log(DATAOBJ_LOG_ERROR,"Property '%s' has a regex validation type, but no regex",$propertyName);
			}

			# Check that the regex type has a regex argument
			if (defined($property->{'validate'}->{'regex'}) && ref($property->{'validate'}->{'regex'}) ne "Regexp") {
				$self->_log(DATAOBJ_LOG_ERROR,"Property '%s' has a regex match but not a type consistent with qr( /.../ )",
						$propertyName);
			}

			# Check if we have a type set
			if (!defined($property->{'validate'}->{'type'})) {
				$self->_log(DATAOBJ_LOG_ERROR,"Property '%s' has no validation type set",$propertyName);
			}

			$self->_log(DATAOBJ_LOG_DEBUG,"Property '%s' has validation type '%s'",$propertyName,
				$property->{'validate'}->{'type'});
		}

		$self->{'_properties'}->{$propertyName}->{'name'} = $propertyName;
		# Map lowercase property name
		$self->{'_properties_lc'}->{lc($propertyName)} = $propertyName;
	}

	# Values for each property
	$self->{'_data'} = { };
	# Values which were loaded
	$self->{'_data.loaded'} = undef;
	# Values which were changed
	$self->{'_data.changed'} = {};


	# Reset error too
	$self->{'_error'} = "";


warn "INITDUMP: ".Dumper($self);

	return $self;
}



# Internal logging method
sub _log
{
	my ($self,$level,$format,@params) = @_;


	# Check if we want this debug level
	if ($DEBUG >= $level) {
		my @caller = caller(1);

		# If we do format our message and send it along
		my $msg = sprintf("%s: ",$caller[3]) . sprintf($format,@params);
		if ($level == DATAOBJ_LOG_ERROR) {
			die($msg);
		} else {
			$self->log($level,$msg);
		}
	}
}



# This function is used to set the last error for this class
sub _error
{
	my ($self,$error) = @_;


	# Set error
	$self->{'_error'} = $error;

	return;
}



# Return the property hash of a given property
sub _propertyByName
{
	my ($self,$propertyName) = @_;


	# No matter what the case, we will still find our property
	$propertyName = $self->{'_properties_lc'}->{lc($propertyName)};
	if (!defined($propertyName)) {
		return;
	}

	return $self->{'_properties'}->{$propertyName};
}



# Get properties
sub _properties
{
	my ($self,$match) = @_;


	my @properties;

	# Find the properties we're after
	foreach my $propertyName (keys %{$self->{'_properties'}}) {
		my $property = $self->{'_properties'}->{$propertyName};

		# Check if there is no match criteria, or the criteria matches
		if (!($property->{'options'} & ~$match)) {
			push(@properties,$propertyName);
		}
	}

	return @properties;
}



# Set property, as this is an internal function it can set ANY property
sub _set
{
	my ($self,$propertyName,$value) = @_;


	my $property = $self->_propertyByName($propertyName);

	# Check if we have data from the DB
	if (defined($self->{'_data.loaded'})) {
		# Check it doesn't match
		if ($self->{'_data.loaded'}->{$property->{'name'}} ne $value) {
			$self->{'_data.changed'}->{$property->{'name'}} = $value;
		# Delete if it exists and its the same
		} else {
			delete($self->{'_data.changed'}->{$property->{'name'}});
		}
	# If DB data is not defined, it means this is new, so its changed
	} else {
		$self->{'_data.changed'}->{$property->{'name'}} = $value;
	}

	$self->_log(DATAOBJ_LOG_DEBUG,"Property '%s' set to '%s'",$property->{'name'},$value);
	$self->{'_data'}->{$property->{'name'}} = $value;

	return $self;
}



# Get property, as this is an internal method, we can get ANY property
sub _get
{
	my ($self,$propertyName) = @_;


	# No matter what the case, we will still find our property
	if (my $property = $self->_propertyByName($propertyName)) {
		my $value = $self->{'_data'}->{$property->{'name'}};
		$self->_log(DATAOBJ_LOG_DEBUG,"Property '%s' retrieved value '%s'",$propertyName,prettyUndef($value));
		return $value;
	}

	$self->_log(DATAOBJ_LOG_ERROR,"Property '$propertyName' not found");

	# This should never return as ERROR has a die() result
	return;
}


# Load record data from hash, using _set and setup special data.loaded items
sub _loadHash
{
	my ($self,$data) = @_;


	# Set properties
	foreach my $item (keys %{$data}) {
		# Set this item as being loaded, if we do this before the _set, we don't generate a data.changed entry
		$self->{'data.loaded'}->{$item} = $data->{$item};
		$self->_set($item,$data->{$item});
	}

	$self->_log(DATAOBJ_LOG_DEBUG,"Loaded %s internal properties from hash: %s", (keys %{$data}), Dumper($data));

	return $self;
}



1;
# vim: ts=4
__END__

=head1 DEBUGGING

	# Change debug level
	# 1 = error, 2 = warning (default), 3 = notice, 4 = info, 5 = debug
	$AWITPT::DB::DataObj::DEBUG = 5;

Verbosity of what the object is doing can be increased by using the above variable to set the logging level.

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
