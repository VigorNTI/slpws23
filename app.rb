require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model/model.rb'
include Model

enable :sessions

max_login_attempts = 3
cooldown_s = 10

# Get the user from the database, it passes the user id from the session automatically
#
# @return [Hash] the hash associated with a user from the database
def get_user()
  return get_user_db(session[:id])
end

# Checks if the logged in user is admin or not
#
# @return [Boolean] true if the user is admin and false otherwise
def is_admin()
  return is_admin_db(session[:id])
end

# Redirects the user to '/products'
get('/') do
  redirect('/products')
end

# Displays a register form
get('/register') do
  slim(:register, locals:{user:nil})
end 

# Creates a new user
#
# @see Model#register_user
post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password != password_confirm)
    return "Lösenorden matchade inte"
  end

  if register_user(username, password) == true then
    redirect("/")
  else
    return "Användarnamn taget!"
  end
end

# Displays a login form
get('/login') do
  if get_user() != nil then
    redirect('/')
    return
  end
  slim(:login, locals:{user:get_user(), state:params[:state]})
end

# Logs the user out
get('/logout') do
  session[:id] = nil
  redirect('/')
end

# Logs the user in
#
# @see Model#login
post('/login') do
  if session["last_login_attempt"] && (Time.now.to_f * 1000).to_i < session["last_login_attempt"] + cooldown_s * 1000 then
    p "Time left: #{session['last_login_attempt'] + cooldown_s * 1000 - (Time.now.to_f * 1000).to_i}"
  else
    session["login_attempts"] = 0
  end

  if session["login_attempts"] != nil && session["login_attempts"] < max_login_attempts then
    session["last_login_attempt"] = (Time.now.to_f * 1000).to_i
    username = params[:username]
    password = params[:password]
    puts("Login attempt for #{username}")
    
    id = login(username, password)
    if id >= 0 then
      session[:id] = id
      session["login_attempts"] = 0
      redirect("/")
    end
    if session["login_attempts"] == nil then
      session["login_attempts"] = 1
    else
      session["login_attempts"] += 1
    end
    if session["login_attempts"] < max_login_attempts then
      redirect("/login?state=badlogin")
    end
  end
  redirect("/login?state=cooldown")
end

# Check if the eventually logged in user is admin or not and halts sinatra if the user is not logged in or the user is not admin
def check_admin()
  if !is_admin() then
    halt 401, {'Content-Type' => 'text/plain'}, 'You should not be here'
  end
end

require_relative 'routes/products.rb'
require_relative 'routes/suppliers.rb'
require_relative 'routes/shoppingcart.rb'
require_relative 'routes/checkout.rb'
require_relative 'routes/orders.rb'
require_relative 'routes/users.rb'
