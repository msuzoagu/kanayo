#!/usr/local/bin/ruby

$LOAD_PATH.unshift(File.expand_path(".", "lib"))
require 'cli.rb'

Cli.start(ARGV)
