require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  let(:admin_user) { create(:user, :admin) }
  let(:manager_user) { create(:user, :manager) }
  let(:regular_user) { create(:user) }

  controller do
    def test_logged_in
      require_login
      render plain: 'OK'
    end

    def test_admin
      require_admin
      render plain: 'OK'
    end

    def test_manager
      require_manager_or_admin
      render plain: 'OK'
    end
  end

  before do
    routes.draw do
      get 'test_logged_in', to: 'application#test_logged_in'
      get 'test_admin', to: 'application#test_admin'
      get 'test_manager', to: 'application#test_manager'
    end
  end

  describe '#current_user' do
    context 'when user is logged in' do
      before { session[:user_id] = regular_user.id }

      it 'returns the current user' do
        expect(controller.send(:current_user)).to eq(regular_user)
      end
    end

    context 'when user is not logged in' do
      it 'returns nil' do
        expect(controller.send(:current_user)).to be_nil
      end
    end
  end

  describe '#logged_in?' do
    context 'when user is logged in' do
      before { session[:user_id] = regular_user.id }

      it 'returns true' do
        expect(controller.send(:logged_in?)).to be true
      end
    end

    context 'when user is not logged in' do
      it 'returns false' do
        expect(controller.send(:logged_in?)).to be false
      end
    end
  end

  describe '#is_admin?' do
    context 'when user is admin' do
      before { session[:user_id] = admin_user.id }

      it 'returns true' do
        expect(controller.send(:is_admin?)).to be true
      end
    end

    context 'when user is not admin' do
      before { session[:user_id] = regular_user.id }

      it 'returns false' do
        expect(controller.send(:is_admin?)).to be false
      end
    end

    context 'when user is not logged in' do
      it 'returns false' do
        expect(controller.send(:is_admin?)).to be false
      end
    end
  end

  describe '#is_manager?' do
    context 'when user is manager' do
      before { session[:user_id] = manager_user.id }

      it 'returns true' do
        expect(controller.send(:is_manager?)).to be true
      end
    end

    context 'when user is not manager' do
      before { session[:user_id] = regular_user.id }

      it 'returns false' do
        expect(controller.send(:is_manager?)).to be false
      end
    end
  end

  describe '#require_login filter' do
    context 'when user is logged in' do
      before do
        session[:user_id] = regular_user.id
        get :test_logged_in
      end

      it 'allows access' do
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is not logged in' do
      before { get :test_logged_in }

      it 'redirects to login' do
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe '#require_admin filter' do
    context 'when user is admin' do
      before do
        session[:user_id] = admin_user.id
        get :test_admin
      end

      it 'allows access' do
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is not admin' do
      before do
        session[:user_id] = regular_user.id
        get :test_admin
      end

      it 'redirects to root' do
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not logged in' do
      before { get :test_admin }

      it 'redirects to login' do
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe '#require_manager_or_admin filter' do
    context 'when user is manager' do
      before do
        session[:user_id] = manager_user.id
        get :test_manager
      end

      it 'allows access' do
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is admin' do
      before do
        session[:user_id] = admin_user.id
        get :test_manager
      end

      it 'allows access' do
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is regular user' do
      before do
        session[:user_id] = regular_user.id
        get :test_manager
      end

      it 'redirects to root' do
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
