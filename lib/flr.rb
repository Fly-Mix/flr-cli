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

    desc "init", "Generate `Flrfile.yaml` and auto specify package `r_dart_library` in `pubspec.yaml`"
    long_desc <<-LONGDESC
      Create a `Flrfile.yaml` file for the current directory if none currently exists,
      and automatically specify package `r_dart_library`(https://github.com/YK-Unit/r_dart_library) in `pubspec.yaml`.

    LONGDESC
    def init
      Command.init
    end

    desc "generate", "Perform once a assets scan, then auto specify scanned assets in `pubspec.yaml`, and generate `R.dart`"
    long_desc <<-LONGDESC
      Perform once a assets scan for your project,
      then automatically specify scanned assets in `pubspec.yaml`,
      and generate `R.dart` file.

    LONGDESC
    def generate
      Command.generate
    end

    desc "monitor", "Launch a monitoring service, and when detects asset changes, will auto run `generate` task. Press `Ctrl-C` can terminate the service"
    long_desc <<-LONGDESC
       Launch a monitoring service that continuously monitors asset changes for your project. 

       If there are any changes, it will automatically perform a assets scan,
       then specify scanned assets in `pubspec.yaml`,
       and generate the `R.dart` file.

       You can terminate the service by manually pressing `Ctrl-C`.

    LONGDESC
    def monitor
      Command.start_assert_monitor
    end

  end
end
