# faastruby-cli

CLI tool for managing workspaces and functions hosted at [FaaStRuby](https://faastruby.io).

## What is FaaStRuby?
Fast, lightweight and scalable serverless platform built for Ruby developers.

* [Tutorial](https://faastruby.io/tutorial.html)

## Try it

1. Install the gem:

```
$ gem install faastruby
```

2. Create a workspace to deploy your functions. The workspace name must be unique (like a username).

```
$ faastruby create-workspace awesome-prod
```

3. Create a function and deploy it to your workspace:

```
$ faastruby new my-first-function
$ cd my-first-function
$ faastruby deploy-to awesome-prod
◐ Running tests... Passed!
...

Finished in 0.00563 seconds (files took 0.15076 seconds to load)
3 examples, 0 failures

◐ Building package... Done!
◐ Deploying to workspace 'awesome-prod'... Done!
```

4. Run it:

```
$ faastruby run awesome-prod --json '{"name":"Ruby"}'
Hello, Ruby!
```

You can also generate a CURL command:

```
$ faastruby run awesome-prod --json '{"name":"Ruby"}' --header 'My-Header: value' --query 'foo=bar' --query 'baz=fox' --curl
curl -X POST -H 'Content-Type: application/json' -H 'My-Header: value' -d '{"name":"Ruby"}' 'https://api.faastruby.io/awesome-prod/my-first-function?foo=bar&baz=fox'
```

Build lots of functions and share them with fellow Ruby devs!

## FaaStRuby + Hyperstack = fullstack Ruby apps!

Do you think JavaScript is your only option for the front-end? Think again. [Hyperstack](https://hyperstack.org) is a Ruby DSL, compiled by Opal, bundled by Webpack, powered by React.