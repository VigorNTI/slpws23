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
