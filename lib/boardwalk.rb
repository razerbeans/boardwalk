module Sinatra
  class Request
    module AWSHandler
        def aws_authenticate
          @amz = {}
          @env.each do |k, v|
            k = k.downcase.gsub('_', '-')
            @amz[$1] = v.strip if k =~ /^http-x-amz-([-\w]+)$/
          end
          date = (@env['HTTP_X_AMZ_DATE'] || @env['HTTP_DATE'])
          auth, key, secret = *@env['HTTP_AUTHORIZATION'].to_s.match(/^AWS (\w+):(.+)$/)
          uri = @env['PATH_INFO']
          uri += "?" + @env['QUERY_STRING'] if RESOURCE_TYPES.include?(@env['QUERY_STRING'])
          canonical = [@env['REQUEST_METHOD'], @env['HTTP_CONTENT_MD5'], @env['HTTP_CONTENT_TYPE'], date, uri]
          @amz.sort.each do |k, v|
              canonical[-1,0] = "x-amz-#{k}:#{v}"
          end
          @user = User.first(:conditions => {:s3key => key})
          if @user and secret != hmac_sha1(@user.s3secret, canonical.map{|v|v.to_s.strip} * "\n")
             raise BadAuthentication
          end
        end
      private
        def hmac_sha1(key, s)
          return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), key, s)).strip
        end     
    end
  end
  helpers Request::AWSHandler
end

class Boardwalk < Sinatra::Base
    use Rack::FiberPool
    load 'lib/boardwalk/mimetypes.rb'
    load 'lib/boardwalk/control_routes.rb'
    load 'lib/boardwalk/helpers.rb'
    load 'lib/boardwalk/errors.rb'
    helpers Sinatra::Request::AWSHandler
    load 'lib/boardwalk/s3_routes.rb'
end