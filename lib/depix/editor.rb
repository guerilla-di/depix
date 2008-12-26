module Depix
  class Editor
    attr_accessor :path
    def initialize(file_path)
      @path = file_path
    end
    
    def get_header
      Depix.from_file(@path)
    end
    
    # Save the header to disk
 # def commit_header(header)
 #   packed = DPX.pack(header)
 #   # Validate that we can unpack first - what if something went wrong?
 #   DPX.apply(packed)
 #   
 #   File.open(@path, 'rb+') do | f |
 #     f.seek(0)
 #     f.write(DPX.pack(header))
 #   end
 # end
  end
end