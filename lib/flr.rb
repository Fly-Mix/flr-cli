require 'thor'
require 'flr/version'
require 'flr/command'

module Flr

  class CLI < Thor

    desc "version", "Show flr version"
    long_desc <<-LONGDESC
      show the version of flr

    LONGDESC
    def version
      Command.version
    end

    desc "init", "Generate `Flrfile.yaml` file and auto specify package `r_dart_library` in `pubspec.yaml`"
    long_desc <<-LONGDESC
      create a `Flrfile.yaml` file for the current directory if none currently exists,
      and auto specify package `r_dart_library`(https://github.com/YK-Unit/r_dart_library) in `pubspec.yaml`.

    LONGDESC
    def init
      Command.init
    end

    desc "generate", "Scan assets, then auto specify assets in `pubspec.yaml` and generate `R.dart` file"
    long_desc <<-LONGDESC
      scan the assets based on the configs in `Flrfile.yaml`,
      then auto specify assets in `pubspec.yaml`,
      and then generate `R.dart` file,
      and generate asset ID codes in `R.dart`.

    LONGDESC
    def generate
      Command.generate
    end
  end
end
