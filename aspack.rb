#!/usr/bin/env ruby

require 'find'
require 'fileutils'
require 'optparse'

class Aspack
  def initialize
    @dryrun = false
    @copy = false
    @prog = File.basename($0, ".*")
  end

  def copy(src, dstdir)
    dstdir += '/' unless %r!/$! =~ dstdir
    puts "#{src} -> #{dstdir}"
    unless @dryrun
      FileUtils.makedirs dstdir
      if @copy
        FileUtils.copy src, dstdir
      else
        FileUtils.symlink src, dstdir, { :force => true}
      end
    end
  end

  def traverse(src, dstdir)
    dstdir += '/' unless %r!/$! =~ dstdir
    Find.find src do |f|
      next unless /\.java$/ =~ f
      d = dstdir
      IO.foreach f do |l|
        if l =~ /^\s*package\s+(.*);/
          d = dstdir + Regexp.last_match[1].gsub('.', '/')
          break
        end
      end
      copy f, d
    end
  end

  def parse_opt
    opts = OptionParser.new "Usage: #{@prog} [opts] src dst"
    begin
      opts.on('-n', 'just print commands') { |v| @dryrun = true }
      opts.on('-c', 'copy instead of ln -s') { |v| @copy = true }
      opts.parse!
      raise ArgumentError if ARGV.length != 2
    rescue
      STDERR.puts opts.help
      raise
    end
    [ARGV[0], ARGV[1]]
  end

  def check_args(src, dst)
    if !FileTest.exist? src
      STDERR.puts "#{@prog}: #{src}: No such file or directory"
      raise ArgumentError
    end
    if FileTest.identical? src, dst
      STDERR.puts "#{@prog}: src and dst are identical."
      raise ArgumentError
    end
    if FileTest.exist?(dst) && !FileTest.directory?(dst)
      STDERR.puts "#{@prog}: #{dst} is not direcotry."
      raise ArgumentError
    end
  end

  def run
    begin
      s, d = parse_opt
      check_args s, d
      traverse File.expand_path(s), d
#    rescue
#      exit 1
    end
    0
  end

 def self.run
   self.new.run
 end

end

Aspack.run

# EOF
