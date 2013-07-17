# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

user = User.find_or_initialize_by_email("admin@example.com")
user.username = "admin"
user.password = "password"
user.password_confirmation = "password"
user.invitation_code = User::INVITATION_CODES.first
user.admin = true
user.save!