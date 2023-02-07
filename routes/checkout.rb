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


