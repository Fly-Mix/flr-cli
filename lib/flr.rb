require 'thor'
require 'flr/version'
require 'flr/command'

module Flr

  class CLI < Thor

    desc "version", "Show flr version"
    long_desc <<-LONGDESC
      Show the version of flr.

    LONGDESC
    def version
      Command.version
    end

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
      
      #{"With no option".bold}, #{"Flr".bold} will perform once an assets scan for your project,
      then specify scanned assets in pubspec.yaml,
      and generate "r.g.dart" file.

      #{"With".bold} #{"--auto".red.bold} #{"option".bold}, #{"Flr".bold} will launch a monitoring service that continuously monitors asset changes for your project,
      and if the service detects any asset changes, it will automatically perform an assets scan,
      then specify scanned assets in pubspec.yaml,
      and generate "r.g.dart" file.

      You can terminate the monitoring service by manually pressing "Ctrl-C" if it exists.

    LONGDESC
    option :auto, :type => :boolean
    def run_command
      options[:auto] ? Command.start_assert_monitor : Command.generate
    end

    map 'run' => 'run_command'

  end
end
