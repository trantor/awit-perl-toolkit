# Makefile
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



use strict;
use warnings;


use ExtUtils::MakeMaker;



WriteMakefile(
	'NAME' => 'AWITPT',

	'VERSION_FROM' => "lib/AWITPT/Version.pm",

	'EXE_FILES' => [qw(
		bin/convert-tsql
	)],

	'MAN3PODS' => {
		'lib/AWITPT/DataObj.pm' => '$(INST_MAN3DIR)/AWITPT::DataObj.3',
		'lib/AWITPT/DataObj/Backend/DBLayer.pm' => '$(INST_MAN3DIR)/AWITPT::DataObj::Backend::DBLayer.3',
		'lib/AWITPT/Util/ConvertTSQL.pm' => '$(INST_MAN3DIR)/AWITPT::Util::ConvertTSQL.3',
		'lib/AWITPT/Util/ConvertTSQL/client.pm' => '$(INST_MAN3DIR)/AWITPT::Util::ConvertTSQL::client.3',
		'lib/AWITPT/Util/ConvertTSQL/MySQL.pm' => '$(INST_MAN3DIR)/AWITPT::Util::ConvertTSQL::MySQL.3',
		'lib/AWITPT/Util/ConvertTSQL/PgSQL.pm' => '$(INST_MAN3DIR)/AWITPT::Util::ConvertTSQL::PgSQL.3',
		'lib/AWITPT/Util/ConvertTSQL/SQLite.pm' => '$(INST_MAN3DIR)/AWITPT::Util::ConvertTSQL::SQLite.3',
	},
);

