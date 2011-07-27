# shellpress

Manage WordPress from the command-line.

## Commands

Shellpress comes with a variety of different commands that help you efficiently manage your wordpress installations. Try one of the following commands:

### Plugins
Activate a plugin:

  `thor plugin:activate NAME`

Deactivate a plugin:

  `thor plugin:deactivate NAME`

Delete a plugin:

  `thor plugin:delete NAME`

Download a new plugin from URL:

  `thor plugin:download URL`

Install a new plugin:

  `thor plugin:install PLUGIN`

### Themes
Delete a theme:

  `thor theme:delete NAME`

Install a theme:

  `thor theme:install NAME`

Switch from current theme to a new theme:

  `thor theme:switch NAME`

Download a new theme:

  `thor theme:download URL`

### Other commands
Cleanup and delete files:

  `thor wordpress:clean`

Download and unpack Wordpress:

  `thor wordpress:download`

Download and install Wordpress:

  `thor wordpress:install`

Add a new user:

  `thor users:add`

Clear all Wordpress tables:

  `thor database:reset`

## Copyright

Copyright (c) 2011 Scott Walkinshaw. See LICENSE.txt for
further details.
