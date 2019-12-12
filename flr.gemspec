
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "flr/version"

Gem::Specification.new do |spec|
  spec.name          = "flr"
  spec.version       = Flr::VERSION
  spec.authors       = ["York"]
  spec.email         = ["yorkzhang520@gmail.com"]

  spec.summary       = "Flr(Flutter-R): a tool like AAPT(Android Asset Packaging Tool) to update pubspec.yaml and generate R.dart."
  spec.description   = "Flr(Flutter-R): a tool like AAPT(Android Asset Packaging Tool) to update pubspec.yaml and generate R.dart when developer update flutter project asserts."
  spec.homepage      = "https://github.com/YK-Unit/flr"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata["allowed_push_host"] = "https://rubygems.org"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/YK-Unit/flr"
    spec.metadata["changelog_uri"] = "https://github.com/YK-Unit/flr"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = "bin"
  spec.executables   = ["flr"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "thor", "~> 0.20.3"

  spec.add_runtime_dependency "bundler", "~> 1.17"
  spec.add_runtime_dependency "thor", "~> 0.20.3"
end
