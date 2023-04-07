def connect_db()
  db = SQLite3::Database.new("db/userbase.db")
  db.results_as_hash = true
  return db
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

def is_admin_db(id)
  user = get_user_db(id)
  if user == nil or user["admin"] < 1 then
    return false
  end
  return true
end

def login(username, password)
    # Match user pwd_digest
    password_digest = BCrypt::Password.create(password)
    db = connect_db()
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    if result != nil then
      pwdigest = result["pwdigest"]
      id = result["id"]

      if BCrypt::Password.new(pwdigest) == password
        puts("Positive password match for #{username}, logging in...")
        return id
      end
    end
    return false
end

def register_user(usr, pwd)
  # Add user
  pwd_digest = BCrypt::Password.create(password)
  db = connect_db()
  db.execute("INSERT INTO users (username, pwdigest, admin) VALUES (?,?,0)", usr, pwd_digest)
end

# Products

def get_products()
  return connect_db().execute("SELECT * FROM products")
end

def get_product(p_id)
  return connect_db().execute("SELECT * FROM products WHERE id=?", p_id).first
end

def get_products_by_ids(ids)
  # TODO: Try to change it to `?`
  return connect_db().execute("SELECT id,name,supplier_id FROM products WHERE id IN(#{ids.join(",")})") # SQL injection is not an issue, `ids` should not be gotten from a user
end

def bykey_get_products_by_ids(ids)
  return by_key(get_products_by_ids(ids))
end

def get_products_by_supplier(s_id)
  return connect_db().execute("SELECT * FROM products WHERE supplier_id=?", s_id).first
end

def get_product_img(id)
  return StringIO.new(connect_db().execute("SELECT showcase_img FROM products WHERE id=?", id).first["showcase_img"]).read
end

def create_product(name, s_id)
  db = connect_db()
  db.execute("INSERT INTO products (name, supplier_id) VALUES (?,?)", name, s_id)
  return db.last_insert_row_id
end

def delete_product(id)
  return connect_db().execute("DELETE FROM products WHERE id = ?", id)
end

def update_product(name, s_id, p_id)
    return connect_db().execute("UPDATE products SET name = ?, supplier_id = ? WHERE id = ?", name, s_id, p_id)
end

def update_product_all(name, s_id, img, p_id)
    return connect_db().execute("UPDATE products SET name = ?, supplier_id = ?, showcase_img = ? WHERE id = ?", name, s_id, SQLite3::Blob.new(img), p_id)
end

# Suppliers

def get_suppliers()
  return connect_db().execute("SELECT * FROM suppliers")
end

def get_suppliers_by_ids(ids)
  # TODO: Try to change it to `?`
  return connect_db().execute("SELECT id,name,origin FROM suppliers WHERE id IN(#{ids.join(",")})")
end

def get_supplier(id)
  return connect_db().execute("SELECT * FROM suppliers WHERE id = ?", id).first
end

def get_supplier_img(id)
  return StringIO.new(connect_db().execute("SELECT showcase_img FROM suppliers WHERE id=?", id).first["showcase_img"]).read
end

def update_supplier_all(name, origin, img, id)
    return connect_db().execute("UPDATE suppliers SET name = ?, origin = ?, showcase_img = ? WHERE id = ?", name, origin, SQLite3::Blob.new(img), id)
end

def update_supplier(name, origin, id)
    return connect_db().execute("UPDATE suppliers SET name = ?, origin = ? WHERE id = ?", name, origin, id)
end

def create_supplier(name)
  db = connect_db()
  db.execute("INSERT INTO suppliers (name) VALUES (?)", name)
  return db.last_insert_row_id
end

def delete_supplier(id)
  return connect_db().execute("DELETE FROM suppliers WHERE id = ?", params["id"])
end

def get_supplier_by_name(name)
  return connect_db().execute("SELECT * FROM suppliers WHERE name = ?", name).first
end

def bykey_get_suppliers()
  return by_key(get_suppliers())
end

# Shoppingcart

def get_shoppingcart_items(uid)
  return connect_db().execute("SELECT product_id,amount FROM shoppingcart WHERE user_id=?", uid);
end

def get_specific_shoppingcart_items(uid, p_id)
  return connect_db().execute("SELECT * FROM shoppingcart WHERE user_id=? AND product_id=?", uid, p_id)
end

def get_specific_shoppingcart_item(uid, p_id)
  return get_specific_shoppingcart_items(uid, p_id).first
end

def force_create_shoppingcart_item(uid, p_id)
  return connect_db().execute("INSERT INTO shoppingcart (user_id,product_id) VALUES (?,?)", uid, p_id)
end

def delete_shoppingcart_item(uid, p_id)
      return connect_db().execute("DELETE FROM shoppingcart WHERE user_id=? AND product_id=?", uid, p_id)
end

def update_shoppingcart_item(amount, uid, p_id)
  if amount <= 0 then
    return delete_shoppingcart_item(uid, p_id)
  end
  return connect_db().execute("UPDATE shoppingcart SET amount = ? WHERE user_id=? AND product_id=?", amount, uid, p_id)
end

def create_shoppingcart_item(uid, p_id)
  items = get_specific_shoppingcart_items(uid, p_id)
  if items.length > 0 then
    update_shoppingcart_item(items[0]["amount"] + 1, uid, p_id)
  else
    force_create_shoppingcart_item(uid, p_id)
  end
end

# Orders

def create_order(uid)
  db = connect_db()
  shoppingcart = get_shoppingcart_items(uid)
  if shoppingcart.length > 0 then
    db.execute("INSERT INTO orders (user_id,date) VALUES (?,?)", uid, Time.now.to_i * 1000)
    order_id = db.last_insert_row_id
    shoppingcart.each do |item|
      db.execute("INSERT INTO orders_products (order_id, product_id, amount) VALUES (?,?,?)", order_id, item["product_id"], item["amount"]);
      delete_shoppingcart_item(uid, item["product_id"])
    end
    return db.last_insert_row_id
  end
  return false
end

def bykey_get_orders_payed(uid)
  return by_key(connect_db().execute("SELECT * FROM orders WHERE user_id=? AND payed=1", uid))
end

def bykey_get_orders_notpayed(uid)
  return by_key(connect_db().execute("SELECT * FROM orders WHERE user_id=? AND payed=0", uid))
end

def get_orders_products_by_ids(ids)
  return connect_db().execute("SELECT * FROM orders_products WHERE order_id IN(#{ids.join(",")})")
end

def get_orders_struct(uid)
  # Grab orders
  orders_payed = bykey_get_orders_payed(uid)
  orders_notpayed = bykey_get_orders_notpayed(uid)
  orders = {payed:orders_payed, notpayed:orders_notpayed}

  # Grab the order ids
  orders_ids = []
  orders.each_value do |sub_orders|
    sub_orders.each_key do |id|
      orders_ids.append id
    end
  end
  
  # Grab the order product linkers
  orders_products = get_orders_products_by_ids(orders_ids)

  products_ids = []
  orders_products.each do |order_product|
    p_id = order_product["product_id"]
    if !products_ids.include? p_id then
      products_ids.append p_id
    end
  end

  # Grab the products used for all the orders
  products = bykey_get_products_by_ids(products_ids)

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
  return {orders:orders, products:products}
end

def order_pay(uid, o_id)
  return connect_db().execute("UPDATE orders SET payed=1 WHERE user_id=? AND id=?", uid, o_id)
end

# Users

def get_user_db(uid)
  return connect_db().execute("SELECT * FROM users WHERE id = ?", uid).first
end

def get_users_max_admin(max_admin)
  return connect_db().execute("SELECT * FROM users WHERE admin < ?", max_admin)
end

def delete_user(id)
  return connect_db().execute("DELETE FROM users WHERE id=?", id)
end

def update_user(uname, admin, id)
  return connect_db().execute("UPDATE users SET username=?,admin=? WHERE id = ?", uname, admin, id)
end
