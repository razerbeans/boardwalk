$:.unshift "./lib"
require 'rubygems'
require 'bundler'
Bundler.setup(:default)
require 'sinatra'
require 'builder'
require 'fiber'
require 'rack/fiber_pool'
require 'boardwalk'
require 'haml'
require 'mongo'
require 'mongo_mapper'
require 'joint'
require 'openssl'
require 'base64'
require 'boardwalk/mimetypes'
require 'boardwalk/models'
require 'boardwalk/errors'

set :environment, :development

configure do
  set :server, %w[thin webrick mongrel]
  set :port, 3002
  set :sessions, true
end

configure :development do
  set :s3key, '44CF9590006BF252F707'
  set :s3secret, 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV'
  set :logging, true
  set :show_exceptions, true
end

configure :production do
  set :logging, false
  set :show_exceptions, false
end

configure :test do
end

BUFSIZE = (4 * 1024)
RESOURCE_TYPES = %w[acl torrent]
CANNED_ACLS = {
    'private' => 0600,
    'public-read' => 0644,
    'public-read-write' => 0666,
    'authenticated-read' => 0640,
    'authenticated-read-write' => 0660
}
READABLE = 0004
WRITABLE = 0002
READABLE_BY_AUTH = 0040
WRITABLE_BY_AUTH = 0020

Boardwalk.run