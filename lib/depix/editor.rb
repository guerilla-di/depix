require 'delegate'

module Depix
  # Used to edit DPX headers. Create an Editor object and pass the path to the file to it. Change the headers variable to contain the edited
  # DPX headers and call commit!. Note that the DPX header will be overwritten in place - if you want to save another version you need to manage
  # it yourself.
  #
  #      dpx = Depix::Editor.new("/RAID/scans/1374470_adjusted.dpx")
  #      dpx.file.copyright = "Copyleft"
  #      dpx.file.reserve = "FileReserve"
  #      dpx.orientation.reserve = "OrientReserve"
  #      dpx.orientation.device = "Chainik"
  #      dpx.orientation.serial = "43"
  #      dpx.film.reserve = "FilmRezerve"
  #      dpx.file.project = "Mastermind"
  #      
  #      dpx.commit! # will write out the headers
  class Editor < Delegator

    # Stores the path to file
    attr_reader :path
    
    # Create a new editor for the file at path
    def initialize(file_path)
      @path = file_path
      @dpx = Depix.from_file(@path)
    end
    
    # Copy headers from another DPX object
    def copy_from(another, *fields_to_copy)
      if fields_to_copy.empty?
        @dpx = another.dup
      else
        fields_to_copy.each{|f| @dpx[f] = another[f] }
      end
    end
    
    # Save the headers to file at path, overwriting the old ones
    def commit!
      raise "No headers" unless @dpx
      raise "Cannot pack LE headers yet" if @dpx.le?
      packed = @dpx.class.pack(@dpx)
      
      # Use in-place writing into DPX file (this is what + does)
      File.open(@path, 'rb+') do | f |
        f.seek(0, IO::SEEK_SET); f.write(packed)
      end
    end
    
    # DEPRECATED
    def headers
      STDERR.puts "Depix::Editor#headers is deprecated, use the Editor itself instead"
      self
    end
    
    def __getobj__
      @dpx # return object we are delegating to, required
    end
  end
end