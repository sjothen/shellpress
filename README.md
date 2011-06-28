# shellpress

Thor script to help install and manage WordPress.

## Notes

This is a work in progress with lots of changes and improvements to come.

## Usage

plugin
------
thor plugin:activate NAME    # activate plugin
thor plugin:deactivate NAME  # deactivate plugin
thor plugin:delete NAME      # delete plugin
thor plugin:download URL     # downloads plugin from URL
thor plugin:install PLUGIN   # install plugin

theme
-----
thor theme:delete NAME   # removes theme
thor theme:install NAME  # downloads and activates theme
thor theme:switch NAME   # switches from the current theme to new theme

wordpress
---------
thor wordpress:clean     # cleanup and delete files
thor wordpress:download  # download and unpack WordPress
thor wordpress:install   # download and install WordPress
