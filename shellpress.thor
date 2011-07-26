class Wordpress < Thor
  require "yaml"
  include Thor::Actions

  def self.source_root
    File.dirname(__FILE__)
  end

  desc "download", "download and unpack WordPress"
  long_desc <<-DESC
    Downloads WordPress from the official site. By default, the latest stable version will be downloaded.
    The downloaded archive will be unpacked and the working directory will become the WordPress root directory.
    Use --version to specify a version to download.
  DESC
  method_option :version, :type => :string, :aliases => %w(-v),
    :desc => "Version of WordPress to download. Any version found in the release archive with a tar.gz link is valid (http://wordpress.org/download/release-archive/)."
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
  long_desc <<-DESC
    Installs and downloads WordPress using the working directory as the WordPress root.
    If the "wp-content" folder already exists, it's assumed that WordPress has already been downloaded so only the install occurs.
    By default, this command will prompt you to enter the needed settings. Use --config (-c) [file] to specify a YAML config file.
    To save your settings into a config for future use, use --output (-o) [file] to write a YAML file.
    Before using this command, the WordPress root needs to be accessible via a URL and a MySQL database needs to exist with a valid user to access it.
  DESC
  method_option :config, :type => :string, :aliases => %w(-c),
    :desc => "Loads settings from config file specified. Config must be in YAML format."
  method_option :skip_config, :type => :boolean, :aliases => %w(-s),
    :desc => "If a config.yml file is found in the working directory, it will automatically be used unless you specify this flag."
  method_option :output, :type => :string, :aliases => %w(-o),
    :desc => "Writes a config file with the settings you chose during install."
  def install
    config = options[:config]
    output = options[:output]

    unless File.exists?("wp-content")
      invoke :download
    end

    if config
      say "*** Loading settings from #{config}", :green
      settings = YAML.load_file(config)
    elsif File.exists?("config.yml") && !options[:skip_config]
      say "*** Loading settings from config.yml", :green
      settings = YAML.load_file("config.yml")
    else
      settings = { "mysql" => {}, "wp" => {} }

      settings["mysql"]["host"] = ask "MySQL host: "
      settings["mysql"]["db"] = ask "MySQL db: "
      settings["mysql"]["user"] = ask "MySQL user: "
      settings["mysql"]["pass"] = ask "MySQL pass: "
      settings["wp"]["title"]= ask "WordPress Title: "
      settings["wp"]["user"] = ask "WordPress User: "
      settings["wp"]["pass"] = ask "WordPress Pass: "
      settings["wp"]["email"] = ask "WordPress Email: "
      settings["wp"]["url"] = ask "WordPress URL: "

      if output
        File.open(output, "w") do |out|
          say "*** #{output} written", :green
          YAML.dump(settings, out)
        end
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

  desc "clean", "delete the contents of the working directory"
  long_desc <<-DESC
    Cleans up the working directory by deleting everything in it. By default, this excludes any *.yml config files.
    To delete everything including *.yml files, use --all (a).
  DESC
  method_option :all => false, :aliases => %w(-a),
    :desc => "Delete everything including *.yml files"
  def clean
    if options[:all]
      FileUtils.rm_rf "."
    else
      Dir.glob("*").reject{|file| ['.yml'].include?(File.extname(file)) }
    end
  end

end

class Database < Thor
  require "mysql"

  desc "reset", "resets by emptying all WordPress tables"
  long_desc <<-DESC
    Empties all WordPress tables by truncating. By default, all tables will be cleared.
    To preserve the user tables, use --exclude_users (-e)
  DESC
  method_option :exclude_users => false, :aliases => %w(-e),
    :desc => "Excludes wp_usermeta and wp_users from being cleared"
  def reset

    tables = %w(wp_commentmeta wp_comments wp_links wp_options wp_postmeta wp_posts wp_terms wp_term_relationships wp_term_taxonomy)
    if options[:exclude_users]
      tables += %w(wp_usermeta wp_users)
    end

    begin
      wp = Mysql.real_connect(mysql['host'], mysql['user'], mysql['pass'])
      tables.each do |t|
        wp.query("TRUNCATE TABLE #{t}")
      end
    rescue Mysql::Error => e
      abort e
    ensure
      wp.close if wp
    end

  end
end

class Users < Thor
  require "tempfile"

  desc "add [USER]", "creates a new WordPress user"
  long <<-DESC
    Creates a new WordPress user account. Do not try using this for existing users.
  DESC
  method_option :role, :type => :string, :aliases => %w(-r),
    :desc => "User role. Valid roles and descriptions can be found here (http://codex.wordpress.org/Roles_and_Capabilities)."
  method_option :email, :type => :string, :aliases => %w(-e),
    :desc => "User's email address. Their account info will be emailed here."
  method_option :url, :type => :string, :aliases => %w(-u),
    :desc => "User's URL"
  method_option :first_name, :type => :string, :aliases => %w(-f),
    :desc => "User's first name"
  method_option :last_name, :type => :string, :aliases => %w(-l),
    :desc => "User's last name"
  method_option :ssl, :type => :string, :aliases => %w(-s), :default => '0'
    :desc => "Force SSL"
  method_option :password, :type => :string, :aliases => %w(-p),
    :desc => "User's password"
  def add(user)
    php = <<-PHP
      <?php
      include 'wp-load.php';
      require_once( ABSPATH . WPINC . '/registration.php');
      if (!is_object(get_user_by('slug', '#{user}'))) {
        wp_insert_user(array(
          'user_login' => '#{user}',
          'role' => '#{option[:role]}',
          'user_email' => '#{option[:email]}',
          'user_url' => '#{option[:url]}',
          'first_name' => '#{option[:first_name]}',
          'last_name' => '#{option[:last_name]}',
          'use_ssl' => '#{option[:ssl]}',
          'user_pass' => '#{option[:password]}'
        ));
      }
      ?>
    PHP

    file = Tempfile.open(["useradd", ".php"])
    begin
      file.write(php)
      run "php -q #{file.path}"
    ensure
      file.close
      file.delete
    end

  end
end

class Plugin < Thor
  require "uri"
  require "open-uri"
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

class Theme < Thor
  require "uri"
  require "open-uri"
  require "fileutils"
  include Thor::Actions

  desc "switch NAME", "switches from the current theme to new theme"
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

  desc "install THEME", "[THEME] can either be a URL or a theme name. If a theme name is supplied, it will be downloaded from the WordPress Theme Directory"
  method_option :version, :type => :string, :aliases => %w(-v),
    :desc => "Version of the theme to install. Valid version numbers can be found in the theme's SVN repository (http://themes.svn.wordpress.org/[theme]/)"
  def install(theme)
    version = options[:version]

    if theme =~ URI::regexp
      invoke :download, [theme]
      filename = File.basename(URI.parse(theme).path)
      name = filename.split(".").first
      invoke :switch, [name]
    else
      if version
        url = "http://wordpress.org/extend/themes/download/#{theme}.#{version}.zip"
      else
        begin
          response = open("http://themes.svn.wordpress.org/#{theme}/").read
          version = response.match(%r|<a href="([\d+.]+)/">(.*)/</a></li>\n </ul>|)[1]
          url = "http://wordpress.org/extend/themes/download/#{theme}.#{version}.zip"
        rescue
          abort "Error: Invalid theme #{theme}"
        end
      end
      invoke :download, [url]
      invoke :switch, [theme]
    end
  end

  desc "download URL", "downloads theme from URL"
  def download(url)
    zip = File.basename(URI.parse(url).path)
    theme = zip.split(".").first
    run "wget #{url}", :verbose => false
    run "unzip #{zip}", :verbose => false
    remove_file "#{zip}", :verbose => false
    run "mv #{theme} wp-content/themes/"
  end

  desc "delete NAME", "removes theme"
  method_option :force, :type => :boolean, :aliases => %w(-f),
    :desc => "Force delete theme without confirmation"
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

class Posts < Thor
  include Thor::Actions

  desc "delete [POST ID/SLUG]", "deletes a post, attachment, or page of the specified ID or path (slug)"
  method_option :force, :type => :boolean, :aliases => %w(-f), :default => true,
    :desc => "Force delete post bypassing the Trash"
  method_option :type, :type => :string, :aliases => %w(-t), :default => "post",
    :desc => "The type of object to delete. Default valid types: post, page, attachment, revision, nav_menu. Custom post types are also supported"
  def delete(id)
    force = options[:force]
    type = options[:type]

    php = "<?php include 'wp-load.php';"

    if id =~ /\d+/
      php << "wp_delete_post(#{id}, #{force});"
    else
      php << "$post = get_page_by_path('#{id}', OBJECT, '#{type}');"
      php << "if ($post) wp_delete_post($post->ID, #{force});"
    end

    php << "?>"

    File.open("temp.php", "w") {|f| f.write(php)}
    run "php -q temp.php"
    remove_file "temp.php", :verbose => false

  end
end
