# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "testdata_generater_for_mysql/version"

Gem::Specification.new do |s|
  s.name        = "testdata_generater_for_mysql"
  s.version     = TestdataGeneraterForMysql::VERSION
  s.authors     = ["pacojp"]
  s.email       = ["paco.jp@gmail.com"]
  s.homepage    = "https://github.com/pacojp/testdata_generater_for_mysql"
  s.summary     = %q{oreore mysql test data generater}
  s.description = %q{oreore mysql test data generater}

  s.add_dependency 'mysql2'
  s.add_dependency 'progressbar'

  s.rubyforge_project = "testdata_generater_for_mysql"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
