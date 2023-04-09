# Module that handles sql communication with a database
module Model
  # Manually connect to the database
  #
  # @return [SQLite3::Database]
  def connect_db()
    db = SQLite3::Database.new("db/userbase.db")
    db.results_as_hash = true
    return db
  end

  # Create a hash with elements of an array, the value `id` in each element will represent the key for each element in the hash while the element will represent the value in the hash
  #
  # @param [Array] table The array to take elements from
  #
  # @return [Hash] containing the key/value pairs of each element
  def by_key(table)
    hash = {}
    for row in table do
      hash[row["id"]] = row
    end
    return hash
  end

  # Create a hash with id/name pairs from an array containing elements with id/name fields, the field `id` will be the key and the field `name` will be the value
  #
  # @param [Array] table The array to take fields from
  #
  # @return [Hash] containing the key/value pairs of each element
  def name_by_key(table)
    hash = {}
    for row in table do
      hash[row["id"]] = row["name"]
    end
    return hash
  end

  # Create a hash from an array with a specific field from each element as the key and the element as the value
  #
  # @param [Array] table The table to take elements from
  # @param [String] field The field to represent each key
  #
  # @return [Hash] containing the key/value pairs of each element
  def by_field(table, field)
    hash = {}
    for row in table do
      hash[row[field]] = row
    end
    return hash
  end

  # Grab the admin flag from the database and determine if the user is admin or not
  #
  # @param [Integer] id The id that represent the user to check
  #
  # @return [Boolean] true if user is admin, false otherwise
  def is_admin_db(id)
    user = get_user_db(id)
    if user == nil or user["admin"] < 1 then
      return false
    end
    return true
  end

  # Authenticate the user with a username and password
  #
  # @param [String] username The username to find in the database
  # @param [String] password The password to encrypt and match against the database saved bcrypt hashed password
  #
  # @return [Integer] negative if login didn't succeed, otherwise a positive id for the authenticated user
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
      return -1
  end

  # Register a new user with a chosen username and password
  #
  # @param [String] usr The username for the new user
  # @param [String] pwd The password for the new user
  #
  # @return [nil] returns nothing
  def register_user(usr, pwd)
    # Add user
    pwd_digest = BCrypt::Password.create(password)
    db = connect_db()
    db.execute("INSERT INTO users (username, pwdigest, admin) VALUES (?,?,0)", usr, pwd_digest)
  end

  # Products

  # Get products and their suppliers visibility from the database
  #
  # @return [Array] an array of hashes representing all of the products in the database and indludes if the supplier is visible
  def get_products()
    return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id")
  end

  # Get the valid products and their suppliers visibility from the database that isn't hidden nor has a hidden supplier
  #
  # @return [Array] an array of hashes with matching products in the database and includes if the supplier is visible in each hash for each product
  def get_valid_products()
    return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id WHERE products.visible=1 AND suppliers.visible=1")
  end

  # Get all of the products that is included in all of a users orders from the database
  #
  # @param [Integer] uid The user's ID
  #
  # @return [Array] an array of matching products in the database as each hash
  def get_products_linked_orders(uid)
    return connect_db().execute("SELECT products.* FROM ((products INNER JOIN orders_products ON products.id=orders_products.product_id) INNER JOIN orders ON orders_products.order_id=orders.id) WHERE orders.user_id=?", uid)
  end

  # Get a specific product and it's supplier's visibility
  #
  # @param [Integer] p_id The product's ID
  #
  # @return [Hash] The matching product and it's suppliers visibility
  def get_product(p_id)
    return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id WHERE products.id=?", p_id).first
  end

  # Get the products whose ID is present in an array
  #
  # @param [Array] ids An array containing the IDs to match
  #
  # @return [Array] an array of matching products in the database as each hash
  def get_products_by_ids(ids)
    return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id WHERE products.id IN(?)", ids.join(","))
  end

  # Get the products whose ID is present in an array and associate each product with it's key in a hash
  #
  # @param [Array] ids An array containing the IDs to match
  #
  # @return [Hash] each key in the hash is associated with the product ID in it's value hash representing a product
  def bykey_get_products_by_ids(ids)
    return by_key(get_products_by_ids(ids))
  end

  # Get the products from the database that has a specific supplier
  #
  # @param [Integer] s_id The ID of the supplier to match the products with
  #
  # @return [Array] an array of matching products in the database as each hash
  def get_products_by_supplier(s_id)
    return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id WHERE products.supplier_id=?", s_id)
  end

  # Get the products from the database that has a specific supplier and isn't hidden nor has a hidden supplier
  #
  # @param [Integer] s_id The ID of the supplier to match the products with
  #
  # @return [Array] an array of mataching products in the database as each hash
  def get_valid_products_by_supplier(s_id)
    return connect_db().execute("SELECT products.*, suppliers.visible as s_visible FROM products INNER JOIN suppliers ON products.supplier_id = suppliers.id WHERE products.supplier_id=? AND products.visible=1 AND suppliers.id=1", s_id)
  end

  # Get the processed image data for a specific product in the database
  #
  # @param [Integer] id The id of the product to find
  #
  # @return [String] A string of the read bytes representing the image
  def get_product_img(id)
    return StringIO.new(connect_db().execute("SELECT showcase_img FROM products WHERE id=?", id).first["showcase_img"]).read
  end

  # Create a new product in the database
  #
  # @param [String] name The name for the new product
  # @param [Integer] s_id The supplier ID for the new product
  #
  # @return [Integer] The row ID for the newly created product in the database
  def create_product(name, s_id)
    db = connect_db()
    db.execute("INSERT INTO products (name, supplier_id) VALUES (?,?)", name, s_id)
    return db.last_insert_row_id
  end

  # Unhide a product in the database
  #
  # @param [Integer] id The ID for the product to unhide
  #
  # @return [Integer] result code
  def unhide_product(id)
    return connect_db().execute("UPDATE products SET visible=1 WHERE id=?", id)
  end

  # Hide a product in the database
  #
  # @param [Integer] id The ID for the product to hide
  #
  # @return [Integer] result code
  def hide_product(id)
    # This breaks the logic, a deleted product will be a missing product on a order, which means a missing part on a receipt
    #return connect_db().execute("DELETE FROM products WHERE id = ?", id)

    # We use the flag instead
    return connect_db().execute("UPDATE products SET visible=0 WHERE id=?", id)
  end

  # Update values for a product in the database
  #
  # @param [String] name The new name
  # @param [Integer] s_id The new supplier ID to be associated with the product
  # @param [Integer] p_id The ID of the product to update
  #
  # @return [Integer] result code
  def update_product(name, s_id, visible, p_id)
      return connect_db().execute("UPDATE products SET name = ?, supplier_id = ?, visible = ? WHERE id = ?", name, s_id, visible, p_id)
  end

  # Update values for a product in the database, also update the image for the product
  #
  # @param [String] name The new name
  # @param [Integer] s_id The new supplier ID to be associated with the product
  # @param [String] img The image data to be saved in the database
  # @param [Integer] p_id The ID of the product to update
  #
  # @return [Integer] result code
  def update_product_all(name, s_id, visible, img, p_id)
      return connect_db().execute("UPDATE products SET name = ?, supplier_id = ?, visible = ?, showcase_img = ? WHERE id = ?", name, s_id, visible, SQLite3::Blob.new(img), p_id)
  end

  # Suppliers

  # Get the suppliers from the database
  #
  # @return [Array] An array of hashes representing each supplier
  def get_suppliers()
    return connect_db().execute("SELECT * FROM suppliers")
  end

  # Get the suppliers from the database as a hash where each key is associated with the `name` field for each supplier
  #
  # @return [Hash] An hash where each key is associated wiht the `name` field for each supplier, and the value is associated with the supplier
  def namebykey_get_suppliers()
    return name_by_key(connect_db().execute("SELECT * FROM suppliers"))
  end

  # Get the suppliers from the database that is visible
  #
  # @return [Array] An array of hashes of matching suppliers
  def get_valid_suppliers()
    return connect_db().execute("SELECT * FROM suppliers WHERE visible=1")
  end

  # Get the suppliers from the database that has an ID present in a passad array
  #
  # @param [Array] ids An array of IDs to match
  #
  # @return [Array] An array of hashes of matching suppliers
  def get_suppliers_by_ids(ids)
    return connect_db().execute("SELECT id,name,origin FROM suppliers WHERE id IN(?)", ids.join(","))
  end

  # Get a specific supplier
  #
  # @param [Integer] id The id of the supplier to get
  #
  # @return [Hash] The hash associated with the supplier
  def get_supplier(id)
    return connect_db().execute("SELECT * FROM suppliers WHERE id = ?", id).first
  end

  # Get a specific supplier's image
  #
  # @param [Integer] id The id of the supplier
  #
  # @return [String] the image data bytes from the supplier
  def get_supplier_img(id)
    return StringIO.new(connect_db().execute("SELECT showcase_img FROM suppliers WHERE id=?", id).first["showcase_img"]).read
  end

  # Update the supplier fields, also update the image
  #
  # @param [String] name The new name
  # @param [String] origin The new origin
  # @param [String] img The new image data
  # @param [Integer] id The ID of the supplier to update
  #
  # @return [Integer] result code
  def update_supplier_all(name, origin, visible, img, id)
      return connect_db().execute("UPDATE suppliers SET name = ?, origin = ?, visible = ?, showcase_img = ? WHERE id = ?", name, origin, visible, SQLite3::Blob.new(img), id)
  end

  # Update the supplier fields
  #
  # @param [String] name The new name
  # @param [String] origin The new origin
  # @param [Integer] id The ID of the supplier to update
  #
  # @return [Integer] result code
  def update_supplier(name, origin, visible, id)
      return connect_db().execute("UPDATE suppliers SET name = ?, origin = ?, visible = ? WHERE id = ?", name, origin, visible, id)
  end

  # Create a new supplier
  #
  # @param [String] name The new name for the new supplier
  #
  # @return [Integer] Table row of the new supplier in the database
  def create_supplier(name)
    db = connect_db()
    db.execute("INSERT INTO suppliers (name) VALUES (?)", name)
    return db.last_insert_row_id
  end

  # Unhide a supplier
  #
  # @param [Integer] id The id of the supplier to unhide
  #
  # @return [Integer] Result code
  def unhide_supplier(id)
    return connect_db().execute("UPDATE suppliers SET visible=1 WHERE id=?", id)
  end

  # Hide a supplier
  #
  # @param [Integer] id The id of the supplier to hide
  #
  # @return [Integer] Result code
  def hide_supplier(id)
    return connect_db().execute("UPDATE suppliers SET visible=0 WHERE id=?", id)
  end

  # Get a supplier by it's name
  #
  # @param [String] name The name to match
  #
  # @return [Hash] The hash associated with the matched supplier
  def get_supplier_by_name(name)
    return connect_db().execute("SELECT * FROM suppliers WHERE name = ?", name).first
  end

  # Get the suppliers in the database and create a hash with each supplier ID as keys in the hash
  #
  # @return [Hash] Hash where each key is an ID of each supplier, each value are hashes of each supplier
  def bykey_get_suppliers()
    return by_key(get_suppliers())
  end

  # Shoppingcart

  # Get the shoppingcart items associated with a user
  #
  # @param [Integer] uid The user ID
  #
  # @return [Array] an array of hashes where each hash include a product and the amount of products
  def get_shoppingcart_items(uid)
    return connect_db().execute("SELECT product_id,amount FROM shoppingcart WHERE user_id=?", uid);
  end

  # Get the shoppingcart items associated with a user and a product
  #
  # @param [Integer] uid The user ID
  # @param [Integer] p_id The product ID
  #
  # @return [Array] Array of matching products
  def get_specific_shoppingcart_items(uid, p_id)
    return connect_db().execute("SELECT * FROM shoppingcart WHERE user_id=? AND product_id=?", uid, p_id)
  end

  # Get a shoppingcart item
  #
  # @param [Integer] uid The user ID
  # @param [Integer] p_id The product ID
  #
  # @return [Hash] Hash of the matching product
  def get_specific_shoppingcart_item(uid, p_id)
    return get_specific_shoppingcart_items(uid, p_id).first
  end

  # Create a shoppingcart item
  #
  # @param [Integer] uid The user ID
  # @param [Integer] p_id The product ID
  #
  # @return [Integer] result code
  def force_create_shoppingcart_item(uid, p_id)
    return connect_db().execute("INSERT INTO shoppingcart (user_id,product_id) VALUES (?,?)", uid, p_id)
  end

  # Delete a shoppingcart item
  #
  # @param [Integer] uid The user ID
  # @param [Integer] p_id The product ID
  #
  # @return [Integer] result code
  def delete_shoppingcart_item(uid, p_id)
        return connect_db().execute("DELETE FROM shoppingcart WHERE user_id=? AND product_id=?", uid, p_id)
  end

  # Update a shoppingcart item, delete if amount is less or equal to zero
  #
  # @param [Integer] amount The new amount for the item
  # @param [Integer] uid The user ID
  # @param [Integer] p_id The product ID
  #
  # @return [Integer] result code
  def update_shoppingcart_item(amount, uid, p_id)
    if amount <= 0 then
      return delete_shoppingcart_item(uid, p_id)
    end
    return connect_db().execute("UPDATE shoppingcart SET amount = ? WHERE user_id=? AND product_id=?", amount, uid, p_id)
  end

  # Create a shoppingcart item and increment the amount if the item already exists
  #
  # @param [Integer] uid The user ID
  # @param [Integer] p_id The product ID
  #
  # @return [nil] returns nothing
  def create_shoppingcart_item(uid, p_id)
    items = get_specific_shoppingcart_items(uid, p_id)
    if items.length > 0 then
      update_shoppingcart_item(items[0]["amount"] + 1, uid, p_id)
    else
      force_create_shoppingcart_item(uid, p_id)
    end
  end

  # Get the shoppingcart items that is not visible or has a supplier that is not visible
  #
  # @param [Integer] uid The user ID
  #
  # @return [Array] an array of matching shoppingcart items as hashes
  def get_shoppingcart_invalid_items(uid)
    return connect_db().execute("SELECT shoppingcart.*,products.visible,suppliers.visible as s_visible FROM ((shoppingcart INNER JOIN products ON shoppingcart.product_id=products.id) INNER JOIN suppliers ON products.supplier_id=suppliers.id) WHERE shoppingcart.user_id=? AND (products.visible=0 OR suppliers.visible=0)", uid)
  end

  # Orders

  # Create a new order, takes the shoppingcart items and creates an order from them
  #
  # @param [Integer] uid The user ID
  #
  # @return [Integer] negative on error, otherwise a positive integer associated with the newly created order as the order row ID
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

  # Get the orders marked as payed and put them in a hash where each key is the ID for each order
  #
  # @param [Integer] uid The user ID
  #
  # @return [Hash] a hash of orders as values and their ID as keys
  def bykey_get_orders_payed(uid)
    return by_key(connect_db().execute("SELECT * FROM orders WHERE user_id=? AND payed=1", uid))
  end

  # Get the orders marked as not payed and put them in a hash where each key is the ID for each order
  #
  # @param [Integer] uid The user ID
  #
  # @return [Hash] a hash of orders as values and their ID as keys
  def bykey_get_orders_notpayed(uid)
    return by_key(connect_db().execute("SELECT * FROM orders WHERE user_id=? AND payed=0", uid))
  end

  # Get an array where each element is an order marked as payed and a product associated with it, as one order can have many products there can be more elements than orders
  #
  # @param [Integer] uid The user ID
  #
  # @return [Array] an array of matching orders
  def get_orders_payed_full(uid)
    return connect_db().execute("SELECT orders.*,orders_products.product_id,orders_products.amount FROM orders INNER JOIN orders_products ON orders.id=orders_products.order_id WHERE user_id=? AND payed=1", uid)
  end

  # Get an array where each element is an order marked as not payed and a product associated with it, as one order can have many products there can be more elements than orders
  #
  # @param [Integer] uid The user ID
  #
  # @return [Array] an array of matching orders
  def get_orders_notpayed_full(uid)
    return connect_db().execute("SELECT orders.*,orders_products.product_id,orders_products.amount FROM orders INNER JOIN orders_products ON orders.id=orders_products.order_id WHERE user_id=? AND payed=0", uid)
  end

  # Get orders whose ID is present in a passed array
  #
  # @param [Array] ids An array of integer IDs to match with each order
  #
  # @return [Array] an array of hashes for each order
  def get_orders_products_by_ids(ids)
    return connect_db().execute("SELECT * FROM orders_products WHERE order_id IN(#{ids.join(",")})")
  end

  # Get a custom structure including orders payed, orders not payed, and all of the products included in all orders. Each order also have a list of IDs associated with the products it includes and present in the products datalist
  #
  # @param [Integer] uid The user ID
  #
  # @return [Hash] a hash which includes orders and products, the orders includes arrays of payed and nonpayed orders, each order includes a list of products to be associated with it
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

  # Set the order payed flag for an order
  #
  # @param [Integer] uid The user ID
  # @param [Integer] o_id The order ID
  #
  # @return [Integer] result code
  def order_pay(uid, o_id)
    return connect_db().execute("UPDATE orders SET payed=1 WHERE user_id=? AND id=?", uid, o_id)
  end

  # Users

  # Get the user information from the database
  #
  # @param [Integer] uid The user ID
  #
  # @return [Hash] the hash for a user containing user information
  def get_user_db(uid)
    return connect_db().execute("SELECT * FROM users WHERE id = ?", uid).first
  end

  # Get the users below a certain admin level
  #
  # @param [Integer] max_admin Maxium admin level to match
  #
  # @return [Array] array of matching users, each user is a hash
  def get_users_max_admin(max_admin)
    return connect_db().execute("SELECT * FROM users WHERE admin < ?", max_admin)
  end

  # Delete a user
  #
  # @param [Integer] id The user ID
  #
  # @return [Integer] result code
  def delete_user(id)
    return connect_db().execute("DELETE FROM users WHERE id=?", id)
  end

  # Update fields for a user
  #
  # @param [String] uname The new username
  # @param [Integer] admin The new admin level
  # @param [Integer] id The user ID
  #
  # @return [Integer] result code
  def update_user(uname, admin, id)
    return connect_db().execute("UPDATE users SET username=?,admin=? WHERE id = ?", uname, admin, id)
  end

  # Advanced querries

  # This function returns products that is included in the shoppingcart, the products include the amount tag and supplier fields
  #
  # @param [Integer] uid The user ID
  #
  # @return [Array] an array of matching shoppingcart items
  def get_shoppingcart_items_full(uid)
    return connect_db().execute("SELECT products.*,shoppingcart.amount,suppliers.name as supplier_name,suppliers.visible as s_visible FROM ((products INNER JOIN shoppingcart ON products.id=shoppingcart.product_id) INNER JOIN suppliers ON products.supplier_id=suppliers.id) WHERE shoppingcart.user_id=?", uid);
  end
end
