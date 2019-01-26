[![Gem Version](https://badge.fury.io/rb/faastruby.svg)](https://badge.fury.io/rb/faastruby)
[![Build Status](https://travis-ci.org/FaaStRuby/faastruby-cli.svg?branch=master)](https://travis-ci.org/FaaStRuby/faastruby-cli)

[Changelog](https://github.com/FaaStRuby/faastruby-cli/blob/master/CHANGELOG.md)

# faastruby-cli

CLI tool for managing workspaces and functions hosted at [FaaStRuby](https://faastruby.io).

## What is FaaStRuby?
FaaStRuby is a serverless platform built for Ruby developers.

* [Tutorial](https://faastruby.io/getting-started)

## Try it

1. Install the gem:

```
~$ gem install faastruby
```

2. Create a function and deploy it to a workspace:

```
~$ faastruby new hello-world
~$ cd hello-world
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
