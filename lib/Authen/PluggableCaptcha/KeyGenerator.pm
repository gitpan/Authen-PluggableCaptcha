#!/usr/bin/perl
#
# Authen::PluggableCaptcha::KeyGenerator
#
######################################################

use strict;

package Authen::PluggableCaptcha::KeyGenerator;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';
our @ISA= qw( Authen::PluggableCaptcha::ErrorLoggingObject );

use Digest::MD5 qw(md5_hex);

######################################################

use Authen::PluggableCaptcha;

######################################################

=pod
This is the base class for generating a captcha public key

This should be subclassed to provide for other implementations

Subclassed modules must support the following public methods (hooks):

	generate_publickey
	init_existing
	
generate_publickey creates a new public key based on a sitesecret, time, and seed ( seed should be something like session_id )

init_existing validates a publickey based on the internal generator requirements

publically addressed variables are:

	time_now
	time_start
	publickey
	
	EXPIRED (bool is expired?)
	INVALID (bool is invalid?)

=cut

sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );

	# required elements
		my 	@_requires= qw( time_now time_expiry time_expiry_future seed site_secret );
		&Authen::PluggableCaptcha::_check_requires( 
			kw_args__ref=> \%kw_args,
			error_message=> "Missing required element '%s' in KeyGenerator::New",
			requires_array__ref=> \@_requires
		);
		$self->{'time_now'}= $kw_args{'time_now'};
		$self->{'time_expiry'}= $kw_args{'time_expiry'};
		$self->{'time_expiry_future'}= $kw_args{'time_expiry_future'};
		$self->{'seed'}= $kw_args{'seed'};
		$self->{'site_secret'}= $kw_args{'site_secret'};

	return $self;
}

sub set_invalid {
	my 	( $self )= @_;
	$self->{'INVALID'}= 1;
	$self->{'ACCEPTABLE_ERROR'}= 1;
}
sub set_expired {
	my 	( $self )= @_;
	$self->{'EXPIRED'}= 1;
	$self->{'ACCEPTABLE_ERROR'}= 1;
}


sub init_existing {
=pod
hoook called when initializing an existing captcha
=cut
	my 	( $self , %kw_args )= @_;
	
	if ( $kw_args{'publickey'} ) {
		$self->{'publickey'}= $kw_args{'publickey'};
	}
	
	if ( !$self->{'publickey'} ) {
		$self->set_invalid();
		$self->set_error( 'init_existing','no publickey' );
		return 0;
	}
	
	#if we have an existing key, we need to perform a referential check
	
	# first check is on the format
	if 	( $self->{'publickey'} !~ m/[\w]{32}_[\d]{9,11}/ ) {
		#	key is not in the right format
		$self->set_invalid();
		$self->set_error( 'init_existing','invalid key format' );
		return 0;
	}

	# if its in the format, then split the format into hash and time_start
	( $self->{'_hash'} , $self->{'time_start'} )= split '_' , $self->{'publickey'};


	# next check is on the timeliness
	if 	( 
			$self->{'time_now'} 
			> 
			( $self->{'time_start'} + $self->{'time_expiry'} ) 
		) 
	{
		$self->set_expired();
		$self->set_error( 'init_existing','EXPIRED captcha time' );
		return 0;
	}

	# is the captcha too new?
	if 	( 
			$self->{'time_start'} 
			> 
			( $self->{'time_now'} + $self->{'time_expiry_future'} ) 
		)
	{
		$self->set_invalid();
		$self->set_error( 'init_existing','FUTURE captcha time' );
		return 0;
	}	

	return 1;
}

sub generate_publickey {
=pod
Returns a hash based on text , seed , and site_secrect.
implemented as a seperate function to be replaced easier
=cut
	my 	( $self )= @_;
	$self->{'_hash'}= md5_hex(  sprintf( "%s|%s|%s" , $self->{'site_secret'}, $self->{'time_now'}, $self->{'seed'} )  );
	#by default we just use a '_' join : KEY_TIMESTART
	$self->{'publickey'}= join '_' , ( $self->{'_hash'} , $self->{'time_now'} ) ;
}





###
1;