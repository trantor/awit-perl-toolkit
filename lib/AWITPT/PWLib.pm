# Copyright (c) 2014-2017, AllWorldIT
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
#
#
# Based off of work from http://www.vboxadm.net/
# Copyright (c) 2010 Dominik Schulz (dominik.schulz@gauner.org). All rights reserved.
#

# TODO: Needs to inherit AWITPT::Object
# TODO: Needs documentation

package AWITPT::PWLib;
use parent 'Exporter';

use strict;
use warnings;

our $VERSION = 1.01;

our (@EXPORT,@EXPORT_OK);
@EXPORT = qw(
	pwlib_crypt
	pwlib_verify
	pwlib_parse
	pwlib_pwgen
);
@EXPORT_OK = qw(
	crypt_cram_md5
	crypt_ldap_md5
	crypt_smd5
	crypt_sha
	crypt_ssha
	crypt_sha256
	crypt_ssha256
	crypt_sha512
	crypt_ssha512
);

use MIME::Base64 qw( encode_base64 decode_base64 );
use Digest::MD5;
use Digest::Perl::MD5;
use Digest::SHA;
use AWITPT::Util qw( base64_pad );



# Hash lengths
my %HASHLEN = (
	'smd5'    => 16,
	'ssha'    => 20,
	'ssha256' => 32,
	'ssha512' => 64,
);


# Password characters
my %PWCHARS = (
	'nums'  => [ '0' .. '9' ],
	'signs' => [ '%', '$', '_', '-', '+', '*', '&', '/', '=', '!', '#' ],
	'lower' => [ 'a' .. 'z' ],
	'upper' => [ 'A' .. 'Z' ],
);
$PWCHARS{'chars'} = [ @{ $PWCHARS{'lower'} }, @{ $PWCHARS{'upper'} } ];
$PWCHARS{'alphanum'} = [ @{ $PWCHARS{'chars'} }, @{ $PWCHARS{'nums'} } ];
$PWCHARS{'alphasym'} = [ @{ $PWCHARS{'alphanum'} }, @{ $PWCHARS{'signs'} } ];



## @fn crypt_plain_md5($password)
# Function to crypt() a password in PLAIN-MD5
#
# @param $password The password to crypt()
#
# @return crypt()'d password string
sub crypt_plain_md5 {
	my $password = shift;


	return "{PLAIN-MD5}" . Digest::MD5::md5_hex($password);
}



## @fn crypt_plain_md5($password)
# Function to crypt() a password in CRAM-MD5
#
# @param $password The password to crypt()
#
# @return crypt()'d password string
## no critic (ProhibitBitwiseOperators)
sub crypt_cram_md5 {
	my $password = shift;


	# NOTE:
	# Since we need to access the internal state array of the MD5 algorithm we can not
	# use the fast XS implementation of the Digest::MD5 algorithm which does not export
	# this state array.

	if (length($password) > 64 ) {
		# Hashing down long password, see RFC2195
		$password = Digest::Perl::MD5::md5($password);
	}

	# Inner HMAC key, see RFC2104, page 2
	my $ki = "$password" ^ ( chr(0x36) x 64 );

	# Outer HMAC key, see RFC2104, page 2
	my $ko = "$password" ^ ( chr(0x5c) x 64 );

	my $innermd5 = Digest::Perl::MD5->new();
	$innermd5->add($ki);
	my $ci = pack('V4', @{$innermd5->{_state}});

	my $outermd5 = Digest::Perl::MD5->new();
	$outermd5->add($ko);
	my $co = pack('V4', @{$outermd5->{_state}});

	my $innerhex = Digest::Perl::MD5::_encode_hex($ci);
	my $outerhex = Digest::Perl::MD5::_encode_hex($co);

	return "{CRAM-MD5}$outerhex$innerhex";
}



## @fn crypt_ldap_md5($password)
# Function to crypt() a password in LDAP-MD5
#
# @param $password The password to crypt()
#
# @return crypt()'d password string
sub crypt_ldap_md5 {
	my $password = shift;


	return "{LDAP-MD5}" . base64_pad( Digest::MD5::md5_base64($password) );
}



## @fn crypt_smd5($password,$salt)
# Function to crypt() a password in SMD5
#
# @param $password The password to crypt()
# @param $salt Optional salt to use for the crypt() process, automatically generated if none supplied
#
# @return crypt()'d password string
sub crypt_smd5 {
	my ($password,$salt) = @_;


	# Make a salt if we don't have one
	$salt ||= _make_salt();

	return "{SMD5}" . base64_pad( encode_base64( Digest::MD5::md5( $password . $salt ) . $salt, '' ) );
}



## @fn crypt_sha($password)
# Function to crypt() a password in SHA
#
# @param $password The password to crypt()
#
# @return crypt()'d password string
sub crypt_sha {
	my $password = shift;


	return "{SHA}" . encode_base64( Digest::SHA::sha1($password), '' );
}



## @fn crypt_ssha($password,$salt)
# Function to crypt() a password in SSHA
#
# @param $password The password to crypt()
# @param $salt Optional salt to use for the crypt() process, automatically generated if none supplied
#
# @return crypt()'d password string
sub crypt_ssha {
	my ($password,$salt) = @_;


	# Make a salt if we don't have one
	$salt ||= _make_salt();

	return "{SSHA}" . encode_base64( Digest::SHA::sha1( $password . $salt ) . $salt, '' );
}



## @fn crypt_sha256($password)
# Function to crypt() a password in SHA256
#
# @param $password The password to crypt()
#
# @return crypt()'d password string
sub crypt_sha256 {
	my $password = shift;


	return "{SHA256}" . encode_base64( Digest::SHA::sha256($password), '' );
}



## @fn crypt_ssha256($password,$salt)
# Function to crypt() a password in SSHA256
#
# @param $password The password to crypt()
# @param $salt Optional salt to use for the crypt() process, automatically generated if none supplied
#
# @return crypt()'d password string
sub crypt_ssha256 {
	my ($password,$salt) = @_;


	# Make a salt if we don't have one
	$salt ||= _make_salt();

	return "{SSHA256}" . encode_base64( Digest::SHA::sha256( $password . $salt ) . $salt, '' );
}



## @fn crypt_sha512($password)
# Function to crypt() a password in SHA512
#
# @param $password The password to crypt()
#
# @return crypt()'d password string
sub crypt_sha512 {
	my $password = shift;


	return "{SHA512}" . encode_base64( Digest::SHA::sha512($password), '' );
}



## @fn crypt_ssha512($password,$salt)
# Function to crypt() a password in SSHA512
#
# @param $password The password to crypt()
# @param $salt Optional salt to use for the crypt() process, automatically generated if none supplied
#
# @return crypt()'d password string
sub crypt_ssha512 {
	my ($password,$salt) = @_;


	# Make a salt if we don't have one
	$salt ||= _make_salt();

	return "{SSHA512}" . encode_base64( Digest::SHA::sha512( $password . $salt ) . $salt, '' );
}



## @fn pwlib_crypt($password,$scheme,$salt)
# Function crypt a password
#
# @param $password Password to crypt
# @param $scheme Password scheme
# @param $salt Optional salt to use for the crypt() process, automatically generated if none supplied
#
# @return Properly crypt()'d password, or undef on error
sub pwlib_crypt {
	my ($password,$scheme,$salt) = @_;


	# Lowercase the scheme and remove -'s
	$scheme = lc($scheme);
	$scheme =~ s/-/_/g;

	# Make a salt if we don't have one
	$salt ||= _make_salt();


	# Check how we going to crypt it
	my $res;
	if ($scheme eq 'ldap_md5') {
		$res = crypt_ldap_md5($password);
	} elsif ($scheme eq 'plain_md5') {
		$res = crypt_plain_md5($password);
	} elsif ($scheme eq 'sha') {
		$res = crypt_sha($password);
	} elsif ($scheme eq 'sha256') {
		$res = crypt_sha256($password);
	} elsif ($scheme eq 'sha512') {
		$res = crypt_sha512($password);
	} elsif ($scheme eq 'smd5') {
		$res = crypt_smd5($password, $salt );
	} elsif ($scheme eq 'ssha') {
		$res = crypt_ssha($password, $salt );
	} elsif ($scheme eq 'ssha256') {
		$res = crypt_ssha256($password, $salt );
	} elsif ($scheme eq 'ssha512') {
		$res = crypt_ssha512($password, $salt );
	} elsif ($scheme eq 'cram_md5') {
		$res = crypt_cram_md5($password);
	} elsif ($scheme eq 'plaintext' || $scheme eq "cleartext" || $scheme eq "plain") {
		$res = "{CLEARTEXT}" . $password;
	}

	return $res;
}



## @fn pwlib_verify($clearPassword,$cryptPassword)
# Function verify a password
#
# @param $clearPassword Password to check
# @param $cryptPassword crypt()'d password
#
# @return 1 on success, 0 on failure
sub pwlib_verify {
	my ($clearPassword,$cryptPassword) = @_;


	# Grab scheme and salt
	my ($scheme, undef, $salt) = pwlib_parse($cryptPassword);

	# Crypt the password so we can verify
	my $comparePassword = pwlib_crypt($clearPassword, $scheme, $salt);

	# Compare and return 1 if they matched
	if ($cryptPassword eq $comparePassword) {
		return 1;
	}

	# Else return 0
	return 0;
}



## @fn pwlib_parse($password)
# Function parse a crypt()'d password into its various parts
#
# @param $password crypt()'d password
#
# @return Array with the following..
# @li $scheme Scheme
# @li $password Raw password portion
# @li $salt Salt
sub pwlib_parse {
	my $password = shift;


	my $scheme = 'cleartext';

	# Get use password scheme and remove leading block
	if ($password =~ s/^\{([^}]+)\}//) {
		$scheme = lc($1);
	}

	# Clear text password, return pw and empty salt
	if ($scheme eq 'plaintext' || $scheme eq "cleartext" || $scheme eq "plain") {

		return ('cleartext',$password,'');

	# Hashed password, no salt
	} elsif ($scheme =~ m/^(plain_md5|ldap_md5|cram_md5|md5|sha|sha256|sha512)$/i) {
		$password = decode_base64($password);

		return ($scheme,$password,'');

	# 3 - hashed pw with salt
	}  elsif ($scheme =~ m/^(smd5|ssha|ssha256|ssha512)/) {
		# HASHLEN can be computed by doing
		# $hashlen = length(Digest::*::digest('string'));
		my $hashlen = $HASHLEN{$scheme};

		# Scheme could also specify an encoding like hex or base64, but right now we assume its b64
		$password = decode_base64($password);

		# Unpack byte-by-byte, the hash uses the full eight bit of each byte, the salt may do so, too.
		my @components = unpack('C*',$password);

		# The salted hash has the form: $saltedhash.$salt, so the first bytes is the hash
		my $i = 0;
		my @hash = ();
		while ($i < $hashlen) {
			push(@hash, shift(@components));
			$i++;
		}
		# And the rest is the variable length salt
		my @salt = ();
		foreach my $ele (@components) {
			push(@salt, $ele);
			$i++;
		}

		# Pack it again, byte-by-byte
		my $password = pack("C$hashlen",@hash);
		my $salt = pack('C*',@salt);

		return ($scheme, $password, $salt);
	}

	# Unknown scheme
	return;
}



## @fn pwlib_pwgen($length)
# Generate a password of $length length
#
# @param $length Length of password to generate
#
# @return Generated password
sub pwlib_pwgen {
	my $length = shift;


	# If length is not specified set it to 16
	$length ||= 16;

	my $password = join( '', map { $PWCHARS{'alphanum'}[ rand( $#{ $PWCHARS{'alphanum'} } ) ] } 0 .. $length - 1 );

	return $password;
}



## @internal
# @fn _make_salt($len)
# Internal function to generate a salt
#
# @return Returns a salt of 4 characters long
sub _make_salt {
	return pwlib_pwgen(4);
}



1;
