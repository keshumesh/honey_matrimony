require 'rails_helper'

RSpec.describe AdminController, type: :controller do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:manager_user) { create(:user, :manager) }

  before do
    session[:user_id] = admin_user.id
  end

  describe 'GET #dashboard' do
    context 'when user is admin' do
      before { get :dashboard }

      it 'returns a success response' do
        expect(response).to be_successful
      end

      it 'assigns user statistics' do
        expect(assigns(:total_users)).to be_a(Integer)
        expect(assigns(:total_admins)).to be_a(Integer)
        expect(assigns(:total_managers)).to be_a(Integer)
        expect(assigns(:total_users_count)).to be_a(Integer)
      end

      it 'assigns recent users' do
        regular_user
        get :dashboard
        expect(assigns(:recent_users)).to include(regular_user)
      end
    end

    context 'when user is not admin' do
      before do
        session[:user_id] = regular_user.id
        get :dashboard
      end

      it 'redirects with access denied' do
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET #users' do
    context 'when user is admin' do
      before { get :users }

      it 'returns a success response' do
        expect(response).to be_successful
      end

      it 'assigns all users to @users' do
        regular_user
        get :users
        expect(assigns(:users)).to include(regular_user)
      end
    end

    context 'with search parameter' do
      before do
        regular_user
        get :users, params: { search: regular_user.first_name }
      end

      it 'filters users by name' do
        expect(assigns(:users)).to include(regular_user)
      end
    end
  end

  describe 'GET #show' do
    context 'when viewing user details' do
      before { get :show, params: { id: regular_user.id } }

      it 'returns a success response' do
        expect(response).to be_successful
      end

      it 'assigns the requested user to @user' do
        expect(assigns(:user)).to eq(regular_user)
      end
    end
  end

  describe 'GET #edit' do
    context 'when editing user' do
      before { get :edit, params: { id: regular_user.id } }

      it 'returns a success response' do
        expect(response).to be_successful
      end

      it 'assigns the requested user to @user' do
        expect(assigns(:user)).to eq(regular_user)
      end
    end
  end

  describe 'PATCH #update' do
    context 'when updating user role' do
      let(:new_params) do
        {
          role: 'manager'
        }
      end

      before do
        patch :update, params: { id: regular_user.id, user: new_params }
        regular_user.reload
      end

      it 'updates the user role' do
        expect(regular_user.role).to eq('manager')
      end

      it 'redirects to user details' do
        expect(response).to redirect_to(admin_user_path(regular_user))
      end
    end

    context 'when updating multiple user fields' do
      let(:new_params) do
        {
          first_name: 'Updated',
          email: 'newemail@example.com',
          role: 'admin'
        }
      end

      before do
        patch :update, params: { id: regular_user.id, user: new_params }
        regular_user.reload
      end

      it 'updates the user fields' do
        expect(regular_user.first_name).to eq('Updated')
      end
    end
  end

  describe 'GET #delete' do
    context 'when viewing delete confirmation' do
      before { get :delete, params: { id: regular_user.id } }

      it 'returns a success response' do
        expect(response).to be_successful
      end

      it 'assigns the requested user to @user' do
        expect(assigns(:user)).to eq(regular_user)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when deleting a user' do
      before do
        delete :destroy, params: { id: regular_user.id }
      end

      it 'deletes the user' do
        expect(User.find_by(id: regular_user.id)).to be_nil
      end

      it 'redirects to users list' do
        expect(response).to redirect_to(admin_users_path)
      end
    end

    context 'when trying to delete own account as admin' do
      it 'prevents deletion' do
        expect {
          delete :destroy, params: { id: admin_user.id }
        }.not_to change { User.find_by(id: admin_user.id) }
      end
    end
  end

  describe 'Authorization' do
    context 'when user is not admin' do
      before do
        session[:user_id] = regular_user.id
      end

      it 'blocks dashboard access' do
        get :dashboard
        expect(response).to redirect_to(root_path)
      end

      it 'blocks users list access' do
        get :users
        expect(response).to redirect_to(root_path)
      end

      it 'blocks user show access' do
        get :show, params: { id: regular_user.id }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is manager' do
      before do
        session[:user_id] = manager_user.id
      end

      it 'blocks admin dashboard access' do
        get :dashboard
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
