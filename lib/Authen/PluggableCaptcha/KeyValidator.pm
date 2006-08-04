#!/usr/bin/perl
#
# Authen::PluggableCaptcha::KeyValidator
#
######################################################

use strict;

package Authen::PluggableCaptcha::KeyValidator;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';
our @ISA= qw( Authen::PluggableCaptcha::ErrorLoggingObject );

######################################################

=pod

This is the base class for validating a captcha public key

By default , this always returns true - there is no validation supported other than the timeliness provided by the key generation module.

This should be subclassed to provide for other implementations

This must support the following hooks:

	validate_publickey
	
This must support the following variables
	EXPIRED (bool is expired?)
	INVALID (bool is invalid?)

=cut

sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );
	return $self;
}

sub validate_publickey {
=pod
validates the publickey

	this is where you'd subclass and toss in functions that handle:
		
		was this key ever used before? ( one time user )
		was this key accessed by more than one ip?
		etc.
		
	we pass in a ref to the keygenerator instance
	
	the keygen has these variables stuffed in it:
		publickey
		publickey_combined
		seed
		site_secret
		time_start

=cut
	my  ( $self , %kw_args )= @_;
		$self->{'keygenerator_instance'}= $kw_args{'keygenerator_instance'};
	return 1;
}


###
1;