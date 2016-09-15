# Test harness for isDomain
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


use AWITPT::Util;
use AWITPT::Object;



my $hash = { 'makeHash' => 1 };
my $object = AWITPT::Object->new();


is(isDomain(0),0,"Check 0 returns 0");

is(isDomain('0'),0,"Check 0 returns 0");

is(isDomain($hash),undef,"Check HASH returns 0");

is(isDomain($object),undef,"Check OBJECT returns 0");

is(isDomain("example"),"example","Check 'example' returns 0");

is(isDomain("example.com"),"example.com","Check 'example.com' returns 1");


done_testing();



