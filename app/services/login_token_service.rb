class LoginTokenService
  def self.create(actor:, uri:)
    return unless actor.presence

    token = LoginToken.create!(redirect: (uri.path if uri&.host == ENV['CANONICAL_HOST']), user: actor)

    UserMailer.delay.login(actor.id, token.id)
    EventBus.broadcast('login_token_create', token, actor)
  end
end
