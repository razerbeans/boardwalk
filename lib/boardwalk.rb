##
# TODO: Tie all required files here. Load from application.rb in root.
##
require 'sinatra'
require 'openssl'
require 'base64'
require 'boardwalk/control_routes.rb'
require 'boardwalk/mimetypes_hash.rb'
require 'boardwalk/s3_routes.rb'
require 'boardwalk/s3_service.rb'

use Rack::Lint # ?
use S3Service

class Application < Sinatra::Base
  load 'lib/boardwalk/control_routes.rb'
  load 'lib/boardwalk/s3_routes.rb'
end