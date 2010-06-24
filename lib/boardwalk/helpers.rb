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
    raise AccessDenied unless @user
  end
  
  def only_can_read(bucket)
    raise AccessDenied unless bucket.readable_by? @user
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
end