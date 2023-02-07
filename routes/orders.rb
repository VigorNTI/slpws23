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
