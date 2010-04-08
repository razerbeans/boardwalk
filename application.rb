LOCATION = File.join(File.dirname(__FILE__))
require 'rubygems'
require 'sinatra'
require 'mongo'
require 'mongo_mapper'
# require "#{File.join(File.dirname(__FILE__))}/lib/boardwalk/mimetypes_hash.rb"
# require "#{File.join(File.dirname(__FILE__))}/lib/boardwalk/s3_service.rb"
require "#{LOCATION}/lib/boardwalk.rb"

# use Boardwalk::Application
Boardwalk.run!