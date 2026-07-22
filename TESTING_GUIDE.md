# Testing Guide - Honey Matrimony Role-Based Dashboard

## Quick Start Testing

### 1. **Database Migration (Already Done)**
✓ Role column added with default "user" value
✓ Index created on role column for performance

### 2. **Create First Admin User**

**Option A: Using Rake Task**
```bash
bundle exec rails admin:create_admin
```

Follow the prompts to create an admin user.

**Option B: Make Existing User Admin**
```bash
bundle exec rails admin:make_first_admin
```

This makes the first registered user an admin.

### 3. **Test User Flows**

#### **Regular User (Role: "user")**
1. Sign up at `/users/new`
2. Fill in all required fields
3. Submit form → Auto-assigned "user" role
4. Redirected to `/dashboard` (User Dashboard)
5. Can see:
   - ✅ Profile status
   - ✅ Quick actions (Edit, View Profile)
   - ✅ Browse Profiles link
   - ✅ Profile information display
   - ✅ Account settings

Navigation shows:
- 👥 Browse Profiles
- 📊 Dashboard
- 👤 User dropdown (View Profile, Edit Profile, Logout)

#### **Admin User (Role: "admin")**
1. Login with admin credentials
2. Navigate to `/admin/dashboard`
3. Can see:
   - ✅ System statistics (Total, Admins, Managers, Users)
   - ✅ Recent users table
   - ✅ Quick action buttons
   - ✅ All user management features

Navigation shows:
- 👥 Browse Profiles
- 🏢 Admin Panel
- 👥 Manage Users
- 👑 Admin badge
- 👤 User dropdown

### 4. **Admin Features Testing**

**Dashboard** (`/admin/dashboard`)
- View system statistics with visual cards
- See recent user registrations
- Quick navigation buttons

**Manage Users** (`/admin/users`)
- Search users by name or email
- View complete user list with details
- Edit user role (User → Manager → Admin)
- Delete user accounts
- Indexed table with gender and role badges

**Edit User** (`/admin/users/:id/edit`)
- Change user role
- Update user information
- See role descriptions

**User Details** (`/admin/users/:id`)
- View all user information
- Navigate to edit or delete

**Delete User** (`/admin/users/:id/delete`)
- Confirmation page
- User details for verification
- Safe deletion process

### 5. **UI Elements to Check**

✅ **Navbar**
- Brand name with heart emoji
- Sticky positioning
- Role-based menu items
- User dropdown
- Mobile hamburger menu

✅ **Color Coding**
- Admin (Red badge) 👑
- Manager (Yellow badge) 👔
- User (Gray badge) 👤

✅ **Icons**
- All menu items have icons
- All buttons have emojis
- Better visual hierarchy

✅ **Forms**
- Section headers with emojis
- Clear labels
- Helpful placeholders
- Error messages display

✅ **Buttons**
- Emoji indicators
- Size variation (sm, lg)
- Proper color coding
- Hover effects

### 6. **Responsive Design**
Test on different screen sizes:
- Desktop (1200px+)
- Tablet (768px-1199px)
- Mobile (320px-767px)

Check:
- Navigation collapses on mobile
- Tables remain readable
- Buttons are touch-friendly
- Forms stack properly

### 7. **Role Permissions**

| Feature | User | Manager | Admin |
|---------|------|---------|-------|
| Browse profiles | ✅ | ✅ | ✅ |
| Dashboard | ✅ | ❌* | ✅ |
| Admin panel | ❌ | ❌ | ✅ |
| View all users | ❌ | ✅ | ✅ |
| Edit user profile | Own only | Any user | Any user |
| Change roles | ❌ | ❌ | ✅ |
| Delete users | Own only | ❌ | ✅ |

*Managers can access limited user management

### 8. **Session Testing**

1. **Login** 
   - Navigate to `/login`
   - Enter valid credentials
   - Verify session created

2. **Dashboard Access**
   - Regular users: `/dashboard` (works)
   - Logout and try: Shows login redirect

3. **Admin Access**
   - Admin: `/admin/dashboard` (works)
   - Non-admin: Shows permission error

4. **Logout**
   - Click logout in dropdown
   - Session destroyed
   - Redirected to home

### 9. **Flash Messages**

Test that these display correctly:
- ✅ "Account created successfully!" (signup)
- ✅ "Profile updated successfully!" (update)
- ✅ "Account deleted successfully!" (delete)
- ✅ "User updated successfully!" (admin edit)
- ✅ Permission errors
- ✅ Validation errors

### 10. **Database Verification**

Check users table:
```ruby
User.all.map { |u| [u.email, u.role] }

# Should show:
# [
#   ["user1@example.com", "user"],
#   ["admin@example.com", "admin"],
#   ...
# ]
```

### 11. **Routes Verification**

```bash
bundle exec rails routes | grep -E 'dashboard|admin'
```

Should include:
- `GET /dashboard` → users#dashboard (user_dashboard_path)
- `GET /admin/dashboard` → admin#dashboard
- `GET /admin/users` → admin#users
- `GET /admin/users/:id` → admin#show
- `GET /admin/users/:id/edit` → admin#edit
- `PATCH /admin/users/:id` → admin#update
- `DELETE /admin/users/:id` → admin#destroy

### 12. **Error Handling**

Test these error scenarios:
1. Non-admin accessing `/admin/dashboard` → Permission error
2. Non-logged-in user accessing `/dashboard` → Redirect to login
3. User accessing another user's edit page → Should show profile only
4. Invalid search on admin users → "No users found"
5. Invalid role selection → Validation error

### 13. **Performance Checks**

- Verify role index is used: `User.where(role: "admin")` should be fast
- Admin dashboard loads quickly even with many users
- Search functionality works smoothly
- No N+1 queries in views

### 14. **Browser Compatibility**

Test on:
- Chrome/Chromium ✅
- Firefox ✅
- Safari ✅
- Edge ✅
- Mobile browsers ✅

### 15. **Accessibility**

Check:
- ✅ Color contrast for readability
- ✅ Form labels linked to inputs
- ✅ Buttons have descriptive text
- ✅ Navigation structure is logical
- ✅ Alerts are announced
- ✅ Images have alt text

## Common Issues & Solutions

### Issue: "No user dashboard link appears"
**Solution:** Ensure you're logged in as a regular user (not admin)

### Issue: "Admin menu doesn't show"
**Solution:** Make sure your user has role = "admin"

### Issue: "Migration not applied"
**Solution:** Run `bundle exec rails db:migrate`

### Issue: "Search not working in admin"
**Solution:** Check database has users, PostgreSQL installed

### Issue: "Styles not showing"
**Solution:** Run `bundle exec rails assets:precompile`

## Success Checklist

- [x] Users created with default "user" role
- [x] User dashboard at `/dashboard`
- [x] Admin dashboard at `/admin/dashboard`
- [x] Role indicators in navigation
- [x] Admin user management working
- [x] Search functionality operational
- [x] Role changes saved correctly
- [x] Logout clears session
- [x] Responsive design works
- [x] All emojis display correctly
- [x] Flash messages show/hide properly
- [x] Permission checks working

## Next Steps

1. ✅ Test all flows
2. ✅ Verify database
3. ✅ Check responsive design
4. ✅ Test with multiple browsers
5. Consider adding:
   - User activity logging
   - Profile completeness percentage
   - Admin notifications
   - Advanced search filters
   - Bulk operations

---

For detailed documentation, see: `ROLES_DOCUMENTATION.md` and `UI_UPDATES_SUMMARY.md`
