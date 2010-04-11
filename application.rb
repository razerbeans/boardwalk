$:.unshift "./lib"
require 'rubygems'
require 'sinatra'
require 'mongo'
require 'mongo_mapper'
require 'boardwalk'
require 'haml'

set :environment, :development

configure do
  set :server, %w[mongrel webrick]
  set :port, 3002
  set :sessions, true
end

configure :development do
  set :s3key, '44CF9590006BF252F707'
  set :s3secret, 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV'
  # set :server, %w[mongrel webrick]
  # set :port, 3002
  set :logging, true
  set :show_exceptions, false
  
  MongoMapper.database = 'boardwalk_dev'
end

configure :production do
  set :logging, false
  set :show_exceptions, false
  
  MongoMapper.database = 'boardwalk'
end

configure :test do
  MongoMapper.database = 'boardwalk_test'
end

# BUFSIZE = (4 * 1024)
# STORAGE_PATH = File.join(Dir.pwd, 'storage')
# STATIC_PATH = File.expand_path('views/', File.dirname(__FILE__))
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