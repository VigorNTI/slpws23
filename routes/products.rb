get("/products") do
  if params['supplier']
    s_id = params['supplier'].scan(/\d+/)[0].to_i
    result = get_products_supplier(s_id)
  else
    result = get_products()
  end
  suppliers = bykey_get_suppliers()
  slim(:"products/index", locals:{user:get_user(), products:result, suppliers:suppliers, s_id:s_id})
end

product_auth_exceptions = ['showcase_img']

before("/products/*") do
  if product_auth_exceptions.any? { |s| request.path_info.include? s } then
    return
  end
  check_admin()
end

get('/products/:id/edit') do
  user = get_user()
  product_id = params[:id]
  product_data = get_product(product_id)
  supplier_data = get_products_by_supplier(product_data["supplier_id"])
  suppliers = get_suppliers()
  slim(:'products/edit', locals:{user:user, product:product_data, supplier:supplier_data, suppliers:name_by_key(suppliers)})
end

post('/products/:id/update') do
  product_name = params["name"]
  supplier_name = params["supplier"]
  product_id = params[:id]

  supplier = get_supplier_by_name(supplier_name)
  if !supplier then
    return "Supplier #{supplier_name} doesn't exist"
  end
  supplier_id = supplier["id"]
  if params["picture"] then
    product_fn = params["picture"]["filename"]
    product_f  = params["picture"]["tempfile"]
    update_product_all(product_name, supplier_id, product_f.read(), product_id)
  else
    update_product(product_name, supplier_id, product_id)
  end
  redirect('/')
end

get('/products/:id/showcase_img') do
  response.headers['Content-Type'] = 'image/webp'
  img = get_product_img(params[:id])
  return img
end

post('/products') do
  check_admin();
  product_name = params["name"]
  if params['s_id']
    product_s_id = params['s_id'].scan(/\d+/)[0].to_i
  else
    product_s_id = 0
  end
  id = create_product(product_name, product_s_id)
  redirect("/products/#{id}/edit")
end

post('/products/:id/delete') do
  delete_product(params["id"])
  return "OK"
end
