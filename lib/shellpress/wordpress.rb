require "yaml"

class Wordpress < Thor
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

