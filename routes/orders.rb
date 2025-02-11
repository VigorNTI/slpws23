# Checks if user is logged in before accessing /orders/* routes, redirects to / otherwise
before("/orders") do
  if !get_user() then
    redirect('/')
  end
end

# Displays a user's orders on a page
get('/orders') do
  uid = session[:id].to_i
  orders_and_products = get_orders_struct(uid)
  slim(:"orders/index", locals:{user:get_user(), orders:orders_and_products[:orders], products:orders_and_products[:products]})
end

# Markes an order as payed
post('/orders/:id/pay') do
  uid = session[:id].to_i
  o_id = params["id"]

  order_pay(uid, o_id)
  redirect('/orders')
end
