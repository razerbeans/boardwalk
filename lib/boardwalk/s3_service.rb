=begin
# NOTE: This will most likely have to be in Rack so that requests using aws can
# be directed before being processed in sinatra.

# Here's what _why did...
# service() in this sense is defined to overwrite the default service behavior
# in camping. Basically, disect and encrypt the header so that it may be 
# checked against the user's signature.
  def service(*a)
    # Copy the header twice. Not sure what meta is for.
      @meta, @amz = ParkPlace::H[], ParkPlace::H[]
  # @env is an H containing the HTTP headers and server info.
      @env.each do |k, v|
          k = k.downcase.gsub('_', '-')
          @amz[$1] = v.strip if k =~ /^http-x-amz-([-\w]+)$/
          @meta[$1] = v if k =~ /^http-x-amz-meta-([-\w]+)$/
      end

      auth, key_s, secret_s = *@env.HTTP_AUTHORIZATION.to_s.match(/^AWS (\w+):(.+)$/)
      date_s = @env.HTTP_X_AMZ_DATE || @env.HTTP_DATE
      if @input.Signature and Time.at(@input.Expires.to_i) >= Time.now
          key_s, secret_s, date_s = @input.AWSAccessKeyId, @input.Signature, @input.Expires
      end
      uri = @env.PATH_INFO
      uri += "?" + @env.QUERY_STRING if ParkPlace::RESOURCE_TYPES.include?(@env.QUERY_STRING)
      canonical = [@env.REQUEST_METHOD, @env.HTTP_CONTENT_MD5, @env.HTTP_CONTENT_TYPE, 
          date_s, uri]
      @amz.sort.each do |k, v|
          canonical[-1,0] = "x-amz-#{k}:#{v}"
      end
      @user = ParkPlace::Models::User.find_by_key key_s
      if @user and secret_s != hmac_sha1(@user.secret, canonical.map{|v|v.to_s.strip} * "\n")
          raise BadAuthentication
      end

      s = super(*a)
      s.headers['Server'] = 'ParkPlace'
      s
  rescue ParkPlace::ServiceError => e
      xml e.status do |x|
          x.Error do
              x.Code e.code
              x.Message e.message
              x.Resource @env.PATH_INFO
              x.RequestId Time.now.to_i
          end
      end
      self
  end

  # Parse any ACL requests which have come in.
  def requested_acl
      # FIX: parse XML
      raise NotImplemented if @input.has_key? 'acl'
      {:access => ParkPlace::CANNED_ACLS[@amz['acl']] || ParkPlace::CANNED_ACLS['private']}
  end
=end

helpers do
  def hmac_sha1(key, s)
    return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), key, s)).strip
  end
end