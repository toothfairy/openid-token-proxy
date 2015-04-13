require 'spec_helper'

RSpec.describe OpenIDTokenProxy::CallbackController, type: :controller do
  routes { OpenIDTokenProxy::Engine.routes }
  let(:access_token) { 'access token' }
  let(:auth_code) { 'authorization code' }
  let(:client) { OpenIDTokenProxy.client }
  let(:token) { double(access_token: access_token) }

  context 'when authorization code is missing' do
    it 'returns 400 BAD REQUEST' do
      get :handle
      expect(response.body).to be_blank
      expect(response.status).to eq 400
    end
  end

  context 'when authorization code is given' do
    before do
      expect(client).to receive(:token_via_auth_code!).and_return token
    end

    context 'with no-op token acquirement hook' do
      it 'redirects to root' do
        OpenIDTokenProxy.configure_temporarily do |config|
          config.token_acquirement_hook = proc { }
          get :handle, code: auth_code
          expect(response).to redirect_to controller.main_app.root_url
        end
      end
    end

    context 'when returning URI from token acquirement hook' do
      it 'redirects to returned URI' do
        OpenIDTokenProxy.configure_temporarily do |config|
          uri = '/#token'
          config.token_acquirement_hook = proc { |token, error|
            uri
          }
          get :handle, code: auth_code
          expect(response).to redirect_to uri
        end
      end
    end

    context 'when performing an action within token acquirement hook' do
      it 'takes no additional action' do
        OpenIDTokenProxy.configure_temporarily do |config|
          config.token_acquirement_hook = proc { |token, error|
            render text: 'Custom action'
          }
          get :handle, code: auth_code
          expect(response.body).to eq 'Custom action'
        end
      end
    end
  end
end
