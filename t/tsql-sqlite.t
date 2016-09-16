# Test harness for AWITPT::Util::ConvertTSQL::SQLite
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
my $tsqlc = AWITPT::Util::ConvertTSQL->new("SQLite",'prefix' => "myprefix_");

is($tsqlc->convert('CREATE TABLE @PREFIX@mytable ...'),'CREATE TABLE myprefix_mytable ...',
		"Prefix test must return myprefix_");


# Recreate with no prefix
$tsqlc = AWITPT::Util::ConvertTSQL->new("SQLite");

is($tsqlc->convert('CREATE TABLE @PREFIX@mytable ...'),'CREATE TABLE mytable ...',
		"Prefix test must return no prefix when one is not specified");


# Test foreign key checks
is($tsqlc->convert('@PRELOAD@'),"","Make sure \@PRELOAD\@ returns blank");
is($tsqlc->convert('@POSTLOAD@'),"","Make sure \@POSTLOAD\@ returns blank");


is($tsqlc->convert('@CREATE_TABLE_SUFFIX@'),"","Make sure the table suffix is blank");


# Check serial types
is($tsqlc->convert('@SERIAL_TYPE@'),'INTEGER PRIMARY KEY AUTOINCREMENT',
		"Make sure \@SERIAL_TYPE\@ is 'INTEGER PRIMARY KEY AUTOINCREMENT'");
is($tsqlc->convert('@SERIAL_REF_TYPE@'),'INT8',"Make sure \@SERIAL_REF_TYPE\@ is 'INT8'");


# Check bigint types
is($tsqlc->convert('@BIG_INTEGER_UNSIGNED@'),'UNSIGNED BIG INT',"Make sure the \@BIG_INTEGER_UNSIGNED\@ is 'UNSIGNED BIG INT'");


# Check integer types
is($tsqlc->convert('@INT_UNSIGNED@'),'INT8',"Make sure the \@INT_UNSIGNED\@ is 'INT8'");


# Check tracking key length
is($tsqlc->convert('@TRACK_KEY_LEN@'),512,"Make sure the \@TRACK_KEY_LEN\@ is 512");



done_testing();



