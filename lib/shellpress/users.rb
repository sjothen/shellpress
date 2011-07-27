class Users < Thor
  require "tempfile"

  desc "add [USER]", "creates a new WordPress user"
  long_desc <<-DESC
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
  method_option :ssl, :type => :string, :aliases => %w(-s), :default => '0',
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

