= depix

* http://rubyforge.org/julik/depix

== DESCRIPTION:

Read DPX file metadata

== SYNOPSIS:

  meta = Depix::Reader.new.from_file(dpx_file_path)
  puts meta.television.time_code #=> 10:00:00:02
  
The data returned is described in the DPX_HEADER_STRUCTURE[link:files/DPX_HEADER_STRUCTURE_txt.html]. The structs
used for actual parsing are in the Depix::Structs module (but in a much less readable form, obviously)

== NOTES:

The reader tries to be efficient - fast Ruby unpacking is used, some shortcuts are taken. Also don't worry - we do not need to read
the whole DPX file (which usually is around 8mb per frame) to know the details

== REQUIREMENTS:

* timecode gem (sudo gem install timecode)

== INSTALL:

* sudo gem install depix

== LICENSE:

(The MIT License)

Copyright (c) 2008 Julik Tarkhanov

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
