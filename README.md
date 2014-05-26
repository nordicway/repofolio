# repofolio

> repofolio is a tool to generate static HTML with a list of your GitHub
 repositories for use as an open source portfolio on your website.

An output sample can be found here:

<a href="http://www.zielke.it/repofolio/github.html">GitHub portfolio
 example</a>

## Features

- automatically fetches repository information using Github API
- sort your repos by their properties (eg. number of forks)
- skip repositories you don't want to include
- manually add repositories which are not on GitHub
- cross-platform support. Runs on Windows with Strawberry Perl and should run
 under ActivePerl, too.

## Requirements

- Perl 5 with the following modules:
- Pithub
- Config::INI
- Template (Template Toolkit)
- HTML::Parser


## Quick Start

*Make sure that all dependencies are installed on your system, then:*

1. Edit `config.ini` in the application directory and set your GitHub user name

2. Run the script on command line: `perl main.pl`
 
3. Open `github.html` with a browser of your choice


## Configuration

*Any configuration explained here is done by editing `config.ini` *


### Ignore certain repositories

The `skip` parameter takes a comma-seperated list of values. It allows you to
 skip repositories by their name. Skipped repositores will not show up in the
 resulting HTML.

Let's say that you want to skip **college-project1** and **college-project2**
 so your configuration now looks like this:
 
    skip = college-project1, college-project2


### Overwrite attributes of your GitHub repository

*repofolio* automatically fetches your repositories from GitHub and retrieves
 all information from there. You may still edit `config.ini` to overwrite
 certain attributes of your repos.

Let's assume that you have a repository called **red-project**. It has been
 superseeded a long time ago by **blue-project** so you want to express that
 in the name and the description of that repo.
 
To do that, add this to the configuration file:

    [red-project]
    name = Red Project (OBSOLETE as of 12/20/2010)
    description = This repo is only kept online for reference. See blue-project instead!


### Add non-GitHub repositories

You may add new repository entries to the configuration file which will be
 treated as regular repositories, despite not being located in your GitHub
 account.
 
This allows you to add repositories from anywhere. Let's say you have a repo
 called **bitbucket-project** on BitBucket. You may add the following to your 
 configuration file to have it included:
 
    [bitbucket-project]
    name = My Project
    description = lorem ipsum
    html_url = https://bitbucket.org/username/myproject


### Sort repositories

Repositories can be sorted based on a configured behaviour. You may set the
 sort criteria and the sort order (ascending or descending).
 
If you choose not to set a sorting behaviour, it will **default to sorting
 by stargazers descending**.

**Sort criteria**

`sort_criteria` is the repo property to use for sorting. This can be
 anything from the Github API like ***forks***, ***watchers*** or even
 properties with alphanumeric content like ***created_at*** which allow you
 to sort repositories by date.
 
**Sort order**

Sort order is ***descending by default*** but you may set `sort_ascending`
 to ***1*** to enable ascending order.
 
Let's say you want to sort repositories by date of creation with an
 ascending order so that the oldest repos come first. The config file would
 have to look like this:
 
    sort_criteria = created_at
    sort_ascending = 1

**Customized sort sequence (manual mode)**

It is also possible to sort repositories manually. This is a special case that
 takes some time to configure, especially if you have a lot of repositories to
 sort.

To enable manual sorting, change `sort_criteria` to ***manual***.
 
Let's assume that we want **first-repo** to show up before **second-repo**.
 The config file would need to look like this:
 
    sort_criteria = manual
    
    [first-repo]
    order = 1
    
    [second-repo]
    order = 2


## Tweak HTML output

*repofolio* uses Template Toolkit, so you may change the template files
 to your liking.
 
 If you plan to *include()* the resulting file within your own HTML, you can
 go ahead and remove all of the boilerplate before `FOREACH`. This is where
 the actual repository loop starts.
 
 The Template Toolkit docs can be found here:
 http://template-toolkit.org/docs/


## License

Copyright (c) 2014, Bjoern Zielke

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written
agreement is hereby granted, provided that the above copyright notice
and this paragraph and the following two paragraphs appear in all
copies.

IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE TO ANY PARTY FOR DIRECT,
INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
DOCUMENTATION, EVEN IF THE AUTHOR OR CONTRIBUTORS HAVE BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

THE AUTHOR OR CONTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING, BUT
NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS
IS" BASIS, AND THE AUTHOR OR CONTRIBUTORS HAVE NO OBLIGATIONS TO PROVIDE
MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.