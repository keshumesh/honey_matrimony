require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:valid_params) do
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

  describe 'GET #index' do
    before { get :index }

    it 'returns a success response' do
      expect(response).to be_successful
    end

    it 'assigns all users to @users' do
      user
      get :index
      expect(assigns(:users)).to include(user)
    end
  end

  describe 'GET #new' do
    before { get :new }

    it 'returns a success response' do
      expect(response).to be_successful
    end

    it 'assigns a new User to @user' do
      expect(assigns(:user)).to be_a_new(User)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new User' do
        expect {
          post :create, params: { user: valid_params }
        }.to change(User, :count).by(1)
      end

      it 'assigns default role as "user"' do
        post :create, params: { user: valid_params }
        user = User.find_by(email: valid_params[:email])
        expect(user.role).to eq('user')
      end

      it 'sets session user_id' do
        post :create, params: { user: valid_params }
        expect(session[:user_id]).to be_present
      end

      it 'redirects to dashboard' do
        post :create, params: { user: valid_params }
        expect(response).to redirect_to(user_dashboard_path)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new User' do
        expect {
          post :create, params: { user: { email: 'invalid' } }
        }.not_to change(User, :count)
      end

      it 're-renders the new template' do
        post :create, params: { user: { email: 'invalid' } }
        expect(response).to render_template(:new)
      end
    end

    context 'with admin role and minimal parameters' do
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

      it 'creates admin user without matrimony fields' do
        expect {
          post :create, params: { user: admin_params }
        }.to change(User, :count).by(1)
      end

      it 'assigns admin role' do
        post :create, params: { user: admin_params }
        admin = User.find_by(email: admin_params[:email])
        expect(admin.role).to eq('admin')
      end

      it 'allows missing last_name for admin' do
        post :create, params: { user: admin_params }
        expect(User.find_by(email: admin_params[:email])).to be_persisted
      end
    end
  end

  describe 'GET #dashboard' do
    context 'when user is logged in' do
      before do
        log_in_as(user)
        get :dashboard
      end

      it 'returns a success response' do
        expect(response).to be_successful
      end

      it 'assigns user to @user' do
        expect(assigns(:user)).to eq(user)
      end
    end

    context 'when user is not logged in' do
      before { get :dashboard }

      it 'redirects to login' do
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'GET #show' do
    before { get :show, params: { id: user.id } }

    it 'returns a success response' do
      expect(response).to be_successful
    end

    it 'assigns the requested user to @user' do
      expect(assigns(:user)).to eq(user)
    end
  end

  describe 'GET #edit' do
    context 'when user is logged in and editing own profile' do
      before do
        log_in_as(user)
        get :edit, params: { id: user.id }
      end

      it 'returns a success response' do
        expect(response).to be_successful
      end

      it 'assigns the requested user to @user' do
        expect(assigns(:user)).to eq(user)
      end
    end

    context 'when user tries to edit another user' do
      let(:other_user) { create(:user) }

      before do
        log_in_as(user)
        get :edit, params: { id: other_user.id }
      end

      it 'redirects with access denied' do
        expect(response).to redirect_to(users_path)
      end
    end
  end

  describe 'PATCH #update' do
    context 'when user is logged in and updating own profile' do
      let(:new_params) do
        {
          first_name: 'Jane',
          middle_name: 'Marie'
        }
      end

      before do
        log_in_as(user)
        patch :update, params: { id: user.id, user: new_params }
      end

      it 'updates the user' do
        user.reload
        expect(user.first_name).to eq('Jane')
      end

      it 'redirects to show' do
        expect(response).to redirect_to(user_path(user))
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user deletes own account' do
      before do
        log_in_as(user)
        delete :destroy, params: { id: user.id }
      end

      it 'deletes the user' do
        expect(User.find_by(id: user.id)).to be_nil
      end

      it 'clears the session' do
        expect(session[:user_id]).to be_nil
      end

      it 'redirects to home' do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # Helper method
  def log_in_as(user)
    session[:user_id] = user.id
  end
end
