current = File.join(File.dirname(__FILE__))
# require 'sinatra'
require 'openssl'
require 'base64'
require 'hmac-sha1'
# if options.webservice
#   require "#{current}/boardwalk/control_routes.rb"
# end
require "#{current}/boardwalk/mimetypes_hash.rb"
# require "#{current}/boardwalk/s3_routes.rb"
require "#{current}/boardwalk/s3_service.rb"

class Boardwalk < Sinatra::Base
  # class Application
    register Sinatra::Request::AWSHandler
    
    # helpers do
    #   def hmac_sha1(key, s)
    #     return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), key, s)).strip
    #   end
    # end
    # load 'lib/boardwalk/control_routes.rb'
    load 'lib/boardwalk/s3_routes.rb'
  # end
end