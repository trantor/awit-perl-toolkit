# Database independent layer module
# Copyright (C) 2009-2014, AllWorldIT
# Copyright (C) 2008, LinuxRulz
# Copyright (C) 2005-2007 Nigel Kukard  <nkukard@lbsd.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.




## @class AWITPT::DB::DBILayer
# Database independant layer module. This module encapsulates the DBI
# module and provides us with some tweaked functionality
package AWITPT::DB::DBILayer;

use strict;
use warnings;


use DBI;



# Our current error message
my $error = "";


## @internal
# @fn _error($err)
# This function is used to set the last error for this class
#
# @param err Error message
sub _error
{
	my $err = shift;
	my ($package,$filename,$line) = caller;
	my (undef,undef,undef,$subroutine) = caller(1);

	# Set error
	$error = "$subroutine($line): $err";
}



## @fn internalError
# Return current module error message
#
# @return Last module error message
sub internalError
{
	my $err = $error;

	# Reset error
	$error = "";

	# Return error
	return $err;
}



## @member Error
# Return current object error message
#
# @return Current object error message
sub Error
{
	my $self = shift;

	my $err = $self->{'_error'};

	# Reset error
	$self->{'_error'} = "";

	# Return error
	return $err;
}



## @fn Init($server,$server_name)
# Initialize a class and return a dbilayer object
#
# @param server Server object
# @param server_name Name of server
#
# @return dbilayer object, undef on error
sub Init
{
	my ($server,$server_name) = @_;


	if (!defined($server)) {
		_error("Server object undefined");
		return;
	}
	if (!defined($server_name)) {
		_error("Server name undefined");
		return;
	}

	my $dbconfig = $server->{$server_name}->{'database'};

	# Check if we created
	my $dbh = AWITPT::DB::DBILayer->new($dbconfig);
	return if (!defined($dbh));

	return $dbh;
}



## @member new($dsn,$username,$password)
# Class constructor
#
# @param settings Database settings hashref
# @li DSN Data source name
# @li Username Username to use
# @li Password Password to use
# @li TablePrefix Table prefix
# @li IgnoreTransactions Flag to ignore transactions
# @li SQLiteJournalMode SQLite: set journal mode
# @li SQLiteCacheSize SQLite: set cache size
# @li SQLiteSynchronous SQLite: set synchronous mode
#
# @return Constructed object, undef on error
sub new
{
	my ($class,$settings) = @_;


	# Check if we were given settings
	if (!defined($settings)) {
		_error("No database settings given");
	}

	# Iternals
	my $self = {
		_type => undef,

		_dbh => undef,
		_error => undef,

		_dsn => undef,
		_username => undef,
		_password => undef,

		_table_prefix => "",

		_in_transaction => undef,
	};

	# Set database parameters
	if (defined($settings->{'DSN'})) {
		$self->{_dsn} = $settings->{'DSN'};
		$self->{_username} = $settings->{'Username'};
		$self->{_password} = $settings->{'Password'};
		$self->{'_table_prefix'} = $settings->{'TablePrefix'} || "";

		$self->{'transactions_ignore'} = $settings->{'IgnoreTransactions'};

		$self->{'sqlite_journal_mode'} = $settings->{'SQLiteJournalMode'};
		$self->{'sqlite_cache_size'} = $settings->{'SQLiteCacheSize'};
		$self->{'sqlite_synchronous'} = $settings->{'SQLiteSynchronous'};

	} else {
		_error("No DSN provided");
		return;
	}

	# Try grab database type
	$self->{_dsn} =~ /^DBI:([^:]+):/i;
	$self->{_type} = (defined($1) && $1 ne "") ? lc($1) : "unknown";

	# Create...
	bless $self, $class;
	return $self;
}



## @member connect(@params)
# Return connection to database
#
# @param params DBI parameters
#
# @return 0 on success, < 0 on error
sub connect
{
	my $self = shift;


	$self->{'_dbh'} = DBI->connect($self->{_dsn}, $self->{_username}, $self->{_password}, {
			'AutoCommit' => 1,
			'PrintError' => 0,
			'RaiseError' => 0,
			'FetchHashKeyName' => 'NAME_lc'
	});

	# Connect to database if we have to, check if we ok
	if (!$self->{'_dbh'}) {
		$self->{'_error'} = "Error connecting to database: $DBI::errstr";
		return -1;
	}

	# Apon connect we are not in a transaction
	$self->{'_in_transaction'} = 0;

	# Check for SQLite options
	if ($self->{_type} eq "sqlite") {
		# Check for journal mode
		if (defined($self->{'sqlite_journal_mode'})) {
			if (!$self->do("PRAGMA journal_mode = ".$self->{'sqlite_journal_mode'})) {
				return -1;
			}
		}
		# Check for cache size
		if (defined($self->{'sqlite_cache_size'})) {
			if (!$self->do("PRAGMA cache_size = -".$self->{'sqlite_cache_size'})) {
				return -1;
			};
		}
		# Check for synchronous setting
		if (defined($self->{'sqlite_synchronous'})) {
			if (!$self->do("PRAGMA synchronous = ".$self->{'sqlite_synchronous'})) {
				return -1;
			}
		}
	}

	return 0;
}



## @member type
# Return database type
#
# @return Database type string
sub type
{
	my $self = shift;

	return $self->{_type};
}



## @member _check
# Check database connection and reconnect if we lost the connection
sub _check
{
	my $self = shift;


	# DB is disconnected if _dbh is not defined
	if (!defined($self->{'_dbh'})) {
		goto RECONNECT;
	}

	# Try ping
	if (!$self->{'_dbh'}->ping()) {
		# If we not in a transaction try connect
		if ($self->{'_in_transaction'} == 0) {
			# Disconnect & reconnect
			$self->{'_dbh'}->disconnect();
			goto RECONNECT;
		}
		$self->{'_error'} = "Cannot reconnect to DB while inside transaction";
		return -1;
	}

	return 0;

RECONNECT:
	return $self->connect();
}



## @member select($query)
# Return database selection results...
#
# @param query SQL query
#
# @return DBI statement handle object, undef on error
sub select
{
	my ($self,$query,@params) = @_;


	if ($self->_check()) {
		return;
	}

	# Prepare query
	my $sth;
	if (!($sth = $self->{'_dbh'}->prepare($query))) {
		$self->{'_error'} = $self->{'_dbh'}->errstr;
		return;
	}

	# Check for execution error
	if (!$sth->execute(@params)) {
		$self->{'_error'} = $self->{'_dbh'}->errstr;
		return;
	}

	return $sth;
}



## @member do($command)
# Perform a command
#
# @param command Command to execute
#
# @return DBI statement handle object, undef on error
sub do
{
	my ($self,$command,@params) = @_;


	if ($self->_check()) {
		return;
	}

	# Do the query
	my $sth;
	if (!($sth = $self->{'_dbh'}->do($command,undef,@params))) {
		$self->{'_error'} = $self->{'_dbh'}->errstr;
		return;
	}

	return $sth;
}



## @method lastInsertID($table,$column)
# Function to get last insert id
#
# @param table Table last entry was inserted into
# @param column Column we want the last value for
#
# @return Last inserted ID, undef on error
sub lastInsertID
{
	my ($self,$table,$column) = @_;


	if ($self->_check()) {
		return;
	}

	# Get last insert id
	my $res;
	if (!($res = $self->{'_dbh'}->last_insert_id(undef,undef,$table,$column))) {
		$self->{'_error'} = $self->{'_dbh'}->errstr;
		return;
	}

	return $res;
}



## @method begin
# Function to begin a transaction
#
# @return 1 on success, undef on error
sub begin
{
	my $self = shift;


	if ($self->_check()) {
		return;
	}

	$self->{'_in_transaction'}++;

	# Don't really start transaction if we more than 1 deep
	if ($self->{'_in_transaction'} > 1) {
		return 1;
	}

	# Check if we need to ignore transactions
	if ($self->{'transactions_ignore'}) {
		return 1;
	}

	# Begin
	my $res;
	if (!($res = $self->{'_dbh'}->begin_work())) {
		$self->{'_error'} = $self->{'_dbh'}->errstr;
		return;
	}

	return $res;
}



## @method commit
# Function to commit a transaction
#
# @return DBI layer result, or 1 on deep transaction commit
sub commit
{
	my $self = shift;


	if ($self->_check()) {
		return;
	}

	# Reduce level
	$self->{'_in_transaction'}--;

	# If we not at top level, return success
	if ($self->{'_in_transaction'} > 0) {
		return 1;
	}

	# Reset transaction depth to 0
	$self->{'_in_transaction'} = 0;

	# Check if we need to ignore transactions
	if ($self->{'transactions_ignore'}) {
		return 1;
	}

	# Commit
	my $res;
	if (!($res = $self->{'_dbh'}->commit())) {
		$self->{'_error'} = $self->{'_dbh'}->errstr;
		return;
	}

	return $res;
}



## @method rollback
# Function to rollback a transaction
#
# @return DBI layer result or 1 on deep transaction
sub rollback
{
	my $self = shift;


	if ($self->_check()) {
		$self->{'_in_transaction'}--;
		return;
	}

	# If we at top level, return success
	if ($self->{'_in_transaction'} < 1) {
		return 1;
	}

	$self->{'_in_transaction'} = 0;

	# Check if we need to ignore transactions
	if ($self->{'transactions_ignore'}) {
		return 1;
	}

	# Rollback
	my $res;
	if (!($res = $self->{'_dbh'}->rollback())) {
		$self->{'_error'} = $self->{'_dbh'}->errstr;
		return;
	}

	return $res;
}



## @method quote($variable)
# Function to quote a database variable
#
# @param variable Variable to quote
#
# @return Quoted variable
sub quote
{
	my ($self,$variable) = @_;

	return $self->{'_dbh'}->quote($variable);
}



## @method free($sth)
# Function to cleanup DB query
#
# @param sth DBI statement handle
sub free
{
	my ($self,$sth) = @_;


	if ($sth) {
		$sth->finish();
	}
}



# Function to return the table prefix
sub table_prefix
{
	my $self = shift;

	return $self->{'_table_prefix'};
}



1;
# vim: ts=4
