#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Challenge::TypeString
# Authen::PluggableCaptcha 
#
######################################################

use strict;

package Authen::PluggableCaptcha::Challenge::TypeString;

use vars qw(@ISA $VERSION);
$VERSION= '0.01';

use Authen::PluggableCaptcha::Challenge;
our @ISA= qw( Authen::PluggableCaptcha::Challenge );

######################################################

use Digest::MD5 qw(md5_hex);

######################################################

=pod

This is a type string captcha.

You have to type a string.  

=cut

sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );
		$self->{'keygenerator_instance'}= $kw_args{'keygenerator_instance'} || die "must supply 'keygenerator_instance'";
		$self->{'instructions'}= "Please type the text you see";
		$self->{'user_prompt'}= 
			substr(
				md5_hex( 
					sprintf(
						"%s|%s|%s|%s" , 
							$self->{'keygenerator_instance'}->{'site_secret'},
							$self->{'keygenerator_instance'}->{'publickey'},
							$self->{'keygenerator_instance'}->{'publickey'},
							$self->{'keygenerator_instance'}->{'time_start'}
					)
				),
				0,
				6
			);
	$self->{'correct_response'}= $self->{'user_prompt'};
	return $self;
}

sub validate {
	my 	( $self , %kw_args )= @_;
	if ( ! defined $kw_args{'user_response'} || !$kw_args{'user_response'} ) {
		die "validate must be called with a 'user_response' argument";
	}
	if ( lc($kw_args{'user_response'}) eq lc($self->{'correct_response'}) ) {
		return 1;		
	}
	return 0;
}






###
1;