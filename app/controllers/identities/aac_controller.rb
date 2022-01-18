class Identities::AacController < Identities::BaseController

  private

  def oauth_url
    super.gsub("%2B", "+")
  end

  def oauth_host
    "#{ENV['AAC_HOST']}/oauth/authorize"
  end

  def oauth_params
    super.merge(response_type: :code, scope: client.scope.join('+'))
  end

  def associate_identity
    user = nil
    if !(user = existing_identity&.user || current_user.presence || existing_user)
      user = UserService.create(params: {:email => identity.email})
      EventBus.broadcast('registration_create', user)
    end
    user.associate_with_identity(identity)
    sign_in(user)
    flash[:notice] = t(:'devise.sessions.signed_in')
  end

end
