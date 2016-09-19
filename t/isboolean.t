# Test harness for isboolean
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



is(isBoolean(0),0,"isBoolean of 0 should return 0");
is(isBoolean("0"),0,"isBoolean of '0' should return 0");
is(isBoolean("00"),undef,"isBoolean of '00' should return undef");
is(isBoolean(1),1,"isBoolean of 1 should return 1");
is(isBoolean("1"),1,"isBoolean of '1' should return 1");
is(isBoolean("11"),undef,"isBoolean of '11' should return undef");

is(isBoolean("-1"),undef,"isBoolean of '-1' should return undef");
is(isBoolean("-0"),undef,"isBoolean of '-0' should return undef");

is(isBoolean("a"),undef,"isBoolean of 'a' should return undef");
is(isBoolean("0a"),undef,"isBoolean of 'a' should return undef");
is(isBoolean("a0"),undef,"isBoolean of 'a' should return undef");

is(isBoolean("TruE"),1,"isBoolean of 'TruE' should return 1");
is(isBoolean("falsE"),0,"isBoolean of 'falsE' should return 0");

is(isBoolean("oN"),1,"isBoolean of 'oN' should return 1");
is(isBoolean("oFf"),0,"isBoolean of 'oFf' should return 0");

is(isBoolean("SeT"),1,"isBoolean of 'SeT' should return 1");
is(isBoolean("unSeT"),0,"isBoolean of 'unSeT' should return 0");

is(isBoolean("EnAblED"),1,"isBoolean of 'EnAblED' should return 1");
is(isBoolean("disabled"),0,"isBoolean of 'disabled' should return 0");

is(isBoolean("yes"),1,"isBoolean of 'yes' should return 1");
is(isBoolean("no"),0,"isBoolean of 'yes' should return 0");

is(isBoolean(1),1,"isBoolean of 1 should return 1");

is(isBoolean("1"),1,"isBoolean of '1' should return 1");


done_testing();



