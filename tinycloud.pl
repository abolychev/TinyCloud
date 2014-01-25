#!/usr/bin/env perl
use utf8;
use Modern::Perl;
use Mojolicious::Lite;
use Data::Dumper;

# Increase limit to 1GB
$ENV{MOJO_MAX_MESSAGE_SIZE} = 1073741824;

@{app->static->paths} = ('.');



sub listDir {
	my $self = shift;
	my $path  = $self->param('ppath');
	$path = '.' if $path eq '';
	
	
	if($self->req->method eq 'POST') {
		uploadSub($self);
	}	
	
	
	$self->stash( ppath => $path );
	say __LINE__ . $path;
	if( -f $path ) {
		say 'file';
		$self->render_static($path);
	} elsif( -d $path ) 
	{
  		say __LINE__ . ' dir';
		my $some_dir = $path; #'.';
		opendir(my $dh, $some_dir) || $self->render( text => "can't opendir $some_dir: $!") && return;
		my @files = ();
		my @dirs = ();
		while(readdir $dh) {
			utf8::decode($_);
			if( -f "$some_dir/$_" ) { push @files, "$some_dir/$_" }
			elsif( -d "$some_dir/$_" ) { push @dirs, "$some_dir/$_" }
		}
		closedir $dh;
		say Dumper(\@dirs);
		$self->stash( files => \@files );
		$self->stash( dirs => \@dirs );
		$self->render('index');
	} else { 
		$self->render( text => "bad req")
	}
}

# Route with placeholder
any '/' => sub {
	listDir(shift);
};
any '/*ppath' => sub {
	listDir(shift);
};

# Multipart upload handler
sub uploadSub {
	my $self = shift;
	 
	# Check file size
	return $self->render(text => 'File is too big.', status => 200)
		if $self->req->is_limit_exceeded;
	 
	# Process uploaded file
	return unless my $example = $self->param('example');
	my $path = $self->param('ppath');
	my $size = $example->size;
	my $name = $example->filename;
	$name = checkFile($path, $name);
	$example->move_to("$path/$name");
	$self->render(text => "Thanks for uploading $size byte file $name.");
}; 

sub checkFile {
	my ($path, $name) = @_;
	if( -f "$path/$name" ) {
		say __FILE__ . " exists $name";
		return checkFile($path, $name . '_' );
	}
	return $name;
}

# Start the Mojolicious command system
app->start;

__DATA__
 
@@ index.html.ep
<!DOCTYPE html>
<html>
 <head>
  <meta charset="utf-8">
  <title>Tiny Cloud</title>
  <style>
  p { color:  navy; }
  </style>
 </head>
 <body>
 Dirs:<br>
 <ul>
% for my $file (@$dirs) {
  <li><a href="<%= $file %>"> <%= $file %> </a></li>
% }
</ul>

Files:<br>
<ul>
% for my $file (@$files) {
  <li><a href="<%= $file %>"> <%= $file %> </a></li>
% }
</ul>

Upload to <%= $ppath %><br>
    %= form_for '' => (enctype => 'multipart/form-data') => (method => 'POST') => begin
      %= file_field 'example'
      %= submit_button 'Upload'
    % end
  
 </body>
</html>
