# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{depix}
  s.version = "1.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Julik Tarkhanov"]
  s.date = %q{2009-05-21}
  s.default_executable = %q{depix-describe}
  s.description = %q{Read and write DPX file metadata}
  s.email = ["me@julik.nl"]
  s.executables = ["depix-describe"]
  s.extra_rdoc_files = ["DPX_HEADER_STRUCTURE.txt", "History.txt", "Manifest.txt", "README.txt"]
  s.files = ["DPX_HEADER_STRUCTURE.txt", "History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/depix-describe", "depix.gemspec", "lib/depix.rb", "lib/depix/benchmark.rb", "lib/depix/compact_structs.rb", "lib/depix/dict.rb", "lib/depix/editor.rb", "lib/depix/enums.rb", "lib/depix/reader.rb", "lib/depix/struct_explainer.rb", "lib/depix/structs.rb", "test/samples/E012_P001_L000002_lin.0001.dpx", "test/samples/E012_P001_L000002_lin.0002.dpx", "test/samples/E012_P001_L000002_log.0001.dpx", "test/samples/E012_P001_L000002_log.0002.dpx", "test/test_depix.rb", "test/test_dict.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://guerilla-di.rubyforge.org/depix}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{guerilla-di}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Read and write DPX file metadata}
  s.test_files = ["test/test_depix.rb", "test/test_dict.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<timecode>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.3"])
    else
      s.add_dependency(%q<timecode>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 1.8.3"])
    end
  else
    s.add_dependency(%q<timecode>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 1.8.3"])
  end
end
