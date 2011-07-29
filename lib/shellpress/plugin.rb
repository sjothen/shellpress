require "uri"
require "open-uri"

class Shellpress::Plugin < Shellpress::Thor
  ORDER = 0
  include Thor::Actions

  desc "install PLUGIN", "install plugin. [PLUGIN] can be a URL or a plugin name. If a plugin name is supplied, it will be downloaded from the WordPress Plugin Directory"
  method_option :version, :type => :string, :aliases => %w(-v),
    :desc => "Version of the plugin to install. Valid versions can be found on the plugin download page (http://wordpress.org/extend/plugins/[plugin]/download/) or in the SVN repository (http://plugins.svn.wordpress.org/[plugin]/tags/)"
  def install(plugin)
    version = options[:version]

    if plugin =~ URI::regexp
      invoke :download, [plugin]
      filename = File.basename(URI.parse(plugin).path)
      name = filename.split(".").first
      invoke :activate, [name]
    else
      if version
        begin
          response = open("http://svn.wp-plugins.org/#{plugin}/tags/#{version}/readme.txt")
          url = "http://downloads.wordpress.org/plugin/#{plugin}.#{version}.zip"
        rescue
          abort "Error: Invalid plugin #{plugin}"
        end
      else
        begin
          response = open("http://svn.wp-plugins.org/#{plugin}/trunk/readme.txt").read
          stable = response.match(/Stable tag: (.*)\n/)[1]
          if stable == "trunk"
            url = "http://downloads.wordpress.org/plugin/#{plugin}.zip"
          elsif stable =~ /[\d\.]+/
            url = "http://downloads.wordpress.org/plugin/#{plugin}.#{stable}.zip"
          else
            abort "Error: Invalid plugin #{plugin} or invalid readme.txt"
          end
        rescue
          abort "Error: Invalid plugin #{plugin}"
        end
      end
      invoke :download, [url]
      invoke :activate, [plugin]
    end
  end

  desc "download URL", "downloads plugin from URL"
  def download(url)
    zip = File.basename(URI.parse(url).path)
    plugin = zip.split(".").first
    run "wget #{url}", :verbose => false
    run "unzip #{zip}", :verbose => false
    remove_file "#{zip}", :verbose => false
    run "mv #{plugin} wp-content/plugins/"
  end

  desc "activate NAME", "activate plugin"
  def activate(name)
    base = "wp-content/plugins"
    php = "php -r \"include 'wp-load.php';"
    php << "require_once(ABSPATH . 'wp-admin/includes/plugin.php');"
    if File.exists?("#{base}/#{name}/#{name}.php")
      php << "activate_plugin('#{name}/#{name}.php');\""
    elsif File.exists?("#{base}/#{name}.php")
      php << "activate_plugin('#{name}.php');\""
    else
      abort "Error: Invalid plugin #{name}"
    end
    run php
  end

  desc "delete NAME", "delete plugin"
  def delete(name)
    base = "wp-content/plugins"
    php = "php -r \"include 'wp-load.php';"
    php << "require_once(ABSPATH . 'wp-admin/includes/plugin.php');"
    php << "require_once(ABSPATH . 'wp-admin/includes/file.php');"
    if File.exists?("#{base}/#{name}/#{name}.php")
      php << "delete_plugins(array('#{name}/#{name}.php'));\""
    elsif File.exists?("#{base}/#{name}.php")
      php << "delete_plugins(array('#{name}.php'));\""
    else
      abort "Error: Invalid plugin #{name}"
    end
    run php
  end

  desc "deactivate NAME", "deactivate plugin"
  def deactivate(name)
    base = "wp-content/plugins"
    php = "php -r \"include 'wp-load.php';"
    php << "require_once(ABSPATH . 'wp-admin/includes/plugin.php');"
    php << "require_once(ABSPATH . 'wp-admin/includes/file.php');"
    if File.exists?("#{base}/#{name}/#{name}.php")
      php << "deactivate_plugins(array('#{name}/#{name}.php'));\""
    elsif File.exists?("#{base}/#{name}.php")
      php << "deactivate_plugins(array('#{name}.php'));\""
    else
      abort "Error: Invalid plugin #{name}"
    end
    run php
  end
end
