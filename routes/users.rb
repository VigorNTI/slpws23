before("/users") do
  check_admin()
end

get("/users") do
  # Grab users below our admin level (normal, admin, super)
  users = grab_db().execute("SELECT * FROM users WHERE admin < ?", get_user()["admin"])
  slim(:"users/index", locals:{user:get_user(), users:users})
end

post('/users/:id/delete') do
  db = grab_db()
  db.execute("DELETE FROM users WHERE id = ?", params["id"])
  return "OK"
end

post('/users/:id/update') do
  user_id = params[:id]
  user_name = params["name"]
  user_admin = params["admin_level"].to_i

  if user_admin >= get_user()["admin"] then
    return "You do not have the authority to do that - Error: trying to set admin higher or equal to themselves"
  end

  db = grab_db()

  db.execute("UPDATE users SET username=?,admin=? WHERE id = ?", user_name, user_admin, user_id)
  return "OK"
end
