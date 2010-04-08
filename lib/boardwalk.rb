current = File.join(File.dirname(__FILE__))
##
# TODO: Tie all required files here. Load from application.rb in root.
##
require 'sinatra'
require 'openssl'
require 'base64'
require 'hmac-sha1'
# if options.webservice
#   require "#{current}/boardwalk/control_routes.rb"
# end
require "#{current}/boardwalk/mimetypes_hash.rb"
require "#{current}/boardwalk/s3_routes.rb"
require "#{current}/boardwalk/s3_service.rb"

set :s3key, '44CF9590006BF252F707'
set :s3secret, 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV'
set :server, 'mongrel'

# use Rack::Lint # ?

class Boardwalk < Sinatra::Base
  class Application
    helpers do
      def hmac_sha1(key, s)
        return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), key, s)).strip
      end
    end
    # load 'lib/boardwalk/control_routes.rb'
    # load 'lib/boardwalk/s3_routes.rb'
  end
end