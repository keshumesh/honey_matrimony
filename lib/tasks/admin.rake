namespace :admin do
  desc "Make first user an admin"
  task make_first_admin: :environment do
    first_user = User.order(:created_at).first
    if first_user
      first_user.update(role: "admin")
      puts "✓ User #{first_user.email} is now an Admin"
    else
      puts "✗ No users found in the database"
    end
  end

  desc "Create an admin user"
  task create_admin: :environment do
    puts "Creating a new admin user..."

    print "First Name: "
    first_name = $stdin.gets.chomp

    print "Email: "
    email = $stdin.gets.chomp

    print "Password: "
    password = $stdin.gets.chomp

    user = User.create(
      first_name: first_name,
      email: email,
      password: password,
      password_confirmation: password,
      gender: "Male",
      dob: Date.today - 30.years,
      religion: "Hindu",
      mother_tongue: "Hindi",
      height: "5'8\"",
      marital_status: "Never Married",
      complexion: "Fair",
      mobile_no: "9999999999",
      role: "admin"
    )

    if user.persisted?
      puts "✓ Admin user created successfully!"
      puts "Email: #{user.email}"
    else
      puts "✗ Error creating admin user:"
      user.errors.full_messages.each { |msg| puts "  - #{msg}" }
    end
  end
end
