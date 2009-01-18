Gem::Specification.new do |s|
  s.name = %q{depix}
  s.version = "1.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Julik Tarkhanov"]
  s.date = %q{2008-12-26}
  s.default_executable = %q{depix-describe}
  s.description = %q{Read DPX file metadata}
  s.email = ["me@julik.nl"]
  s.executables = ["depix-describe"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt", "DPX_HEADER_STRUCTURE.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "DPX_HEADER_STRUCTURE.txt", "Rakefile", "bin/depix-describe", "lib/depix.rb", "lib/depix/struct_explainer.rb", "lib/depix/structs.rb", "lib/depix/benchmark.rb", "lib/depix/compact_structs.rb", "lib/depix/enums.rb", "lib/depix/dict.rb", "lib/depix/reader.rb", "lib/depix/editor.rb", "test/test_dict.rb", "test/test_depix.rb", "test/samples/E012_P001_L000002_lin.0001.dpx", "test/samples/E012_P001_L000002_lin.0002.dpx", "test/samples/E012_P001_L000002_log.0001.dpx", "test/samples/E012_P001_L000002_log.0002.dpx"]
  s.has_rdoc = true
  s.homepage = %q{http://guerilla-di.rubyforge.org/depix}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{guerilla-di}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Read DPX file metadata}
  s.test_files = ["test/test_depix.rb", "test/test_dict.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.8.2"])
    else
      s.add_dependency(%q<hoe>, [">= 1.8.2"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.8.2"])
  end
end
