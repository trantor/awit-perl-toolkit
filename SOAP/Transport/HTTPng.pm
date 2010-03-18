# Copyright (C) 2008-2010, AllWorldIT
# Copyright (C) 2005-2007, LinuxRulz
# Copyright (C) 2005, Nigel Kukard <nkukard@lbsd.net>
# Copyright 1996-2003, Gisle Aas
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.




use strict;
use warnings;


# Overrided server so we can intercept sensitive info
package SOAP::Transport::HTTPng::Server;

use SOAP::Transport::HTTP;

use base qw(SOAP::Transport::HTTP::Server);

# Setup a logging function
sub set_logger {
	my ($self,$logobj) = @_;

	$self->{'logobj'} = $logobj;
}

# We want to override the make_fault function to catch sensitive information
# being sent out when code b0rkage occurs.
sub make_fault {
	my ($self, $code, $string, $detail, $actor) = @_;


	# Check if this is a string?
	if (ref($code) eq "") {
		# If its a server fault, just output something nice
		if ($code eq "Server") {
			# If we have a logging element in ourselves, use it
			if (defined($self->{'logobj'})) {
				$self->{'logobj'}->log(0,"[SOAP::Server] $string");
			}
			$string = "An error occured while processing the request. Please try again later.";
		}
	}
	return $self->SUPER::make_fault($code,$string,$detail,$actor);
}



# PreForked implementation of a SOAP HTTP transport
package SOAP::Transport::HTTPng::Daemon;
use base qw(Net::Server::PreFork);


use HTTP::Daemon;
use HTTP::Status;
use URI::Escape;
use IO::Socket qw(inet_ntoa);
use Socket;

use SOAP::Lite;
use SOAP::Transport::HTTP;

use Data::Dumper;

sub new
{
	my $self = shift;

	unless (ref $self) {
		my $class = ref($self) || $self;
		$self = $class->SUPER::new(@_);
		$self->{'soap_config'}->{'dispatch_to'} = ();
		$self->{'soap_config'}->{'dispatch_with'} = {};
	}

	return $self;
}



sub post_configure
{
	my $self = shift;
	my $server = $self->{'server'};


	# Make sure we have a timeout
	if (!defined($server->{'timeout'})) {
		$server->{'timeout'} = 30;
	}

	# Set constants
	$server->{'proto'} = "TCP";


	$self->SUPER::post_configure(@_);
}


sub child_init_hook
{
	my $self = shift;
	my $soapcfg = $self->{'soap_config'};


	$self->{'_soap_engine'} = SOAP::Transport::HTTPng::Server->new;
	# Mappings
	if (defined($soapcfg->{'dispatch_to'}) && @{$soapcfg->{'dispatch_to'}} > 0) {
		$self->{'_soap_engine'}->dispatch_to(@{$soapcfg->{'dispatch_to'}});
	}
	if (defined($soapcfg->{'dispatch_with'}) && @{$soapcfg->{'dispatch_with'}} > 0) {
		$self->{'_soap_engine'}->dispatch_with(%{$soapcfg->{'dispatch_with'}});
	}
	# Hooks
	if (defined($soapcfg->{'on_action'})) {
		$self->{'_soap_engine'}->on_action($soapcfg->{'on_action'});
	}
	if (defined($soapcfg->{'on_dispatch'})) {
		$self->{'_soap_engine'}->on_dispatch($soapcfg->{'on_dispatch'});
	}
	
	$self->{'_soap_engine'}->set_logger($self);
}

sub process_request
{
	my ($self) = @_;
	my $soap = $self->{'_soap_engine'};

	my $c = SOAP::Transport::HTTPng::Daemon::Client->new($self);
	my $r = $c->get_request();

	$soap->request($r);
	$soap->handle;
	$c->send_response($soap->response);
}

sub log
{
	my $self = shift;

	return $self->SUPER::log(@_);
}


package SOAP::Transport::HTTPng::Daemon::Client;

require Exporter;
our (@ISA);
@ISA= qw(Exporter);

use HTTP::Request();
use HTTP::Response();
use HTTP::Status;
use HTTP::Date qw(time2str);
use LWP::MediaTypes qw(guess_media_type);
use Carp ();
use URI;

use Data::Dumper;

# Some constants we need
use constant {
	DEBUG 	=> 0,
	CRLF 	=> "\015\012",  # HTTP::Daemon claims \r\n is not portable?
};


# Create object
sub new
{
	my ($class,$daemon) = @_;

	# Define ourselves and our variables
	my $self = {
		'daemon'	=> $daemon,
		'_nomore'	=> undef,
		'_rbuf'		=> undef,
		'_client_proto'	=> undef,
	};

	bless $self, $class;
	return $self;
}


# Get request
sub get_request
{
	my($self, $only_headers) = @_;


	# Check if no more requests
	if ($self->{'_nomore'}) {
		$self->reason("No more requests from this connection");
		return;
	}

	# Init
	$self->reason("");
	my $buf = $self->{'_rbuf'};
	$buf = "" unless defined $buf;

	# Pull in timeout
    	my $timeout = $self->{'_daemon'}->{'server'}->{'timeout'};


	# Setup fdset with STDIN
	my $fdset = "";
	vec($fdset, fileno(STDIN), 1) = 1;

	# Grab HTTP header
	while (1) {
		# loop until we have the whole header in $buf
		$buf =~ s/^(?:\015?\012)+//;  # ignore leading blank lines
		if ($buf =~ /\012/) {  # potential, has at least one line
			if ($buf =~ /^\w+[^\012]+HTTP\/\d+\.\d+\015?\012/) {
				if ($buf =~ /\015?\012\015?\012/) {
					last;  # we have it

				# Header is over 16kb
				} elsif (length($buf) > 16*1024) {
					$self->send_error(413); # REQUEST_ENTITY_TOO_LARGE
					$self->reason("Very long header");
					return;
				}
			} else {
				last;  # HTTP/0.9 client
			}

		# Again ... too large
		} elsif (length($buf) > 16*1024) {
			$self->send_error(414); # REQUEST_URI_TOO_LARGE
			$self->reason("Very long first line");
			return;
		}
		return unless $self->_need_more(\$buf, $timeout, $fdset);
	}

	# Disect the protocol
	if ($buf !~ s/^(\S+)[ \t]+(\S+)(?:[ \t]+(HTTP\/\d+\.\d+))?[^\012]*\012//) {
		$self->{'_client_proto'} = $self->_http_version("HTTP/1.0");
		$self->send_error(400);  # BAD_REQUEST
		$self->reason("Bad request line: $buf");
		return;
	}
	my $method = $1;
	my $uri = $2;
	my $proto = $3 || "HTTP/0.9";

	$uri = "http://$uri" if $method eq "CONNECT";
	$uri = URI->new($uri, $self->{'daemon'}->{'config'}->{'url'});
	my $r = HTTP::Request->new($method, $uri);
	$r->protocol($proto);
	$self->{'_client_proto'} = $proto = $self->_http_version($proto);

	if ($self->proto_ge("HTTP/1.0")) {
		# we expect to find some headers
		my($key, $val);

		while ($buf =~ s/^([^\012]*)\012//) {
			$_ = $1;
			s/\015$//;
			if (/^([^:\s]+)\s*:\s*(.*)/) {
				$r->push_header($key, $val) if $key;
				($key, $val) = ($1, $2);
			} elsif (/^\s+(.*)/) {
				$val .= " $1";
			} else {
				last;
			}
		}
		$r->push_header($key, $val) if $key;
	}

	my $conn = $r->header('Connection');
	if ($self->proto_ge("HTTP/1.1")) {
		$self->{'_nomore'}++ if $conn && lc($conn) =~ /\bclose\b/;
	} else {
		$self->{'_nomore'}++ unless $conn && lc($conn) =~ /\bkeep-alive\b/;
	}

	if ($only_headers) {
		$self->{'rbuf'} = $buf;
		return $r;
	}

	# Find out how much content to read
	my $te = $r->header('Transfer-Encoding');
	my $ct = $r->header('Content-Type');
	my $len = $r->header('Content-Length');
	if ($te && lc($te) eq 'chunked') {
		# Handle chunked transfer encoding
		my $body = "";
		while (1) {
			print STDERR "Chunked\n" if DEBUG;
			if ($buf =~ s/^([^\012]*)\012//) {
				my $chunk_head = $1;
				unless ($chunk_head =~ /^([0-9A-Fa-f]+)/) {
					$self->send_error(400);
					$self->reason("Bad chunk header $chunk_head");
					return;
				}
				my $size = hex($1);
				last if $size == 0;

				my $missing = $size - length($buf) + 2; # 2=CRLF at chunk end
				# must read until we have a complete chunk
				while ($missing > 0) {
					print STDERR "Need $missing more bytes\n" if DEBUG;
					my $n = $self->_need_more(\$buf, $timeout, $fdset);
					return unless $n;
					$missing -= $n;
				}
				$body .= substr($buf, 0, $size);
				substr($buf, 0, $size+2) = '';
			# need more data in order to have a complete chunk header
			} else {
				return unless $self->_need_more(\$buf, $timeout, $fdset);
			}
		}
		$r->content($body);

		# pretend it was a normal entity body
		$r->remove_header('Transfer-Encoding');
		$r->header('Content-Length', length($body));

		my($key, $val);
		while (1) {
			if ($buf !~ /\012/) {
				# need at least one line to look at
				return unless $self->_need_more(\$buf, $timeout, $fdset);
			} else {
				$buf =~ s/^([^\012]*)\012//;
				$_ = $1;
				s/\015$//;
				if (/^([\w\-]+)\s*:\s*(.*)/) {
					$r->push_header($key, $val) if $key;
					($key, $val) = ($1, $2);
				} elsif (/^\s+(.*)/) {
					$val .= " $1";
				} elsif (!length) {
					last;
				} else {
					$self->reason("Bad footer syntax");
					return;
				}
			}
		}
		$r->push_header($key, $val) if $key;

    	} elsif ($te) {
		$self->send_error(501); # Unknown transfer encoding
		$self->reason("Unknown transfer encoding '$te'");
		return;

    	} elsif ($ct && lc($ct) =~ m/^multipart\/\w+\s*;.*boundary\s*=\s*(\w+)/) {
		# Handle multipart content type
		my $boundary = sprintf('%s--%s--%s',CRLF,$1,CRLF);
		my $index;
		while (1) {
			$index = index($buf, $boundary);
			last if $index >= 0;
			# end marker not yet found
			return unless $self->_need_more(\$buf, $timeout, $fdset);
		}
		$index += length($boundary);
		$r->content(substr($buf, 0, $index));
		substr($buf, 0, $index) = '';

	} elsif ($len) {
		# Plain body specified by "Content-Length"
		my $missing = $len - length($buf);
		while ($missing > 0) {
			print "Need $missing more bytes of content\n" if DEBUG;
			my $n = $self->_need_more(\$buf, $timeout, $fdset);
			return unless $n;
			$missing -= $n;
		}
		if (length($buf) > $len) {
			$r->content(substr($buf,0,$len));
			substr($buf, 0, $len) = '';
		} else {
			$r->content($buf);
			$buf='';
		}
	}
	$self->{'rbuf'} = $buf;

	return $r;
}


sub _need_more
{
	my($self,$buf,$timeout,$fdset) = @_;


	# If we have a timeout, use select on FH
	if ($timeout) {
		my $n = select($fdset,undef,undef,$timeout);
		unless ($n) {
			$self->reason(defined($n) ? "Timeout" : "select: $!");
			return;
		}
	}
	my $n = sysread(STDIN, $$buf, 2048, length($$buf));
	$self->reason(defined($n) ? "Client closed" : "sysread: $!") unless $n;
	return $n;
}


sub reason
{
	my $self = shift;
	my $old = $self->{'reason'};
	$self->{'reason'} = shift if (@_);
	return $old;
}


sub proto_ge
{
	my $self = shift;
	return ($self->{'_client_proto'} >= $self->_http_version(shift));
}

sub proto_lt
{
	my $self = shift;
	return ($self->{'_client_proto'} < $self->_http_version(shift));
}


sub _http_version
{
	my ($self,$version) = @_;

	return 0 unless ($version =~ m,^(?:HTTP/)?(\d+)\.(\d+)$,i);
	return ($1 * 1000 + $2);
}


sub antique_client
{
	my $self = shift;
	return ($self->{'_client_proto'} < $self->_http_version("HTTP/1.0"));
}


sub force_last_request
{
	my $self = shift;
	$self->{'_nomore'}++;
}


sub send_status_line
{
	my ($self, $status, $message, $proto) = @_;
	return if $self->antique_client;
	$status  ||= RC_OK;
	$message ||= status_message($status) || "";
	$proto   ||= $HTTP::Daemon::PROTO || "HTTP/1.1";
	printf(STDOUT '%s %s %s%s',$proto,$status,$message,CRLF);
}


sub send_crlf
{
	my $self = shift;
	print(STDOUT CRLF);
}


sub send_basic_header
{
	my $self = shift;
	return if $self->antique_client;
	$self->send_status_line(@_);
	printf(STDOUT 'Date: %s%s',time2str(time), CRLF);
	printf(STDOUT 'Server: %s%s', $self->{'daemon'}->{'_product_tokens'}, CRLF) if ($self->{'daemon'}->{'_product_tokens'});
}


sub send_response
{
	my ($self,$res) = @_;

	if (!ref $res) {
		$res ||= RC_OK;
		$res = HTTP::Response->new($res, @_);
	}

	my $content = $res->content;
	my $chunked;
	unless ($self->antique_client) {
		my $code = $res->code;
		$self->send_basic_header($code, $res->message, $res->protocol);
		if ($code =~ /^(1\d\d|[23]04)$/) {
			# make sure content is empty
			$res->remove_header("Content-Length");
			$content = "";
		} elsif ($res->request && $res->request->method eq "HEAD") {
			# probably OK
		} elsif (ref($content) eq "CODE") {
			if ($self->proto_ge("HTTP/1.1")) {
				$res->push_header("Transfer-Encoding" => "chunked");
				$chunked++;
			} else {
				$self->force_last_request;
			}
		} elsif (length($content)) {
			$res->header("Content-Length" => length($content));
		} else {
			$self->force_last_request;
		}
		print(STDOUT $res->headers_as_string(CRLF));
		print(STDOUT CRLF);  # separates headers and content
	}
	if (ref($content) eq "CODE") {
		while (1) {
			my $chunk = &$content();
			last unless defined($chunk) && length($chunk);
			if ($chunked) {
				printf(STDOUT '%x%s%s%s', length($chunk), CRLF, $chunk, CRLF);
			} else {
				print(STDOUT $chunk);
			}
		}
		printf(STDOUT '0%s%s',CRLF,CRLF) if $chunked;  # no trailers either
	} elsif (length $content) {
		print(STDOUT $content);
	}
}


sub send_redirect
{
	my($self, $loc, $status, $content) = @_;
	$status ||= RC_MOVED_PERMANENTLY;
	Carp::croak("Status '$status' is not redirect") unless is_redirect($status);
	$self->send_basic_header($status);
	my $base = $self->{'daemon'}->{'config'}->{'url'};
	$loc = URI->new($loc, $base) unless ref($loc);
	$loc = $loc->abs($base);
	printf(STDOUT 'Location: %s%s',$loc,CRLF);
	if ($content) {
		my $ct = $content =~ /^\s*</ ? "text/html" : "text/plain";
		printf(STDOUT 'Content-Type: %s%s',$ct,CRLF);
	}
	print(STDOUT CRLF);
	print(STDOUT $content) if $content;
	return $self->force_last_request;  # no use keeping the connection open
}


sub send_error
{
	my($self, $status, $error) = @_;
	$status ||= RC_BAD_REQUEST;
	Carp::croak("Status '$status' is not an error") unless is_error($status);
	my $mess = status_message($status);
	$error  ||= "";
	$mess = <<EOT;
<title>$status $mess</title>
<h1>$status $mess</h1>
$error
EOT
	unless ($self->antique_client) {
		$self->send_basic_header($status);
		printf(STDOUT 'Content-Type: text/html%s',CRLF);
		printf(STDOUT 'Content-Length: %s%s',length($mess),CRLF);
		print(STDOUT CRLF);
	}
	print(STDOUT $mess);
	return $status;
}


sub send_file_response
{
	my($self, $file) = @_;

	if (-d $file) {
		$self->send_dir($file);
	} elsif (-f _) {
		# plain file
		local(*F);
		sysopen(F, $file, 0) or
			return $self->send_error(RC_FORBIDDEN);
		binmode(F);
		my($ct,$ce) = guess_media_type($file);
		my($size,$mtime) = (stat _)[7,9];
		unless ($self->antique_client) {
			$self->send_basic_header;
			printf(STDOUT 'Content-Type: %s%s',$ct,CRLF);
			printf(STDOUT 'Content-Encoding: %s%s',$ce,CRLF) if $ce;
			printf(STDOUT 'Content-Length: %s%s',$size,CRLF) if $size;
			printf(STDOUT 'Last-Modified: %s%s',time2str($mtime),CRLF) if $mtime;
			print(STDOUT CRLF);
		}
		$self->send_file(\*F);
	return RC_OK;

	} else {
		$self->send_error(RC_NOT_FOUND);
	}
}


sub send_dir
{
	my($self, $dir) = @_;
	$self->send_error(RC_NOT_FOUND) unless -d $dir;
	$self->send_error(RC_NOT_IMPLEMENTED);
}


sub send_file
{
	my($self, $file) = @_;

	my $opened = 0;
	local(*FILE);
	if (!ref($file)) {
		open(FILE, $file) || return undef;
		binmode(FILE);
		$file = \*FILE;
		$opened++;
	}
	my $cnt = 0;
	my $buf = "";
	my $n;
	while ($n = sysread($file, $buf, 8*1024)) {
		last if !$n;
		$cnt += $n;
		print(STDOUT $buf);
	}
	close($file) if $opened;
	return $cnt;
}


1;
# vim: ts=4
