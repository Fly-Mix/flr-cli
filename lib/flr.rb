require 'thor'
require 'flr/version'
require 'flr/command'
require 'flr/string_extensions'

module Flr

  class CLI < Thor

    def self.help(shell, subcommand = false, display_introduction = true)
      introduction = <<-MESSAGE
A Flutter Resource Manager CLI TooL, which can help flutter developer to auto specify assets in pubspec.yaml and generate r.g.dart file after he changes the flutter project assets.
More details see https://github.com/Fly-Mix/flr-cli

      MESSAGE
      if display_introduction
        puts(introduction)
      end
      super(shell,subcommand)
    end

    def self.exit_on_failure?
      puts("")
      help(CLI::Base.shell.new, false, false)
      true
    end

    desc "version", "Display version"
    long_desc <<-LONGDESC
      Display the version of Flr.

    LONGDESC
    def version
      Command.version
    end
    map %w[-v --version] => :version

    desc "init", "Add flr configuration and dependency \"r_dart_library\" into pubspec.yaml"
    long_desc <<-LONGDESC
      Add flr configuration 
      and dependency \"r_dart_library\"(https://github.com/YK-Unit/r_dart_library) into pubspec.yaml.

    LONGDESC
    def init
      Command.init
    end

    desc "run [--auto]", "Scan assets, specify scanned assets in pubspec.yaml, generate \"r.g.dart\""
    long_desc <<-LONGDESC
      
      #{"With no option".bold}, #{"Flr".bold} will scan the asset directories configured in `pubspec.yaml`,
      then specify scanned assets in pubspec.yaml,
      and generate "r.g.dart" file.

      #{"With".bold} #{"--auto".red.bold} #{"option".bold}, #{"Flr".bold} will launch a monitoring service that continuously monitors asset directories configured in pubspec.yaml.
      If the service detects any asset changes, #{"Flr".bold} will automatically scan the asset directories,
      then specify scanned assets in pubspec.yaml,
      and generate "r.g.dart" file.

      You can terminate the monitoring service by manually pressing #{"\"Ctrl-C\"".bold} if it exists.

    LONGDESC
    option :auto, :type => :boolean
    def run_command
      options[:auto] ? Command.start_monitor : Command.generate
    end

    map 'run' => :run_command

  end
end
