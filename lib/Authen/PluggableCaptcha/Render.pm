#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';
our @ISA= qw( Authen::PluggableCaptcha::ErrorLoggingObject );

######################################################

=pod

This is the base class for the rendering of a captcha

This should never be called.  Subclass this with the required public methods
	init
		initialization
	init_valid
		initialization for valid captchas
	init_expired
		initialization for expired captchas
	validate
		validator function
	render
		render function


=cut


sub _init_render {
	my	( $self , $kw_args__ref )= @_;

	# make sure we have the requisite kw_args
	my 	@_requires= qw( challenge_instance );
	&Authen::PluggableCaptcha::_check_requires( 
		kw_args__ref=> $kw_args__ref,
		error_message=> "Missing required element '%s' in _init_render",
		requires_array__ref=> \@_requires
	);
	
	$self->{'challenge_instance'}= $$kw_args__ref{'challenge_instance'};
	return 1;
}



###
1;