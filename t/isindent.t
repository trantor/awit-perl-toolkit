# Test harness for indentExpand
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



is(indentExpand(' ', 4),'    ',"Check that indentExpand 4 spaces returns 4 spaces");
is(indentExpand('   ', 4),'            ',"Check that indentExpand 4 x 4 spaces returns 16 spaces");

is(indentExpand(' ', 2),'  ',"Check that indentExpand 2 spaces returns 2 spaces");
is(indentExpand('  ', 2),'    ',"Check that indentExpand 2 x 2 spaces returns 4 spaces");

is(indentExpand(' ', 1),' ',"Check that indentExpand 1 spaces returns 1 space");
is(indentExpand('     ', 1),'     ',"Check that indentExpand 1 x 5 spaces returns 1 space");

is(indentExpand(' ', 3),'   ',"Check that indentExpand 3 returns 3 spaces");
is(indentExpand('   ', 3),'         ',"Check that indentExpand 3 x 3 spaces returns 9 spaces");


done_testing();



