require 'feature_helper'
require 'api_test_helper'

RSpec.describe 'user encounters error page' do
  let(:api_saml_endpoint) { api_uri('session') }
  let(:api_select_idp_endpoint) { api_uri(select_idp_endpoint(default_session_id)) }

  it 'will present the user with a list of transactions' do
    stub_transactions_list
    stub_request(:post, api_saml_endpoint).to_return(status: 500)
    visit '/test-saml'
    click_button "saml-post"
    expect(page).to have_content "Sorry, something went wrong"
    expect(page).to have_css "#piwik-custom-url", text: "errors/generic-error"
    expect(page).to have_link "register for an identity profile", href: "http://localhost:50130/test-rp"
  end

  it 'will present the user with no list of transactions if we cant read the errors' do
    allow(Rails.logger).to receive(:error)
    expect(Rails.logger).to receive(:error).with(kind_of(KeyError)).at_least(:once)
    bad_transactions_json = {
        'public' => [{ 'homepage' => 'http://localhost:50130/test-rp' }],
        'private' => []
    }
    stub_request(:post, api_saml_endpoint).to_return(status: 500)
    stub_request(:get, api_transactions_endpoint).to_return(body: bad_transactions_json.to_json, status: 200)
    visit '/test-saml'
    click_button "saml-post"
    expect(page).to have_content "Sorry, something went wrong"
    expect(page).to_not have_content "Find the service you were using to start again"
    expect(page).to have_css "#piwik-custom-url", text: "errors/generic-error"
    expect(page.status_code).to eq(500)
  end

  it 'will present error page when timeout occurs in upstream systems' do
    stub_request(:post, api_saml_endpoint).to_timeout
    stub_transactions_list
    visit '/test-saml'
    click_button "saml-post"
    expect(page).to have_content "Sorry, something went wrong"
    expect(page).to have_css "#piwik-custom-url", text: "errors/generic-error"
    expect(page.status_code).to eq(500)
  end

  it 'will present error page when standard error occurs in upstream systems' do
    e = StandardError.new("my message")
    stub_request(:post, api_saml_endpoint).to_raise(e)
    stub_transactions_list
    visit '/test-saml'
    click_button "saml-post"
    expect(page).to have_content "Sorry, something went wrong"
    expect(page).to have_css "#piwik-custom-url", text: "errors/generic-error"
    expect(page.status_code).to eq(500)
  end

  it 'will log to raven when standard error' do
    e = StandardError.new("my message")
    expect(Raven).to receive(:capture_exception).with(e)
    stub_request(:post, api_saml_endpoint).to_raise(e)
    stub_transactions_list
    visit '/test-saml'
    click_button "saml-post"
    expect(page).to have_content "Sorry, something went wrong"
    expect(page.status_code).to eq(500)
  end

  it 'will present something went wrong when parsable upstream error occurs and not log error' do
    expect(Raven).to_not receive(:capture_exception)
    expect(Rails.logger).to_not receive(:error)
    error_body = { id: '0', type: 'SERVER_ERROR' }
    stub_request(:post, api_saml_endpoint).and_return(status: 500, body: error_body.to_json)
    stub_transactions_list
    visit '/test-saml'
    click_button "saml-post"
    expect(page).to have_content "Sorry, something went wrong"
    expect(page.status_code).to eq(500)
  end

  it 'will present session error page when session error occurs in upstream systems' do
    set_session_and_session_cookies!
    error_body = { id: '0', type: 'SESSION_ERROR' }
    stub_request(:post, api_uri('session')).to_return(body: error_body.to_json, status: 400)
    visit('/test-saml')
    click_button 'saml-post'
    expect(page).to have_content "You need to start again"
    expect(page).to have_content "For security reasons"
    expect(page).to have_css "#piwik-custom-url", text: "errors/session-error"
    expect(page.status_code).to eq(400)
  end

  it 'will present a session timeout error page when the API returns session timeout' do
    set_session_and_session_cookies!
    error_body = { id: '0', type: 'SESSION_TIMEOUT' }
    stub_request(:post, api_uri('session')).to_return(body: error_body.to_json, status: 400)
    visit('/test-saml')
    click_button 'saml-post'
    expect(page).to have_content "Your session has timed out"
    expect(page).to have_content "Please go back to your service"
    expect(page).to have_css "#piwik-custom-url", text: "errors/timeout-error"
    expect(page).to have_css "a[href*=EXPIRED_ERROR_PAGE]"
    expect(page.status_code).to eq(403)
  end

  it 'will present the something went wrong page in Welsh when secure cookie is invalid' do
    set_session_and_session_cookies!
    stub_transactions_list
    stub_request(:put, api_select_idp_endpoint).and_return(status: 403)
    visit sign_in_cy_path
    click_button 'Welsh IDCorp'
    expect(page).to have_content I18n.translate('errors.something_went_wrong.heading', locale: :cy)
    expect(page.status_code).to eq(500)
  end

  it 'will present the something went wrong page when secure cookie is invalid' do
    set_session_and_session_cookies!
    stub_transactions_list
    stub_request(:put, api_select_idp_endpoint).and_return(status: 403)
    visit sign_in_path
    click_button 'IDCorp'
    expect(page).to have_content "Sorry, something went wrong"
    expect(page).to have_link "register for an identity profile", href: "http://localhost:50130/test-rp"
    expect(page).to have_css "#piwik-custom-url", text: "errors/generic-error"
    expect(page.status_code).to eq(500)
  end
end
