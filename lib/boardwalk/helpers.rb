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
end