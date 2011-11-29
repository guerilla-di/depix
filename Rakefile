require 'rubygems'
require './lib/depix'
require 'jeweler'

Jeweler::Tasks.new do |gem|
  gem.version = Depix::VERSION
  gem.name = "depix"
  gem.summary = "Read and write DPX file headers"
  gem.description = "Allows you to read and edit DPX file headers parsed into Ruby objects"
  gem.email = "me@julik.nl"
  gem.homepage = "http://guerilla-di.org/depix"
  gem.authors = ["Julik Tarkhanov"]
  gem.extra_rdoc_files << "DEVELOPER_DOCS.rdoc"
  gem.license = 'MIT'
  gem.executables = ["depix_describe", "depix_fix_headers"]
  gem.extra_rdoc_files  = FileList['*.rdoc']
end

Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
desc "Run all tests"
Rake::TestTask.new("test") do |t|
  t.libs << "test"
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end

task :default => [ :test ]

task :document_structs do
  require './lib/depix/binary/descriptor'
  File.open('DPX_HEADER_STRUCTURE.rdoc', 'w') {|f| f << Depix::Binary::RdocGenerator.new.get_rdoc_for(Depix::DPX) }
end