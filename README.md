# ruby-interlnk
Ruby gem to support INTERLNK/INTERSVR communications.

## Description

Ruby class/gem to handle INTERLNK/INTERSVR communications, to communicate with DOS machines.

## Features
 * Supports serial channel type over TCP transport
 * Able to read lists of available drives, names and specifications of the drives
 * Provides a ruby IO-compatible object and can perform general block I/O using it
 * Block I/O layer has basic caching functionality to avoid transfering data over slow links as much as possible

## TODO
 * Actual serial port support
 * Parallel port support
 * Support baud rates other than 115200
 * More graceful error handling, should retry rather than giving up in many places


## Use
    require 'interlnk'
    
    interlnk = Interlnk::Client.new(host: 'localhost', port: 5000)
    drives = @interlnk.drives
    p drives
    interio = @drives['C'].interio
    # can now use interio just like you would a file, likely hooking it up to a FAT library


## Full Documentation
YARD docs included, also available on [RubyDoc.info](https://www.rubydoc.info/github/sarahemm/ruby-interlnk/master)