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
  slim(:login, locals:{user:get_user()})
end

get('/logout') do
  session[:id] = nil
  redirect('/')
end

post('/login') do
  username = params[:username]
  password = params[:password]
  
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
    session[:id] = id
    redirect("/")
  else
    return BCrypt::Password.new(pwdigest)
    "Wrong password"
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

def check_admin()
  user = get_user()
  if user == nil or !user["admin"] then
    halt 401, {'Content-Type' => 'text/plain'}, 'You should not be here'
  end
end

###################################################################################################################################
########################################################   SUPPLIERS   ############################################################
###################################################################################################################################

get("/suppliers") do
  result = grab_db().execute("SELECT * FROM suppliers")
  slim(:"suppliers/index", locals:{user:get_user(), suppliers:result})
end

post("/suppliers") do
  check_admin()
  uid = session[:id].to_i
  product_name = params[:supplier_name]
  supplier_id = params[:supplier_origin]
  db = grab_db()
  result = db.execute("SELECT admin FROM users WHERE user_id = ?", uid)
  db.execute("INSERT INTO suppliers (name, origin) VALUES (?,?)", supplier_name, supplier_origin)
  redirect('/suppliers')
end

##################################################################################################################################
########################################################   PRODUCTS   ############################################################
##################################################################################################################################

get("/products") do
  suppliers = by_key(grab_db().execute("SELECT * FROM suppliers"))
  result = grab_db().execute("SELECT * FROM products")
  slim(:"products/index", locals:{user:get_user(), products:result, suppliers:suppliers})
end

before("/products/*") do
  check_admin()
end

get('/products/:id/edit') do
  user = get_user()
  product_id = params[:id]
  db = grab_db()
  product_data = db.execute("SELECT * FROM products WHERE id = ?", product_id).first
  supplier_data = db.execute("SELECT * FROM suppliers WHERE id = ?", product_data["supplier_id"]).first
  suppliers = db.execute("SELECT * FROM suppliers")
  slim(:'products/edit', locals:{user:user, product:product_data, supplier:supplier_data, suppliers:name_by_key(suppliers)})
end

post('/products/:id/update') do
  product_name = params["name"]
  supplier_name = params["supplier"]
  product_id = params[:id]
  product_fn = params["picture"]["filename"]
  product_f  = params["picture"]["tempfile"]

  db = grab_db()
  supplier = db.execute("SELECT id FROM suppliers WHERE name = ?", supplier_name).first
  if !supplier then
    return "Supplier #{supplier_name} doesn't exist"
  end
  supplier_id = supplier["id"]
  db.execute("UPDATE products SET name = ?, supplier_id = ?, showcase_img = ? WHERE id = ?", product_name, supplier_id, SQLite3::Blob.new(product_f.read()), product_id)
  redirect('/')
end

get('/products/:id/showcase_img') do
  db = grab_db()
  response.headers['Content-Type'] = 'image/webp'
  sio = StringIO.new(db.execute("SELECT showcase_img FROM products WHERE id=?", params[:id]).first["showcase_img"])
  return sio.read
end

post('/products') do
  check_admin();
  product_name = params["name"]
  db = grab_db()
  db.execute("INSERT INTO products (name, supplier_id) VALUES (?,0)", product_name)
  redirect("/products/#{db.last_insert_row_id}/edit")
end

post('/products/:id/delete') do
  db = grab_db()
  p db.execute("DELETE FROM products WHERE id = ?", params["id"])
  return "OK"
end
