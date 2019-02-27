[![Gem Version](https://badge.fury.io/rb/faastruby.svg)](https://badge.fury.io/rb/faastruby)
[![Build Status](https://travis-ci.org/FaaStRuby/faastruby-cli.svg?branch=master)](https://travis-ci.org/FaaStRuby/faastruby-cli)

* Looking for help? [Ask a question](https://meta.stackoverflow.com/questions/ask?tags=FaaStRuby,Serverless,Ruby,FaaS).

* [Changelog](https://github.com/FaaStRuby/faastruby-cli/blob/master/CHANGELOG.md)

# faastruby-cli

CLI tool for managing workspaces and functions hosted at [FaaStRuby](https://faastruby.io).

## What is FaaStRuby?
FaaStRuby is a Serverless Software Development Platform for Ruby and Crystal.

* [Tutorial](https://faastruby.io/getting-started)

## Try it

Getting up and running is quick and easy:

![Getting up and running](https://s3.amazonaws.com/faastruby/public/create-project.mp4)

1. Install the gem so `faastruby` is available in your terminal

```
~$ gem install faastruby
```

2. Create a new FaaStRuby project

```
~$ faastruby new-project hello-world
+ d ./hello-world
+ f ./hello-world/project.yml
+ f ./hello-world/secrets.yml
+ d ./hello-world/functions/root
+ f ./hello-world/functions/root/index.html.erb
+ f ./hello-world/functions/root/template.rb
+ f ./hello-world/functions/root/handler.rb
+ f ./hello-world/functions/root/faastruby.yml
+ d ./hello-world/functions/catch-all
+ f ./hello-world/functions/catch-all/404.html
+ f ./hello-world/functions/catch-all/handler.rb
+ f ./hello-world/functions/catch-all/faastruby.yml
+ f ./hello-world/public/faastruby.yml
+ f ./hello-world/.gitignore
Initialized empty Git repository in /Users/mf/OpenSource/faastruby/hello-world/.git/
Project 'hello-world' initialized.
Now run:
$ cd hello-world
$ faastruby local
```

3. Fire up the local development environment for your new project

```
~$ cd hello-world
~/hello-world$ faastruby local
Puma starting in single mode...
* Version 3.12.0 (ruby 2.5.3-p105), codename: Llamas in Pajamas
* Min threads: 0, max threads: 32
* Environment: production
sh: crystal: command not found
2019-02-27 23:36:03 +0800 (EventHub) Channel subscriptions: {}
---
2019-02-27 23:36:03 +0800 (EventHub) Please restart the server if you modify channel subscriptions in 'faastruby.yml' for any function.
---
2019-02-27 23:36:03 +0800 (EventHub) Events thread started.
---
2019-02-27 23:36:03 +0800 (Sentinel) Ruby functions: ["root", "catch-all"]
---
2019-02-27 23:36:03 +0800 (Sentinel) Watching for new Ruby functions...
```

As you can see, this runs with Ruby only. If you want to run Crystal as well (similar to Ruby, but with types and compiled to run very fast), simply [install Crystal](https://crystal-lang.org/reference/installation/) and start `faastruby local` again.


`faastruby local` is very powerful. When you add a new folder with a `handler.rb` or `handler.cr`, it will automatically be detected. FaaStRuby will automatically add the configuration for the function so you can jump straight in:

![How to add a new folder and file](https://s3.amazonaws.com/faastruby/public/new-paths.mp4)

Changes to the code will automatically be detected and immediately refreshed for you, making local development easy and comfortable:
[!How to edit files and refresh them in the browser](https://s3.amazonaws.com/faastruby/public/local-file-refresh.mp4)

4. Deploy it to a workspace:

```
~/hello-world$ faastruby deploy-to awesome-prod
◐ Running tests... Passed!
...

Finished in 0.00563 seconds (files took 0.15076 seconds to load)
3 examples, 0 failures

◐ Building package... Done!
◐ Deploying to workspace 'awesome-prod'... Done!
Endpoint: https://api.tor1.faastruby.io/awesome-prod/hello-world
```

3. Run it:

```
~/hello-world$ curl https://api.tor1.faastruby.io/awesome-prod/hello-world
Hello, World!
```

Build lots of functions and share them with fellow Ruby devs!

## FaaStRuby + Hyperstack = fullstack Ruby apps!

Do you think JavaScript is your only option for the front-end? Think again. [Hyperstack](https://hyperstack.org) is a Ruby DSL, compiled by Opal, bundled by Webpack, powered by React.