before("/checkout") do
  if !get_user() then
    redirect('/')
  end
end

post("/checkout") do
  uid = session[:id].to_i
  if create_order(uid) >= 0 then
    redirect('/products')
  else
    redirect('/shoppingcart')
  end
end


