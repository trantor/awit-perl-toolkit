# Test harness for isVariable
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



my $hashtable = { 'makeHash' => 1 };
my $scalar = 1;


is(isVariable($hashtable),0,"Check that a hash returns 0");

is(isVariable($scalar),1,"Check that a variable returns 1");

is(isVariable(1),1,"Check that 1 returns 1");

is(isVariable(undef),undef,"Check that a undef returns undef");


done_testing();



