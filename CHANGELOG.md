# Changelog

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
