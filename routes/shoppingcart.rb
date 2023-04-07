before("/shoppingcart") do
  if !get_user() then
    redirect('/login')
  end
end

get('/shoppingcart') do
  product_ids = []
  cart = get_shoppingcart_items(get_user()["id"]);
  cart.each do |item|
    product_ids.append item["product_id"]
  end
  products = get_products_by_ids(product_ids)
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
  suppliers = get_suppliers_by_ids(supplier_ids)

  slim(:"shoppingcart/index", locals:{user:get_user(), products:products_keys, suppliers:by_key(suppliers)})
end

post("/shoppingcart") do
  uid = session[:id].to_i
  p_id = params["product_id"]
  create_shoppingcart_item(uid, p_id)
  return "OK"
end

post('/shoppingcart/:id/update') do
  uid = session[:id].to_i
  p_id = params["id"]
  pol = params["pol"]

  value_action = -1

  result = get_specific_shoppingcart_items(uid, p_id)
  if result.length > 0 then
    if pol == "DEC" then
      value_action = -1
    elsif pol == "ADD" then
      value_action = 1
    else
      return "NOK"
    end
    if result[0]["amount"] + value_action <= 0 then
      delete_shoppingcart_item(uid, p_id)
      return "DEL"
    end
    update_shoppingcart_item(result[0]["amount"] + value_action, uid, p_id)
    return pol
  end
  return "DEL"
end


post('/shoppingcart/:id/delete') do
  uid = session[:id].to_i
  p_id = params["id"]

  delete_shoppingcart_item(uid, p_id)
  return "DEL"
end
