before("/users") do
  check_admin()
end

get("/users") do
  # Grab users below our admin level (normal, admin, super)
  users = get_users_max_admin(get_user()["admin"])
  slim(:"users/index", locals:{user:get_user(), users:users})
end

post('/users/:id/delete') do
  delete_user(params["id"])
  return "OK"
end

post('/users/:id/update') do
  user_id = params[:id]
  user_name = params["name"]
  user_admin = params["admin_level"].to_i

  if user_admin >= get_user()["admin"] then
    return "You do not have the authority to do that - Error: trying to set admin higher or equal to themselves"
  end

  update_user(user_name, user_admin, user_id)
  return "OK"
end
