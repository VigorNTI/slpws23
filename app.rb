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

suppliers_auth_exceptions = ['showcase_img']

before("/suppliers/*") do
  if suppliers_auth_exceptions.any? { |s| request.path_info.include? s } then
    return
  end
  check_admin()
end

get("/suppliers") do
  result = grab_db().execute("SELECT * FROM suppliers")
  slim(:"suppliers/index", locals:{user:get_user(), suppliers:result})
end

post("/suppliers") do
  check_admin()
  uid = session[:id].to_i
  supplier_name = params["name"]
  db = grab_db()
  db.execute("INSERT INTO suppliers (name) VALUES (?)", supplier_name)
  redirect('/suppliers')
end

post('/suppliers/:id/delete') do
  db = grab_db()
  p db.execute("DELETE FROM suppliers WHERE id = ?", params["id"])
  return "OK"
end

get('/suppliers/:id/edit') do
  user = get_user()
  supplier_id = params[:id]
  db = grab_db()
  supplier = db.execute("SELECT * FROM suppliers WHERE id = ?", supplier_id).first
  slim(:'suppliers/edit', locals:{user:user, supplier:supplier})
end

post('/suppliers/:id/update') do
  supplier_id = params[:id]
  supplier_name = params["name"]
  supplier_origin = params["origin"]

  db = grab_db()

  if params["picture"] then
    pic_tempfile = params["picture"]["tempfile"]
    db.execute("UPDATE suppliers SET name = ?, origin = ?, showcase_img = ? WHERE id = ?", supplier_name, supplier_origin, SQLite3::Blob.new(pic_tempfile.read()), supplier_id)
  else
    db.execute("UPDATE suppliers SET name = ?, origin = ? WHERE id = ?", supplier_name, supplier_origin, supplier_id)
  end
  redirect('/suppliers')
end

get('/suppliers/:id/showcase_img') do
  db = grab_db()
  response.headers['Content-Type'] = 'image/webp'
  if db.execute("Select showcase_img FROM suppliers WHERE id=?", params[:id]).first["showcase_img"] then
    sio = StringIO.new(db.execute("SELECT showcase_img FROM suppliers WHERE id=?", params[:id]).first["showcase_img"])
    return sio.read
  end
    return ""
end

##################################################################################################################################
########################################################   PRODUCTS   ############################################################
##################################################################################################################################

get("/products") do
  if params['supplier']
    s_id = params['supplier'].scan(/\d+/)[0].to_i
    result = grab_db().execute("SELECT * FROM products WHERE supplier_id=?", s_id)
  else
    result = grab_db().execute("SELECT * FROM products")
  end
  suppliers = by_key(grab_db().execute("SELECT * FROM suppliers"))
  slim(:"products/index", locals:{user:get_user(), products:result, suppliers:suppliers, s_id:s_id})
end

product_auth_exceptions = ['showcase_img']

before("/products/*") do
  if product_auth_exceptions.any? { |s| request.path_info.include? s } then
    return
  end
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

  db = grab_db()
  supplier = db.execute("SELECT id FROM suppliers WHERE name = ?", supplier_name).first
  if !supplier then
    return "Supplier #{supplier_name} doesn't exist"
  end
  supplier_id = supplier["id"]
  if params["picture"] then
    product_fn = params["picture"]["filename"]
    product_f  = params["picture"]["tempfile"]
    db.execute("UPDATE products SET name = ?, supplier_id = ?, showcase_img = ? WHERE id = ?", product_name, supplier_id, SQLite3::Blob.new(product_f.read()), product_id)
  else
    db.execute("UPDATE products SET name = ?, supplier_id = ? WHERE id = ?", product_name, supplier_id, product_id)
  end
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
  if params['s_id']
    product_s_id = params['s_id'].scan(/\d+/)[0].to_i
  else
    product_s_id = 0
  end
  db = grab_db()
  db.execute("INSERT INTO products (name, supplier_id) VALUES (?,?)", product_name, product_s_id)
  redirect("/products/#{db.last_insert_row_id}/edit")
end

post('/products/:id/delete') do
  db = grab_db()
  p db.execute("DELETE FROM products WHERE id = ?", params["id"])
  return "OK"
end
