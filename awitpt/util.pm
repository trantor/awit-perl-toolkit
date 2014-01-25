# Utility functions
# Copyright (C) 2008-2014, AllWorldIT
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


## @class awitpt::util
# System functions
package awitpt::util;

use strict;
use warnings;

use File::Spec;

# Exporter stuff
require Exporter;
our (@ISA,@EXPORT,@EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw(
	indentExpand

	isNumber
	isHash
	isVariable
	isDomain
	isUsername
	isDatabaseName
	isBoolean
	isDate
	isEmailSpec
	isIPv4

	booleanize

	parseMacro

	sanitizePath

	prettyUndef

	getHashChanges

	toHex

	parseFormContent
	parseURIQuery
	parseKeyPairString

	ISNUMBER_ALLOW_ZERO
	ISNUMBER_ALLOW_NEGATIVE

	ISUSERNAME_ALLOW_ATSIGN

	ISDATE_YEAR
	ISDATE_MONTH
	ISDATE_DAY
	ISDATE_TIME
	ISDATE_UNIX
);
@EXPORT_OK = qw(
);


# Define constants
use constant {
	ISNUMBER_ALLOW_ZERO => 1,
	ISNUMBER_ALLOW_NEGATIVE => 2,

	ISUSERNAME_ALLOW_ATSIGN => 1,

	ISDATE_YEAR => 1,
	ISDATE_MONTH => 2,
	ISDATE_DAY => 4,
	ISDATE_TIME => 8,
	ISDATE_UNIX => 16
};



## @fn indentExpand($char,$count)
# Return indentation
#
# @param char Indent character
# @param count Number of indent characters to add
#
# @return Indent string
sub indentExpand
{
	my ($char,$count) = @_;
	my $ret = "";

	for (my $i = 0; $i < $count; $i++) {
		$ret .= $char;
	}

	return $ret;
}



## @fn isNumber($var,$options)
# Check if variable is a number
#
# @param var Variable to check
# @param options Optional check options
# ISNUMBER_ALLOW_ZERO: Allow zero
# ISNUMBER_ALLOW_NEGATIVE: Allow negatives
#
# @return undef on error, value otherwise
sub isNumber
{
	my ($var,$options) = @_;

	$options = 0 if (!defined($options));

	# Make sure we're not a ref
	if (!isVariable($var)) {
		return undef;
	}

	# Strip leading 0's
	if ($var =~ s/^(-?)0*([0-9]+)$/$1$2/) {
		my $val = int($var);

		# Check we not 0 or negative
		if ($val > 0) {
			return $val;
		}

		# Check if we allow 0's
		if ($val == 0 && (($options & ISNUMBER_ALLOW_ZERO) == ISNUMBER_ALLOW_ZERO)) {
			return $val;
		}

		# Check if we negatives
		if ($val < 0 && (($options & ISNUMBER_ALLOW_NEGATIVE) == ISNUMBER_ALLOW_NEGATIVE)) {
			return $val;
		}

	}

	return undef;
}



## @fn isHash($var)
# Check if variable is a hash
#
# @param var Variable to check
#
# @return 1 on success, 0 on failure
sub isHash
{
	my $var = shift;

	# A hash cannot be undef?
	if (!defined($var)) {
		return undef;
	}

	return (ref($var) eq "HASH");
}



## @fn isVariable($var)
# Check if variable is normal
#
# @param var Variable to check
#
# @return 1 on success, 0 on failure
sub isVariable
{
	my $var = shift;


	# A variable cannot be undef?
	if (!defined($var)) {
		return undef;
	}

	return (ref($var) eq "");
}



# FIXME - improve this function to be more compliant
## @fn isDomain($var,$options)
# Check if variable is a domain
#
# @param var Variable to check
# @param options Optional check options
# (NONE AT PRESENT)
#
# @return undef on error, value otherwise
sub isDomain
{
	my ($var,$options) = @_;

	$options = 0 if (!defined($options));

	# Make sure we're not a ref
	if (!isVariable($var)) {
		return undef;
	}

	# Lowercase it
	$var = lc($var);
	# Now check
	if ($var =~ /^[a-z0-9_\-\.]+$/) {
		return $var;
	}

	return undef;
}



## @fn isUsername($var,$options)
# Check if variable is a username
#
# @param var Variable to check
# @param options Optional check options
# (NONE AT PRESENT)
#
# @return undef on error, value otherwise
sub isUsername
{
	my ($var,$options) = @_;

	$options = 0 if (!defined($options));

	# Make sure we're not a ref
	if (!isVariable($var)) {
		return undef;
	}

	# Lowercase it
	$var = lc($var);

	# Normal username
	if ($var =~ /^[a-z0-9_\-\.]+$/) {
		return $var;
	}

	# Username with domain
	if ($var =~ /^[a-z0-9_\-\.]+\@[a-z0-9\-\.]+$/) {

		# Check if this is allowed
		if (($options & ISUSERNAME_ALLOW_ATSIGN) == ISUSERNAME_ALLOW_ATSIGN) {
			return $var;
		}
	}

	return undef;
}



## @fn isDatabaseName($var,$options)
# Check if variable can be a database name
#
# @param var Variable to check
# @param options Optional check options
# (NONE AT PRESENT)
#
# @return undef on error, value otherwise
sub isDatabaseName
{
	my ($var,$options) = @_;

	$options = 0 if (!defined($options));

	# Make sure we're not a ref
	if (!isVariable($var)) {
		return undef;
	}

	# Lowercase it
	$var = lc($var);
	# Now check
	if ($var =~ /^[a-z0-9]+$/) {
		return $var;
	}

	return undef;
}



## @fn booleanize($var)
# Booleanize the variable depending on its contents
#
# @param var Variable to booleanize
#
# @return 1 or 0
sub booleanize
{
	my $var = shift;


	# Check if we're defined
	if (!isVariable($var)) {
		return 0;
	}

	# If we're a number
	if (my $val = isNumber($var,ISNUMBER_ALLOW_ZERO)) {
		if ($val == 0) {
			return 0;
		} else {
			return 1;
		}
	}

	# Nuke whitespaces
	$var =~ s/\s//g;

	# Allow true, on, set, enabled, 1
	if ($var =~ /^(?:true|on|set|enabled|1)$/i) {
		return 1;
	}

	# Invalid or unknown
	return 0;
}



## @fn isBoolean($var)
# Check if a variable is boolean
#
# @param var Variable to check
#
# @return 1, 0 or undef
sub isBoolean
{
	my $var = shift;


	# Check if we're defined
	if (!isVariable($var)) {
		return undef;
	}

	# Nuke whitespaces
	$var =~ s/\s//g;

	# Allow true, on, set, enabled, 1, false, off, unset, disabled, 0
	if ($var =~ /^(?:true|on|set|enabled|1)$/i) {
		return 1;
	}
	if ($var =~ /^(?:false|off|unset|disabled|0)$/i) {
		return 0;
	}

	# Invalid or unknown
	return undef;
}



## @fn isDate($var)
# Check if a variable is a valid date string and return $year,$month,$day,$hour,$min,$sec
#
# @param var Variable to check
#
# @return ($month,$year,$day,$hour,$min,$sec) or undef
sub isDate
{
	my ($date,$options) = @_;


	# Make sure we're not a ref
	if (!isVariable($date)) {
		return undef;
	}

	# Check options
	if (!defined($options)) {
		$options = ISDATE_YEAR | ISDATE_MONTH | ISDATE_DAY
	}

	# Regex out components
	my ($year,$month,$day,$hour,$min,$sec) = ($date =~ /^(\d{4})(?:[-\/ \.](\d{1,2})(?:[-\/ \.](\d{1,2})(?:\s(\d{2})\:(\d{2})(?:\:(\d{2}))?)?)?)?$/);

	my @result;

	# Year
	if (($options & ISDATE_YEAR) == ISDATE_YEAR) {
		if (!defined($year)) {
			return undef;
		}
		# Insane?
		if ($year < 1900) {
			return undef;
		}
		push(@result,$year);
	}
	# Month
	if (($options & ISDATE_MONTH) == ISDATE_MONTH) {
		if (!defined($month)) {
			return undef;
		}
		# Check month is valid
		if (!($month > 0 && $month < 13)) {
			return undef;
		}
		push(@result,$month);
	}
	# Day
	if (($options & ISDATE_DAY) == ISDATE_DAY) {
		if (!defined($day)) {
			return undef;
		}
		# Basic check
		if (!($day > 0 && $day < 32)) {
			return undef;
		}
		# Reject 31st of a month with 30 days
		if ($day == 31 && ($month == 4 || $month == 6 || $month == 9 || $month == 11)) {
			return undef;
		# Reject February 30th or 31st
		} elsif ($day >= 30 && $month == 2) {
			return undef;
		# February 29th outside a leap year
		} elsif ($month == 2 && $day == 29 && !($year % 4 == 0 && ($year % 100 != 0 || $year % 400 == 0))) {
			return undef;
		}
		push(@result,$day);
	}
	# Time
	if (($options & ISDATE_TIME) == ISDATE_TIME) {
		if (!(defined($hour) && defined($min))) {
			return undef;
		}
		# Hour
		if (!($hour >= 0 && $hour < 25)) {
			return undef;
		}
		push(@result,$hour);
		# Min
		if (!($min >= 0 && $min < 61)) {
			return undef;
		}
		push(@result,$min);
		# Sec
		if (defined($sec)) {
			if (!$sec >= 0 && $sec < 61) {
				return undef;
			}
			push(@result,$sec);
		}
	}
	# Unix time
	if (($options & ISDATE_UNIX) == ISDATE_UNIX) {
		if (!isNumber($date)) {
			return undef;
		}
		return $date;
	}

	return (@result);
}



## @fn isEmailSpec($var)
# Check if a variable is a valid email spec
#
# @param var Variable to check
#
# @return specification or undef
sub isEmailSpec
{
	my $var = shift;

	# Make sure we're defined
	if (!defined($var)) {
		return undef;
	}

	# Make sure we're not a ref
	if (!isVariable($var)) {
		return undef;
	}

	# Check IPv4
	if ($var =~ /^(?:\d{1,3})(?:\.(?:\d{1,3})(?:\.(?:\d{1,3})(?:\.(?:\d{1,3}))?)?)?(?:\/(\d{1,2}))?$/) {
		return $var;
	}

	# Check user@domain, user@, @domain
	if ($var =~ /^(\S+)?@(\S+)?$/) {

		my ($user,$domain) = ($1,$2);

		if (!(defined($user) || defined($domain))) {
			return undef;
		}

		if (defined($user)) {
			if (!$user =~ /^\S+$/i) {
				return undef;
			}
		}

		if (defined($domain)) {
			if (!$domain =~ /^(?:[a-z0-9\-_\*]+\.)+[a-z0-9]+$/i) {
				return undef;
			}
		}

		return $var;
	}

	return undef;
}



## @fn isIPv4($string)
# Check if $string is an IPv4 address
#
# @param string String to test
#
# @result Returns a stanitized IPv4 address
sub isIPv4
{
	my $var = shift;


	# Make sure we're not a ref
	if (!isVariable($var)) {
		return undef;
	}

	# Lowercase it
	$var = lc($var);

	# Normal IPv4
	if ($var =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
		return $var;
	}

	return undef;
}



## @fn parseMacro($mappings,$specification)
# Parse a $specification against $mappings hash ref and produce result.
#
# @param mappings Hashref of macro => values
# @param specification Macro specification...
#		%{MACRO} - Use entire macro value
#		%{MACRO(n)} - Use first n characters of value
#		%{MACRO(m,n)} - Use n characters starting at m
#
# @result Returns an array with the result code and string.
#	Result code of 0 means success and -1 means error. In the case of an
#	error, the reason will be the second value in the returned array.
sub parseMacro
{
	my ($mappings,$rest) = @_;


	# This will be our result
	my $res = "";

	# Loop with macro items
	while ((my $match = $rest) =~ /([^%]+)?(?:\%{([a-zA-Z_0-9]+)(?:\(([0-9]+)(?:,([0-9]+))?\))?})(.*)/) {
		my ($before,$macro,$n,$m) = ($1,$2,$3,$4);
		$rest = $5;

		# Just blank before it isn't present
		$before = '' if (!defined($before));

		my $value;

		# If the macro is defined ...
		if (defined($mappings->{$macro})) {

			# Check if we using substr
			if (defined($n)) {
				# Check which substr to use
				if (defined($m)) {
					$value = substr($mappings->{$macro},$n,$m);
				} else {
					$value = substr($mappings->{$macro},0,$n);
				}
			# No substr needed
			} else {
				$value = $mappings->{$macro};
			}

		# Oh noes, no macro
		} else {
			return (-1,"Macro '$macro' does not exist!!!");
		}

		$res .= "$before$value";
	}

	# Add on the last rest
	$res .= "$rest";

	return (0,$res);
}



## @fn sanitizePath
# Get a relative to Abs path and sanitize
sub sanitizePath
{
	my $path = shift;

	my $newPath = File::Spec->rel2abs($path);
	$newPath =~ s/\/+$//;

	return $newPath;
}



## @fn prettyUndef
# Return a undef in a pretty fashion
sub prettyUndef
{
	my $var = shift;
	if (!defined($var)) {
		return "-undef-";
	} else {
		return $var;
	}
}



## @fn getHashChanges
# Function to return the changes between two hashes using a list of keys
sub getHashChanges
{
	my ($orig,$new,$keys) = @_;


	my $changed = { };

	foreach my $key (@{$keys}) {
		# We can only do this if we have a new value
		if (exists($new->{$key})) {
			if (!defined($orig->{$key}) || !defined($new->{$key}) || $orig->{$key} ne $new->{$key}) {
				$changed->{$key} = $new->{$key};
			}
		}
	}

	return $changed;
}



## @fn toHex
# Return hex representation of a decimal
sub toHex
{
	my $decimal = shift;
	return sprintf('%x',$decimal);
}



## @fn parseFormContent
# Parse form post data from HTTP content
sub parseFormContent
{
	my $data = shift;
	my %res;

	# Split information into name/value pairs
	my @pairs = split(/&/, $data);
	foreach my $pair (@pairs) {
		# Spaces are represented by +'s
		$pair =~ tr/+/ /;
		# Split off name value pairs
		my ($name, $value) = split(/=/, $pair);
		# Unescape name value pair
		$name =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
		$value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
		# Cleanup...
		$name =~ s/[^0-9A-Za-z\[\]\.]/_/g;
		# Add to hash
		$res{$name}->{'value'} = $value;
		push(@{$res{$name}->{'values'}},$value);
	}

	return \%res;
}



## @fn parseURIQuery
# Parse query data
sub parseURIQuery
{
	my $request = shift;
	my %res;


	# Grab URI components
	my @components = $request->uri->query_form;
	# Loop with the components in sets of name & value
	while (@components) {
		my ($name,$value) = (shift(@components),shift(@components));
		# Unescape name value pair
		$name =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
		$value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
		# Add to hash
		$res{$name}->{'value'} = $value;
		push(@{$res{$name}->{'values'}},$value);
	}

	return \%res;
}



# Function to parse a keypair string and return a hash
sub parseKeyPairString
{
	my $str = shift;


	my %res;
	# Grab components
	my @keyPairs = split(/\s+/,$str);
	# Loop with the components in sets of name & value
	foreach my $item (@keyPairs) {
		my ($name,$value) = split(/=/,$item);
		# Unescape name value pair
		$value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
		# Add to hash
		$res{$name}->{'value'} = $value;
		push(@{$res{$name}->{'values'}},$value);
	}

	return \%res;
}



1;
# vim: ts=4
