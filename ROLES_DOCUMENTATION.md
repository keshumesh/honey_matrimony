# Role-Based Access Control System

## Roles Overview

The Honey Matrimony application now includes a comprehensive role-based access control system with three distinct roles:

### 1. **User** (Default Role)
- Browse matrimony profiles
- Create and manage own profile
- Edit own profile information
- Delete own account

### 2. **Manager**
- All User permissions
- View all user profiles
- Edit other user profiles
- Access the admin panel (limited)
- Manage regular user accounts

### 3. **Admin** (Super User)
- All Manager permissions
- Full access to admin dashboard
- View all users and their roles
- Change user roles
- Delete any user account
- Complete system administration

---

## Admin Dashboard

The admin dashboard provides:

- **Statistics**: Total users, admins, managers, and regular users count
- **Recent Users**: Latest registered users with quick actions
- **User Management**: List all users with search functionality
- **Role Management**: Assign and modify user roles
- **User Details**: View comprehensive user information
- **User Deletion**: Safely remove user accounts with confirmation

### Access Admin Panel
Navigate to: `/admin/dashboard`

---

## Database Schema

The `users` table has been updated with:
- `role` (string): User role (user, manager, admin) - Defaults to "user"
- Index on role for faster queries

---

## Setting Up Admin Users

### Option 1: Make First User an Admin
After creating your first user, run:
```bash
bundle exec rails admin:make_first_admin
```

### Option 2: Create Admin User Interactively
```bash
bundle exec rails admin:create_admin
```
This will prompt you for:
- First Name
- Email
- Password

### Option 3: Manual Database Update
```ruby
user = User.find(1)
user.update(role: "admin")
```

---

## Authorization

### Controller Filters

**Require Login:**
```ruby
before_action :require_login
```

**Require Admin:**
```ruby
before_action :require_admin
```

**Require Manager or Admin:**
```ruby
before_action :require_manager_or_admin
```

### Helper Methods

Available in views and controllers:
- `current_user` - Get logged-in user
- `logged_in?` - Check if user is logged in
- `is_admin?` - Check if current user is admin
- `is_manager?` - Check if current user is manager
- `user.admin?` - Check if user object is admin
- `user.manager?` - Check if user object is manager
- `user.regular_user?` - Check if user is regular user
- `user.can_manage_users?` - Check if user can manage others
- `user.can_edit_user?(other_user)` - Check edit permission
- `user.can_delete_user?(other_user)` - Check delete permission

---

## Admin Routes

| Route | Method | Purpose |
|-------|--------|---------|
| `/admin/dashboard` | GET | Admin dashboard with statistics |
| `/admin/users` | GET | List all users |
| `/admin/users/:id` | GET | View user details |
| `/admin/users/:id/edit` | GET | Edit user form |
| `/admin/users/:id` | PATCH/PUT | Update user |
| `/admin/users/:id/delete` | GET | Delete confirmation |
| `/admin/users/:id` | DELETE | Delete user |

---

## User Model Methods

### Role Check Methods
```ruby
user.admin?        # Returns true if admin
user.manager?      # Returns true if manager
user.regular_user? # Returns true if regular user
```

### Permission Check Methods
```ruby
user.can_manage_users?           # Returns true if admin or manager
user.can_edit_user?(other_user)  # Admin can edit anyone, manager can edit users only
user.can_delete_user?(other_user) # Admin can delete anyone, user can delete themselves
```

---

## Authentication Flow

1. User signs up → Assigned "user" role by default
2. Admins can change roles via admin panel
3. Role determines available features and permissions
4. Navigation updates based on user role
5. Protected routes check authorization

---

## Best Practices

1. **First User as Admin**: Make your first user an admin
2. **Limit Admins**: Keep admin count low for security
3. **Managers for Support**: Use manager role for customer support staff
4. **Regular Backups**: Before bulk operations
5. **Activity Logging**: Consider adding audit logs for admin actions
6. **Role Changes**: Document when roles are changed and why

---

## Security Considerations

- Passwords are hashed using bcrypt
- Session-based authentication
- CSRF protection on all forms
- Role-based access control on all admin routes
- Authorization checks on every protected action
- Users cannot promote themselves
- Only admins can modify roles

---

## Future Enhancements

- Activity/Audit logging
- Soft delete for users
- Role-based email notifications
- Custom permissions per role
- User approval workflow
- Two-factor authentication for admins

