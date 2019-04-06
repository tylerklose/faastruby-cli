# Changelog

## 0.5.23 - Unreleased
- Move regions configuration to a separate file, so it can be shared among different among different components of the gem
- Replace hardcoded URLs by the correct variables
- Fix messy env vars

## 0.5.22 - April 1 2019
- Detect Crystal functions that have `handler.cr` inside `src` directory
- Exclude Crystal function handler binaries when generating a deployment package
- Move Crystal Runtime Macro to the top of the file, outside the FaaStRuby module
- Fix bug preventing `--sync` from working with any other environment.

## 0.5.21 - Mar 24 2019
- Require supported_runtimes on every command run.

## 0.5.20 - Mar 24 2019
- Improved email regex.
- Display the correct error message when confirmation token is invalid
- Add option `--skip-dependencies` to the commands `deploy-to` and `deploy` to allow skipping of `bundle install` and `shards install`.
- Change Ruby runtimes to `2.5` and `2.6` and use the pessimistic version operator to compare Ruby versions and maintain backwards compatibility.
- Fix error message on `deploy-to` when workspace credentials are missing

## 0.5.19 - Mar 20 2019
- Fix bug preventing `faastruby deploy` from working when secrets are nil

## 0.5.18 - Mar 19 2019
- Reverted changes from 0.5.17
- Refactored headers parsing
- Bump `faastruby-rpc` version
- Force RPC calls to use event.body instead of extra arguments
- Added `favicon.ico` to the public template to stop annoying catch-all invocations on log
- Match platform behaviour when render text is used on an object

## 0.5.17 - Mar 19 2019
- Refactored headers parsing
- Change Oj load behaviour to use hash with symbol keys when loading rpc_args
- Bump `faastruby-rpc` version
- Added `favicon.ico` to the public template to stop annoying catch-all invocations on log

## 0.5.16 - Mar 18 2019
- Remove unused arguments from update workspace `run` method.
- Update Help
- Change the argument that measures the execution time on `run` to `--measure`
- Add argument to read context from STDIN when running `deploy-to`
- Switch default config files method from array to multiline string
- Allow passwords with up to 50 characters.
- Fix bug preventing `faastruby deploy` to deploy the secrets.

## 0.5.15 - Mar 18 2019
- Remove `nil` entries from error array before trying to print error messages

## 0.5.14 - Mar 17 2019
- Fix bug when trying to detect Gemfile.lock
- Add helper method to debug listener event
- Local will give the cloud Workspace URL after booting when sync is enabled
- `faastruby deploy` will print the workspace URL when it succeeds.

## 0.5.13 - Mar 17 2019
- Update help with new spelling
- Better handle of deploys when sync is enabled
- Fix broken output spinners
- Improved console messages
- Disable initial compile of crystal functions when starting Local
- Fixed output bug when deploying from Local
- Clearer message output for the command `confirm-account`
- Ignore when Gemfile.lock is added
- Don't trigger a deploy when Gemfile is added
- Ignore Gemfile changes while initializing it

## 0.5.12 - Mar 16 2019
- Add new branding to Local web templates.
- Fix secrets.yml example in comments.
- Cleanup logger module.
- Local generated deploy-to command was not escaping JSON before bassing to `--context`.
- Bump faastruby-rpc to 0.2.5


## 0.5.11 - Mar 14 2019
- Bump faastruby-rpc to 0.2.4

## 0.5.10 - Mar 13 2019
- Fix Watchdog message when a function is removed from the project.
- Add method render_nothing to ruby and crystal functions, to make it clear how to send an empty response body
- Empty functions will render an empty body
- Ensure Watchdog listeners stop when exiting
- Fix bug preventing `--create-local-dir` from creating a folder when `create-workspace` is used
- Change message confirmation when destroying a workspace
- Update YAML template comments with mention to `test_command`
- FaaStRuby Local won't start unless it can find `project.yml` in current directory.
- Fix command `faastruby deploy`
- Fix bug when response headers are empty

## 0.5.9 - Mar 11 2019
- Add Gemfile support to Watchdog. When a `Gemfile` is added to a function, Watchdog will initialize it if the file is empty and run `bundle install` every time you modify it.
- Watchdog will stream the output of commands instead of printing everything once it's done.
- Disable caching for static files on Local

## 0.5.8 - Mar 11 2019
- Bump dependency faastruby-rpc to v0.2.3
- Use CSS gradient instead of background picture on Local Web template
- Match response headers with cloud platform

## 0.5.7 - Mar 11 2019
- Refactor API class
- Bump faastruby-rpc dependency to 0.2.2
- Better API error handling
- Display alert when new gem version is available
- Add command `faastruby update`
- Quit server when FaaStRuby Local fails to start

## 0.5.6 - Mar 10 2019
- Fix bug preventing require libraries. Thanks to @jbonney for spotting that one!
- Support for static files with space in their names
- Cleanup comments code
- Limit the size of static files to 5MB
- Check if the number of runners is an integer

## 0.5.5 - Mar 9 2019
- Use a class method inside FaaStRuby::Response to handle invalid response messages.

## 0.5.4 - Mar 8 2019
- Fix invalid response error when functions return invalid responses

## 0.5.3 - Mar 8 2019
- Fix logout problem
- Fix help to display the correct `new-project` command

## 0.5.2 - Mar 8 2019
- Fix bug with migrating accounts

## 0.5.1 - Mar 8 2019
- Enforce one special character on account passwords.

## 0.5.0 - Mar 8 2019
- Introduces FaaStRuby Local
- Introduce user accounts and a migration tool to move the legacy workspace credentials into your account.
- New key on faastruby.yml - `before_build` allows you to specify commands to run locally before building and uploading the function package.
- New command: `update-workspace WORKSPACE_NAME --runners INT` - set the number of runners for a workspace.

## 0.4.18 - Feb 6 2019
- Bumps runtime crystal:0.27.1 to crystal:0.27.2

## 0.4.17 - Feb 4 2019
- Fix bug when cloning git repos with --template git:...

## 0.4.16 - Feb 4 2019
- Add support for function templates
- Add cli_version to `faastruby.yml`

## 0.4.15 - Feb 2 2019
- Add support for Crystal 0.27.1 and Ruby 2.6.1

## 0.4.14 - Feb 1 2019
- Ruby functions now use a spec helper from `faastruby` gem.
- Crystal functions now use the shard `faastruby-spec-helper` to assist on tests.
- Mock `publish` method on tests.
- Wrap functions in anonymous module to avoid concurrency problems.
- Read all STDIN when updating context with --stdin [PR-5](https://github.com/FaaStRuby/faastruby-cli/pull/5) | Thanks [Justin](https://github.com/presidentbeef)!
- `shards install` runs when building crystal function before deploy
- Better message when updating the function context
- Fixed output when creating a function with `faastruby new`

A new version of the platform API was released in tandem to address the issue that would erase contexts when a function is redeployed. Thanks [Justin](https://github.com/presidentbeef) again for pointing that out.

## 0.4.12 - Jan 26 2019
Special thanks to [Sean Earle](https://github.com/HellRok) for fixing those bugs!
- FaaStRuby Server: Respond with css content type [PR-4](https://github.com/FaaStRuby/faastruby-cli/pull/4)
- Setup the server to respond to HEAD requests [PR-3](https://github.com/FaaStRuby/faastruby-cli/pull/3)

## 0.4.11 - Jan 19 2019
- Fix wrong working directory when running functions locally with `faastruby server`

## 0.4.10 - Jan 14 2019
- Fix command `faastruby server`

## 0.4.9 - Jan 13 2019
- Changes in `faastruby server`
  - Cleaned up code
  - Logs are easier to read
  - Function responses show up in the log
  - Support for events with `publish`

## 0.4.8 - Jan 8 2019
- Use the actual param rather than the Sinatra::Params object

## 0.4.7 - Jan 8 2019
- `create-workspace` will not create a folder on current dir, unless specified with `--create-local-dir`

## 0.4.6 - Jan 5 2019
- Default value when no runtime is provided to `new`

## 0.4.5 - Jan 5 2019
- Change help terminal colors for better readability
- Add png, jpeg, css, svg, gif and icon mime-types to `render`

## 0.4.4 - Jan 3 2019
- Update faastruby-rpc to 0.2.1

## 0.4.3 - Dec 31 2018
- Updated `faastruby-rpc` dependency to 0.2.0.
- Improved FaaStRuby Server.

## 0.4.2 - Dec 30 2018
- Simplified Crystal Hello World example.

## 0.4.1 - Dec 30 2018
- Updated ruby templates.

## 0.4.0 - Dec 29 2018
- Faster hello-world Ruby template.
- Ruby 2.6.0 and Crystal (beta) 0.27.0 released.

## 0.3.8 - Dec 29 2018
- Crystal template runs a lot faster.

## 0.3.7 - Dec 29 2018
- Error when unsupported runtimes are passed to `new`

## 0.3.6 - Dec 29 2018
- Add support for different runtimes with `--runtime` to `new` command. Example: `faastruby new hello-world --runtime ruby:2.6.0`
- Add runtime `ruby:2.6.0`
- Add runtime `crystal:0.27.0`

## 0.3.5 - Dec 27 2018
- Clean up credentials file when listing or saving it to remove nulls.
- Raise error when trying to save null credentials to file.
- Ignore null entries from credentials hash.

## 0.3.4 - Dec 27 2018
- Use `JSON.pretty_generate` when writing to credentials file, so it is more human readable.
- Fix bug: when creating a workspace from `deploy-to` command, if the workspace existed it would not error, but the deploy would fail and a null entry would go in the credentials file.

## 0.3.3 - Dec 21 2018
- `deploy-to` will try to create the workspace if it doesn't exist.
- Changed template to add a carriage return.

## 0.3.2 - Dec 15 2018
- Better output for tests
- `bundle check && bundle install` runs before building a package to make sure Gemfile.lock is updated.
- New command: `faastruby deploy`. This command is meant to be run in a FaaStRuby Project folder, and will deploy all workspaces and their functions.
- Updated spec templates with new helper that stubs calls to FaaStRuby server when using `faastruby-rpc`.
- `render` is now the preferred method to set the return value of functions.
- Upgraded dependency `faastruby-rpc` to version 0.1.3.
- Removed region SFO2 (sorry, but the usage was minimal.)

## 0.3.1 - Dec 9 2018
- Add faastruby-rpc to Gemfile template and runtime dependencies

## 0.3.0 - Dec 9 2018
- Add spinner feedback when destroying workspace
- Better error handling when response is not JSON
- New command `faastruby server` will start a development environment.

## 0.2.6 - Nov 20 2018
- Change Ruby minimum version to 2.5.0
- Disable timeout on HTTP requests.
- Handle CTRL+C interruptions gracefully
- Add `--region` to help

## 0.2.5 - Nov 18 2018
- Support for multiple regions with `faastruby --region [REGION] ...`

## 0.2.4 - Skipped

## 0.2.3 - Oct 20 2018
- Added #status_code to Workspace class to hold the API response code after a request
- Added refresh_credentials endpoint
- Fix the request headers
- Fix bug with `faastruby help`

## 0.2.2 - Oct 20 2018
### New
- Functions can be scheduled via faastruby.yml
### Fixed
- Some API errors were not being properly displayed

## 0.2.1 - Oct 16 2018
- New command: `add-credentials` - add credentials to a credentials file
- New command: `list-credentials` - list current credentials in a credentials file
Run `faastruby help` for usage details.

## 0.2.0 - Oct 12 2018
- Full rewrite of the gem. All command line parameters have changed. Please see the [documentation](https://faastruby.io/tutorial.html).
- No more git repositories.
- Functions are packaged, deployed and managed individually.
- Functions have a YAML configuration file.
- Functions can have tests and they can be configured to run before each deploy, aborting if a failure happens.
- Added option to print or save the workspace credentials into a different file upon creation, instead of saving it to ~/.faastruby
- Read a different credentials file via FAASTRUBY_CREDENTIALS environment variable.
- Read credentials via environment variables: FAASTRUBY_API_KEY and FAASTRUBY_API_SECRET.
