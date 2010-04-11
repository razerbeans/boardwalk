require 'openssl'
require 'base64'
require 'hmac-sha1'
require 'boardwalk/mimetypes'
# require 'boardwalk/s3_routes'
require 'boardwalk/s3_service'
require 'boardwalk/models'

class Boardwalk < Sinatra::Base
    register Sinatra::Request::AWSHandler
    load 'lib/boardwalk/control_routes.rb'
    load 'lib/boardwalk/helpers.rb'
    load 'lib/boardwalk/s3_routes.rb'
end