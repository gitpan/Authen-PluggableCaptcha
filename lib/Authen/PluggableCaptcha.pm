#!/usr/bin/perl
#
#############################################################################
# Authen::PluggableCaptcha
# Pluggable Captcha system for perl
# Copyright(c) 2006, Jonathan Vanasco (cpan@2xlp.com)
# Distribute under the Perl Artistic License
#
#############################################################################

=head1 NAME

Authen::PluggableCaptcha - A pluggable Captcha system for Perl

=head1 SYNOPSIS

  use Authen::PluggableCaptcha;
  use Authen::PluggableCaptcha::Challenge::TypeString;
  use Authen::PluggableCaptcha::Render::Image::Imager;

  # create a new captcha for your form
  my $captcha= Authen::PluggableCaptcha->new( 
    type=> "new", 
    seed=> $session->user->seed , 
    site_secret=> $MyApp::Config::site_secret 
  );
  my $captcha_publickey= $captcha->get_publickey();
  
  # image captcha?  create an html link to your captcha script with the public key
  my $html= qq|<img src="/path/to/captcha.pl?captcha_publickey=${captcha_publickey}"/>|;
  
  # image captcha?  render it
  my $existing_publickey= 'a33d8ce53691848ee1096061dfdd4639_1149624525';
  my $existing_publickey = $apr->param('captcha_publickey');
  my $captcha= Authen::PluggableCaptcha->new( 
    type=> 'existing' , 
    publickey=> $existing_publickey , 
    seed=> $session->user->seed , 
    site_secret=> $MyApp::Config::site_secret 
  );

  # save it as a file
  my $as_string= $captcha->render( 
    challenge=> 'Authen::PluggableCaptcha::Challenge::TypeString', 
    render=>'Authen::PluggableCaptcha::Render::Image::Imager' ,  
    format=>'jpeg' 
  );
  open(WRITE, ">test.jpg");
  print WRITE $as_string;
  close(WRITE);

  # or serve it yourself
  $r->add_header('Content Type: image/jpeg');
  $r->print( $as_string );
  
  # wait, what if we want to validate the captcha first?
  my $captcha= Authen::PluggableCaptcha->new( 
    type=> 'existing' , 
    publickey=> $apr->param('captcha_publickey'), 
    seed=> $session->user->seed , 
    site_secret= $MyApp::Config::site_secret 
  );
  if ( !$captcha->validate_response( user_response=> $apr->param('captcha_response') ) ) {
	  my $reason= $captcha->get_error('validate_response');
	  die "could not validate captcha because: ${reason}.";
  };

in the above example, $captcha->new just configures the captcha.  $captcha->render actually renders the image.
if the captcha is expired (too old by the default configuration) , the default expired captcha  routine from the plugin will take place
better yet, handle all the timely and ip/request validation in the application logic.  the timeliness just makes someone answer a captcha 1x every 5minutes, but doesn't prevent re/mis use

render accepts a 'render' argument that will internally handle a dispatcher funciton.  this way one could create a image sound and text logic rendering for the same public key

=head1 DESCRIPTION

Authen::PluggableCaptcha is a fully modularized and extensible system for making Pluggable Catpcha (Completely Automated Public Turing Test to Tell Computers and Humans Apart) tests.

Pluggable?  All Captcha objects are instantiated and interfaced via the main module, and then manipulated to require various submodules as plug-ins.

Authen::PluggableCaptcha borrows from the functionality in Apache::Session::Flex

=head2 The Base Modules:

=head3 KeyGenerator

  Generates and parses publickeys which are used to validate and create captchas
  Default is Authen::PluggableCaptcha::KeyGenerator , which makes a key %md5%_%time%

=head3 KeyValidator

  User supplied class to validate a publickey.  
  This can contain a regex or a bunch of DB interaction stuff to ensure a key is used only one time per ip address
  Default is Authen::PluggableCaptcha::KeyValidator , which just returns true.

=head3 Challenge

  simply put, a challenge is a test.  
  challenges internally require a ref to a keygenerator instance , it then maps that instance via it's own facilities into a test to render or validate
  a challege generates 3 bits of text: 
	instructions
	user_prompt
	correct_response

  a visual captcha would have user_prompt and correct_response as the same.  
  a text logic puzzle would not.

=head3 Render

  the rendering of a captcha for presentation to a user.
  This could be an image, sound, block of (obfuscated?) html or just plain text

=head1 Reasoning (reinventing the wheel)

Current CPAN captcha modules all exhibit one or more of the following traits:

=over

=item -
the module is tied heavily into a given image rendering library

=item -
the module only supports a single style of an image Catpcha

=item -
the module renders/saves the image to disk

=back

I wanted a module that works in a clustered environment, could be easily extended / implemented with the following design requirements:

=over

=item 1
challenges are presented by a public_key

=item 2
a seed (sessionID ?) + a server key (siteSecret) hash together to create a public key

=item 3
the public_key is handled by its own module which can be subclassed as long as it provides the required methods

=back

with this method, generating a public key 'your own way' is very easy, so the module integrates easily into your app

furthermore:

=over

=item *
the public_key creates a captcha test / challenge ( instructions , user_prompt , correct_repsonse ) for presentation or validation

=over

=item -
the captcha test is handled by its own module which can be subclassed as long as it provides the required methods

=item -
    want to upgrade a test? its right there

=item -
    want a private test?  create a new subclass

=item -
    want to add tests to cpan?  please do!

=back

=item *
the rendering is then handled by its own module which can be subclassed as long as it provides the required methods

=item *
the rendering doesn't just render a jpg for a visual captcha... the captcha challenge can then be rendered in any format

=over

=item -
image

=item -
audio

=item -
text

=back

=back

any single component can be extended or replaced - that means you can cheaply/easily/quickly create new captchas as older ones get defeated ( instead of going crazy trying to make the worlds best captcha)
everything is standardized and made for modular interaction
since the public_key maps to a captcha test, the same key can create an image/audio/text captcha, 

Note that Render::Image is never called - it is just a base class.
The module ships with Render::Img::Imager, which uses the Imager library.  Its admittedly not very good- just a proof-of-concept.

want gd/imagemagick?  write Render::Img::GD or Render::Image::ImageMagick with the appropriate hooks (and submit to CPAN!)

This is so that you don't need to run GD on your box if you've got a mod_perl setup that is trying to be lean and already uses Imager
Using any of the image libraries should be a snap- just write a render function that can create an image with 'user_prompt' text, and returns 'as_string'
Using any of the audio libraries works in the same manner too.

Initial support includes the ability to have Textual logic Catptchas.  They do silly things like say "What is one plus one ? (as text in english)" 
HTML::Email::Obfuscate makes it hard to scrape, though a better solution is needed and welcome.

One of the main points of PluggableCaptcha is that even if you create a Captcha that is one step ahead of spammers ( read: assholes ) , they're not giving up -- they're just going to take longer to break the Captcha-- and once they do, you're sweating trying to protect yourself again.  

With PluggableCaptcha, it should be easier to :

=over

=item a-
create new captchas cheaply: make a new logic puzzle , a new way of rendering images , or change the random character builder into something that creates strings that look like words, so people can spell them easier.

=item b-
customize existing captchas: subclass captchas from the distribution , or others people submit to CPAN. create some site specific changes on the way fonts are rendered, etc.

=item c-
constantly change captchas ON THE FLY.  mix and match render and challenge classes.  the only thing that would take much work is swapping from a text to an image.  but 1 line of code controls what is in the image, or how to solve it!

=back

Under this system, ideally, people can change / adapt / update so fast , that spammers never get a break in their efforts to break captcha schemes!


=head1 BUGS/TODO

This is an initial alpha release.  

There are a host of issues with it.  Most are discussed here:

To Do:

	priority | task
	++ | Imager does not have facilities right now to do a 'sine warp' easily.  figure some sort of text warping for the imager module.
	++ | Port the rendering portions of cpan gd/imagemagick captchas to Img::(GD|ImageMagick)
	++ | clean up how stuff is stored / passed around / accessing defaults.  there's a lot of messy stuff with in regards to passing around default values and redundancy of vars
	++ | Img::Imager make the default font more of a default
	++ | Img::Imager add in support to render each letter seperately w/a different font/size
	+  | Img::Imager better handle as_string/save + support for png format etc
	+  | create a better way to make attributes shared stored and accessed
	-- | add a sound plugin ( text-logic might render that a trivial enhancement depending on how obfuscation treats display )
	-  | is there a way to make the default font more cross platform?

=head1 REFERENCES

Many ideas , most notably the approach to creating layered images, came from PyCaptcha , http://svn.navi.cx/misc/trunk/pycaptcha/

=head1 AUTHOR

Jonathan Vanasco , cpan@2xlp.com

Patches, support, features, additional etc

	Kjetil Kjernsmo, kjetilk@cpan.org


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jonathan Vanasco

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#############################################################################
#head

package Authen::PluggableCaptcha;

use strict;
use vars qw(@ISA $VERSION);

use Authen::PluggableCaptcha::ErrorLoggingObject;

$VERSION= '0.01';
@ISA= qw( Authen::PluggableCaptcha::ErrorLoggingObject );

#############################################################################
#use modules

use Authen::PluggableCaptcha::KeyGenerator;
use Authen::PluggableCaptcha::KeyValidator;
use Authen::PluggableCaptcha::Render;

#############################################################################
#use constants

use constant DEBUG_FUNCTION_NAME=> 0;
use constant BENCH_RENDER=> 0;

#############################################################################
#defined variables

our %_DEFAULTS= (
	time_expiry=> 300,
	time_expiry_future=> 30,
);

our %_types= (
	'existing'=> 1,
	'new'=> 1
);


#############################################################################
#begin
BEGIN {
	if ( BENCH_RENDER ) {
		use Time::HiRes();
	}
};

#############################################################################
#subs

# constructor
sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );

	# make sure we have the requisite kw_args
	my 	@_requires= qw( type seed site_secret );
	&Authen::PluggableCaptcha::_check_requires( 
		kw_args__ref=> \%kw_args,
		error_message=> "Missing required element '%s' in new",
		requires_array__ref=> \@_requires
	);

	if ( !$_types{$kw_args{'type'}} ) {
		die "invalid type";
	}

		$self->__init_base_captcha( \%kw_args );
	return $self;
}

sub __init_base_captcha {
=pod
	base captcha initialization
=cut
	my  ( $self , $kw_args__ref )= @_;
	DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__init_base_captcha');
	$self->__init_errors(); # re- ErrorLoggingObject 
	$self->{'time_now'}= time();
	$self->{'seed'}= $$kw_args__ref{'seed'};
	$self->{'site_secret'}= $$kw_args__ref{'site_secret'};
	$self->{'time_expiry'}= $$kw_args__ref{'time_expiry'} || $Authen::PluggableCaptcha::_DEFAULTS{'time_expiry'};
	$self->{'time_expiry_future'}= $$kw_args__ref{'time_expiry_future'} || $Authen::PluggableCaptcha::_DEFAULTS{'time_expiry_future'};

	$self->{'keygenerator_class'}= $$kw_args__ref{'keygenerator_class'} || 'Authen::PluggableCaptcha::KeyGenerator';
	unless ( $self->{'keygenerator_class'}->can('generate_publickey') ) {
		eval "require $self->{'keygenerator_class'}" || die $@ ;
	}

	$self->{'keyvalidator_class'}= $$kw_args__ref{'keyvalidator_class'} || 'Authen::PluggableCaptcha::KeyValidator';
	unless ( $self->{'keyvalidator_class'}->can('validate_publickey') ) {
		eval "require $self->{'keyvalidator_class'}" || die $@ ;
	}
	$self->{'keyvalidator_instance'}= $self->{'keyvalidator_class'}->new();

	$self->{'__did_init'}= {};
	$self->{'__Render'}= {};
	$self->{'__Challenge'}= {};

	if ( $$kw_args__ref{'type'} eq 'existing' ) {
		$self->{'__type'}= 'existing';
		$self->__init_existing( $kw_args__ref );
	}
	else {
		$self->{'__type'}= 'new';
		$self->__init_new( $kw_args__ref );
	}
}

sub __init_existing {
=pod
existing captcha specific inits
=cut
	my 	( $self , $kw_args__ref )= @_;
	DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__init_existing');
	if ( ! $$kw_args__ref{'publickey'} ) {
		die "'publickey' must be supplied during init";
	}
	$self->{'publickey'}= $$kw_args__ref{'publickey'};
	$self->{'keygenerator_instance'}= $self->{'keygenerator_class'}->new( 
		time_now=> $self->{'time_now'} , 
		time_expiry=> $self->{'time_expiry'} , 
		time_expiry_future=> $self->{'time_expiry_future'} , 
		seed=> $self->{'seed'} , 
		site_secret=> $self->{'site_secret'} 
	) or die "Could not create keygenerator";
	if ( !$self->{'keygenerator_instance'}->init_existing( publickey=> $$kw_args__ref{'publickey'} ) ) {
		$self->{'keygenerator_instance'}->{'ACCEPTABLE_ERROR'} or die "Could not init_existing on keygen";
	}
	if ( $self->{'keygenerator_instance'}->{'EXPIRED'} ) {
		$self->{'EXPIRED'}= 1;
		return 0;
	}
	if ( $self->{'keygenerator_instance'}->{'INVALID'} ) {
		$self->{'INVALID'}= 1;
		return 0;
	}
	$self->{'__did_init'}{'existing'}= 1;
	return 1;
}

sub __init_new {
=pod
new captcha specific inits
=cut
	my 	( $self , $kw_args__ref )= @_;
	DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__init_new');
	$self->{'keygenerator_instance'}= $self->{'keygenerator_class'}->new( 
		time_now=> $self->{'time_now'} , 
		time_expiry=> $self->{'time_expiry'} , 
		time_expiry_future=> $self->{'time_expiry_future'} , 
		seed=> $self->{'seed'} , 
		site_secret=> $self->{'site_secret'} 
	) or die "Could not create keygenerator";
	$self->{'keygenerator_instance'}->generate_publickey() or die "Could not generate_publickey on keygen";
	$self->{'__did_init'}{'new'}= 1;
	return 1;
}


sub _check_requires {
	my 	( %args )= @_;

	# make sure we were called with the requisite args
	my 	@check_requireds= qw( kw_args__ref requires_array__ref error_message );
	foreach my $check_required ( @check_requireds ) {
		if ( !$args{ $check_required } ) {
			die "Missing required element in _check_requires";
		}
	}

	# then check to make sure we have the right args
	foreach my $required ( @{$args{'requires_array__ref'}} ) {
		if ( ! defined $args{'kw_args__ref'}{$required} ) {
			die ( sprintf( $args{'error_message'} , $required ) );
		}
	}
	return 1;
}

sub __check_invalid {
	my 	( $self , $function )= @_;
	if ( $self->{'INVALID'} ) {
		die "Authen::PluggableCaptcha Invalid , can not '$function'";
	}
}

sub is_valid {
	my 	( $self )= @_;
	return !$self->{'INVALID'};
}

sub is_invalid {
	my 	( $self )= @_;
	return $self->{'INVALID'};
}

sub is_expired {
	my 	( $self )= @_;
	return $self->{'EXPIRED'};
}

sub get_publickey {
=pod
Generates a key that can be used to ( generate a captcha ) or ( validate a captcha )
=cut
	my 	( $self )= @_;
	DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('generate_publickey');

	# die if the captcha is invalid
	$self->__check_invalid('generate_publickey');

	return $self->{'keygenerator_instance'}{'publickey'};
}

sub __validate_key_extended {
=pod
This uses the extended validation module
=cut
	my 	( $self )= @_;
	DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__validate_key_extended');

	# make sure we instantiated as an existing captcha
	if ( $self->{'__type'} ne 'existing' ) {
		die "only 'existing' type can validate";
	}

	my 	$validity= $self->{'keyvalidator_instance'}->validate_publickey( keygenerator_instance=> $self->{'keygenerator_instance'} );
	if ( $self->{'keyvalidator_instance'}->{'EXPIRED'} ) {
		$self->{'EXPIRED'}= 1;
	}
	if ( $self->{'keyvalidator_instance'}->{'INVALID'} ) {
		$self->{'INVALID'}= 1;
	}

	return $validity;
}

sub validate_response {
=pod
Validates a user response against the key/time for this captcha
=cut
	my 	( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('validate_response');

	# die if the captcha is invalid
	$self->__check_invalid('validate_response');
	if ( $self->{'EXPIRED'} ) {
		$self->set_error( 'validate_response' , 'KEY expired' );
		return 0;
	}

	# make sure we instantiated as an existing captcha
	if ( $self->{'__type'} ne 'existing' ) {
		die "only 'existing' type can validate";
	}

	# make sure we have the requisite kw_args
	my 	@_requires= qw( challenge user_response );
	&Authen::PluggableCaptcha::_check_requires( 
		kw_args__ref=> \%kw_args,
		error_message=> "Missing required element '%s' in validate",
		requires_array__ref=> \@_requires
	);


	# then validate the key extended
	if ( !$self->__validate_key_extended() ) {
		$self->set_error( 'validate_response' , $self->get_error('KEY invalid') );
		return 0;
	}


	# then actually validate the captcha

	# generate a challenge if necessary
	$self->_generate_challenge( challenge=>$kw_args{'challenge'} );
	my 	$class_challenge= $kw_args{'challenge'};
	my 	$challenge= $self->{'__Challenge'}{ $class_challenge } ;

	# validate the actual challenge
	if ( !$challenge->validate( user_response=> $kw_args{'user_response'} ) ) {
		$self->set_error('validate_response',"INVALID user_response");
		return 0;
	}

	return 1;
}

sub _generate_challenge {
	my 	( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('_generate_challenge');

	# make sure we instantiated as an existing captcha
	if ( $self->{'__type'} ne 'existing' ) {
		die "only 'existing' type can _generate_challenge";
	}

	# make sure we have the requisite kw_args
	my 	@_requires= qw( challenge );
	&Authen::PluggableCaptcha::_check_requires( 
		kw_args__ref=> \%kw_args,
		error_message=> "Missing required element '%s' in _generate_challenge",
		requires_array__ref=> \@_requires
	);

	my 	$class_challenge= $kw_args{'challenge'};
	unless ( $class_challenge->can('generate_challenge') ) {
		eval "require $class_challenge" || die $@ ;
	}

	# if we haven't created a challege for this output already, do so
	if ( !$self->{'__Challenge'}{ $class_challenge } ){
		# delete the 'challenge' from the kwargs, add a 'class_challenge' and push all of that to the wrapper function
		delete $kw_args{'challenge'};
		$kw_args{'class_challenge'}= $class_challenge;
		$self->__generate_challenge__actual( \%kw_args );
	}
}


sub __generate_challenge__actual {
=pod
	actually generates the challenge for an item and caches internally
=cut
	my 	( $self , $kw_args__ref )= @_;
	DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__generate_challenge__actual');
	if ( !$$kw_args__ref{'class_challenge'} ) {
		die "missing class_challenge in __generate_challenge__actual";
	}

	my 	$class_challenge= $$kw_args__ref{'class_challenge'};
	delete  $$kw_args__ref{'class_challenge'};
	$$kw_args__ref{'keygenerator_instance'}= $self->{'keygenerator_instance'} || die "No keygenerator_instance";

	my 	$challenge= $class_challenge->new( %{$kw_args__ref} );
	$self->{'__Challenge'}{ $class_challenge }= $challenge;
}



sub render {
	my 	( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('render');

	# die if the captcha is invalid
	$self->__check_invalid('render');

	# make sure we instantiated as an existing captcha
	if ( $self->{'__type'} ne 'existing' ) {
		die "only 'existing' type can render";
	}

	# make sure we have the requisite kw_args
	my 	@_requires= qw( render challenge );
	&Authen::PluggableCaptcha::_check_requires( 
		kw_args__ref=> \%kw_args,
		error_message=> "Missing required element '%s' in render",
		requires_array__ref=> \@_requires
	);


	my 	$class_render= $kw_args{'render'};
	unless ( $class_render->can('render') ) {
		eval "require $class_render" || die $@ ;
	}

	# if we haven't rendered for this output already, do so
	if ( !$self->{'__Render'}{ $class_render } ){

		# delete the 'render' from the kwargs, add a 'class_render' and push all of that to the wrapper function
		delete $kw_args{'render'};
		$kw_args{'class_render'}= $class_render;

		# grab a ref to the challenge
		$self->_generate_challenge( challenge=>$kw_args{'challenge'} );
		my 	$class_challenge= $kw_args{'challenge'};
		my 	$challenge_instance= $self->{'__Challenge'}{ $class_challenge } ;

		# supply the necessary refs
		$kw_args{'challenge_instance'}= $challenge_instance;
		$kw_args{'keygenerator_instance'}= $self->{'keygenerator_instance'};
		$self->__render_actual( \%kw_args );
	}
	return $self->{'__Render'}{ $class_render }->as_string();
}


sub __render_actual {
=pod
	actually renders an item and caches internally
=cut
	my 	( $self , $kw_args__ref )= @_;
	DEBUG_FUNCTION_NAME && &Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__render_actual');

	# make sure we have the requisite kw_args
	my 	@_requires= qw( class_render challenge_instance );
	&Authen::PluggableCaptcha::_check_requires( 
		kw_args__ref=> $kw_args__ref,
		error_message=> "Missing required element '%s' in __render_actual",
		requires_array__ref=> \@_requires
	);

	my 	$class_render= $$kw_args__ref{'class_render'};
	delete  $$kw_args__ref{'class_render'};

	BENCH_RENDER && { $self->{'time_to_render'}= Time::HiRes::time() };
	my 	$render= $class_render->new( %{$kw_args__ref} );
	if ( $self->{'EXPIRED'} ){
		$render->init_expired( $kw_args__ref );
	}
	else {
		$render->init_valid( $kw_args__ref );
	}
	$render->render();
	$self->{'__Render'}{ $class_render }= $render;
	BENCH_RENDER && { $self->{'time_to_render'}= Time::HiRes::time()- $self->{'time_to_render'} };
}



#############################################################################
1;
