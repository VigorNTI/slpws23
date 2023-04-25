# Checks if user is logged in before accessing /checkout/* routes, redirects to / otherwise
before("/checkout") do
  if !get_user() then
    redirect('/')
  end
end

# Creates an order for the logged in user, if the order creation succeeds, redirect to /orders, otherwise redirect to the /shoppingcart
post("/checkout") do
  uid = session[:id].to_i
  if create_order(uid) >= 0 then
    redirect('/orders')
  else
    redirect('/shoppingcart')
  end
end
