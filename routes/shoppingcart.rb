# Checks if user is logged in before accessing /shoppingcart* routes, redirects to /login otherwise
before("/shoppingcart") do
  if !get_user() then
    redirect('/login')
  end
end

# Displays a page with shoppingcart items
get('/shoppingcart') do
  product_ids = []
  products = get_shoppingcart_items_full(get_user()["id"]);

  slim(:"shoppingcart/index", locals:{user:get_user(), products:products})
end

# Adds a product as a shoppingcart item to the shoppingcart and returns "OK"
post("/shoppingcart") do
  uid = session[:id].to_i
  p_id = params["product_id"]
  create_shoppingcart_item(uid, p_id)
  return "OK"
end

# Updates a specified shoppingcart item with a specied value and returns "DEC" if the amount value has been decremented, "ADD" if it has been incremented or "DEL" if it has been deleted (decremented to zero or below)
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


# Deletes a specified shoppingcart item and returns "DEL"
post('/shoppingcart/:id/delete') do
  uid = session[:id].to_i
  p_id = params["id"]

  delete_shoppingcart_item(uid, p_id)
  return "DEL"
end
