# frozen_string_literal: true

version = File.readlines("lib/jit_buffer.rb").grep(/VERSION = /).first[/[\d.]+/]

Gem::Specification.new do |spec|
  spec.name          = "jit_buffer"
  spec.version       = version
  spec.authors       = ["Aaron Patterson"]
  spec.email         = ["tenderlove@ruby-lang.org"]

  spec.summary       = %q{A JIT Buffer object for Ruby.}
  spec.description   = %q{A JIT Buffer object for Ruby.}
  spec.homepage      = "https://github.com/tenderlove/jit_buffer"
  spec.licenses      = ["Apache-2.0"]

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.require_paths = ["lib"]
  spec.extensions = ["ext/jit_buffer/extconf.rb"]

  spec.add_development_dependency "rake", '~> 13.0'
  spec.add_development_dependency "rake-compiler", '~> 1.1'
  spec.add_development_dependency "minitest", '~> 5.15'
  spec.add_dependency "fiddle", '~> 1.1'
end
