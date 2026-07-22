require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'GET #new' do
    before { get :new }

    it 'returns a success response' do
      expect(response).to be_successful
    end

    it 'renders the login template' do
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    context 'with valid email and password' do
      before do
        user
        post :create, params: {
          session: {
            email: 'test@example.com',
            password: 'password123'
          }
        }
      end

      it 'sets the session user_id' do
        expect(session[:user_id]).to eq(user.id)
      end

      it 'redirects to dashboard' do
        expect(response).to redirect_to(user_dashboard_path)
      end

      it 'sets a success flash message' do
        expect(flash[:notice]).to match(/logged in successfully/i)
      end
    end

    context 'with invalid email' do
      before do
        post :create, params: {
          session: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
      end

      it 'does not set session user_id' do
        expect(session[:user_id]).to be_nil
      end

      it 're-renders the login template' do
        expect(response).to render_template(:new)
      end

      it 'sets an error flash message' do
        expect(flash[:alert]).to match(/invalid|incorrect/i)
      end
    end

    context 'with incorrect password' do
      before do
        user
        post :create, params: {
          session: {
            email: 'test@example.com',
            password: 'wrongpassword'
          }
        }
      end

      it 'does not set session user_id' do
        expect(session[:user_id]).to be_nil
      end

      it 're-renders the login template' do
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      session[:user_id] = user.id
      delete :destroy
    end

    it 'clears the session user_id' do
      expect(session[:user_id]).to be_nil
    end

    it 'redirects to home' do
      expect(response).to redirect_to(root_path)
    end

    it 'sets a success flash message' do
      expect(flash[:notice]).to match(/logged out|goodbye/i)
    end
  end
end
