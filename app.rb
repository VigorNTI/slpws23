require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

def grab_db()
  db = SQLite3::Database.new("db/userbase.db")
  db.results_as_hash = true
  return db
end

def get_user()
  uid = session[:id].to_i
  db = grab_db()
  return db.execute("SELECT * FROM users WHERE id = ?", uid).first
end

get('/') do
  redirect('/products')
end

get('/register') do
  slim(:register, locals:{user:get_user()})
end 

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password != password_confirm)
    return "Lösenorden matchade inte"
  end
  
  # Add user
  password_digest = BCrypt::Password.create(password)
  db = grab_db()
  db.execute("INSERT INTO users (username, pwdigest, admin) VALUES (?,?,0)", username, password_digest)
  redirect("/")
end

get('/login') do
  if get_user() != nil then
    redirect('/')
    return
  end
  slim(:login, locals:{user:get_user(), state:params[:state]})
end

get('/logout') do
  session[:id] = nil
  redirect('/')
end

post('/login') do
  username = params[:username]
  password = params[:password]
  puts("Login attempt for #{username}")
  
  # Match user pwd_digest
  password_digest = BCrypt::Password.create(password)
  db = grab_db()
  result = db.execute("SELECT * FROM users WHERE username = ?", username).first
  if result == nil then
    return "Username or password did not match"
  end
  pwdigest = result["pwdigest"]
  id = result["id"]

  if BCrypt::Password.new(pwdigest) == password
    puts("Positive password match for #{username}, logging in...")
    session[:id] = id
    redirect("/")
  else
    redirect("/login?state=badlogin")
  end
end

def by_key(table)
  hash = {}
  for row in table do
    hash[row["id"]] = row
  end
  return hash
end

def name_by_key(table)
  hash = {}
  for row in table do
    hash[row["id"]] = row["name"]
  end
  return hash
end

def by_field(table, field)
  hash = {}
  for row in table do
    hash[row[field]] = row
  end
  return hash
end

def is_admin()
  user = get_user()
  if user == nil or user["admin"] < 1 then
    return false
  end
  return true
end

def check_admin()
  user = get_user()
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
