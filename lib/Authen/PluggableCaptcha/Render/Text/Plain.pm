#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Render::Text::Plain
#
######################################################

use strict;

package Authen::PluggableCaptcha::Render::Text::Plain;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';
use Authen::PluggableCaptcha::Render::Text;
our @ISA= qw( Authen::PluggableCaptcha::Render::Text );

######################################################

######################################################

# constructor
sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );

		# init the base class
		$self->_init_render( \%kw_args );

		# do the subclass init
		$self->_init( \%kw_args );
	return $self;
}

sub _init {
	Authen::PluggableCaptcha::DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('_init');
	my  ( $self , $kw_args__ref )= @_;
	$self->{'rendered'}= 0;
}

sub to_string {
=pod
get the object object as a string
=cut
	my 	( $self , %kw_args )= @_;
	return $self->{'challenge_instance'}->{'instructions'} . " : " . $self->{'challenge_instance'}->{'user_prompt'};
}


###
1;