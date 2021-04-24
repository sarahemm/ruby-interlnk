# ruby-interlnk
Ruby gem to support INTERLNK/INTERSVR communications.

## Description

Ruby class/gem to handle INTERLNK/INTERSVR communications, to communicate with DOS machines.

## Features
 * Supports client-side communications (emulates INTERLNK)
 * Supports serial channel type over TCP transport (for use with e.g. VirtualBox serial ports)
 * Able to read lists of available drives, names and specifications of the drives
 * Provides an IO-compatible object to perform IO against
 * Basic caching functionality to avoid transfering data over slow links as much as possible

## TODO
 * Actual serial port support
 * Parallel port support
 * Support baud rates other than 115200
 * Support server-side communications (emulate INTERSVR)
 * More graceful error handling, should retry rather than giving up in many places


## Use
    require 'interlnk'
    
    # connect to INTERSVR over a TCP serial port (e.g. to VirtualBox)
    interlnk = Interlnk::Client.new(
      transport: Interlnk::Transport::Tcp,
      channel: Interlnk::Channel::Serial,
      connection_info: {host: 'localhost', port: 5000}
    )
    drives = interlnk.drives
    p drives
    interio = drives['C'].interio
    # can now use interio just like you would a file, likely hooking it up to a FAT library


## Full Documentation
YARD docs included, also available on [RubyDoc.info](https://www.rubydoc.info/github/sarahemm/ruby-interlnk/master)
