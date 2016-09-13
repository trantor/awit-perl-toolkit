# Test harness for isNumber
# Copyright (C) 2014, AllWorldIT
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


use AWITPT::Util;
use AWITPT::Object;



my $hash = { 'makeHash' => 1 };
my $scalar = 1;
my $object = AWITPT::Object->new();


is(isHash($hash),1,"Make sure a HASH returns 1");

is(isHash($scalar),0,"Make sure a scalar returns 0");

is(isHash(0),0,"Make sure 0 returns 0");

is(isHash("0"),0,"Make sure '0' returns 0");

is(isHash("a"),0,"Make sure 'a' returns 0");

is(isHash($object),0,"Make sure OBJECT returns 0");


done_testing();



