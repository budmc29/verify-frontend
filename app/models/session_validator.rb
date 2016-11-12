class SessionValidator
  def initialize(session_duration)
    @validators = [
      NoCookiesValidator.new,
      MissingCookiesValidator.new,
      SessionIdValidator.new,
      TransactionSimpleIdPresence.new,
      IdpPresence.new,
      SessionStartTimeValidator.new(session_duration),
      CookieSizeValidator.new
    ]
  end

  def validate(cookies, session)
    @validators.lazy.map { |validator| validator.validate(cookies, session) }.detect(&:bad?) || SuccessfulValidation
  end
end
