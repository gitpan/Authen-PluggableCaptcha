=head1 NAME

Authen::PluggableCaptcha::Tutorial - How to use the Captcha System

=head1 Introduction

=head1 Conventions

=head1 TUTORIAL

=head2 Illustrated Steps

=head3 Generate a New Key...

	my 	$captcha= Authen::PluggableCaptcha->new( 
		type=>'new' , 
		seed=> 'a' , 
		site_secret=> 'z' 
	);
	my 	$captcha_publickey= $captcha->get_publickey();

=head3 Generate a JPEG...

	my	$captcha= Authen::PluggableCaptcha->new( 
		type=> 'existing' , 
		publickey=> $captcha_publickey, 
		seed=> 'a' , 
		site_secret=> 'z' 
	);

	my $as_string= $captcha->render( 
		challenge=> 'Authen::PluggableCaptcha::Challenge::TypeString', 
		render=>'Authen::PluggableCaptcha::Render::Image::Imager' ,  
		font_filename=> '/usr/X11R6/lib/X11/fonts/TTF/VeraMoIt.ttf',
		format=>'jpeg' 
	);
	
	# serve it directly, or write it
		open(WRITE, ">/path/to/dest.jpg");
		print WRITE $as_string;
		close(WRITE);

=head3 Generate an obfuscated HTML item...

again, create a new object

	my	$captcha= Authen::PluggableCaptcha->new( 
			type=> 'existing' , 
			publickey=> $captcha_publickey, 
			seed=> 'a' , 
			site_secret=> 'z' 
		);

render it

	my 	$as_string= $captcha->render( 
			challenge=> 'Authen::PluggableCaptcha::Challenge::DoMath', 
			render=>'Authen::PluggableCaptcha::Render::Text::HTML' 
		);

now you can serve it directly, or write it-- its just html text.  

note: if you put it into Tal or some other formats, it must be marked as a 'structure'

alternately, you could render with Authen::PluggableCaptcha::Render::Text::Plain, which does no obfuscation (bad! bad! bad!)

	open(WRITE, ">/path/to/dest.html");
	print WRITE $as_string;
	close(WRITE);

=head3 test an existing captcha for validation

create an object

	my 	$captcha= Authen::PluggableCaptcha->new( 
		type=> 'existing' , 
		publickey=> $captcha_publickey, 
		seed=> 'a' , 
		site_secret=> 'z' 
	);

run the validation 1x through, just so we get the vars set up and can pull the correct_response for the success

	my 	$i_doubt_this_will_work= $captcha->validate_response( 
			challenge=> 'Authen::PluggableCaptcha::Challenge::TypeString' , 
			user_response=>'a' 
		) ? "yes" : "no" ;

then we can toss in the correct response

	my 	$success= $captcha->validate_response( 
			challenge=> 'Authen::PluggableCaptcha::Challenge::TypeString' , 
			user_response=>$captcha->{'__Challenge'}{'Authen::PluggableCaptcha::Challenge::TypeString'}{'correct_response'} 
		) ? "yes" : "no" ;

=head2 A real-world implementation

Originally Authen::PluggableCaptcha was designed for use in mod_perl under a clustered environment

This is how it is currently implemented on FindMeOn.com and RoadSound.com ( June 2006 ) 

=head3 Create a general Captcha init function in a webapp utility library

	sub CAPTCHA_init {
		my 	( $pageObject , $sectionName , $overrideFlag )= @_;
	
		# pageObject- context object that includes access to session , account, and libapreq
		# sectionName- the name of the what is requesting a captcha.  ie, your registration page would want to say 'registration', or a general auth page would say 'auth'
		#	this is used to create a seed, so the user doesn't get an identical captcha on each page
		# overrideFlag- bool value to force a re-init of the captcha
	
		if ( $pageObject->{'CaptchaInstance'} && !$overrideFlag ) {
			return;
		}
	
		# the seed for the captcha is a hash of the sectionName and the user's session_id
		my 	$seed= md5_hex( $sectionName . '|' . $pageObject->{'PageUser'}->get_session_id() );
		
		# we set/store the publickey to the captcha in the session.  we could show it to people, but honestly we do it like this because store/retrieve is easier than generating/validating every damn time
		my 	$captcha_key= $pageObject->{'PageUser'}->get_session_stored("captcha_publickey__${sectionName}");
	
		my 	$captcha;
		if 	( $captcha_key ) {
			$captcha= Authen::PluggableCaptcha->new( 
				type=> 'existing' , 
				site_secret=> $FindMeOn::Config::site_secret , 
				seed=> $seed ,
				publickey=> $captcha_key,
			);
			if ( $captcha->is_invalid() ) {
				$captcha_key= undef;
				$pageObject->{'_CaptchaInvalid'}= 1;
			} 
			if ( $captcha->is_expired() ) {
				$pageObject->{'_CaptchaExpired'}= 1;
				$captcha_key= undef;
			} 
		}
	
		if 	( !$captcha_key ) {
			$captcha= Authen::PluggableCaptcha->new( 
				type=> 'new' , 
				site_secret=> $FindMeOn::Config::site_secret , 
				seed=> $seed ,
			);
			$captcha_key= $captcha->get_publickey() or die "Error";
			$pageObject->{'PageUser'}->set_session_stored("captcha_publickey__${sectionName}",$captcha_key);
			$captcha= Authen::PluggableCaptcha->new( 
				type=> 'existing' , 
				site_secret=> $FindMeOn::Config::site_secret , 
				seed=> $seed ,
				publickey=> $captcha_key,
			);
		}
		$pageObject->{'CaptchaInstance'}= $captcha;
	}

=head3 Configure page views to intialize Captchas as needed 

a page that displays / verifies captchas just calls:

	&CAPTCHA_init( $self , 'registration', 1 );
	
if you didn't read the section above on what CAPTCHA_init does, you should

the cliffnotes are this though:
	
	$self= a page object that contains a context object with access to the session and libapreq functions
	'registration'= the name of the page used in creating a public_key seed ( this way register and confirm pages don't have the same captcha )
	1= an override flag, that forces the captcha object to be reset, as sometimes we cache objects
	

=head3 Show the captcha

make sure we called the init already 

to show a text captcha, we can render this directly into a Petal document

	%PetalPersonalizedHash= (
		'Captcha'=> {
			instructions=> undef,
			user_prompt=> $self->{'CaptchaInstance'}->render( 
				challenge=> 'Authen::PluggableCaptcha::Challenge::DoMath', 
				render=>'Authen::PluggableCaptcha:::Render::Text::HTML' 
			),
		},
	);

=head3 Validate the captcha

make sure we called the init already 

	if 	(
			!$self->{'CaptchaInstance'}->validate_response(
				challenge=> 'Authen::PluggableCaptcha::Challenge::DoMath',
				user_response=> $self->{'Form'}->get_validated('captcha_response'),
			)
		) {
		$self->{'Form'}->set_error('captcha_response','That answer is not correct, please try again');
		return $self->FORM_print();
	}
	else {
		# we're valid!
	}

=head3 So you want to diplay an image Dynamically?

first print the img block on a page that called Captcha Init

	my 	$captcha_embed= "<img src="/path/to/captcha/handler?section=registration" />";

then set up a sub / handler to generate the captcha on a url mapping

in this example, the captcha generator is in a central location -- /service/captcha/ -- so we supply the section name as a query arg.  
if the captcha generator were locked into a page, then you could just hardcode the section name
	
	sub render_image {
		my 	( $self )= @_ ;
	
		my 	$sectionName= $self->{'PageUser'}{'ApacheRequest'}->param('section');
	
		#initialize the captcha
		&FindMeOn::Functions::Misc::CAPTCHA_init( $self , $sectionName );
	
		$self->{'PageUser'}{'ApacheRequest'}->content_type('image/jpeg');
		$self->{'__BODY'}= $self->{'CaptchaInstance'}->render( 
			challenge=> 'Authen::PluggableCaptcha::Challenge::TypeString', 
			render=>'Authen::PluggableCaptcha::Render::Image::Imager' ,  
			font_filename=> '/usr/X11R6/lib/X11/fonts/TTF/VeraMoIt.ttf',
			format=>'jpeg' 
		);
		
		return;
	}

=head2 That's it!

yep.  sweet.


=head1 SUPPORT

=head1 AUTHOR

Jonathan Vanasco , cpan@2xlp.com

=head1 COPYRIGHT

Copyright (c) 2006 by Jonathan Vanasco.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.