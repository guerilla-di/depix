require 'rubygems'
require 'hoe'
require './lib/depix.rb'

Hoe.new('depix', Depix::VERSION) do |p|
  p.developer('Julik Tarkhanov', 'me@julik.nl')
  p.rubyforge_name = 'wiretap'
  p.extra_deps.reject! {|e| e[0] == 'hoe' }
end

task :describe_structs do
  require File.dirname(__FILE__) + '/lib/depix/struct_explainer'
  File.open('DPX_HEADER_STRUCTURE.txt', 'w') {|f| f << RdocExplainer.new.get_rdoc_for(Depix::Structs::DPX_INFO) }
end