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

AWITPT::DataObj - AWITPT Database Data Object

=head1 SYNOPSIS

	#
	# Create a child class
	#
	package AWITPT::DataObj::myobject;
	use AWITPT::DataObj 1.00;
	use base 'AWITPT::DataObj';

	use strict;
	use warnings;

	our $VERSION = '1.000';

	# Return the configuration for this object
	sub config
	{
		my $config = {
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

The AWITPT::DataObj class provides an abstraction layer between a data definition and the underlying data store, providing easy
access to data.

=cut


package AWITPT::DataObj;
use parent 'Exporter';

use strict;
use warnings;

our $VERSION = "3.000";

our (@EXPORT,@EXPORT_OK);
@EXPORT = qw(
	DATAOBJ_LOADONIDSET

	DATAOBJ_PROPERTY_ALL
	DATAOBJ_PROPERTY_READONLY
	DATAOBJ_PROPERTY_NOLOAD
	DATAOBJ_PROPERTY_ID
	DATAOBJ_PROPERTY_NOSAVE

	DATAOBJ_RELATION_READONLY

	DATAOBJ_LOG_ERROR
	DATAOBJ_LOG_WARNING
	DATAOBJ_LOG_NOTICE
	DATAOBJ_LOG_INFO
	DATAOBJ_LOG_DEBUG
	DATAOBJ_LOG_DEBUG2
);
@EXPORT_OK = qw(
);

# Constant exports...
use constant {
	# Object must be loaded on property ID set
	'DATAOBJ_LOADONIDSET' => 1,

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

# FIXME - Needs implementing
	# Relation is read only, it will not create the sub-object
	'DATAOBJ_RELATION_READONLY' => 1,

	# Debug options
	'DATAOBJ_LOG_ERROR' => 1,
	'DATAOBJ_LOG_WARNING' => 2,
	'DATAOBJ_LOG_NOTICE' => 3,
	'DATAOBJ_LOG_INFO' => 4,
	'DATAOBJ_LOG_DEBUG' => 5,
	'DATAOBJ_LOG_DEBUG2' => 6
};

# Module debugging
our $DEBUG = 2;

use AWITPT::Util 2.00 qw(
	prettyUndef
	isUsername
	isNumber
	isVariable
	isEmail
	isBoolean
	isDomain
);
use Carp qw(longmess);
use Data::Dumper;



=head1 METHODS

C<AWITPT::DataObj> provides the below manipulation methods.

=cut



=head2 new

	my $obj = AWITPT::DataObj::myobject->new();

The C<new> method is used to instantiate the object.

Data object C<options> can also be specified to customize the objects behavior.

=head3 Options

Each object supports options described below...

	'options' => OPTION1 | OPTION2

Below is a list of supported options:

=over

=item *
B<DATAOBJ_LOADONIDSET>

This property will cause the object to load when a DATAOBJ_PROPERTY_ID is set.

=back


=cut

# Class instantiation
sub new
{
	my ($class,$options) = @_;

	# These are our internal properties
	my $self = {
	};

	# Build our class
	bless($self, $class);

	# And initialize
	$self->_init($options);

	return $self;
}



=head2 config

	# Data object configuration
	sub config
	{
		retrun {
			'properties' => {
				'OwnerID' => { }, # No parameters as its pretty much handled by the relation
				'Description' => {
					'validate' => { 'type' => 'text', 'length' => 2 },
					# 'options' => ... property options can be specified here
				}
			},
			'relations' => {
				'Owner' => {
					'class' => "DataObj::User",
					'type' => "Direct",
					'associate' => { 'OwnerID' => 'ID' },
					'options' => DATAOBJ_RELATION_READONLY
				}
			}
		}
	}

The C<config> method is used to return configuration information for the current object, it must be overridden for each object
created and must return a hashref with the object configuration.

=head3 Property Options

Each property supports options described below...

	'options' => OPTION1 | OPTION2

Below is a list of supported options:

=over

=item *
B<DATAOBJ_PROPERTY_READONLY>

Internal use, this property cannot be set

=item *
B<DATAOBJ_PROPERTY_NOLOAD>

This property is not loaded from the database

=item *
B<DATAOBJ_PROPERTY_NOSAVE>

This property is not saved to the database

=back


=head3 Property Validation

Each property supports optional validation criteria described below...

	'validate' => { 'type' => <VALIDATE_TYPE>, <VALIDATION_OPTIONS>... }

Below is a list of supported validation types:

=over

=item *
B<text>

Validate text.  The C<length> and C<regex> options are supported.

=over

=item *
B<length>

Optional minimum length.

=item *
B<regex>

Optional regex, eg. qr ( /^ABc/ ).

=back

=item *
B<username>

Validate username, additional parameters in C<params> can be passed for validation.

=over

=item *
B<params> (arrayref)

See L<AWITPT::Util> for options for C<isUsername>.

=back

=item *
B<email>

Validate an email address.

=item *
B<boolean>

Validate boolean.

=item *
B<domain>

Validate domain.

=item *
B<number>

Validate number, additional validation options can be specified using the C<params> option.

=over

=item *
B<params> (arrayref)

See L<AWITPT::Util> for options for C<isNumber>.

=back

=item *
B<regex>

Validate against a regex. The C<regex> option must be specified with a qr(/..../) regex.

=item *
B<relation>

Validate using the related object. This calls the related objects validate() method.

=item *
B<load>

Validate by attempting to load the property, this calls the load() method on the current object.

=back

=head3 Relation Options

Each relation defined supports a number of options described below...

	'options' => OPTION1 | OPTION2

Below is a list of supported options:

=over

=item *
B<DATAOBJ_RELATION_READONLY>

The child object will not be created if it does not exist. This only relates to the 'Direct' relation.

=back


=cut

# Blank config method, this needs to be overridden for each data object
sub config
{
	my $self = shift;


	$self->_log(DATAOBJ_LOG_ERROR,"The 'records' method needs to be implemented");

	return;
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

The same special cases apply as with C<set>.

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

NOTE: There is a special case where if you are setting a relation property, and that property has DATAOBJ_LOADONIDSET and
DATAOBJ_PROPERTY_ID options set, that this will cause a $obj->load() to occur. In this case the return is the same as C<load>.

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

	# Check if we should insted do a load if we're have DATAOBJ_LOADONIDSET and we're an ID property
	if ($self->{'_options'} & DATAOBJ_LOADONIDSET && $property->{'options'} & DATAOBJ_PROPERTY_ID == DATAOBJ_PROPERTY_ID) {
warn " - - - LOAD ID:".prettyUndef($value);
		# As this is a object set to load when set, and set as a ID
		if (!defined($self->load($property->{'name'} => $value))) {
			return;
		}

	# Check its not a protected property
	} elsif ($property->{'options'} & DATAOBJ_PROPERTY_READONLY) {
		$self->_log(DATAOBJ_LOG_ERROR,"Cannot set property '%s' as its read-only",$property->{'name'});
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
		$self->_log(DATAOBJ_LOG_ERROR,"Property '%s' not found",$property->{'name'});
	}

	return $self->_get($property->{'name'});
}



=head2 validate

	$dataObj->validate("Name",$value,...);

The C<validate> method returns the value of a data object property. The method returns the validated value on success, undef on
failure.

The optional parameters are type specific. Currently types 'username' and 'number' accept additional parameters which match up to
the C<isUsername> and C<isNumber> L<AWITPT::Util> functions.

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

	my $validateType;
	if (defined($property->{'validate'})) {
		$validateType = $property->{'validate'}->{'type'};
	} else {
		# If we have relations, use the relation as validation by default
		if (defined($self->_relationNamesFromProperty($property))) {
			$validateType = 'relation';
		} else {
			return $value;
		}
	}

	# Check this is a normal variable
	if (!defined(isVariable($value))) {
		$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed variable",$property->{'name'});
		$self->_error("Validation of '".$property->{'name'}."' failed");
		return;
	}

	# Grab validate option
	my $validated = 0;


	# Validate 'regex' type
	if ($validateType eq "regex") {
		# Validate against a regex
		my $regex = $property->{'validate'}->{'regex'};
		if (!($value =~ $regex)) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed regex =~",$property->{'name'});
			$self->_error("Validation of '".$property->{'name'}."' failed");
			return;
		}
		# Validate length
		if (defined(my $length = $property->{'validate'}->{'length'})) {
			if (length($value) < $length) {
				$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed regex length",$property->{'name'});
				$self->_error("Validation of '".$property->{'name'}."' length failed");
				return;
			}
		}

		return $value;

	# Validate 'text' type
	} elsif ($validateType eq "text") {
		# Make sure this is text
		if (!($value =~ /^[[:print:]]*$/)) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed text printable characters",$property->{'name'});
			$self->_error("Validation of '".$property->{'name'}."' failed");
			return;
		}

		# Check if we have a regex to also match against
		if (defined(my $regex = $property->{'validate'}->{'regex'})) {
			# Validate against a regex
			if (!($value =~ $regex)) {
				$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed text regex =~",$property->{'name'});
				$self->_error("Validation of '".$property->{'name'}."' failed");
				return;
			}
		}

		# Validate length
		if (defined(my $length = $property->{'validate'}->{'length'})) {
			if (length($value) < $length) {
				$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed length",$property->{'name'});
				$self->_error("Validation of '".$property->{'name'}."' length failed");
				return;
			}
		}

		return $value;

	# Validate 'email' type
	} elsif ($validateType eq "email") {
		# Validate email address
		if (!isEmail($value)) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed email",$property->{'name'});
			$self->_error("Validation of '".$property->{'name'}."' failed");
			return;
		}

		return $value;

	# Validate 'username' type
	} elsif ($validateType eq "username") {
		# Validate username
		if (!isUsername($value,@params)) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed username",$property->{'name'});
			$self->_error("Validation of '".$property->{'name'}."' failed");
			return;
		}

		# Validate length
		if (defined(my $length = $property->{'validate'}->{'length'})) {
			if (length($value) < $length) {
				$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed username length",$property->{'name'});
				$self->_error("Validation of '".$property->{'name'}."' length failed");
				return;
			}
		}

		return $value;

	# Validate 'boolean' type
	} elsif ($validateType eq "boolean") {
		# Validate boolean
		if (!defined($value = isBoolean($value))) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed boolean",$property->{'name'});
			$self->_error("Validation of '".$property->{'name'}."' failed");
			return;
		}

		return $value;

	# Validate 'domain' type
	} elsif ($validateType eq "domain") {
		# Validate domain
		if (!defined(isDomain($value))) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed domain",$property->{'name'});
			$self->_error("Validation of '".$property->{'name'}."' failed");
			return;
		}

		return $value;

	# Validate 'number' type
	} elsif ($validateType eq "number") {
		# Validate username
		if (!defined($value = isNumber($value,@params))) {
			$self->_log(DATAOBJ_LOG_INFO,"Validation of '%s' failed number",$property->{'name'});
			$self->_error("Validation of '".$property->{'name'}."' failed");
			return;
		}

		return $value;

	# Validate 'relation' type
	} elsif ($validateType eq "relation") {

		# Loop with relations and validate
		my $mismatch = 0;
		foreach my $relationName ($self->_relationNamesFromProperty($property)) {
			my $relationPropertyName = $self->_relationPropertyName($property,$relationName);

			# Grab validated value and compare
			my $validateMethod = "validate$relationPropertyName";
			my $validatedValue = $self->_relation($relationName)->$validateMethod($value,@params);
			if (!defined($validatedValue) || $validatedValue ne $value) {
				$mismatch = 1;
				last;
			}
		}

		# If nothing mismatched, return the value
		if (!$mismatch) {
			return $value;
		}

	# Validate 'load' type
	} elsif ($validateType eq "load") {
		# Load item from DB
		if (my $obj = $self->clone()->reset()->load($property->{'name'} => $value)) {
			my $methodName = "get".$property->{'name'};
			# If we didn't load anything, the method will return undef
			return $obj->$methodName();
		}

	# Fallthrough
	} else {
		$self->_log(DATAOBJ_LOG_ERROR,"Property '".$property->{'name'}."' has invalid validation type");
	}

	return;
}



=head2 changed

	my %changed = $dataObj->changed();

The C<changed> method returns a hash containing the properties and values of each item which was changed since the last C<load> or
C<commit>

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

NOTE: This method must be implemented by child classes.

=cut

# Get records as an array of objects
sub records
{
	my $self = shift;


	$self->_log(DATAOBJ_LOG_ERROR,"The 'records' method needs to be implemented");

	return;
}



=head2 load

	$dataObj->load($id);

	$dataObj->load('Name' => 'Joe Soap');

The C<load> method is used to load a single record from the database. It has 2 forms of invocation, either by specifying one
parameter which is assumed to be the value of the ID field, or by specifying a hash of key-value pairs.

Only the first matching record is returned, if multiple records exist the result can be any one of them being returned.

NOTE: This method must be implemented by child classes.

=cut

# Load Record
# - The load defaults to loading on ID, but a hash can be provided to load on various matches
sub load
{
	my ($self,@params) = @_;


	$self->_log(DATAOBJ_LOG_ERROR,"The 'load' method needs to be implemented");

	return;
}



=head2 loadHash

	$dataObj->loadHash($dataHash);

The C<loadHash> method loads properties from a hashref. If the data was previously changed the changed flag is reset and the
loaded flag is applied to the property.

=cut

# Load record data from hash
# NOTE: The _loadHash function uses _set()
sub loadHash
{
	my ($self,$data) = @_;


	# Blank data if there is no data
	if (!defined($data)) {
		$data = { };
	}

	# Set properties
	foreach my $item (keys %{$data}) {
		$self->set($item,$data->{$item});
	}

	$self->_log(DATAOBJ_LOG_DEBUG,"Loaded %s properties from hash", scalar keys %{$data});

	return $self;
}



=head2 dataLoaded

	$dataObj->dataLoaded();

The C<dataLoaded> method returns the properties previously loaded with C<load>.

=cut

# Return the property names previously loaded by the load() method
sub dataLoaded
{
	my ($self,$data) = @_;


	# Return the properties loaded
	return ( keys %{$self->{'_data.loaded'}} );
}



=head2 commit

	$dataObj->commit();

The C<commit> method is used to commit the record, this means updating it if it exists or inserting it if it does not yet exist.

NOTE: This method must be implemented by child classes.

=cut

# Commit record to database
sub commit
{
	my $self = shift;


	$self->_log(DATAOBJ_LOG_ERROR,"The 'commit' method needs to be implemented");

	return;
}



=head2 remove

	$dataObj->remove();

	$dataObj->remove('Name' => "Sam", 'Surname' => "Soap");

The C<remove> method is used to remove the data object from the database. The function can take an optional set of parameters which
will be used in the SQL DELETE WHERE statement instead of using the current object ID.

NOTE: This method must be implemented by child classes.

=cut

# Remove Record
# - The remove defaults to removing on ID, but a hash can be provided to load on various matches
sub remove
{
	my ($self,@params) = @_;


	$self->_log(DATAOBJ_LOG_ERROR,"The 'commit' method needs to be implemented");

	# Return number removed
	return;
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
	my ($self,$properties) = @_;


	# Setup our internals
	my $clone = {
		'_properties' => $self->{'_properties'},
		'_properties_lc' => $self->{'_properties_lc'},
		'_data' => $self->{'_data'},
		'_data.changed' => $self->{'_data'},
		'_error' => ""
	};

	# Load optionals if we have any
	if (defined($properties)) {
		foreach my $opt (keys %{$properties}) {
			$clone->{$opt} = $properties->{$opt};
		}
	}

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



# Initialize internals of the object
sub _init
{
	my ($self,$options) = @_;


	# Grab our configuration
	my $config = $self->config();

	$self->_log(DATAOBJ_LOG_DEBUG,"Initializing object '%s'",ref($self));

	# Set options
	# // is like ||, but // is for undefined
	$self->{'_options'} = $options // 0;
	# Loop through the properties, check them and clean them up
	foreach my $propertyName (keys %{$config->{'properties'}}) {
		my $propertyConfig = $config->{'properties'}->{$propertyName};

		$self->_log(DATAOBJ_LOG_DEBUG2," - Processing property '%s'",$propertyName);

		# Check format of property
		if (!($propertyName =~ /^[A-Z][A-Za-z0-9]+$/)) {
			$self->_log(DATAOBJ_LOG_ERROR,"Property '%s' has an invalid name",$propertyName);
		}

		# Check if we have options, if we don't set to 0
		# // is like ||, but // is for undefined
		$self->{'_properties'}->{$propertyName}->{'options'} = $propertyConfig->{'options'} // 0;

		# Set property
		my $property = $self->{'_properties'}->{$propertyName};

		# Start with blank relations
		$self->{'_relations'} = { };
		$self->{'_relations_map'} = { };

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
						$validateValue ne "number" &&
						$validateValue ne "relation" &&
						$validateValue ne "load"
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

			$self->_log(DATAOBJ_LOG_DEBUG2,"   - Property '%s' has validation type '%s'",$propertyName,
				$property->{'validate'}->{'type'});
		}

		$self->{'_properties'}->{$propertyName}->{'name'} = $propertyName;
		# Map lowercase property name
		$self->{'_properties_lc'}->{lc($propertyName)} = $propertyName;
	}

	# Loop through the relations
	if (defined($config->{'relations'})) {
		foreach my $relationName (keys %{$config->{'relations'}}) {
			# Grab relation info
			my $relationConfig = $config->{'relations'}->{$relationName};
			my $class = $relationConfig->{'class'};
			my $type = $relationConfig->{'type'};
			my $associations = $relationConfig->{'associate'};

			# Check we have everything
			if (!defined($class)) {
				$self->_log(DATAOBJ_LOG_ERROR,"DataObj '%s' relation '%s' has no attribute 'class'",ref($self),$relationName);
			}
			if (!defined($type)) {
				$self->_log(DATAOBJ_LOG_ERROR,"DataObj '%s' relation '%s' has no attribute 'type'",ref($self),$relationName);
			}
			if (!defined($associations)) {
				$self->_log(DATAOBJ_LOG_ERROR,"DataObj '%s' relation '%s' has no attribute 'associate'",ref($self),$relationName);
			}

			$self->_log(DATAOBJ_LOG_DEBUG2," - Relation '%s' => '%s' [%s]",$relationName,$class,$type);
			# Loop with the associations
			foreach my $ourProperty (keys %{$associations}) {
				my $relationPropertyName = $associations->{$ourProperty};

				$self->_log(DATAOBJ_LOG_DEBUG2,"    - Associate '%s' => '%s'",$ourProperty,$relationPropertyName);

				# Try instantiate class
				my $relationHandler;
				eval "
					use AWITPT::DataObj::Relation::$type;
					\$relationHandler = AWITPT::DataObj::Relation::$type->new('$class');
				";
				die $@ if $@;

				# Checki f we actually got something back
				if (!defined($relationHandler)) {
					$self->_log(DATAOBJ_LOG_ERROR,"ERROR: Cannot create relation '%s' => '%s' [%s]",$relationName,$class,$type);
				}

				# Add to our list of relations, we add the relation handler object here
				$self->{'_relations'}->{$relationName} = $relationHandler;
				# We then map our property to the relation, to the handler
				$self->{'_relations_map'}->{$ourProperty}->{$relationName} = $relationPropertyName;
			}
		}
	}

	# Values for each property
	$self->{'_data'} = { };
	# Values which were loaded
	$self->{'_data.loaded'} = undef;
	# Values which were changed
	$self->{'_data.changed'} = {};


	# Reset error too
	$self->{'_error'} = "";


	return $self;
}



# Internal logging method
sub _log
{
	my ($self,$level,$format,@params) = @_;


	my $msg;

	# Check if we want this debug level
	if ($DEBUG >= $level) {
		# Serious messages have full debugging
		if ($DEBUG == DATAOBJ_LOG_DEBUG || $level == DATAOBJ_LOG_ERROR) {
			$msg = longmess(sprintf($format,@params));
		# Not so serious just has our caller
		} else {
			my @caller = caller(1);
			$msg = sprintf("%s (from %s): $format",ref($self),$caller[3],@params);
		}

	}

	# Check if we aborting
	if ($level == DATAOBJ_LOG_ERROR) {
		die($msg);
	} elsif (defined($msg)) {
		$self->log($level,$msg);
	}

	return;
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
		if (!defined($match) || $match == 0 || !($property->{'options'} & ~$match)) {
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
	if (!defined($property)) {
		$self->_log(DATAOBJ_LOG_ERROR,"Cannot set property '%s'",$propertyName);
	}

	# Check if we have data from the DB
	if (defined($self->{'_data.loaded'})) {

		# If we did not load, then this has changed
		if (!defined($self->{'_data.loaded'}->{$property->{'name'}})) {
			$self->{'_data.changed'}->{$property->{'name'}} = $value;

		} else {
			# If loaded does not match the new value, then set changed
			if ($self->{'_data.loaded'}->{$property->{'name'}} ne $value) {
				$self->{'_data.changed'}->{$property->{'name'}} = $value;
			# Delete if it exists and its the same
			} else {
				delete($self->{'_data.changed'}->{$property->{'name'}});
			}
		}

	# If DB data is not defined, it means this is new, so its changed
	} else {
		$self->{'_data.changed'}->{$property->{'name'}} = $value;
	}

	# Trigger a relation change if we have a relation for this property
	foreach my $relationName ($self->_relationNamesFromProperty($property)) {
		# Grab destination property name
		my $relationPropertyName = $self->_relationPropertyName($property,$relationName);

warn sprintf("  - THIS IS A RELATION  '%s' [%s => %s] ",$property->{'name'},$relationName,$relationPropertyName);
		# Check if we actually managed to set something, if not just return undef
		if (!defined($self->_relation($relationName)->set($relationPropertyName,$value))) {
			return;
		}
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


	# Blank data if there is no data
	if (!defined($data)) {
		$data = { };
	}

	# Set properties
	foreach my $item (keys %{$data}) {
		# Set this item as being loaded, if we do this before the _set, we don't generate a data.changed entry
		$self->{'data.loaded'}->{$item} = $data->{$item};
		$self->_set($item,$data->{$item});
	}

	$self->_log(DATAOBJ_LOG_DEBUG,"Loaded %s internal properties from hash", scalar keys %{$data});

	return $self;
}



# Return the relation names of a property
sub _relationNamesFromProperty
{
	my ($self,$property) = @_;


	# Grab relations from hash or name
	my $propertyName;
	if (ref($property) eq "HASH") {
		$propertyName = $property->{'name'};
	} else {
		$propertyName = $property;
	}

	# Return list, array or arrayref, or undef
	my $relations = $self->{'_relations_map'}->{$propertyName};
	if (defined($relations)) {
		return wantarray ? keys %{$relations} : [ keys %{$relations} ];
	} else {
		return;
	}
}



# Return a properties relation property name from a property
sub _relationPropertyName
{
	my ($self,$property,$relationName) = @_;


	# Grab target property name
	my $propertyName;
	if (ref($property) eq "HASH") {
		$propertyName = $property->{'name'};
	} else {
		$propertyName = $property;
	}

	return $self->{'_relations_map'}->{$propertyName}->{$relationName};
}



# Return a properties relation handle to the relation class
sub _relation
{
	my ($self,$relationName) = @_;


	return $self->{'_relations'}->{$relationName};
}



1;
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
