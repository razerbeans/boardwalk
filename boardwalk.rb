require 'rubygems'
require 'sinatra'
require 'mongo'
require 'mongo_mapper'
require "#{File.join(File.dirname(__FILE__))}/lib/boardwalk/mimetypes_hash.rb"

# module Boardwalk  
  # class Application < Sinatra::Base
  ##
  # Views were contained in the control in parkplace, however sinatra loads 
  # the views from the [root]/views/ directory. That removes the need to
  # include them here.
  ##    
    load 'lib/boardwalk/control_routes.rb'
    load 'lib/boardwalk/s3_routes.rb'
  # end
# end