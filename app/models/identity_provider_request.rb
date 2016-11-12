class IdentityProviderRequest
  attr_reader :location, :saml_request, :relay_state, :registration, :hints, :language_hint

  def initialize(outbound_saml_message, simple_id, answers)
    @location = outbound_saml_message.location
    @saml_request = outbound_saml_message.saml_request
    @relay_state = outbound_saml_message.relay_state
    @registration = outbound_saml_message.registration
    @hints = get_hints(simple_id, answers, @registration)
    @language_hint = get_language_hint(simple_id)
  end

  def get_hints(simple_id, answers, registration)
    if IDP_HINTS_CHECKER.enabled?(simple_id) && registration
      HintsMapper.map_answers_to_hints(answers)
    else
      []
    end
  end

  def get_language_hint(simple_id)
    I18n.locale if IDP_LANGUAGE_HINT_CHECKER.enabled?(simple_id)
  end
end
