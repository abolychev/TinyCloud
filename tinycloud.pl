#!/usr/bin/env perl
use utf8;
use Modern::Perl;
use Mojolicious::Lite;
use Data::Dumper;

# Increase limit to 1GB
$ENV{MOJO_MAX_MESSAGE_SIZE} = 10737418240;

@{app->static->paths} = ('.');

# Route with placeholder
any '/' => sub {
	shift->redirect_to('disk');
} => 'home';
any '/disk/(*ppath)' => { ppath => '.' } => sub {
	listDir(shift);
} => 'disk';

sub listDir {
	my $self = shift;
	my $path  = $self->param('ppath');
	
	#$path =~ s/^\///;
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
			next if /^\.$/ or /^\.\.$/;
			if( -f "$some_dir/$_" ) { push @files, "$_" }
			elsif( -d "$some_dir/$_" ) { push @dirs, "$_" }
		}
		closedir $dh;
		#say Dumper(\@dirs);
		$self->stash( files => \@files );
		$self->stash( dirs => \@dirs );
		$self->render('index');
	} else { 
		$self->render( text => "bad req")
	}
}



# Multipart upload handler
sub uploadSub {
	my $self = shift;
	 
	# Check file size
	return $self->render(text => 'File is too big.', status => 200)
		if $self->req->is_limit_exceeded;
	 
	for my $file ( $self->req->upload('files') )
	{
		my $path = $self->param('ppath');
		my $size = $file->size;
		my $name = $file->filename;
		$name = checkFile($path, $name);
		$file->move_to("$path/$name");
		$self->flash(message => "Thanks for uploading $size byte file $name.");
	}
	
}; 

sub checkFile {
	my ($path, $name) = @_;
	if( -e "$path/$name" ) {
		say __FILE__ . " exists $name";
		return checkFile($path, $name . '_' );
	}
	return $name;
}

# Start the Mojolicious command system
app->start('daemon', '-l', 'http://*:3000');

__DATA__

@@ home.html.ep
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
 </body>
</html>

 
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

% if (my $msg = flash 'message') {
  <b><%= $msg %></b><br>
% }

<a href="<%= url_for 'disk', ppath => '' %>">Home</a>
% my $pp = ''; for my $p  (split '/', $ppath) { 
 / <a href="<%= url_for 'disk', ppath => "$pp$p" %>"><%= "$p" %></a> 
%	$pp.="$p/"; }

 
 <br>
 Dirs:<br>
 <ul>
% for my $file (sort @$dirs) {
  <li><a href="<%= url_for 'disk', ppath => "$ppath/$file" %>"> <%= $file %> </a></li>
% }
</ul>

Files:<br>
<ul>
% for my $file (sort @$files) {
  <li><a href="<%= url_for 'disk', ppath => "$ppath/$file" %>"> <%= $file %> </a></li>
% }
</ul>

Upload to <%= $ppath %><br>
    %= form_for '' => (enctype => 'multipart/form-data') => (method => 'POST') => begin
      %= file_field 'files', multiple => "multiple"
      %= submit_button 'Upload'
    % end
  
 </body>
</html>
