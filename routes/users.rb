# Checks for admin privileges for a logged in user, if the user is not logged in or is not an admin an error message will be displayed, otherwise nothing will happen
before("/users") do
  check_admin()
end

# Displays all users on a page
get("/users") do
  # Grab users below our admin level (normal, admin, super)
  users = get_users_max_admin(get_user()["admin"])
  slim(:"users/index", locals:{user:get_user(), users:users})
end

# Deletes a specified user
#
post('/users/:id/delete') do
  delete_user(params["id"])
  return "OK"
end

# Updates a specified user with specified values
#
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
