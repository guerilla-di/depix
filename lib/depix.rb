require 'rubygems'
require 'timecode'

require File.expand_path(File.dirname(__FILE__)) + '/depix/binary/fields'
require File.expand_path(File.dirname(__FILE__)) + '/depix/binary/structure'

require File.expand_path(File.dirname(__FILE__)) + '/depix/structs'
require File.expand_path(File.dirname(__FILE__)) + '/depix/compact_structs'
require File.expand_path(File.dirname(__FILE__)) + '/depix/enums'

require File.expand_path(File.dirname(__FILE__)) + '/depix/synthetics'
require File.expand_path(File.dirname(__FILE__)) + '/depix/reader'
require File.expand_path(File.dirname(__FILE__)) + '/depix/editor'


module Depix
  VERSION = '2.0.0'
  
  class InvalidHeader < RuntimeError; end
  
  DPX.send(:include, Synthetics)
  
  # Return a DPX object describing a file at path.
  # The second argument specifies whether you need a compact or a full description
  def self.from_file(path, compact = false)
    Reader.new.from_file(path, compact)
  end
  
  # Return a DPX object describing headers embedded at the start of the string.
  # The second argument specifies whether you need a compact or a full description
  def self.from_string(string, compact = false)
    Reader.new.parse(string, compact)
  end
  
  # Retrurn a formatted description of the DPX file at path. Empty values are omitted.
  def self.describe_file(path, compact = false)
    Reader.new.describe_file(path, compact)
  end
  
  # Return a formatted description of the DPX file at path, showing only synthetic attributes
  def self.describe_brief(path)
    Reader.new.describe_synthetics_of_struct(from_file(path))
  end
  
end