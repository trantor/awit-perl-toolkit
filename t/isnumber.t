# Test harness for isNumber
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


is(isNumber(0),undef,"Check 0 returns undef");
is(isNumber("0"),undef,"Check '0' returns undef");

is(isNumber(0,ISNUMBER_ALLOW_ZERO),0,"Check 0 returns 0 when using ISNUMBER_ALLOW_ZERO");
is(isNumber("000",ISNUMBER_ALLOW_ZERO),0,"Check 000 returns 0 when using ISNUMBER_ALLOW_ZEOR");
is(isNumber("-0",ISNUMBER_ALLOW_ZERO),0,"Check -0 returns 0 when using ISNUMBER_ALLOW_ZERO");

is(isNumber(-1),undef,"Check -1 returns undef");
is(isNumber("-1"),undef,"Check '-1' returns undef");
is(isNumber(-1,ISNUMBER_ALLOW_NEGATIVE),-1,"Check -1 returns -1 when using ISNUMBER_ALLOW_NEGATIVE");
is(isNumber("-1",ISNUMBER_ALLOW_NEGATIVE),-1,"Check '-1' returns -1 when using ISNUMBER_ALLOW_NEGATIVE");
is(isNumber("-01",ISNUMBER_ALLOW_NEGATIVE),-1,"Check '-01' returns -1 when using ISNUMBER_ALLOW_NEGATIVE");

is(isNumber(1),1,"Check 1 returns 1");
is(isNumber("1"),1,"Check '1' returns 1");

is(isNumber("0001"),1,"Check '0001' returns 1");

is(isNumber("a"),undef,"Check 'a' returns undef");
is(isNumber("0a"),undef,"Check '0a' returns undef");
is(isNumber("a0"),undef,"Check 'a0' returns undef");
is(isNumber("-a0"),undef,"Check '-a0' returns undef");
is(isNumber("-0a"),undef,"Check '-0a' returns undef");

is(isNumber($hash),undef,"Check HASH returns undef");

is(isNumber($object),undef,"Check OBJECT returns undef");


done_testing();



