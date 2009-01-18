require 'rubygems'
require 'hoe'
require './lib/depix'

Hoe.new('depix', Depix::VERSION) do |p|
  p.developer('Julik Tarkhanov', 'me@julik.nl')
  p.rubyforge_name = 'guerilla-di'
  p.extra_deps << 'timecode'
  p.remote_rdoc_dir = 'depix'
end

task :describe_structs do
  require File.dirname(__FILE__) + '/lib/depix/struct_explainer'
  File.open('DPX_HEADER_STRUCTURE.txt', 'w') {|f| f << RdocExplainer.new.get_rdoc_for(Depix::DPX) }
end