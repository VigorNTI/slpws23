before("/checkout") do
  if !get_user() then
    redirect('/')
  end
end

post("/checkout") do
  uid = session[:id].to_i
  create_order(uid)
  redirect('/products')
end


