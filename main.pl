#!/usr/bin/perl -w

use strict;
use warnings;

use Pithub;
use Config::INI::Reader;
use HTML::Entities;
use utf8;
use encoding "utf8";
use Template;

# github user whose repositories to list
my $username = 'nordicway';

# 0 to hide private repos, 1 to show them
my $include_private_repos = 0;

# config file location
my $ini_file = 'config.ini';

# template file location
my $template_file = 'template.tt';

# output file location
my $output_file = 'github.html';

my $repos = load();
my @ignored_repos;

# list all repos of $username
my $p = Pithub->new;
my $q_repos  = Pithub::Repos->new;
my $result = $q_repos->list( user => $username );
$result->auto_pagination(1);
    while ( my $row = $result->next ) {
    	
    	#check if we run into API block, eg. due to Github rate limiting
    	if (exists $row->{message}) {
    		die "error from Github API: " . $row->{message};
    	}
    	
    	#skip repo if private and we do not want private repos to show
    	#or if it is on the ignore list
    	if (
    			($row->{private} eq "true" and $include_private_repos == 0 ) or
    			( is_ignored($row->{name}) )
    		) {
    		next;
    	}
    	
    	my %repo = get_repo($row);
    	$repos->{ $row->{name} } = \%repo;
    }
output($repos);

# load configuration from config file
sub load {
	my $read = Config::INI::Reader->read_file($ini_file);
	
	$username = $read->{_}->{username};
	
	# set ignored repos explicitly because underscore variables are private
	# in Template Toolkit
	my $repo_skip = $read->{_}->{skip};
	
	delete $read->{_};
	$repo_skip =~ s/\s//g;
	@ignored_repos = split(',', $repo_skip);
	foreach my $ignored (@ignored_repos) {
		delete $read->{$ignored};
	}
	return $read;
}

# returns a repository hash from API repo information
sub get_repo {
	my $row = shift;
	my $name = $row->{name};
	# TODO allow custom attributes from config file to be inserted and/or
	# inherit all incoming values from API
	my %repo = (
    		name => existing_or_new($name, 'name', $row->{name}),
    		description => existing_or_new($name, 'description', $row->{description}),
    		stars => existing_or_new($name, 'stargazers_count', $row->{stargazers_count}),
    		watchers => existing_or_new($name, 'watchers_count', $row->{watchers_count}),
    		forks => existing_or_new($name, 'forks_count', $row->{forks_count}),
    		language => existing_or_new($name, 'language', $row->{language}),
    		url => existing_or_new($name, 'html_url', $row->{html_url})
    	);
    return %repo;
}

# returns the attribute from config file if it exists.
# returns the attribute from Github API otherwise.
# this allows you to overwrite attributes via config file.
sub existing_or_new {
	my $name = shift;
	my $attribute = shift;
	my $value = shift;
	my $ret_val;
	
	if (my $from_ini = $repos->{$name}->{$attribute} ) {
		$ret_val = $from_ini;
	} else {
		$ret_val = $value;
	}
	# return HTML encoded entities so we can print them properly
	return encode_entities($ret_val);
}

# check if a repository with this name is on the ignore list
sub is_ignored {
	my $name = shift;
	return grep( /^$name$/, @ignored_repos );
}

# writes formatted repository information to output file using the given
# template
sub output {
	my $var = shift;
	my $tt = Template->new({
    INTERPOLATE  => 1,
	}) or die "$Template::ERROR\n";

	my $tt_vars = {
		repos => $var
	};
	
	$tt->process($template_file, $tt_vars, $output_file) or die $tt->error(), "\n";
}