
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "flr/version"

Gem::Specification.new do |spec|
  spec.name          = "flr"
  spec.version       = Flr::VERSION
  spec.authors       = ["York"]
  spec.email         = ["yorkzhang520@gmail.com"]

  spec.summary       = "Flr(Flutter-R): A Flutter Resource Manager CLI TooL."
  spec.description   = "Flr(Flutter-R): A Flutter Resource Manager CLI TooL, which can help flutter developer to auto specify assets in pubspec.yaml and generate r.g.dart file after he changes the flutter project assets."
  spec.homepage      = "https://github.com/Fly-Mix/flr-cli"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata["allowed_push_host"] = "https://rubygems.org"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|README)}) }
  end

  spec.bindir        = "bin"
  spec.executables   = ["flr"]
  spec.require_paths = ["lib"]

  # spec.add_development_dependency "rake", "~> 10.0"
  # spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "bundler", "~> 2.0", '>= 2.0.2'
  spec.add_runtime_dependency "thor", "~> 1.0", '>= 1.0.1'
  spec.add_runtime_dependency "listen", "~> 3.0", '>= 3.2.1'

end
