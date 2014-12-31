# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'confetti1/import/version'

Gem::Specification.new do |spec|
  spec.name          = "confetti1-import"
  spec.version       = Confetti1::Import::VERSION
  spec.authors       = ["Vitaliy Trofymyuk"]
  spec.email         = ["vitaliy.trofymyuk@globallogic.com"]
  spec.summary       = %q{Import from ClearCase to GIT}
  spec.description   = %q{Provides import}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency  'bundler', '1.7.7'
  spec.add_development_dependency  'rake', '10.0'
  spec.add_development_dependency  'minitest', '5.4.2'
  spec.add_development_dependency  'pry', '0.10.1'
  spec.add_development_dependency  'colorize', '0.7.5'
  spec.add_development_dependency  'awesome_print', '1.2.0'
end
