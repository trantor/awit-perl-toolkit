# Test harness for AWITPT::Util::ConvertTSQL::MySQL
# Copyright (C) 2014-2016, AllWorldIT
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

use Test::More;


use strict;
use warnings;


use AWITPT::Util::ConvertTSQL;



# Create with a prefix
my $tsqlc = AWITPT::Util::ConvertTSQL->new("MySQL",'prefix' => "myprefix_");

is($tsqlc->convert('CREATE TABLE @PREFIX@mytable ...'),'CREATE TABLE myprefix_mytable ...',
		"Prefix test must return myprefix_");


# Recreate with no prefix
$tsqlc = AWITPT::Util::ConvertTSQL->new("MySQL");

is($tsqlc->convert('CREATE TABLE @PREFIX@mytable ...'),'CREATE TABLE mytable ...',
		"Prefix test must return no prefix when one is not specified");


# Test foreign key checks
is($tsqlc->convert('@PRELOAD@'),"SET FOREIGN_KEY_CHECKS=0;","Make sure foreign key checks are disabled with \@PRELOAD\@");
is($tsqlc->convert('@POSTLOAD@'),"SET FOREIGN_KEY_CHECKS=1;","Make sure foreign key checks are enabled with \@POSTLOAD\@");

is($tsqlc->convert('@CREATE_TABLE_SUFFIX@'),"ENGINE=InnoDB CHARACTER SET latin1 COLLATE latin1_bin",
		"Make sure the table suffix is correctly set");


# Check serial types
is($tsqlc->convert('@SERIAL_TYPE@'),'SERIAL',"Make sure \@SERIAL_TYPE\@ is 'SERIAL'");
is($tsqlc->convert('@SERIAL_REF_TYPE@'),'BIGINT UNSIGNED',"Make sure \@SERIAL_REF_TYPE\@ is 'BIGINT UNSIGNED'");


# Check bigint types
is($tsqlc->convert('@BIG_INTEGER_UNSIGNED@'),'BIGINT UNSIGNED',"Make sure the \@BIG_INTEGER_UNSIGNED\@ is 'BIGINT UNSIGNED'");


# Check integer types
is($tsqlc->convert('@INT_UNSIGNED@'),'INT UNSIGNED',"Make sure the \@INT_UNSIGNED\@ is 'INT UNSIGNED'");


# Check tracking key length
is($tsqlc->convert('@TRACK_KEY_LEN@'),512,"Make sure the \@TRACK_KEY_LEN\@ is 512");



done_testing();



