#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Challenge
# Copyright(c) 2006, Jonathan Vanasco (cpan@2xlp.com)
# Distribute under the Artistic License
#
#############################################################################

use strict;

package Authen::PluggableCaptcha::Challenge;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';
our @ISA= qw( Authen::PluggableCaptcha::ErrorLoggingObject );

#############################################################################

=pod

=head1 NAME

Authen::PluggableCaptcha::Challenge

=head1 DESCRIPTION
This is the base class for generating a captcha challenge

captcha challenges must support the following methods

  ->new( keygenerator_instance=> $keygenerator_instance );
  ->validate( user_response=> $user_response );
     validate must return 1 or 0

there are 3 public variables that must be available to other modules

  'instructions'
    what a user should do
  'user_prompt'
    what to prompt the user with
    this will be rendered by the render engine
    for image/audio this is probably the same as correct_response
  'correct_response'
    the repsonse
		
Example:
	Image Authen::PluggableCaptcha:
		instructions: type in the letters you see
		user_prompt: abcdef
		correct_response: abcdef
	
	Text Logic Authen::PluggableCaptcha:
		instructions: do this math problem
		user_prompt: what is 12 divided by 1 ?
		correct_response: 12

=cut

###
1;