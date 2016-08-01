# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rooted_tree/version'

Gem::Specification.new do |spec|
  spec.name          = "rooted_tree"
  spec.version       = RootedTree::VERSION
  spec.authors       = ["Sebastian Lindberg"]
  spec.email         = ["seb.lindberg@gmail.com"]

  spec.summary       = %q{A basic implementation of a tree data structure.}
  spec.description   = %q{This gem implements a rooted, ordered tree, with a focus on easy iteration over nodes and access to basic tree properties.}
  spec.homepage      = "https://github.com/seblindberg/ruby-rooted_tree"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "coveralls", "~> 0.8"
end
