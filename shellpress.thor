class Wordpress < Thor
  require "yaml"
  include Thor::Actions

  def self.source_root
    File.dirname(__FILE__)
  end

  desc "download", "download and unpack WordPress"
  method_option :version, :type => :string, :aliases => "-v" 
  def download
    version = options[:version]

    if version
      say "*** Downloading WordPress #{version}", :green
      run "wget http://wordpress.org/wordpress-#{version}.tar.gz -O wordpress.tar.gz", :verbose => false
    else
      say "*** Downloading latest WordPress", :green
      run "wget http://wordpress.org/latest.tar.gz -O wordpress.tar.gz", :verbose => false
    end

    run "tar zxf wordpress.tar.gz", :verbose => false
    remove_file "wordpress.tar.gz", :verbose => false
    run "mv wordpress/* .", :verbose => false
    run "rmdir wordpress", :verbose => false
  end

  desc "install", "download and install WordPress"
  method_option :config, :type => :string, :aliases => "-c"
  method_option :output, :type => :string, :aliases => "-o"
  def install
    config = options[:config]
    output = options[:output]
    unless File.exists?("wordpress")
      invoke :download
    end

    if config
      say "*** Loading settings from #{config}", :green
      settings = YAML.load_file(config)
    elsif File.exists?("config.yml")
      say "*** Loading settings from config.yml", :green
      settings = YAML.load_file("config.yml")
    else
      settings = { 'mysql' => {}, 'wp' => {} }

      settings["mysql"]["host"] = ask "mysql host: "
      settings["mysql"]["db"] = ask "mysql db: "
      settings["mysql"]["user"] = ask "mysql user: "
      settings["mysql"]["pass"] = ask "mysql pass: "
      settings["wp"]["title"]= ask "WP Title: "
      settings["wp"]["user"] = ask "WP User: "
      settings["wp"]["pass"] = ask "WP Pass: "
      settings["wp"]["email"] = ask "WP Email: "
      settings["wp"]["url"] = ask "WP URL: "

      unless output
        output = "config.yml"
      end

      File.open(output, "w") do |out|
        say "*** #{output} written", :green
        YAML.dump(settings, out)
      end
    end

    say "*** Downloading WordPress Salt keys", :green
    run "wget https://api.wordpress.org/secret-key/1.1/salt/ -O /tmp/wp.keys", :verbose => false

    say "*** Updating wp-config with settings", :green
    run "sed -e 's/localhost/#{settings['mysql']['host']}/' -e 's/database_name_here/#{settings['mysql']['db']}/' -e 's/username_here/#{settings['mysql']['user']}/' -e 's/password_here/#{settings['mysql']['pass']}/' wp-config-sample.php > wp-config.php", :verbose => false
    run "sed -i '\/\#\@\-\/r \/tmp\/wp.keys' wp-config.php", :verbose => false
    run "sed -i '\/\#\@\+\/,\/\#\@\-\/d' wp-config.php", :verbose => false

    run "curl -d 'weblog_title=#{settings['wp']['title']}&user_name=#{settings['wp']['user']}&admin_password=#{settings['wp']['pass']}&admin_password2=#{settings['wp']['pass']}&admin_email=#{settings['wp']['email']}' http://#{settings['wp']['url']}/wp-admin/install.php?step=2"

  end

  # TODO
  desc 'clean', 'cleanup and delete files'
  method_option :all => false, :aliases => '-a'
  def clean
    all = options[:all]
    if all
      #delete everything in current dir
    else
      #just delete WP dir?
    end
  end

end

class Plugin < Thor
  require "uri"
  require "open-uri"
  include Thor::Actions

  desc 'install PLUGIN', 'install plugin'
  method_option :version, :type => :string, :aliases => "-v"
  def install(plugin)
    version = options[:version]

    if plugin =~ URI::regexp
      invoke :download, [plugin]
      invoke :activate, [plugin]
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

  desc 'download URL', 'downloads plugin from URL'
  def download(url)
    zip = File.basename(URI.parse(url).path)
    plugin = zip.split(".").first
    run "wget #{url}", :verbose => false
    run "unzip #{zip}", :verbose => false
    remove_file "#{zip}", :verbose => false
    run "mv #{plugin} wp-content/plugins/"
  end

  desc 'activate NAME', 'activate plugin'
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


  desc 'delete NAME', 'delete plugin'
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

  desc 'deactivate NAME', 'deactivate plugin'
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

class Theme < Thor
  require "uri"
  require "open-uri"
  require "fileutils"
  include Thor::Actions

  desc 'switch NAME', 'switches from the current theme to new theme'
  def switch(theme)
    base = "wp-content/themes/#{theme}"

    if !File.exists?(base)
      abort "Error: Invalid theme #{theme}"
    end

    path = File.join(base, "style.css")
    file = File.open(path, "rb").read
    if file =~ /Template: (.*)\n/
      parent = $1
    end
    php = "php -r \"include 'wp-load.php';"
    if parent
      php << "switch_theme('#{parent}', '#{theme}');\""
    else
      php << "switch_theme('#{theme}', '#{theme}');\""
    end
    run php
  end

  # TODO
  desc 'install NAME', 'downloads and activates theme'
  def install(theme)
    #dl
    #move to theme dir
    #invoke switch, [theme]
  end

  desc 'delete NAME', 'removes theme'
  method_option :force, :type => :boolean, :aliases => "-f"
  def delete(theme)
    path = "wp-content/themes/#{theme}"

    if !File.exists?(path)
      abort "Error: Invalid theme #{theme}"
    end

    force = options[:force]
    if force
      FileUtils.rm_rf path
    else
      confirm = ask "Delete #{path}? [Yn]"
      if confirm == "Y"
        FileUtils.rm_rf path
      end
    end
  end

end
