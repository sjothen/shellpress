class Shellpress::CLI < Shellpress::Thor
  no_tasks do
    def constantize(s)
      Shellpress.constants.each { |k| return Shellpress.const_get(k) if k.to_s.downcase == s }
      nil
    end

    def prefix(s)
      s.to_s.downcase.gsub(/::.+/, "")
    end

    def suffix(s)
      s.to_s.gsub(/.+?::/, "")
    end

    def print_table_for_class(klass)
      pref = prefix(self.class)
      say "#{suffix(klass)} commands:"
      tasks = klass.printable_tasks.reject { |task| task[0] =~ /^#{pref} #{suffix(klass).downcase} help/ }
      print_table(tasks, :ident => 2)
      say
    end
  end

  desc "plugin", "Commands related to plugins."
  subcommand "plugin", Shellpress::Plugin

  desc "theme", "Commands related to themes."
  subcommand "theme", Shellpress::Theme

  desc "user", "Commands related to users."
  subcommand "user", Shellpress::User

  desc "wordpress", "Commands related to wordpress."
  subcommand "wordpress", Shellpress::Wordpress

  desc "database", "Commands related to the database."
  subcommand "database", Shellpress::Database

  desc "post", "Commands related to posts."
  subcommand "post", Shellpress::Post

  def help(*commands)
    if commands.empty?
      # Case 1:
      # Either `shellpress help' or `shellpress' called. Print out help for all commands.
      ks = Shellpress.constants.map { |k| Shellpress.const_get(k) }
      ks = ks.sort_by { |k| k::ORDER }
      # Don't call help on CLI or infinite recursion occurs
      ks.reject { |k| self.class == k || k == Shellpress::Thor }.each do |klass|
        print_table_for_class(klass)
      end
      say "Use `#{prefix(self.class)} help [COMMAND] [SUBCOMMAND]' to learn more."
    else
      cmd = commands[0]
      klass = constantize(cmd)
      unless klass
        say "Unknown command `#{cmd}'."
      else
        klass.new.help(*commands[1..-1])
      end
    end
  end
end
