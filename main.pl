#!/usr/bin/perl -w

use strict;
use warnings;

use Pithub;
use Config::INI::Reader;
use HTML::Entities;
use utf8;
use encoding "utf8";
use Template;
use Scalar::Util qw(looks_like_number);
use POSIX qw(LONG_MAX);

# github user whose repositories to list.
# username value from config.ini overrides this.
my $username = 'nordicway';

# 0 to hide private repos, 1 to show them.
# TODO make this work and test it with a private Github account.
my $include_private_repos = 0;

# template file location
my $template_file = 'templates/template_bootstrap_fancy.tt';

# output file location
my $output_file = 'github.html';

##############################################################################
# End of configuration.                                                      #
# Only change anything below this line if you know what you are doing.       #
##############################################################################

# sort criteria, eg. stargazers_count
my $sort_criteria;

# sort order, 1 for ascending order, 0 for descending order
my $sort_ascending;

# config file location
my $ini_file = 'config.ini';

# 1 to encode entities (default), 0 not to
my $encode_entities = 1;

my $repos = load();
my @ignored_repos;
my @sorted_repos;

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
    	#or if it is on the ignore list.
    	if (
    			#this is actually a "true" string we get back from Github API
    			($row->{private} eq "true" and $include_private_repos == 0 ) or
    			( is_ignored($row->{name}) )
    		) {
    		next;
    	}
    	
    	#get repo information from API and add them to the existing entries
    	#from config.ini .
    	my %repo = get_repo($row);
    	foreach my $key(keys %repo) {
    		$repos->{ $row->{name} }->{$key} = %repo->{$key};
    	}
    }

sort_repos();
output(\@sorted_repos);
print "done. see " . $output_file;

# load configuration from config file
sub load {
	my $read = Config::INI::Reader->read_file($ini_file);
	
	$username = $read->{_}->{username};
	$sort_criteria = $read->{_}->{sort_criteria} || "stars";
	if ($sort_criteria eq "manual") {
		#enforce sort order to be ascending when sorting manually
		$sort_ascending = 1;
	} else {
		$sort_ascending = $read->{_}->{sort_ascending} || 0;
	}
	
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

	#fill with attributes that cannot be taken from API.
	#this is mainly for backward compatibility (eg. stars) and internal logic
	#(manual order).
	my %repo = (
			manual => existing_or_new($name, 'order', ( $row->{order} || LONG_MAX ) ),
    		stars => existing_or_new($name, 'stargazers_count', $row->{stargazers_count}),
    		watchers => existing_or_new($name, 'watchers_count', $row->{watchers_count}),
    		forks => existing_or_new($name, 'forks_count', $row->{forks_count})
    	);
    
    #inherit all incoming values from API
	foreach my $key(keys $row) {
		$repo{$key} = existing_or_new($name, $key, $row->{$key}); 
	}
	
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
	
	# return HTML encoded entities based on user setting
	if ($encode_entities) {
		return encode_entities($ret_val);
	} else {
		return $ret_val;
	}
}

# check if a repository with this name is on the ignore list
sub is_ignored {
	my $name = shift;
	return grep( /^$name$/, @ignored_repos );
}

# sort all repos
sub sort_repos {
    foreach my $sorted_repo (
        sort sort_algo keys %$repos ) {
    		push(@sorted_repos, $$repos{$sorted_repo});
	}
	if ($sort_ascending  == 0) {
		@sorted_repos = reverse @sorted_repos;
	}
}

# numeric sort if both values are numbers, alphanumeric otherwise.
sub sort_algo {
	my $attribute = $sort_criteria;
	
	my $val1 = $$repos{$a}->{$attribute};
	my $val2 = $$repos{$b}->{$attribute};
	
	if (looks_like_number($val1) and looks_like_number($val2)) {
		return $val1 <=> $val2;
	} else {
		return $val1 cmp $val2;
	}
}

# writes formatted repository information to output file using the given
# template
sub output {
	my $var = shift;
	my $tt = Template->new({
    INTERPOLATE  => 1,
	}) or die "$Template::ERROR\n";

	my $tt_vars = {
		repos => $var,
		username => $username
	};
	
	$tt->process($template_file, $tt_vars, $output_file) or die $tt->error(), "\n";
}