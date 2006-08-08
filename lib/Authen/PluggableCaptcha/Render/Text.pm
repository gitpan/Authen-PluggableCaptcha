#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render::Text
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Text;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';
use Authen::PluggableCaptcha::Render;
our @ISA= qw( Authen::PluggableCaptcha::Render );

######################################################

######################################################

our %_DEFAULTS = (
	'format'=> 'PLAIN',
	message_expired=> 'This captcha has expired',
);

######################################################

sub _init__text {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('_init__text');
	my  ( $self , $kw_args__ref )= @_;
	$self->{'rendered'}= 0;
}

sub render {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('render');
	my 	( $self )= @_;
	if ( $self->{'rendered'} ) {
		return;
	}

	# we would do a render here.

	$self->{'rendered'}= 1;
}




sub as_string {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('as_string');
=pod
alias to_string
=cut
	my 	( $self , %kw_args )= @_;
	return $self->to_string( %kw_args );
}

sub init_valid {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('init_valid');
	my 	( $self )= @_;
	$self->{'_textlogic'}{'message'}= '';
}

sub init_expired {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('init_expired');
	my 	( $self )= @_;
	$self->{'_textlogic'}{'message'}= $Authen::PluggableCaptcha::TextLogic::_DEFAULTS{'message_expired'};
}


###
1;