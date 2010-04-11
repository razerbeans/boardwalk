# See parkplace helpers.rb for reference.
require 'sinatra/base'
require 'openssl'
require 'base64'
require 'hmac-sha1'

##
# TODO: Removed User class from this document once implementing database 
#       handler.
##
class User
  def initialize(key)
    @login = 'testuser'
    @key = key
  end
  
  def key
    @key
  end
  
  def login
    @login
  end
end

module Sinatra
  class Request
    module AWSHandler
      def aws_authenticate
        before {
          puts "Should do env loop."
          @env.each do |k, v|
            puts "Running env loop. (#{k}, #{v})"
            k = k.downcase.gsub('_', '-')
            @amz[$1] = v.strip if k =~ /^http-x-amz-([-\w]+)$/
          end
          date = (@env['HTTP_X_AMZ_DATE'] || @env['HTTP_DATE'])
          auth, key, secret = *@env['HTTP_AUTHORIZATION'].to_s.match(/^AWS (\w+):(.+)$/)
          uri = @env['PATH_INFO']
          uri += "?" + @env['QUERY_STRING'] if RESOURCE_TYPES.include?(@env['QUERY_STRING'])
          canonical = [@env['REQUEST_METHOD'], @env['HTTP_CONTENT_MD5'], @env['HTTP_CONTENT_TYPE'], date, uri]
          # PSEDUO: If the user sent secret string is equal to the user's 
          #         [encrypted] information from the server, user is clear.
          #         otherwise, user is not allowed.
          # TODO: Remove User.new!
          # @user = Boardwalk::Models::User.find_by_key key
          @user = User.new(key)
          if @user and secret != hmac_sha1(options.s3secret, canonical.map{|v|v.to_s.strip} * "\n")
            raise BadAuthentication
          end
        }
      end
      
      def hmac_sha1(key, s)
        return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), key, s)).strip
      end     
    end
  end
  register Request::AWSHandler
end