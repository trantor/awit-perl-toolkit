# TSQL conversion client
# Copyright (C) 2007-2016, AllWorldIT
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

AWITPT::Util::ConvertTSQL::client - TSQL conversion client

=head1 SYNOPSIS

	use AWITPT::Util::ConvertTSQL::client;

	my $res = AWIT::Util::ConvertTSQL::client->run();
	return $res;

=head1 DESCRIPTION

The AWITPT::Object class provides a basic abstraction layer to Perl objects.

=cut


package AWITPT::Util::ConvertTSQL::client;

use strict;
use warnings;

use base 'AWITPT::Object';

use AWITPT::Util::ConvertTSQL;
use Getopt::Long qw( GetOptionsFromArray );


our $VERSION = "1.000";



=head1 METHODS

C<AWITPT::Util::ConvertTSQL::client> provides the below methods.

=cut



=head2 run

The C<run> method runs the client, possibly with arguments we supply instead of from the commandline.

=over

=back

=cut

# Run the client
sub run
{
	my ($self,@methodArgs) = @_;
	# Instantiate if we're not already instantiated
	$self = $self->new() if (!ref($self));


	print(STDERR "AWIT ConvertTSQL v$VERSION - Copyright (c) 2007-2016, AllWorldIT\n");

	print(STDERR "\n");

	# Grab runtime arguments
	my @runArgs = @methodArgs ? @methodArgs : @ARGV;

	# Parse command line params
	my $cmdline;
	%{$cmdline} = ();
	if (!GetOptionsFromArray(
		\@runArgs,
		\%{$cmdline},
		"help",
	)) {
		print(STDERR "ERROR: Error parsing commandline arguments");
		return 1;
	}

	# Check for some args
	if ($cmdline->{'help'}) {
		displayHelp();
		return 0;
	}

	# Make sure we have at least 2 args
	if (@runArgs < 2) {
		print(STDERR "ERROR: Invalid number of arguments\n");
		displayHelp();
		return 1;
	}

	print(STDERR "\n");

	# Pull in details of the type and file we're processing
	my $type = shift(@runArgs);
	my $file = shift(@runArgs);
	my $prefix = shift(@runArgs) // "";

	my $tsqlc = AWITPT::Util::ConvertTSQL->new($type,'prefix' => $prefix);


	open(my $FILE,'<',$file)
		or die("Failed to open '$file': $!");
	# Read in one line at a time
	while (my $line = <$FILE>) {
		print($tsqlc->convert($line));
	}
	# Close file
	close($FILE);


	return 0;
}




=head2 displayHelp

The C<displayHelp> method is somewhat internal to the ConvertTSQL client and displays the commandline help.

=over

=back

=cut

# Display help
sub displayHelp {
	print(STDERR<<EOF);

Usage: $0 [args] <DB_TYPE> <DB_FILE> [TABLE_PREFIX]

    --help                 Display this help.
EOF

	return;
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
