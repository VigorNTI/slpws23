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

def by_field(table, field)
  hash = {}
  for row in table do
    hash[row[field]] = row
  end
  return hash
end

def is_admin()
  user = get_user()
  if user == nil or user["admin"] != 1 then
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

###################################################################################################################################
##########################################################   ORDERS   #############################################################
###################################################################################################################################

before("/orders") do
  if !get_user() then
    redirect('/')
  end
end

get('/orders') do
  uid = session[:id].to_i
  db = grab_db()

  # Grab orders
  orders_payed = by_key(db.execute("SELECT * FROM orders WHERE user_id=? AND payed=1", uid))
  orders_notpayed = by_key(db.execute("SELECT * FROM orders WHERE user_id=? AND payed=0", uid))
  orders = {payed:orders_payed, notpayed:orders_notpayed}

  # Grab the order ids
  orders_ids = []
  orders.each_value do |sub_orders|
    sub_orders.each_key do |id|
      orders_ids.append id
    end
  end
  
  # Grab the order product linkers
  orders_products = db.execute("SELECT * FROM orders_products WHERE order_id IN(#{orders_ids.join(",")})")

  products_ids = []
  orders_products.each do |order_product|
    p_id = order_product["product_id"]
    if !products_ids.include? p_id then
      products_ids.append p_id
    end
  end

  # Grab the products used for all the orders
  products = by_key(db.execute("SELECT * FROM products WHERE id IN(#{products_ids.join(",")})"))

  # Final part, link them together
  # we iterate over the linker table, orders_products, and link orders with products
  orders_products.each do |order_product|
    p_id = order_product["product_id"]
    o_id = order_product["order_id"]
    new_product = {id:p_id, amount:order_product["amount"]}
    # Find the right order
    if orders[:payed][o_id] then
      order = orders[:payed][o_id]      
    elsif orders[:notpayed][o_id] then
      order = orders[:notpayed][o_id]
    else
      order = nil
    end
    # Add product to order
    if order then
      # Create an array inside the order hash
      if !order[:products] then
        order.merge!({products:[]})
      end
      # Add the product to the array inside the order hash
      order[:products].append new_product
    end
  end
  slim(:"orders/index", locals:{user:get_user(), orders:orders, products:products})
end

post('/orders/:id/pay') do
  uid = session[:id].to_i
  o_id = params["id"]

  db = grab_db()
  db.execute("UPDATE orders SET payed=1 WHERE user_id=? AND id=?", uid, o_id)
  redirect('/orders')
end

###################################################################################################################################
#########################################################   CHECKOUT   ############################################################
###################################################################################################################################

before("/checkout") do
  if !get_user() then
    redirect('/')
  end
end

post("/checkout") do
  uid = session[:id].to_i
  db = grab_db()
  shoppingcart = db.execute("SELECT * FROM shoppingcart WHERE user_id=?", uid)
  if shoppingcart.length > 0 then
    db.execute("INSERT INTO orders (user_id,date) VALUES (?,?)", uid, Time.now.to_i * 1000)
    order_id = db.last_insert_row_id
    shoppingcart.each do |item|
      db.execute("INSERT INTO orders_products (order_id, product_id, amount) VALUES (?,?,?)", order_id, item["product_id"], item["amount"]);
      db.execute("DELETE FROM shoppingcart WHERE user_id=? AND product_id=?", uid, item["product_id"])
    end
  end
  redirect('/products')
end

###################################################################################################################################
#######################################################   SHOPPINGCART   ##########################################################
###################################################################################################################################

before("/shoppingcart") do
  if !get_user() then
    redirect('/login')
  end
end

get('/shoppingcart') do
  db = grab_db()
  product_ids = []
  cart = db.execute("SELECT product_id,amount FROM shoppingcart WHERE user_id=?", get_user()["id"]);
  cart.each do |item|
    product_ids.append item["product_id"]
  end
  products = db.execute("SELECT id,name,supplier_id FROM products WHERE id IN(#{product_ids.join(",")})")
  products_keys = by_key(products)
  cart.each do |item|
    products_keys[item["product_id"]].merge!({amount:item["amount"]})
  end
  
  supplier_ids = []
  products.each do |product|
    if !supplier_ids.include? product["supplier_id"]
      supplier_ids.append product["supplier_id"]
    end
  end
  suppliers = db.execute("SELECT id,name,origin FROM suppliers WHERE id IN(#{supplier_ids.join(",")})")

  slim(:"shoppingcart/index", locals:{user:get_user(), products:products_keys, suppliers:by_key(suppliers)})
end

post("/shoppingcart") do
  uid = session[:id].to_i
  p_id = params["product_id"]
  db = grab_db()
  result = db.execute("SELECT * FROM shoppingcart WHERE user_id=? AND product_id=?", uid, p_id)
  if result.length > 0 then
    db.execute("UPDATE shoppingcart SET amount = ? WHERE user_id=? AND product_id=?", result[0]["amount"] + 1, uid, p_id)
  else
    db.execute("INSERT INTO shoppingcart (user_id,product_id) VALUES (?,?)", uid, p_id)
  end
  return "OK"
end

post('/shoppingcart/:id/update') do
  uid = session[:id].to_i
  p_id = params["id"]
  pol = params["pol"]

  value_action = -1

  db = grab_db()
  result = db.execute("SELECT * FROM shoppingcart WHERE user_id=? AND product_id=?", uid, p_id)
  if result.length > 0 then
    if pol == "DEC" then
      value_action = -1
    elsif pol == "ADD" then
      value_action = 1
    else
      return "NOK"
    end
    if result[0]["amount"] + value_action <= 0 then
      db.execute("DELETE FROM shoppingcart WHERE user_id=? AND product_id=?", uid, p_id)
      return "DEL"
    end
    db.execute("UPDATE shoppingcart SET amount = ? WHERE user_id=? AND product_id=?", result[0]["amount"] + value_action, uid, p_id)
    return pol
  end
  return "DEL"
end


post('/shoppingcart/:id/delete') do
  uid = session[:id].to_i
  p_id = params["id"]

  db = grab_db()
  db.execute("DELETE FROM shoppingcart WHERE user_id=? AND product_id=?", uid, p_id)
  return "DEL"
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
  db.execute("DELETE FROM suppliers WHERE id = ?", params["id"])
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
  db.execute("DELETE FROM products WHERE id = ?", params["id"])
  return "OK"
end
