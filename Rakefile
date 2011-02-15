require 'rubygems'
require 'hoe'
require './lib/depix'

Hoe.spec('depix') do |p|
  p.version = Depix::VERSION
  p.developer('Julik Tarkhanov', 'me@julik.nl')
  p.rubyforge_name = 'guerilla-di'
  p.extra_deps << ['timecode']
  p.remote_rdoc_dir = 'depix'
  p.readme_file   = 'README.rdoc'
  p.extra_rdoc_files  = FileList['*.rdoc']
  
  p.clean_globs = %w( **/.DS_Store )
end

task :describe_structs do
  require File.dirname(__FILE__) + '/lib/depix/struct_explainer'
  File.open('DPX_HEADER_STRUCTURE.rdoc', 'w') {|f| f << RdocExplainer.new.get_rdoc_for(Depix::DPX) }
end