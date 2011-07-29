# shellpress

Manage WordPress from the command-line.

## Commands

Shellpress comes with a variety of different commands that help you efficiently manage your WordPress installations. Try one of the following commands:

### WordPress

Command: wordpress download

    $ shellpress wordpress download  # download and unpack WordPress

      Options:
        -v, [--version=VERSION]  # Version of WordPress to download. Any version found in the release archive with a tar.gz link is valid (http://wordpress.org/download/release-archive/).

      Description:
        Downloads WordPress from the official site. By default, the latest stable version will be downloaded. The downloaded archive will be unpacked and the working directory will become the WordPress root directory. Use --version to specify a version to download.

Command: wordpress install

    $ shellpress wordpress install   # download and install WordPress

      Options:
        -c, [--config=CONFIG]  # Loads settings from config file specified. Config must be in YAML format.
        -s, [--skip-config]    # If a config.yml file is found in the working directory, it will automatically be used unless you specify this flag.
        -o, [--output=OUTPUT]  # Writes a config file with the settings you chose during install.

      Description:
        Installs and downloads WordPress using the working directory as the WordPress root. If the "wp-content" folder already exists, it's  assumed that WordPress has already been downloaded so only the install occurs. By default, this command will prompt you to enter the needed settings. Use --config (-c) [file] to specify a YAML config file. To save your settings into a config for future use, use --output (-o) [file] to write a YAML file. Before using this command, the WordPress root needs to be accessible via a URL and a MySQL database needs to exist with a valid user to access it.

Command: wordpress clean

    $ shellpress wordpress clean

      Options:
        [--aliases-aallfalsedescDelete everything including *.yml files=ALIASES-AALLFALSEDESCDELETE EVERYTHING INCLUDING *.YML FILES]  

      Description:
        Cleans up the working directory by deleting everything in it. By default, this excludes any *.yml config files. To delete everything including *.yml files, use --all (a).

### Plugins

Command: plugin install

    $ shellpress plugin install PLUGIN   # install plugin. [PLUGIN] can be a URL or a plugin name. If a plugin name is supplied, it will be downloaded from the WordPress Plugin Directory

      Description:
        install plugin. [PLUGIN] can be a URL or a plugin name. If a plugin name is supplied, it will be downloaded from the WordPress Plugin Directory

      Options:
        -v, [--version=VERSION]  # Version of the plugin to install. Valid versions can be found on the plugin download page (http://wordpress.org/extend/plugins/[plugin]/download/) or in the SVN repository (http://plugins.svn.wordpress.org/[plugin]/tags/)

Command: plugin activate

    $ shellpress plugin activate NAME    # activate plugin

Command: plugin deactivate

    $ shellpress plugin deactivate NAME  # deactivate plugin

Command: plugin delete

    $ shellpress plugin delete NAME      # delete plugin

Command: plugin download

    $ shellpress plugin download URL     # downloads plugin from URL


### Themes

Command: theme install

    $ shellpress theme install THEME  # [THEME] can either be a URL or a theme name. If a theme name is supplied, it will be downloaded from the WordPress Theme Directory

      Description:
        [THEME] can either be a URL or a theme name. If a theme name is supplied, it will be downloaded from the WordPress Theme Directory

      Options:
        -v, [--version=VERSION]  # Version of the theme to install. Valid version numbers can be found in the theme's SVN repository (http://themes.svn.wordpress.org/[theme]/)

Command: theme delete

    $ shellpress theme delete NAME    # removes theme

      Options:
        -f, [--force]  # Force delete theme without confirmation

Command: theme switch

    $ shellpress theme switch NAME    # switches from the current theme to new theme

Command: theme download

    $ shellpress theme download URL   # downloads theme from URL

### Users

Command: user add

    $ shellpress user add [USER]

      Options:
        -u, [--url=URL]                # User's URL
        -r, [--role=ROLE]              # User role. Valid roles and descriptions can be found here (http://codex.wordpress.org/Roles_and_Capabilities).
        -p, [--password=PASSWORD]      # User's password
        -f, [--first-name=FIRST_NAME]  # User's first name
        -e, [--email=EMAIL]            # User's email address. Their account info will be emailed here.
        -l, [--last-name=LAST_NAME]    # User's last name
        -s, [--ssl=SSL]                # Force SSL
                                       # Default: 0

      Description:
        Creates a new WordPress user account. Do not try using this for existing users.


### Database

Command: database reset

    $ shellpress database reset

      Options:
        -e, [--exclude-users]  # Excludes wp_usermeta and wp_users from being cleared

      Description:
        Empties all WordPress tables by truncating. By default, all tables will be cleared. To preserve the user tables, use --exclude_users (-e)

## Config

See `config.yml.sample` for an example of an installation config.yml.

Usage: `shellpress wordpress install -c config.yml`

## Copyright

Copyright (c) 2011 Scott Walkinshaw. See LICENSE for further details.
