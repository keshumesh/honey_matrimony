# RSpec Testing Guide - Honey Matrimony

## Overview

This project uses RSpec for comprehensive automated testing. All features are covered with unit tests, controller tests, and integration tests.

## Installation & Setup

### Gems Added

```ruby
# Gemfile - development, test group
gem "rspec-rails", "~> 6.0.0"
gem "factory_bot_rails"

# Gemfile - test group
gem "shoulda-matchers", "~> 5.0"
```

### Installation Commands

```bash
# Install gems
bundle install

# Generate RSpec setup (already done)
bundle exec rails generate rspec:install
```

### Files Generated

- `.rspec` - RSpec configuration
- `spec/spec_helper.rb` - RSpec helpers
- `spec/rails_helper.rb` - Rails-specific RSpec setup

## Database Setup for Testing

### PostgreSQL Configuration

Ensure your development/test database has proper authentication:

```bash
# For Windows with PostgreSQL:
# 1. Ensure PostgreSQL is running
# 2. Set the password in config/database.yml

# config/database.yml
test:
  <<: *default
  database: honey_matrimony_test
  username: postgres
  password: your_password
  host: localhost
```

### Prepare Test Database

```bash
# Create and migrate test database
bundle exec rails db:test:prepare

# Or manually:
bundle exec rails db:create RAILS_ENV=test
bundle exec rails db:migrate RAILS_ENV=test
```

## Running Tests

### Run All Tests

```bash
# Run all RSpec tests
bundle exec rspec

# With detailed output
bundle exec rspec --format documentation

# With color output
bundle exec rspec --color
```

### Run Specific Tests

```bash
# Run only model tests
bundle exec rspec spec/models/

# Run only controller tests
bundle exec rspec spec/controllers/

# Run only request tests
bundle exec rspec spec/requests/

# Run a specific file
bundle exec rspec spec/models/user_spec.rb

# Run a specific test case
bundle exec rspec spec/models/user_spec.rb:10

# Run tests matching a pattern
bundle exec rspec --pattern "**/*_spec.rb" -p "authentication"
```

### Run with Coverage

```bash
# Run tests with code coverage (if simplecov added)
bundle exec rspec --format documentation --require rails_helper

# View coverage report
open coverage/index.html
```

## Test Structure

### Test Files Organization

```
spec/
├── factories/           # Factory Bot definitions
│   └── users.rb        # User factory with traits
├── models/             # Model specs
│   └── user_spec.rb    # User model tests
├── controllers/        # Controller specs
│   ├── users_controller_spec.rb
│   ├── sessions_controller_spec.rb
│   ├── admin_controller_spec.rb
│   └── application_controller_spec.rb
├── requests/           # Integration/request specs
│   └── authentication_spec.rb
├── rails_helper.rb     # Rails-specific helpers
└── spec_helper.rb      # Basic RSpec config
```

## Test Coverage

### User Model Tests

File: `spec/models/user_spec.rb`

Tests covered:
- ✅ Validations (email, password, mobile, etc.)
- ✅ Email format validation
- ✅ Mobile number format (10 digits)
- ✅ Password encryption with bcrypt
- ✅ Password authentication
- ✅ Enum role definitions (user, manager, admin)
- ✅ Role predicate methods (#admin?, #manager?, #regular_user?)
- ✅ Permission methods (#can_manage_users?, #can_edit_user?, #can_delete_user?)
- ✅ Matrimony profile fields presence

### Users Controller Tests

File: `spec/controllers/users_controller_spec.rb`

Tests covered:
- ✅ GET #index - list all users
- ✅ GET #new - show signup form
- ✅ POST #create - create new user with default "user" role
- ✅ GET #dashboard - user dashboard (with login required)
- ✅ GET #show - view user profile
- ✅ GET #edit - edit profile (own only)
- ✅ PATCH #update - update profile
- ✅ DELETE #destroy - delete account
- ✅ Authorization checks

### Sessions Controller Tests

File: `spec/controllers/sessions_controller_spec.rb`

Tests covered:
- ✅ GET #new - show login form
- ✅ POST #create - login with valid credentials
- ✅ Login with invalid email
- ✅ Login with incorrect password
- ✅ DELETE #destroy - logout
- ✅ Session management
- ✅ Flash messages

### Admin Controller Tests

File: `spec/controllers/admin_controller_spec.rb`

Tests covered:
- ✅ GET #dashboard - admin statistics
- ✅ GET #users - user list with search
- ✅ GET #show - user details
- ✅ GET #edit - edit user form
- ✅ PATCH #update - update user role
- ✅ GET #delete - delete confirmation
- ✅ DELETE #destroy - delete user
- ✅ Authorization (admin only)
- ✅ Prevention of self-deletion

### Application Controller Tests

File: `spec/controllers/application_controller_spec.rb`

Tests covered:
- ✅ #current_user - get logged-in user
- ✅ #logged_in? - check login status
- ✅ #is_admin? - check admin role
- ✅ #is_manager? - check manager role
- ✅ #require_login filter
- ✅ #require_admin filter
- ✅ #require_manager_or_admin filter

### Authentication Integration Tests

File: `spec/requests/authentication_spec.rb`

Tests covered:
- ✅ Complete signup flow
- ✅ Default role assignment
- ✅ Login with valid/invalid credentials
- ✅ Logout functionality
- ✅ Dashboard access and redirects
- ✅ Admin dashboard authorization
- ✅ User management CRUD
- ✅ Access control across roles

## Factory Definitions

### User Factory

Location: `spec/factories/users.rb`

```ruby
# Basic user
create(:user)

# Admin user
create(:user, :admin)

# Manager user
create(:user, :manager)

# User with complete profile
create(:user, :with_complete_profile)
```

### Available Attributes

```ruby
user = build(:user)
user.email           # unique
user.password        # "password123"
user.first_name      # "John"
user.last_name       # "Doe"
user.mobile_no       # "9876543210"
user.gender          # "Male"
user.role            # "user"
```

## Configuration Files

### .rspec

Defines RSpec behavior:

```
--require spec_helper
--format documentation
--color
```

### spec/rails_helper.rb

Key configurations:
- FactoryBot syntax methods included
- Shoulda Matchers configured
- Transactional fixtures enabled
- Database schema maintained

### spec/spec_helper.rb

Basic RSpec configuration (auto-generated).

## Running Tests in CI/CD

### GitHub Actions Example

```yaml
- name: Run RSpec tests
  run: |
    bundle exec rails db:test:prepare
    bundle exec rspec --format progress
```

### Local Testing Before Commit

```bash
# Run all tests before committing
bundle exec rspec

# Run specific test suite
bundle exec rspec spec/models/
```

## Common Test Patterns

### Testing Authentication

```ruby
it 'redirects to login when not authenticated' do
  get :dashboard
  expect(response).to redirect_to(login_path)
end
```

### Testing Authorization

```ruby
it 'allows admin to access dashboard' do
  session[:user_id] = admin.id
  get :dashboard
  expect(response).to be_successful
end
```

### Testing Model Validations

```ruby
it { is_expected.to validate_presence_of(:email) }
it { is_expected.to validate_uniqueness_of(:email) }
```

### Testing Role Methods

```ruby
it 'correctly identifies admin' do
  admin = create(:user, :admin)
  expect(admin.admin?).to be true
end
```

### Testing Factories

```ruby
let(:user) { create(:user) }
let(:admin) { create(:user, :admin) }
let(:manager) { create(:user, :manager) }
```

## Debugging Tests

### Run with Verbose Output

```bash
bundle exec rspec --format documentation -v
```

### Run Single Test

```bash
# Run one specific test
bundle exec rspec spec/models/user_spec.rb -e "validates presence of email"
```

### Drop Into Debugger

```ruby
it 'tests something' do
  user = create(:user)
  binding.pry  # Debugger pauses here
  expect(user).to be_valid
end
```

### Show Pending Tests

```bash
bundle exec rspec --format documentation -fp
```

## Best Practices

### ✅ Do's

1. **Use factories** for test data
2. **One assertion per test** when possible
3. **Descriptive test names** that explain the test
4. **Use traits** for variations (`:admin`, `:manager`)
5. **DRY up tests** with `let` and `before` blocks
6. **Test edge cases** (invalid input, nil, empty)
7. **Test behavior** not implementation
8. **Keep tests fast** - avoid unnecessary database hits

### ❌ Don'ts

1. Don't use fixtures - use factories instead
2. Don't create side effects in tests
3. Don't test Rails internals
4. Don't use `sleep` in tests
5. Don't make database calls in unit tests
6. Don't hardcode values - use factories
7. Don't test multiple concerns in one test
8. Don't leave pending tests

## Adding New Tests

### When to Add Tests

- When fixing a bug - add test that catches it
- When adding features - write tests first (TDD)
- When refactoring - ensure tests still pass
- For edge cases - add specific tests

### Test Template

```ruby
require 'rails_helper'

RSpec.describe YourClass, type: :model do
  describe 'method_name' do
    context 'when condition is true' do
      it 'does something' do
        # Arrange
        obj = create(:your_object)
        
        # Act
        result = obj.method_name
        
        # Assert
        expect(result).to eq(expected_value)
      end
    end
  end
end
```

## Troubleshooting

### Database Connection Errors

**Error**: `ActiveRecord::ConnectionNotEstablished`

**Solution**:
1. Ensure PostgreSQL is running
2. Check `config/database.yml` credentials
3. Run `bundle exec rails db:test:prepare`

### Factory Definition Errors

**Error**: `Unknown factory: :user`

**Solution**:
1. Ensure `spec/factories/users.rb` exists
2. Run `bundle exec rspec` instead of direct test run
3. Check factory syntax

### Missing RSpec Configuration

**Error**: `Uninitialized constant RSpec`

**Solution**:
1. Run `bundle exec rails generate rspec:install`
2. Ensure gems are installed: `bundle install`

## Performance Tips

### Run Specific Test Suite

```bash
# Much faster for development
bundle exec rspec spec/models/user_spec.rb
```

### Parallelize Tests (with gem)

```ruby
# Gemfile
gem 'parallel_tests'
```

```bash
bundle exec parallel_test spec/
```

### Use Focused Tests

```ruby
# Run only this test
fit 'does something' do
  expect(true).to be true
end

# Run only tests with :focus tag
bundle exec rspec --tag focus
```

## CI/CD Integration

All tests automatically run in the CI pipeline before deployment. Ensure:

1. All tests pass locally
2. No pending tests
3. Database configured correctly
4. All gems installed

## Documentation Links

- [RSpec Documentation](https://rspec.info/)
- [RSpec-Rails Guide](https://rspec.info/features/6-0/rspec-rails/)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)

## Quick Reference

```bash
# Install dependencies
bundle install

# Setup test database
bundle exec rails db:test:prepare

# Run all tests
bundle exec rspec

# Run specific file
bundle exec rspec spec/models/user_spec.rb

# Run with coverage
bundle exec rspec --format documentation

# Run with fail-fast (stop on first failure)
bundle exec rspec --fail-fast

# Run only recently modified tests
bundle exec rspec --pattern '**/*_spec.rb' -p spec

# Generate coverage report
bundle exec rspec
open coverage/index.html
```

---

**Last Updated**: 2026-06-20
**RSpec Version**: 3.13
**Rails Version**: 7.2
**Status**: ✅ Ready for Testing
