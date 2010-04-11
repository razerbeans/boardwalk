helpers do
  def current_user_session(user)
    session[:user] = user
  end
  
  def login_required
    if !session[:user]
      403
      redirect '/control/login'
    end
  end
end