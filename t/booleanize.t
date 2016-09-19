# Test harness for booleanize
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




is(booleanize(0),0,"Booleanize of 0 should return 0");
is(booleanize("0"),0,"Booleanize of '0' should return 0");
is(booleanize("00"),0,"Booleanize of '00' should return 0");

is(booleanize("-1"),0,"Booleanize of '-1' should return 0");
is(booleanize("-0"),0,"Booleanize of '-0' should return 0");

is(booleanize("a"),0,"Booleanize of 'a' should return 0");
is(booleanize("0a"),0,"Booleanize of 'a' should return 0");
is(booleanize("a0"),0,"Booleanize of 'a' should return 0");

is(booleanize("TruE"),1,"Booleanize of 'TruE' should return 1");

is(booleanize("oN"),1,"Booleanize of 'oN' should return 1");

is(booleanize("SeT"),1,"Booleanize of 'SeT' should return 1");

is(booleanize("EnAblED"),1,"Booleanize of 'EnAblED' should return 1");

is(booleanize("yes"),1,"Booleanize of 'yes' should return 1");

is(booleanize(1),1,"Booleanize of 1 should return 1");

is(booleanize("1"),1,"Booleanize of '1' should return 1");


done_testing();



