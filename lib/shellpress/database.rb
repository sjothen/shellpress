require "mysql"

class Shellpress::Database < Shellpress::Thor
  ORDER = 3
  desc "reset", "resets by emptying all WordPress tables"
  long_desc <<-DESC
    Empties all WordPress tables by truncating. By default, all tables will be cleared.
    To preserve the user tables, use --exclude_users (-e)
  DESC
  method_option :exclude_users, :type => :boolean, :aliases => %w(-e),
    :desc => "Excludes wp_usermeta and wp_users tables from being cleared"
  def reset

    tables = %w(wp_commentmeta wp_comments wp_links wp_options wp_postmeta wp_posts wp_terms wp_term_relationships wp_term_taxonomy)
    if options[:exclude_users]
      tables += %w(wp_usermeta wp_users)
    end

    # doesnt work yet since there's no way to retrieve config settings
    begin
      #wp = Mysql.real_connect(mysql['host'], mysql['user'], mysql['pass'])
      #tables.each do |t|
      #  wp.query("TRUNCATE TABLE #{t}")
      #end
    rescue Mysql::Error => e
      abort e
    ensure
      wp.close if wp
    end

  end
end
