$:.unshift "./lib"
require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
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
  set :logging, true
  set :show_exceptions, true
  DataMapper.setup(:default, 'mysql://root:into3ternity@localhost/boardwalk_development')
end

configure :production do
  set :logging, false
  set :show_exceptions, false
  DataMapper.setup(:default, 'mysql://root:into3ternity@localhost/boardwalk_production')
end

configure :test do
  DataMapper.setup(:default, 'mysql://root:into3ternity@localhost/boardwalk_test')
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