$:.unshift "./lib"
require 'rubygems'
require 'optparse'
require 'sinatra'
require 'bundler'
Bundler.setup
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
require 'digest/md5'
require 'boardwalk/mimetypes'

DEFAULT_PASSWORD = 'pass@word1'
DEFAULT_SECRET = 'OtxrzxIsfpFjA7SwPzILwy8Bw21TLhquhboDYROV'

VERSION = '0.2.0.3'

File.exists?("config.yaml") ? options = OpenStruct.new(YAML.load(File.open("config.yaml"))) : options = OpenStruct.new
options.host = '127.0.0.1' if options.host.nil?
options.port = 3002 if options.port.nil?
options.environment = :production if options.environment.nil?
options.server = 'thin' if options.server.nil?
options.mongodb_host = 'localhost' if options.mongodb_host.nil?
options.mongodb_port = 27017 if options.mongodb_port.nil?
options.mongodb_prefix = 'boardwalk' if options.mongodb_prefix.nil?
options.mongodb_user = '' if options.mongodb_user.nil?
options.mongodb_password = '' if options.mongodb_password.nil?

opts = OptionParser.new do |opts|
  opts.banner = "Usage: boardwalk [options] [host] [port]"
  opts.separator "Default host is #{options.host}; default port is #{options.port.to_s}."
  
  opts.separator ""
  opts.separator "Boardwalk specific options:"
  
  opts.on("-e", "--environment ENVIRONMENT", "Environment in which Boardwalk will be run (default: #{options.environment.to_s})") do |e|
    options.environment = e.to_sym
  end
  opts.on("-s", "--server SERVER", "Desired web server software to use. (default: thin)") do |s|
    options.server = s
  end
  
  opts.separator ""
  opts.separator "MongoDB specific options:"
  
  opts.on("--mongodb-host HOST",
          "Host address of MongoDB. (default: localhost)") do |h|
    options.mongodb_host = h
  end
  opts.on("--mongodb-port PORT",
          "Port number of MongoDB. (default: 27017)") do |p|
    options.mongodb_port = p
  end
  opts.on("--mongodb-prefix PREFIX",
          "Prefix of the MongoDB database. (i.e. 'boardwalk_production' if PREFIX is 'boardwalk' and environment is 'production')") do |p|
    options.mongodb_prefix = n
  end
  opts.on("--mongodb-user USER",
          "User to use when connecting to the MongoDB as. (nil by default)") do |u|
    options.mongodb_user = u
  end
  opts.on("--mongodb-password PASSWORD",
          "Password to use when conncting to MongoDB. (nil by default)") do |p|
    options.mongodb_password = p
  end
  
  opts.separator ""
  opts.separator "Common options:"
  
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
  
  opts.on_tail("--version", "Show the current version of Boardwalk") do
    puts "Boardwalk v" + VERSION
    exit
  end
end

opts.parse! ARGV
options.host = ARGV[0] if ARGV[0]
options.port = ARGV[1].to_i if ARGV[1]

BIND_HOST = options.host

set :environment, options.environment.to_sym
set :root, File.dirname(__FILE__).to_s+'/../'
MONGO_HOST = options.mongodb_host
MONGO_PORT = options.mongodb_port
MONGO_USER = options.mongodb_user
MONGO_PASSWORD = options.mongodb_password

configure do
  set :server, options.server
  set :bind, options.host
  set :port, options.port
  set :sessions, true
  set :show_exceptions, false
  set :raise_errors, false
end

configure :development do
  set :logging, true
  MONGO_DB = options.mongodb_prefix.to_s+'_development'
end

configure :production do
  set :logging, false
  MONGO_DB = options.mongodb_prefix.to_s+'_production'
end

load 'boardwalk/models.rb'

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