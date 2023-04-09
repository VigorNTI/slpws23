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
  return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id")
end

def get_valid_products()
  return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id WHERE products.visible=1 AND suppliers.visible=1")
end

def get_products_linked_orders(uid)
  return connect_db().execute("SELECT products.* FROM ((products INNER JOIN orders_products ON products.id=orders_products.product_id) INNER JOIN orders ON orders_products.order_id=orders.id) WHERE orders.user_id=?", uid)
end

def get_product(p_id)
  return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id WHERE products.id=?", p_id).first
end

def get_products_by_ids(ids)
  return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id WHERE products.id IN(?)", ids.join(","))
end

def bykey_get_products_by_ids(ids)
  return by_key(get_products_by_ids(ids))
end

def get_products_by_supplier(s_id)
  return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id WHERE products.supplier_id=?", s_id)
end

def get_valid_products_by_supplier(s_id)
  return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id WHERE products.supplier_id=? AND products.visible=1 AND suppliers.id=1", s_id)
end

def get_product_img(id)
  return StringIO.new(connect_db().execute("SELECT showcase_img FROM products WHERE id=?", id).first["showcase_img"]).read
end

def create_product(name, s_id)
  db = connect_db()
  db.execute("INSERT INTO products (name, supplier_id) VALUES (?,?)", name, s_id)
  return db.last_insert_row_id
end

def unhide_product(id)
  return connect_db().execute("UPDATE products SET visible=1 WHERE id=?", id)
end

def hide_product(id)
  # This breaks the logic, a deleted product will be a missing product on a order, which means a missing part on a receipt
  #return connect_db().execute("DELETE FROM products WHERE id = ?", id)

  # We use the flag instead
  return connect_db().execute("UPDATE products SET visible=0 WHERE id=?", id)
end

def update_product(name, s_id, visible, p_id)
    return connect_db().execute("UPDATE products SET name = ?, supplier_id = ?, visible = ? WHERE id = ?", name, s_id, visible, p_id)
end

def update_product_all(name, s_id, visible, img, p_id)
    return connect_db().execute("UPDATE products SET name = ?, supplier_id = ?, visible = ?, showcase_img = ? WHERE id = ?", name, s_id, visible, SQLite3::Blob.new(img), p_id)
end

# Suppliers

def get_suppliers()
  return connect_db().execute("SELECT * FROM suppliers")
end

def namebykey_get_suppliers()
  return name_by_key(connect_db().execute("SELECT * FROM suppliers"))
end

def get_valid_suppliers()
  return connect_db().execute("SELECT * FROM suppliers WHERE visible=1")
end

def get_suppliers_by_ids(ids)
  return connect_db().execute("SELECT id,name,origin FROM suppliers WHERE id IN(?)", ids.join(","))
end

def get_supplier(id)
  return connect_db().execute("SELECT * FROM suppliers WHERE id = ?", id).first
end

def get_supplier_img(id)
  return StringIO.new(connect_db().execute("SELECT showcase_img FROM suppliers WHERE id=?", id).first["showcase_img"]).read
end

def update_supplier_all(name, origin, visible, img, id)
    return connect_db().execute("UPDATE suppliers SET name = ?, origin = ?, visible = ?, showcase_img = ? WHERE id = ?", name, origin, visible, SQLite3::Blob.new(img), id)
end

def update_supplier(name, origin, visible, id)
    return connect_db().execute("UPDATE suppliers SET name = ?, origin = ?, visible = ? WHERE id = ?", name, origin, visible, id)
end

def create_supplier(name)
  db = connect_db()
  db.execute("INSERT INTO suppliers (name) VALUES (?)", name)
  return db.last_insert_row_id
end

def unhide_supplier(id)
  return connect_db().execute("UPDATE suppliers SET visible=1 WHERE id=?", id)
end

def hide_supplier(id)
  return connect_db().execute("UPDATE suppliers SET visible=0 WHERE id=?", id)
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

def get_shoppingcart_invalid_items(uid)
  return connect_db().execute("SELECT shoppingcart.*,products.visible,suppliers.visible as s_visible FROM ((shoppingcart INNER JOIN products ON shoppingcart.product_id=products.id) INNER JOIN suppliers ON products.supplier_id=suppliers.id) WHERE shoppingcart.user_id=? AND (products.visible=0 OR suppliers.visible=0)", uid)
end

# Orders

def create_order(uid)
  db = connect_db()
  if get_shoppingcart_invalid_items(uid).length > 0 then
    return -1
  end
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
  return -1
end

def bykey_get_orders_payed(uid)
  return by_key(connect_db().execute("SELECT * FROM orders WHERE user_id=? AND payed=1", uid))
end

def bykey_get_orders_notpayed(uid)
  return by_key(connect_db().execute("SELECT * FROM orders WHERE user_id=? AND payed=0", uid))
end

def get_orders_payed_full(uid)
  return connect_db().execute("SELECT orders.*,orders_products.product_id,orders_products.amount FROM orders INNER JOIN orders_products ON orders.id=orders_products.order_id WHERE user_id=? AND payed=1", uid)
end

def get_orders_notpayed_full(uid)
  return connect_db().execute("SELECT orders.*,orders_products.product_id,orders_products.amount FROM orders INNER JOIN orders_products ON orders.id=orders_products.order_id WHERE user_id=? AND payed=0", uid)
end

def get_orders_products_by_ids(ids)
  return connect_db().execute("SELECT * FROM orders_products WHERE order_id IN(#{ids.join(",")})")
end

def get_orders_struct(uid)
  orders_payed = bykey_get_orders_payed(uid)
  orders_notpayed = bykey_get_orders_notpayed(uid)
  orders = {payed:orders_payed, notpayed:orders_notpayed}

  # Add product linkers to orders
  pf = get_orders_payed_full(uid)
  if pf.length > 0 then
    pf.each do |order|
      if not orders_payed[order["id"]]["products"] then
        orders_payed[order["id"]]["products"] = []
      end
      product = {id:order["product_id"],amount:order["amount"]}
      orders_payed[order["id"]]["products"].append product
    end
  end
  npf = get_orders_notpayed_full(uid)
  if npf.length > 0 then
    npf.each do |order|
      if not orders_notpayed[order["id"]]["products"] then
        orders_notpayed[order["id"]]["products"] = []
      end
      product = {id:order["product_id"],amount:order["amount"]}
      orders_notpayed[order["id"]]["products"].append product
    end
  end

  products = by_key(get_products_linked_orders(uid))

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

# Advanced querries

# This function returns products that is included in the shoppingcart, the products include the amount tag and supplier fields
def get_shoppingcart_items_full(uid)
  return connect_db().execute("SELECT products.*,shoppingcart.amount,suppliers.name as supplier_name,suppliers.visible as s_visible FROM ((products INNER JOIN shoppingcart ON products.id=shoppingcart.product_id) INNER JOIN suppliers ON products.supplier_id=suppliers.id) WHERE shoppingcart.user_id=?", uid);
end
