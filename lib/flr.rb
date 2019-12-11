require 'thor'
require 'flr/version'
require 'flr/command'

module Flr

  class CLI < Thor

    desc "version", "Show flr version"
    def version
      Command.version
    end

    desc "init", "Generate a `Flrfile.yaml` and Add `r_dart_library` declaration into `pubspec.yaml`"
    long_desc <<-LONGDESC
      Create a `Flrfile` for the current directory if none currently exists, 
      and add the dependency declaration of `r_dart_library`(https://github.com/YK-Unit/r_dart_library)  into `pubspec.yaml`.

    LONGDESC
    def init
      Command.init
    end

    desc "generate", "Search asserts, and Add assert declarations into `pubspec.yaml`, and Generate `R.dart`"
    long_desc <<-LONGDESC
      Search the asserts based on the assert directory settings in `Flrfile`,
      and then add the assert declarations into `pubspec.yaml`,
      and then generate `R.dart`.

    LONGDESC
    def generate
      Command.generate
    end
  end
end
