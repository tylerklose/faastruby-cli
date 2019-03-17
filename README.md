![faastRuby](https://faastruby.io/wp-content/uploads/2019/03/logo-positive.png)

[![Gem Version](https://badge.fury.io/rb/faastruby.svg)](https://badge.fury.io/rb/faastruby)
[![Build Status](https://travis-ci.org/FaaStRuby/faastruby-cli.svg?branch=master)](https://travis-ci.org/FaaStRuby/faastruby-cli)

* Looking for help? [Ask a question](https://meta.stackoverflow.com/questions/ask?tags=faastRuby,Serverless,Ruby,FaaS).

* [Changelog](https://github.com/faastRuby/faastruby-cli/blob/master/CHANGELOG.md)

# faastruby-cli

Local development kit and CLI tool for managing workspaces and functions hosted at [faastRuby](https://faastruby.io).

## What is faastRuby?
faastRuby is a Serverless Software Development Platform for Ruby and Crystal.

* [Documentation](https://faastruby.io/docs/faastruby-local/)

## Try it

Getting up and running is quick and easy:

![Getting up and running](https://s3.amazonaws.com/faastruby/public/create-project.mp4)

1. Install the gem so `faastruby` is available in your terminal

```
~$ gem install faastruby
```

2. Create a new faastRuby project

```
~$ faastruby new-project my-project
+ d ./myproject
+ f ./myproject/project.yml
+ f ./myproject/secrets.yml
+ d ./myproject/functions/root
+ f ./myproject/functions/root/index.html.erb
+ f ./myproject/functions/root/template.rb
+ f ./myproject/functions/root/handler.rb
+ f ./myproject/functions/root/faastruby.yml
+ d ./myproject/functions/catch-all
+ f ./myproject/functions/catch-all/404.html
+ f ./myproject/functions/catch-all/handler.rb
+ f ./myproject/functions/catch-all/faastruby.yml
+ f ./myproject/public/faastruby.yml
+ f ./myproject/.gitignore
Initialized empty Git repository in /Users/DemoUser/myproject/.git/
Project 'myproject' initialized.
Now run:
$ cd myproject
$ faastruby local
```

3. Fire up the local development environment for your new project

```
~$ cd myproject
~/myproject$ faastruby local
Puma starting in single mode...
* Version 3.12.0 (ruby 2.5.3-p105), codename: Llamas in Pajamas
* Min threads: 0, max threads: 32
* Environment: production
* Listening on tcp://0.0.0.0:3000
Use Ctrl-C to stop
2019-03-16 21:09:36 -0300 | Detecting existing functions.
---
2019-03-16 21:09:36 -0300 | Ruby functions: ["lists/pets", "root", "catch-all", "ruby"]
---
2019-03-16 21:09:36 -0300 | Crystal functions: []
---
2019-03-16 21:09:37 -0300 | Listening for changes.
---
```

As you can see, this runs with Ruby only. If you want to run Crystal as well (similar to Ruby, but with types and compiled to run very fast), simply [install Crystal](https://crystal-lang.org/reference/installation/) and start `faastruby local` again.


`faastruby local` is very powerful. When you add a new folder with a `handler.rb` or `handler.cr`, it will automatically be detected. faastRuby will automatically add the configuration for the function so you can jump straight in:

![How to add a new folder and file](https://s3.amazonaws.com/faastruby/public/new-paths.mp4)

Changes to the code will automatically be detected and immediately refreshed for you, making local development easy and comfortable:
[!How to edit files and refresh them in the browser](https://s3.amazonaws.com/faastruby/public/local-file-refresh.mp4)

4. Deploy it to the cloud:

```
~/hello-world$ faastruby deploy
...
* Project URL: https://myproject-stage-abd123.tor1.faast.cloud
```
Now visit that url in the browser!

## faastRuby + Hyperstack = fullstack Ruby apps!

Do you think JavaScript is your only option for the front-end? Think again. [Hyperstack](https://hyperstack.org) is a Ruby DSL, compiled by Opal, bundled by Webpack, powered by React.
