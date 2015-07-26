[![Build Status](https://travis-ci.org/guerilla-di/depix.svg?branch=master)](https://travis-ci.org/guerilla-di/depix)

A Ruby reader and writer library for DPX file metadata.

## What are DPX files?

DPX stands for [Digital Picture Exchange.](http://en.wikipedia.org/wiki/Digital_Picture_Exchange)

In addition to the image data these files embed a massive amount of metadata which can be used to
automatically catalog and search in big file collections (and searching is essential since a complete
feature film will run well into tens of thousands of files). Reading this metadata can easily help with
cumbersome tasks like sorting DPX files per reel/timecode, resolution, selective copying/processing and such daily tasks.

This is what Depix does, in pure Ruby (no C libraries required).

Additionally, **depix** supports editing of DPX metadata without the need to copy the file over (since files can
be big). The metadata gets modified in-place without any copy operations, which is especially helpful when operating across a network.

## Basic usage

Reading headers

    meta = Depix.from_file(dpx_file_path)
    puts meta.time_code #=> 10:00:00:02

Writing headers
  
    editor = Depix::Editor.new(dpx_file_path)
    
    # Advance the time code by one frame and save
    editor.headers.time_code = editor.headers.time_code + 1
    editor.commit!
  
The data returned is described in the [DPX_HEADER_STRUCTURE.rdoc](DPX_HEADER_STRUCTURE.rdoc)
It's a vanilla Ruby object with no extra methods except for the readers that
have the same name as the specified fields.

The gem also contains an executable called depix-desribe which can be used from the command line
  
    $depix_describe 001_PTAPE_001.001.dpx

for a long description or 

    $depix_describe -s 001_PTAPE_001.001.dpx 

for a short description.

    $depix_describe ~/Desktop/Storm/E036/E036_L005.0007.dpx
    Describing DPX /Users/julik/Desktop/Storm/E036/E036_L005.0007.dpx. Empty elements are omitted.
    ===================================================
    File information   Endianness (SDPX is big endian) SDPX
      Offset to image data in bytes 8192
      Version of header format V1.0
      Total image size in bytes 9641984
      Whether the basic headers stay the same through the sequence (1 means they do) 1
      Generic header length 1664
      Industry header length 384
      User header length 6144
      Original filename E036_L005.0007.dpx
      Creation 15 2009:02:13:11:19:37+10
      Creator application ARRISCAN077
      Project name De_Storm_VFX
    ..... lots of info...
    
    
    Synthetic properties
    ============
    keycode : 02 05 32 173388 6668
    component_type : RGB
    colorimetric : UserDefined
    aspect : 1.00
    le? : false
    time_code : 03:38:02:01
    flame_reel : 000005

If you have a file that does not import into some application you could run `depix_fix headers` on it to comb
out invalid data (or data some systems do not approve of). To do so, run depix_fix_headers. Note that the files
will be modified in-place

    $depix_fix_headers 001_PTAPE_001.001.dpx

or for a whole sequence - just supply the -s flag and pass one file

    $depix_fix_headers -s 001_PTAPE_001.001.dpx


## Notes and remarks

Autodesk IFFS systems write the reel name for the file to the orientation.device field, some scanners write it into user data.
Currently unpacking slots which contain invalid reals and ints will yield the maximum possible value for the type

Scanning tens of thousands of files is slow, not because Ruby is slow per se but because the disk is constantly
on seek. It is recommended to **cache** the whole bulk of your metadata objects for later reuse, which is perfectly
easy since Depix objects are serializable.

## Dependencies

* timecode gem (sudo gem install timecode)

## Installation

    $gem install depix

## License

(The MIT License)

Copyright (c) 2008-2016 Julik Tarkhanov

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
