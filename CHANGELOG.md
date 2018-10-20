# Changelog

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