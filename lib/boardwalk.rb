current = File.join(File.dirname(__FILE__))
# require 'sinatra'
require 'openssl'
require 'base64'
require 'hmac-sha1'
# if options.webservice
#   require "#{current}/boardwalk/control_routes.rb"
# end
# require "#{current}/boardwalk/mimetypes_hash.rb"
# # require "#{current}/boardwalk/s3_routes.rb"
# require "#{current}/boardwalk/s3_service.rb"
# require "#{current}/boardwalk/models.rb"
require 'boardwalk/mimetypes_hash'
# require 'boardwalk/s3_routes'
require 'boardwalk/s3_service'
require 'boardwalk/models'

class Boardwalk < Sinatra::Base
    register Sinatra::Request::AWSHandler
    
    load 'lib/boardwalk/s3_routes.rb'
end