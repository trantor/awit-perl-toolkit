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


is(isNumber(0),undef);
is(isNumber(0,ISNUMBER_ALLOW_ZERO),0);
is(isNumber("000",ISNUMBER_ALLOW_ZERO),0);
is(isNumber("-0",ISNUMBER_ALLOW_ZERO),0);

is(isNumber(-1),undef);
is(isNumber(-1,ISNUMBER_ALLOW_NEGATIVE),-1);
is(isNumber("-1",ISNUMBER_ALLOW_NEGATIVE),-1);
is(isNumber("-01",ISNUMBER_ALLOW_NEGATIVE),-1);

is(isNumber(1),1);

is(isNumber("0001"),1);

is(isNumber("a"),undef);
is(isNumber("0a"),undef);
is(isNumber("a0"),undef);
is(isNumber("-a0"),undef);
is(isNumber("-0a"),undef);

done_testing();

