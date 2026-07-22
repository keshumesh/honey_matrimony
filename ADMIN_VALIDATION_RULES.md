# Admin User Validation Rules - Honey Matrimony

## Overview

As of 2026-06-20, the User model has been updated with conditional validations to support different validation requirements based on user role.

## Validation Rules

### For All Users (Required)

These fields are **mandatory** for all users regardless of role:

- `email` - Valid email format, must be unique
- `password` - Minimum 6 characters (on user creation)
- `first_name` - User's first name
- `mobile_no` - Must be exactly 10 digits
- `gender` - User's gender
- `role` - Must be one of: user, manager, admin

### For Regular Users & Managers (Required)

These fields are **mandatory** for non-admin users (user, manager roles):

- `last_name` - User's last name
- `dob` - Date of birth
- `religion` - User's religion
- `height` - User's height
- `marital_status` - User's marital status
- `complexion` - User's complexion
- `mother_tongue` - User's mother tongue

### For Admin Users (Optional)

Admin users do **NOT** need to fill in matrimony/profile fields:

- `last_name` - ✅ Optional
- `dob` - ✅ Optional
- `religion` - ✅ Optional
- `height` - ✅ Optional
- `marital_status` - ✅ Optional
- `complexion` - ✅ Optional
- `mother_tongue` - ✅ Optional

## Rationale

Admin users are typically system administrators or managers who:
- Don't need complete matrimony profiles
- Should be able to be created quickly
- May not be actively using the matrimony features

## Implementation

### Model Validation

```ruby
# User.rb
validates :last_name, :dob, :religion, :height, :marital_status, 
          :complexion, :mother_tongue, presence: true, unless: :admin?
```

The `unless: :admin?` clause makes these validations conditional - they only apply if the user is NOT an admin.

### Admin User Creation Examples

#### Valid Minimal Admin User
```ruby
User.create!(
  email: 'admin@example.com',
  password: 'password123',
  first_name: 'Admin',
  mobile_no: '9876543210',
  gender: 'Male',
  role: 'admin'
)
# ✅ Valid - creates successfully
```

#### Valid Minimal Regular User
```ruby
User.create!(
  email: 'user@example.com',
  password: 'password123',
  first_name: 'John',
  last_name: 'Doe',           # Required for non-admin
  mobile_no: '9876543210',
  gender: 'Male',
  dob: Date.new(1995, 5, 15),   # Required for non-admin
  religion: 'Hindu',             # Required for non-admin
  height: '5.10',                # Required for non-admin
  marital_status: 'Single',      # Required for non-admin
  complexion: 'Fair',            # Required for non-admin
  mother_tongue: 'Hindi',        # Required for non-admin
  role: 'user'
)
# ✅ Valid - creates successfully
```

#### Invalid Admin User (Missing Required)
```ruby
User.create(
  email: 'admin@example.com',
  password: 'password123',
  first_name: 'Admin'
  # Missing: mobile_no, gender (required for all)
)
# ❌ Invalid - validation fails on mobile_no, gender
```

## Factory Usage

### Regular User Factory
```ruby
# Includes all required fields for non-admin user
create(:user)
```

### Admin User Factory
```ruby
# Only includes required fields, matrimony fields are nil
create(:user, :admin)
```

### Manager User Factory
```ruby
# Includes all required fields (managers need full profiles)
create(:user, :manager)
```

## Testing Updates

### Model Tests
- Added separate context for non-admin user validations
- Added separate context for admin user validations (allows missing matrimony fields)

### Controller Tests
- Added tests for admin user creation with minimal parameters
- Verified that admin users can be created without matrimony fields

### Request Tests
- Added integration tests for admin user creation via `/users` endpoint

## API/Form Examples

### Creating Admin User via Form
```erb
<form action="/users" method="POST">
  <input name="user[email]" required />
  <input name="user[password]" required />
  <input name="user[first_name]" required />
  <input name="user[mobile_no]" required />
  <select name="user[gender]" required>
    <option>Male</option>
    <option>Female</option>
  </select>
  <select name="user[role]" required>
    <option value="user">User</option>
    <option value="admin">Admin</option>
  </select>
  <!-- No matrimony fields required for admin -->
  <button type="submit">Create Admin</button>
</form>
```

### Creating Regular User via Form
```erb
<form action="/users" method="POST">
  <!-- All personal detail fields (required) -->
  <input name="user[email]" required />
  <input name="user[password]" required />
  <input name="user[first_name]" required />
  <input name="user[mobile_no]" required />
  
  <!-- Matrimony fields (required for non-admin) -->
  <input name="user[last_name]" required />
  <input name="user[dob]" type="date" required />
  <input name="user[religion]" required />
  <input name="user[height]" required />
  <input name="user[marital_status]" required />
  <input name="user[complexion]" required />
  <input name="user[mother_tongue]" required />
  
  <button type="submit">Sign Up</button>
</form>
```

## Backward Compatibility

- Existing regular users and managers require the same fields as before
- Only admin users have relaxed validation requirements
- No database changes needed
- Existing data is not affected

## Database Schema

No migration needed - validation happens at the model level using `unless: :admin?` conditional.

The `role` column already exists (added in migration 20260620091639_add_role_to_users.rb).

## Testing Coverage

All validation changes are covered by:
- ✅ Unit tests in `spec/models/user_spec.rb`
- ✅ Controller tests in `spec/controllers/users_controller_spec.rb`
- ✅ Request/integration tests in `spec/requests/authentication_spec.rb`

## Admin Panel Impact

### Admin Create User (if added)
When admins create other users through the admin panel:
- If creating an admin → Only require personal details
- If creating a regular user → Require all matrimony fields
- If creating a manager → Require all matrimony fields

### Form Conditional Logic
Forms should conditionally show/require matrimony fields based on the selected role:

```ruby
# Example Rails form helper
<%= f.select :role, options_for_select(['user', 'manager', 'admin'], @user.role) %>
<%= f.text_field :last_name, required: @user.role != 'admin' %>
<%= f.date_field :dob, required: @user.role != 'admin' %>
<!-- etc. -->
```

## Summary

| Field | Personal Detail | All Users | Regular/Manager Only |
|-------|---|---|---|
| email | ✅ | Required | - |
| password | ✅ | Required | - |
| first_name | ✅ | Required | - |
| mobile_no | ✅ | Required | - |
| gender | ✅ | Required | - |
| last_name | ❌ | - | Required |
| dob | ❌ | - | Required |
| religion | ❌ | - | Required |
| height | ❌ | - | Required |
| marital_status | ❌ | - | Required |
| complexion | ❌ | - | Required |
| mother_tongue | ❌ | - | Required |

---

**Date Updated**: 2026-06-20  
**Status**: ✅ Complete  
**Tests**: All passing  
**Backward Compatible**: Yes
