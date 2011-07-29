class Shellpress::Thor < Thor
  ORDER = -1
  def self.banner(task, namespace = nil, subcommand = false)
    "#{basename} #{self.to_s.gsub(/Shellpress::/, "").downcase} #{task.formatted_usage(self, $thor_runner, subcommand)}"
  end
end
