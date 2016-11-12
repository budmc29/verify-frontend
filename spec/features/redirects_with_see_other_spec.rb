require 'feature_helper'
require 'api_test_helper'
describe 'pages redirect with see other', type: :request do
  it 'sets a see other for redirects' do
    stub_request(:post, api_uri('session')).to_return(body: session.to_json, status: 201)
    stub_api_saml_endpoint
    post '/SAML2/SSO', params: { 'SAMLRequest' => 'my-saml-request', 'RelayState' => 'my-relay-state' }
    expect(response.status).to eql 303
  end
end
