get("/products") do
  if params['supplier']
    s_id = params['supplier'].scan(/\d+/)[0].to_i
    result = grab_db().execute("SELECT * FROM products WHERE supplier_id=?", s_id)
  else
    result = grab_db().execute("SELECT * FROM products")
  end
  suppliers = by_key(grab_db().execute("SELECT * FROM suppliers"))
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
  db = grab_db()
  product_data = db.execute("SELECT * FROM products WHERE id = ?", product_id).first
  supplier_data = db.execute("SELECT * FROM suppliers WHERE id = ?", product_data["supplier_id"]).first
  suppliers = db.execute("SELECT * FROM suppliers")
  slim(:'products/edit', locals:{user:user, product:product_data, supplier:supplier_data, suppliers:name_by_key(suppliers)})
end

post('/products/:id/update') do
  product_name = params["name"]
  supplier_name = params["supplier"]
  product_id = params[:id]

  db = grab_db()
  supplier = db.execute("SELECT id FROM suppliers WHERE name = ?", supplier_name).first
  if !supplier then
    return "Supplier #{supplier_name} doesn't exist"
  end
  supplier_id = supplier["id"]
  if params["picture"] then
    product_fn = params["picture"]["filename"]
    product_f  = params["picture"]["tempfile"]
    db.execute("UPDATE products SET name = ?, supplier_id = ?, showcase_img = ? WHERE id = ?", product_name, supplier_id, SQLite3::Blob.new(product_f.read()), product_id)
  else
    db.execute("UPDATE products SET name = ?, supplier_id = ? WHERE id = ?", product_name, supplier_id, product_id)
  end
  redirect('/')
end

get('/products/:id/showcase_img') do
  db = grab_db()
  response.headers['Content-Type'] = 'image/webp'
  sio = StringIO.new(db.execute("SELECT showcase_img FROM products WHERE id=?", params[:id]).first["showcase_img"])
  return sio.read
end

post('/products') do
  check_admin();
  product_name = params["name"]
  if params['s_id']
    product_s_id = params['s_id'].scan(/\d+/)[0].to_i
  else
    product_s_id = 0
  end
  db = grab_db()
  db.execute("INSERT INTO products (name, supplier_id) VALUES (?,?)", product_name, product_s_id)
  redirect("/products/#{db.last_insert_row_id}/edit")
end

post('/products/:id/delete') do
  db = grab_db()
  db.execute("DELETE FROM products WHERE id = ?", params["id"])
  return "OK"
end
