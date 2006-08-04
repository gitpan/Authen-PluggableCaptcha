#!/usr/bin/perl
#
#
# ErrorLoggingObject
# PerlLib 2XLP ErrorLoggingObject Package
#
######################################################

=pod
	
	This is an ErrorLoggingObject- it contains routines that log and retreive errors for objects


	It's really nothing more than a few simple methods and an _ERROR namespace that can help manage objects
	
	This also supports '__dict__', which returns a Data::Dumper representation of an object ( kind of like a python __dict__ )
	
=cut



use strict;
use warnings;

package Authen::PluggableCaptcha::ErrorLoggingObject;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';

######################################################

use constant DEBUG=> 0;
use constant DEBUG_ERROR=> 0;

######################################################

sub new {
	my  $proto= shift;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class);
		$self->__init_errors();
	return $self;
}

sub __init_errors {
	my 	( $self )= @_;
	$self->{'__ERRORS'}= {};
}

sub get_error {
	my 	( $self , $function )= @_;
	if ( !defined $self->{'__ERRORS'}{$function} ) {
		return undef;
	};
	return $self->{'__ERRORS'}{$function};
}
	
sub set_error {
	my 	( $self , $function , $error )= @_;
	$self->{'__ERRORS'}{$function}= $error;
}

sub log_function_name {
	print STDERR "\n\t".$_[0];
}

sub __dict__ {
	my 	( $self )= @_;
	use Data::Dumper();
	return Data::Dumper->Dump( [$self] , [qw(self)] );
}


####
1;
