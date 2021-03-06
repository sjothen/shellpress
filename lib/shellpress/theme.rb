require "uri"
require "open-uri"
require "fileutils"

class Shellpress::Theme < Shellpress::Thor
  ORDER = 1
  include Thor::Actions

  desc "switch NAME", "switches from the current theme to new theme"
  long_desc <<-DESC
    Switches (activates) to [NAME] theme. [NAME] is the theme directory name in wp-content/themes/.
    Child themes are also supported.
  DESC
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

  desc "install THEME", "download and installs a WordPress theme"
  long_desc <<-DESC
    [THEME] can either be a URL or a theme name. If a theme name is supplied, it will be downloaded from the WordPress Theme Directory (http://wordpress.org/extend/themes/).
    If [THEME] is a URL, it needs to be a ZIP file that contains a directory.
  DESC
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
  long_desc <<-DESC
    Downloads a theme from the URL provided. URL needs be a ZIP file that contains 1 directory.
    ZIP will be expanded and deleted. The theme will be moved to wp-content/themes/.
  DESC
  def download(url)
    zip = File.basename(URI.parse(url).path)
    theme = zip.split(".").first
    run "wget #{url}", :verbose => false
    run "unzip #{zip}", :verbose => false
    remove_file "#{zip}", :verbose => false
    run "mv #{theme} wp-content/themes/"
  end

  desc "delete NAME", "removes theme"
  long_desc <<-DESC
    Deletes a theme. [NAME] is the name of the theme directory in wp-content/themes/.
  DESC
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
