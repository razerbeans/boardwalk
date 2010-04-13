helpers do
  def current_user_session(user)
    session[:user] = user
  end
  
  def login_required
    if !session[:user]
      redirect '/control/login'
    end
  end
end