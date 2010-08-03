= depix

* http://guerilla-di.org/depix

== DESCRIPTION:

Read and write DPX file metadata

== SYNOPSIS:

Reading headers

  meta = Depix.from_file(dpx_file_path)
  puts meta.time_code #=> 10:00:00:02

Writing headers
  
  editor = Depix::Editor.new(dpx_file_path)

  # Advance the time code by one frame and save
  editor.headers.time_code = editor.headers.time_code + 1
  editor.commit!
  
The data returned is described in the DPX_HEADER_STRUCTURE[link:files/DPX_HEADER_STRUCTURE_txt.html]. It's
a vanilla Ruby object with no extra methods except for the readers that have the same name as the specified
fields

The gem also contains an executable called depix-desribe which can be used from the command line
  
  $book depix-describe 001_PTAPE_001.001.dpx

for a long description or 

  $book depix-describe -s 001_PTAPE_001.001.dpx 

for a short description

== NOTES:

Autodesk IFFS systems write the reel name for the file to the orientation.device field, some scanners write it into user data.

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
