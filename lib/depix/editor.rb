module Depix
  # Used to edit DPX headers. Create an Editor object
  class Editor

    # Stores the path to file
    attr_reader :path
    
    # Stores the Depix::DPX object with headers
    attr_reader :headers
    
    # Save the headers to file at path, overwriting the old ones
    def initialize(file_path)
      @path = file_path
      @headers = Depix.from_file(@path)
    end
    
    # Save the headers to file at path, overwriting the old ones
    def commit!
      raise "No instance" unless @headers
      packed = @headers.class.pack(@headers)
      
      # Validate that we can unpack first - what if something went wrong?
      Depix::Reader.new.parse(packed, false)
      
      File.open(@path, 'rb+') do | f |
        f.seek(0, IO::SEEK_SET); f.write(packed)
      end
    end
  end
end