# network IP Address Handling
# Copyright (C) 2009, AllWorldIT
# Copyright (C) 2008, LinuxRulz
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
# * * *
# 2009-12-03: Portions of this are derived from ideas and code in Net::IP
# - Robert Anderson <randerson@lbsd.net>
# * * *


package awitpt::netip;

use strict;
use warnings;


# Our current error message
my $error = "";


sub setError
{
    my $err = shift;
    my ($package,$filename,$line) = caller;
    my (undef,undef,undef,$subroutine) = caller(1);

    # Set error
    $error = "$subroutine($line): $err";
}


sub Error
{
    my $err = $error;

    # Reset error
    $error = "";

    # Return error
    return $err;
}


# Create object
sub new
{
	my ($type,$ip) = @_;

	my $self = {};

	# Guess ip version
	if ($ip =~ /:/) {
		$self->{'ip_version'} = 6;
	} elsif (($ip =~ /\./) || ($ip =~ /^\d{1,3}(\/\d{1,2})?$/)) {
		$self->{'ip_version'} = 4;
	} else {
		setError("Failed to guess ip version");
		return undef;
	}

	$self->{'raw_ip'} = $ip;

	# Instantiate object
	bless($self,$type);

	# Clean the raw IP
	if (!$self->clean_ip()) {
		return undef;
	}

	return $self;
}


# Check for a valid ipv6/ipv4 address
sub is_valid
{
	my $ip = shift;


	# Check if defined
	if (!defined($ip)) {
		return 0;
	}

	# Check for valid IPv4 address
	if ($ip =~ /^(\d{1,3})(?:\.(\d{1,3})(?:\.(\d{1,3})(?:\.(\d{1,3}))?)?)?(?:\/(\d{1,2}))?$/) {

		# Check octets are within limits
		foreach ($1,$2,$3,$4) {
			if (defined($_)) {
				if ($_ > 255 || $_ < 0) {
					return 0;
				}
			}
		}

		# Check bitmask is within limits
		if (defined($5)) {
			if ($5 > 32 || $5 < 1) {
				return 0;
			}
		}

	# Check for valid IPv6 address
	} elsif ($ip =~ /:/) {

		# Pull off and check bitmask
		if ($ip =~ s/\/(\d{1,3})$//g) {
			if ($1 > 128 || $1 < 1) {
				return 0;
			}
		}

		# Check for illegal characters
		if (!($ip =~ /^[a-f\d:]+$/i)) {
			return 0;
		}

		# Does the IP address have more than one '::' pattern ?
		my $count;
		while ($ip =~ /::/g) {
			$count++;
		}
		if ($count > 1) {
			return 0;
		}

		# Count octets
		my $n = ($ip =~ tr/:/:/);
		if (!($n > 0 and $n < 8)) {
			return 0;
		}

		# Check octets
		foreach (split /:/, $ip) {

			# Empty octet ?
			next if ($_ eq '');

			# Normal v6 octet ?
			next if (/^[a-f\d]{1,4}$/i);

			return 0;
		}

	# Do not recognise
	} else {
		return 0;
	}


	return 1;
}


# Clone an object
sub copy
{
	my $self = shift;

	my $clone = bless({
		'ip_version' => $self->{'ip_version'},
		'ip' => $self->{'ip'},
		'cidr' => $self->{'cidr'}
	}, ref($self));

	return $clone;
}


# Check the IP address and format accordingly
sub clean_ip
{
	my $self = shift;

	if ($self->{'ip_version'} == 4) {

		# Pull off mask
		my $mask;
		if ($self->{'raw_ip'} =~ s/\/(\d{1,2})$//g) {
			$mask = $1 ? $1 : undef;
		}

		# Check for invalid chars
		if (!($self->{'raw_ip'} =~ m/^[\d\.]+$/)) {
			setError("IPv4 Address '".$self->{'raw_ip'}."' contains invalid characters");
			return 0; 
		}

		# Check for leading .
		if ($self->{'raw_ip'} =~ m/^\./) {
			setError("IPv4 Address '".$self->{'raw_ip'}."' begins with '.'");
			return 0;
		}

		# Check for trailing .
		if ($self->{'raw_ip'} =~ m/\.$/) {
			setError("IPv4 Address '".$self->{'raw_ip'}."' ends with '.'");
			return 0;
		}

		# Expand address
		if ($self->{'raw_ip'} =~ /^(\d{1,3})(?:\.(\d{1,3})(?:\.(\d{1,3})(?:\.(\d{1,3}))?)?)?$/) {

			# Strip ip components from string
			my ($a,$b,$c,$d) = ($1,$2,$3,$4);

			# Check for invalid octets
			foreach my $octet ($a,$b,$c,$d) {
				if (defined($octet) && $octet > 255) {
					setError("Address '".$self->{'raw_ip'}."' contains octets which exceed 255");
					return 0;
				}
			}

			# Set undefined octets and mask if missing
			if (!defined($b)) {
				$b = 0;
				$mask = 8 if !defined($mask);
			}
			if (!defined($c)) {
				$c = 0;
				$mask = 16 if !defined($mask);
			}
			if (!defined($d)) {
				$d = 0;
				$mask = 24 if !defined($mask);
			}

			# Default mask
			$mask = ( defined($mask) && $mask >= 1 && $mask <= 32 ) ? $mask : 32;
			$self->{'cidr'} = $mask;

			# Build ip
			$self->{'ip'} = "$a.$b.$c.$d";

			# Check for full ipv4
			if (!($self->{'ip'} =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)) {
				setError("Address '".$self->{'ip'}."' is not a full ipv4 address");
				return 0;
			}
		} else {
			setError("Address '".$self->{'raw_ip'}."' is not a supported format");
			return 0;
		}

	} elsif ($self->{'ip_version'} == 6) {

		# Pull off mask
		my $mask;
		if ($self->{'raw_ip'} =~ s/\/(\d{1,3})$//g) {
			$mask = $1 ? $1 : undef;
		}

		# Count octets
		my $n = ($self->{'raw_ip'} =~ tr/:/:/);
		if (!($n > 0 and $n < 8)) {
			setError("Address '".$self->{'ip'}."' is not a valid IPv6 address");
			return 0;
		}

		# $k is a counter
		my $k;

		# Check octets
		foreach (split /:/, $self->{'raw_ip'}) {

			# Empty octet ?
			next if ($_ eq '');

			$k++;

			# Normal v6 octet ?
			next if (/^[a-f\d]{1,4}$/i);

			setError("Address component '$_' is invalid");
			return 0;
		}

		# Does the IP address have more than one '::' pattern ?
		my $count;
		while ($self->{'raw_ip'} =~ /::/g) {
			$count++;
		}
		if ($count > 1) {
			setError("Address '".$self->{'raw_ip'}."' contains more than one ::");
			return 0;
		}

		# Expand address
		my $tempIP;
		if ($k < 8) {

			# If there is no :: return 0
			if (!$self->{'raw_ip'} =~ /::/) {
				setError("Address '".$self->{'raw_ip'}."' has missing components");
				return 0;
			}

			# Set mask
			if (!defined($mask)) {
				$mask = 16*$k
			}

			my @missingOctets;
			for (my $i = 0; $i < (8 - $k); $i++) {
				push(@missingOctets, '0000');
			}
			my $octets = join(':', @missingOctets);

			$tempIP = $self->{'raw_ip'};

			# Replace ::
			$tempIP =~ s/::/:$octets:/g;

			# Remove trailing and leading :
			$tempIP =~ s/^://;
			$tempIP =~ s/:$//;
		}

		# Check for and add leading 0s
		my @fullipv6;
		foreach my $octet (split(':',$tempIP)) {
			if ($octet =~ /^[a-f\d]{1}$/) {
				$octet = '000'.$octet;
			}
			if ($octet =~ /^[a-f\d]{2}$/) {
				$octet = '00'.$octet;
			}
			if ($octet =~ /^[a-f\d]{3}$/) {
				$octet = '0'.$octet;
			}
			push(@fullipv6, $octet);
		}
		$self->{'ip'} = join(':', @fullipv6);

		# Check for full ipv6
		if (!($self->{'ip'} =~ /^[a-f\d]{4}:[a-f\d]{4}:[a-f\d]{4}:[a-f\d]{4}:[a-f\d]{4}:[a-f\d]{4}:[a-f\d]{4}:[a-f\d]{4}$/i)) {
			setError("Address '".$self->{'raw_ip'}."' is not a valid IPv6 address");
			return 0;
		}

		# Default mask
		$self->{'cidr'} = $mask ? $mask : 128;
	}

	return 1;
}


# Convert to binary
sub to_bin
{
	my $self = shift;

	# We already have it in bin
	return $self->{'ip_bin'} if ($self->{'ip_bin'});

	# Check how to convert to bin
	if ($self->{'ip_version'} == 6) {
		my $cleanIP = $self->{'ip'};
		$cleanIP =~ s/://g;
   		$self->{'ip_bin'} = unpack('B128', pack('H32', $cleanIP));

	} elsif ($self->{'ip_version'} == 4) {
		$self->{'ip_bin'} = unpack('B32', pack('C4C4C4C4', split(/\./, $self->{'ip'})));
	}

	return $self->{'ip_bin'};
}


# Convert address to Math::BigInt
sub to_int
{
    my $self = shift;

    # $n is the increment (the numerical value of the bit we about to 'set')
    my $n = Math::BigInt->new(1);
	# $ret is the returned value
    my $ret = Math::BigInt->new(0);

    # Reverse the bit string
    foreach my $bit (reverse(split '', $self->to_bin())) {
        # If the nth bit is 1, add 2**n to $dec
        if ($bit) {
			$ret += $n;
		}
		# Next bit value...
        $n *= 2;
    }

# XXX: This would convert to a string?
#   # Strip leading + sign
#    $ret =~ s/^\+//;

    return $ret;
}


# Calculate network and broadcast
sub _calc_ranges
{
	my $self = shift;


	# Grab CIDR
	my $cidr = $self->{'cidr'};

	# Grab length of this address, we don't care if its v4 or v6
	my $bitlen = length($self->to_bin);

	# Create the masks
	my $NETWORK_MASK = '1' x  $cidr . '0' x ($bitlen - $cidr);
	my $BROADCAST_MASK = '0' x  $cidr . '1' x ($bitlen - $cidr);

	# network = remove bits (AND)
	# broadcast = add bits (OR)
	my $bin = $self->to_bin();
	$self->{'network'} = '';
	$self->{'broadcast'} = '';
	# Loop with all bits
	for (my $i = 0; $i < $bitlen; $i++) {
		# Cut off the bits
		my $a = substr($bin,$i,1);
		my $b = substr($NETWORK_MASK,$i,1);
		my $c = substr($BROADCAST_MASK,$i,1);
		# Bit arithmatic ! , sneaky but quick
		$self->{'network'} .= ($a + $b == 2) ? 1 : 0;
		$self->{'broadcast'} .= ($a + $c > 0) ? 1 : 0;
	}
}


# Get the network address
sub to_network 
{
	my $self = shift;


	if (!defined($self->{'network'})) {
		$self->_calc_ranges();
	}

	$self->{'ip'} = $self->{'network'};
	$self->{'cidr'} = undef;

	return $self;
}


# Get the broadcast address
sub to_broadcast 
{
	my $self = shift;


	if (!defined($self->{'broadcast'})) {
		$self->_calc_ranges();
	}
	
	$self->{'ip'} = $self->{'broadcast'};
	$self->{'cidr'} = undef;

	return $self;
}


# Check if ip address is inside another ip address range
sub is_within
{
	my ($self,$test) = @_;

	my $network = $test->copy()->to_network()->to_int();
	my $broadcast = $test->copy()->to_broadcast()->to_int();

	my $self_int = $self->to_int();

	if ($self_int >= $network && $self_int <= $broadcast) {
		return 1;
	}

	return 0;
}


1;
# vim: ts=4
