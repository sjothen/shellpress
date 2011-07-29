class Shellpress::Thor < Thor
  ORDER = -1

  def self.banner(task, namespace = nil, subcommand = false)
    "#{basename} #{self.to_s.gsub(/Shellpress::/, "").downcase} #{task.formatted_usage(self, $thor_runner, subcommand)}"
  end

  no_tasks do
    def prefix(s)
      s.to_s.gsub(/::.+/, "")
    end

    def suffix(s)
      s.to_s.gsub(/.+?::/, "")
    end
  end

  def help(*cmds)
    klass = self.class
    pref = prefix(klass).downcase

    if cmds[0]
      # Subcommand
      super(*cmds)
    else
      say "#{suffix(klass)} commands:"
      tasks = klass.printable_tasks.reject { |task| task[0] =~ /^#{pref} #{suffix(klass).downcase} help/ }
      print_table(tasks, :ident => 2)
    end

    say
  end
end
