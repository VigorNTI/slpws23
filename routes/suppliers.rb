suppliers_auth_exceptions = ['showcase_img']

before("/suppliers/*") do
  if suppliers_auth_exceptions.any? { |s| request.path_info.include? s } then
    return
  end
  check_admin()
end

get("/suppliers") do
  result = grab_db().execute("SELECT * FROM suppliers")
  slim(:"suppliers/index", locals:{user:get_user(), suppliers:result})
end

post("/suppliers") do
  check_admin()
  uid = session[:id].to_i
  supplier_name = params["name"]
  db = grab_db()
  db.execute("INSERT INTO suppliers (name) VALUES (?)", supplier_name)
  redirect('/suppliers')
end

post('/suppliers/:id/delete') do
  db = grab_db()
  db.execute("DELETE FROM suppliers WHERE id = ?", params["id"])
  return "OK"
end

get('/suppliers/:id/edit') do
  user = get_user()
  supplier_id = params[:id]
  db = grab_db()
  supplier = db.execute("SELECT * FROM suppliers WHERE id = ?", supplier_id).first
  slim(:'suppliers/edit', locals:{user:user, supplier:supplier})
end

post('/suppliers/:id/update') do
  supplier_id = params[:id]
  supplier_name = params["name"]
  supplier_origin = params["origin"]

  db = grab_db()

  if params["picture"] then
    pic_tempfile = params["picture"]["tempfile"]
    db.execute("UPDATE suppliers SET name = ?, origin = ?, showcase_img = ? WHERE id = ?", supplier_name, supplier_origin, SQLite3::Blob.new(pic_tempfile.read()), supplier_id)
  else
    db.execute("UPDATE suppliers SET name = ?, origin = ? WHERE id = ?", supplier_name, supplier_origin, supplier_id)
  end
  redirect('/suppliers')
end

get('/suppliers/:id/showcase_img') do
  db = grab_db()
  response.headers['Content-Type'] = 'image/webp'
  if db.execute("Select showcase_img FROM suppliers WHERE id=?", params[:id]).first["showcase_img"] then
    sio = StringIO.new(db.execute("SELECT showcase_img FROM suppliers WHERE id=?", params[:id]).first["showcase_img"])
    return sio.read
  end
    return ""
end
