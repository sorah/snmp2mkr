# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'snmp2mkr/version'

Gem::Specification.new do |spec|
  spec.name          = "snmp2mkr"
  spec.version       = Snmp2mkr::VERSION
  spec.authors       = ["sorah (Shota Fukumori)"]
  spec.email         = ["her@sorah.jp"]

  spec.summary       = %q{Collect SNMP values then send to mackerel.io}
  spec.homepage      = "https://github.com/sorah/snmp2mkr"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "snmp"
  spec.add_dependency "mackerel-client"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
end
