require 'feature_helper'
require 'i18n'

RSpec.describe 'When the user visits the choose a certified company page' do
  before(:each) do
    set_session_cookies!
  end

  let(:selected_evidence) { { documents: [:passport, :driving_licence], phone: [:mobile_phone] } }
  let(:one_doc_selected_evidence) { { documents: [:driving_licence], phone: [:mobile_phone] } }
  let(:given_a_session_with_selected_evidence) {
    page.set_rack_session(
      selected_evidence: selected_evidence,
    )
  }

  let(:given_a_session_without_selected_evidence) {
    page.set_rack_session(
      selected_evidence: {},
    )
  }

  let(:given_a_session_with_one_doc_selected_evidence) {
    page.set_rack_session(
      selected_evidence: one_doc_selected_evidence,
    )
  }

  it 'includes the appropriate feedback source' do
    stub_federation
    visit '/choose-a-certified-company'

    expect_feedback_source_to_be(page, 'CHOOSE_A_CERTIFIED_COMPANY_PAGE')
  end

  it 'displays recommended IDPs' do
    stub_federation
    given_a_session_with_selected_evidence
    visit '/choose-a-certified-company'

    expect(page).to have_current_path(choose_a_certified_company_path)
    expect(page).to have_content('Based on your answers, 2 companies can verify you now:')
    within('#matching-idps') do
      expect(page).to have_button('Choose IDCorp')
    end
  end

  it 'displays no IDPs if no recommendations' do
    stub_federation
    given_a_session_without_selected_evidence
    visit '/choose-a-certified-company'
    expect(page).to have_current_path(choose_a_certified_company_path)
    expect(page).to_not have_css('#non-matching-idps')
    expect(page).to have_content('Based on your answers, no companies can verify you now:')
  end

  it 'recommends some IDPs with a recommended profile, hides non-recommended profiles, and omits non-matching profiles' do
    stub_federation_no_docs
    given_a_session_with_one_doc_selected_evidence
    visit '/choose-a-certified-company'

    expect(page).to have_content('Based on your answers, 2 companies can verify you now:')
    within('#matching-idps') do
      expect(page).to have_button('Choose No Docs IDP')
      expect(page).to have_button('Choose IDCorp')
      expect(page).to_not have_button('Bob\'s Identity Service')
    end

    within('#non-matching-idps') do
      expect(page).to have_button('Choose Bob\'s Identity Service')
    end

    expect(page).to_not have_button('Choose Carol\'s Secure ID')
  end

  it 'redirects to the redirect warning page when selecting a recommended IDP' do
    entity_id = 'http://idcorp.com'
    given_a_session_with_one_doc_selected_evidence
    stub_federation(entity_id)
    visit '/choose-a-certified-company'

    within('#matching-idps') do
      click_link 'About IDCorp'
      within('#about-stub-idp-one') do
        click_button 'Choose IDCorp'
      end
    end

    expect(page).to have_current_path(redirect_to_idp_warning_path)
    expect(page.get_rack_session_key('selected_idp')).to eql('entity_id' => entity_id, 'simple_id' => 'stub-idp-one')
    expect(page.get_rack_session_key('selected_idp_was_recommended')).to eql true
  end

  it 'redirects to the redirect warning page when selecting a non-recommended IDP' do
    given_a_session_with_one_doc_selected_evidence
    stub_federation
    visit '/choose-a-certified-company'

    click_link 'Show all companies'

    within('#non-matching-idps') do
      click_link 'About Bob\'s Identity Service'
      within('#about-stub-idp-two') do
        click_button 'Choose Bob\'s Identity Service'
      end
    end

    expect(page).to have_current_path(redirect_to_idp_warning_path)
    expect(page.get_rack_session_key('selected_idp')).to eql('entity_id' => 'other-entity-id', 'simple_id' => 'stub-idp-two')
    expect(page.get_rack_session_key('selected_idp_was_recommended')).to eql false
  end

  it 'displays the page in Welsh' do
    stub_federation
    visit '/choose-a-certified-company-cy'
    expect(page).to have_title 'Choose a certified company - GOV.UK Verify - GOV.UK'
    expect(page).to have_css 'html[lang=cy]'
  end
end
