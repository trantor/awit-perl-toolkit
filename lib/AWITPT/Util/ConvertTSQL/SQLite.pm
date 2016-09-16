# TSQL conversion to SQLite
# Copyright (C) 2016, AllWorldIT
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

AWITPT::Util::ConvertTSQL::SQLite - TSQL conversion to SQLite

=head1 SYNOPSIS

	my $tsql = AWITPT::Util::ConvertTSQL->new('SQLite','prefix' => "myapp_");

=head1 DESCRIPTION

The AWITPT::Util::ConvertTSQL::SQLite class provides TSQL conversion to SQLite.



=cut


package AWITPT::Util::ConvertTSQL::SQLite;

use strict;
use warnings;

use base 'AWITPT::Util::ConvertTSQL';

our $VERSION = "1.000";

our (@EXPORT,@EXPORT_OK);
@EXPORT = qw(
);
@EXPORT_OK = qw(
);



=head1 METHODS

C<AWITPT::Util::ConvertTSQL::SQLite> provides the below methods.

=cut


=head2 new

This class is instantiated by the parent class.

The C<new> method is used to instantiate the object, it supports some options including 'prefix' which can be used to set the
table prefix for the resulting SQL.

=head3 'prefix'

Allow the specification of the resulting table prefixes.

=over

=cut



#
# INTERNAL METHODS BELOW
#



# Initialize internals of the object
sub _config
{
	my ($self,@params) = @_;


	# Call parent config
	$self->SUPER::_config(@params);

	$self->substitute('@PRELOAD@','');
	$self->substitute('@POSTLOAD@','');

	$self->substitute('@CREATE_TABLE_SUFFIX@','');

	$self->substitute('@SERIAL_TYPE@','INTEGER PRIMARY KEY AUTOINCREMENT');
	$self->substitute('@SERIAL_REF_TYPE@','INT8');

	$self->substitute('@BIG_INTEGER_UNSIGNED@','UNSIGNED BIG INT');
	$self->substitute('@INT_UNSIGNED@','INT8');

	$self->substitute('@TRACK_KEY_LEN@','512');

	return $self;
}



1;
__END__

=head1 AUTHORS

Nigel Kukard E<lt>nkukard@lbsd.netE<gt>

=head1 BUGS

All bugs should be reported via the project issue tracker
L<http://gitlab.devlabs.linuxassist.net/awit-frameworks/awit-perl-toolkit/issues/>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016, AllWorldIT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<AWITPT::Util::ConvertTSQL>, L<AWITPT::DataObj>.

=cut
