suppliers_auth_exceptions = ['showcase_img']

before("/suppliers/*") do
  if suppliers_auth_exceptions.any? { |s| request.path_info.include? s } then
    return
  end
  check_admin()
end

get("/suppliers") do
  if is_admin() then
    result = get_suppliers()
  else
    result = get_valid_suppliers()
  end
  slim(:"suppliers/index", locals:{user:get_user(), suppliers:result})
end

post("/suppliers") do
  check_admin()
  uid = session[:id].to_i
  supplier_name = params["name"]
  create_supplier(supplier_name)
  redirect('/suppliers')
end

post('/suppliers/:id/delete') do
  hide_supplier(params["id"])
  return "OK"
end

get('/suppliers/:id/edit') do
  user = get_user()
  supplier_id = params[:id]
  supplier = get_supplier(supplier_id)
  slim(:'suppliers/edit', locals:{user:user, supplier:supplier})
end

post('/suppliers/:id/update') do
  supplier_id = params[:id]
  supplier_name = params["name"]
  supplier_origin = params["origin"]
  supplier_visible = 0
  if params["visibility"] and params["visibility"] == "visible" then
    supplier_visible = 1
  end

  if params["picture"] then
    pic_tempfile = params["picture"]["tempfile"]
    update_supplier_all(supplier_name, supplier_origin, supplier_visible, pic_tempfile.read(), supplier_id)
  else
    update_supplier(supplier_name, supplier_origin, supplier_visible, supplier_id)
  end
  redirect('/suppliers')
end

get('/suppliers/:id/showcase_img') do
  response.headers['Content-Type'] = 'image/webp'
  supplier = get_supplier(params[:id])
  if supplier["showcase_img"] then
    img = get_supplier_img(params[:id])
    return img
  end
    return ""
end
