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

    desc "generate", "Perform once a assets scan, then auto specify scanned assets in pubspec.yaml, and generate \"r.g.dart\""
    long_desc <<-LONGDESC
      Perform once a assets scan for your project,
      then automatically specify scanned assets in pubspec.yaml,
      and generate "r.g.dart" file.

    LONGDESC
    def generate
      Command.generate
    end

    desc "monitor", "Launch a monitoring service. When detects asset changes, the service will auto execute \"flr generate\". Press \"Ctrl-C\" can terminate it"
    long_desc <<-LONGDESC
       Launch a monitoring service that continuously monitors asset changes for your project. 

       If there are any changes, it will automatically execute "flr generate" command which 
       will perform a assets scan,
       then automatically specify scanned assets in pubspec.yaml,
       and generate the "r.g.dart" file.

       You can terminate the service by manually pressing "Ctrl-C".

    LONGDESC
    def monitor
      Command.start_assert_monitor
    end

  end
end
