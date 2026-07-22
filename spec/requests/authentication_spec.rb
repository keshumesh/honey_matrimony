require 'rails_helper'

RSpec.describe 'Authentication Requests', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'POST /sessions' do
    context 'with valid credentials' do
      it 'logs in the user' do
        post '/sessions', params: {
          session: {
            email: 'test@example.com',
            password: 'password123'
          }
        }
        user
        expect(session[:user_id]).to eq(user.id)
      end

      it 'redirects to dashboard' do
        user
        post '/sessions', params: {
          session: {
            email: 'test@example.com',
            password: 'password123'
          }
        }
        expect(response).to redirect_to(user_dashboard_path)
      end
    end

    context 'with invalid credentials' do
      it 'does not log in the user' do
        post '/sessions', params: {
          session: {
            email: 'test@example.com',
            password: 'wrongpassword'
          }
        }
        expect(session[:user_id]).to be_nil
      end
    end
  end

  describe 'DELETE /logout' do
    it 'logs out the user' do
      user
      post '/sessions', params: {
        session: {
          email: 'test@example.com',
          password: 'password123'
        }
      }
      delete '/logout'
      expect(session[:user_id]).to be_nil
    end
  end

  describe 'GET /login' do
    it 'displays the login form' do
      get '/login'
      expect(response).to have_http_status(:success)
      expect(response.body).to include('login')
    end
  end
end

RSpec.describe 'User Dashboard Requests', type: :request do
  let(:user) { create(:user) }

  describe 'GET /dashboard' do
    context 'when user is logged in' do
      it 'displays the user dashboard' do
        login_as(user)
        get '/dashboard'
        expect(response).to have_http_status(:success)
      end

      it 'assigns the current user' do
        login_as(user)
        get '/dashboard'
        expect(assigns(:user)).to eq(user)
      end
    end

    context 'when user is not logged in' do
      it 'redirects to login' do
        get '/dashboard'
        expect(response).to redirect_to(login_path)
      end
    end
  end
end

RSpec.describe 'User Registration Requests', type: :request do
  describe 'POST /users' do
    let(:user_params) do
      {
        email: 'newuser@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        first_name: 'John',
        last_name: 'Doe',
        mobile_no: '9876543210',
        gender: 'Male'
      }
    end

    it 'creates a new user' do
      expect {
        post '/users', params: { user: user_params }
      }.to change(User, :count).by(1)
    end

    it 'assigns default role "user"' do
      post '/users', params: { user: user_params }
      user = User.find_by(email: user_params[:email])
      expect(user.role).to eq('user')
    end

    it 'logs in the new user' do
      post '/users', params: { user: user_params }
      expect(session[:user_id]).to be_present
    end

    it 'redirects to dashboard' do
      post '/users', params: { user: user_params }
      expect(response).to redirect_to(user_dashboard_path)
    end
  end

  describe 'GET /users/new' do
    it 'displays the signup form' do
      get '/users/new'
      expect(response).to have_http_status(:success)
      expect(response.body).to include('sign up')
    end
  end

  describe 'POST /users with admin role' do
    let(:admin_params) do
      {
        email: 'admin@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        first_name: 'Admin',
        mobile_no: '9876543211',
        gender: 'Male',
        role: 'admin'
      }
    end

    it 'creates admin user with minimal fields' do
      expect {
        post '/users', params: { user: admin_params }
      }.to change(User, :count).by(1)
    end

    it 'allows admin creation without matrimony fields' do
      post '/users', params: { user: admin_params }
      admin = User.find_by(email: admin_params[:email])
      expect(admin).to be_persisted
      expect(admin.role).to eq('admin')
    end
  end
end

RSpec.describe 'Admin Dashboard Requests', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  describe 'GET /admin/dashboard' do
    context 'when user is admin' do
      it 'displays admin dashboard' do
        login_as(admin)
        get '/admin/dashboard'
        expect(response).to have_http_status(:success)
      end

      it 'shows statistics' do
        login_as(admin)
        get '/admin/dashboard'
        expect(response.body).to include('Admin')
      end
    end

    context 'when user is not admin' do
      it 'denies access' do
        login_as(regular_user)
        get '/admin/dashboard'
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /admin/users' do
    context 'when user is admin' do
      it 'displays user list' do
        login_as(admin)
        get '/admin/users'
        expect(response).to have_http_status(:success)
      end

      it 'shows users' do
        login_as(admin)
        regular_user
        get '/admin/users'
        expect(response.body).to include(regular_user.first_name)
      end
    end

    context 'when user is not admin' do
      it 'denies access' do
        login_as(regular_user)
        get '/admin/users'
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /admin/users/:id' do
    context 'when updating user role' do
      it 'updates the role' do
        login_as(admin)
        patch "/admin/users/#{regular_user.id}", params: {
          user: { role: 'manager' }
        }
        regular_user.reload
        expect(regular_user.role).to eq('manager')
      end
    end
  end

  describe 'DELETE /admin/users/:id' do
    context 'when deleting a user' do
      it 'deletes the user' do
        login_as(admin)
        user_to_delete = create(:user)
        expect {
          delete "/admin/users/#{user_to_delete.id}"
        }.to change(User, :count).by(-1)
      end
    end
  end
end

# Helper method
def login_as(user)
  post '/sessions', params: {
    session: {
      email: user.email,
      password: 'password123'
    }
  }
end
