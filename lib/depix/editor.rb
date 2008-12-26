module Depix
  # Used to edit DPX headers. Create an Editor object and pass the path to the file to it. Change the headers variable to contain the edited
  # DPX headers and call commit!. Note that the DPX header will be overwritten in place - if you want to save another version you need to manage it yourself
  class Editor

    # Stores the path to file
    attr_reader :path
    
    # Stores the Depix::DPX object with headers
    attr_accessor :headers
    
    # Create a new editor for the file at path
    def initialize(file_path)
      @path = file_path
      @headers = Depix.from_file(@path)
    end
    
    # Save the headers to file at path, overwriting the old ones
    def commit!
      raise "No headers" unless @headers
      raise "Cannot pack LE headers" if @headers.le?
      packed = @headers.class.pack(@headers)
      
      # Validate that we can unpack first - what if something went wrong?
      Depix::Reader.new.parse(packed, false)
      
      File.open(@path, 'rb+') do | f |
        f.seek(0, IO::SEEK_SET); f.write(packed)
      end
    end
  end
end