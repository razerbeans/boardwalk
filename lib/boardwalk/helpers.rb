helpers do
  def current_user_session(user)
    session[:user] = user
  end
  
  def login_required
    if !session[:user]
      redirect '/control/login'
    end
  end
  
  def only_authorized
    raise AccessDenied unless current_user
  end
  
  def only_can_read(bucket)
    raise AccessDenied unless bucket.readable_by? current_user
  end
  
  def check_credentials(username, password)
    user = User.first(:login => username)
    puts user.inspect
    puts "COMPARISON #{hmac_sha1(password, user.s3secret)}"
    if user.password == hmac_sha1(password, user.s3secret)
      session[:user] = user
      return true
    else
      return false
    end
  end
  
  def current_user
    return session[:user]
  end
  
  def hmac_sha1(key, s)
    return Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), key, s)).strip
  end
  
  def load_buckets
    # First, look up the buckets that are owned by the user.
    buckets = current_user.buckets
    # Second, look up the buckets that the user has access to.
    
    @buckets = buckets
    @bucket = Bucket.new(:access => CANNED_ACLS['private'])
  end
end