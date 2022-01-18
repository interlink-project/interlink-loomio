class Identities::Aac < Identities::Base
  include Identities::WithClient
  set_identity_type :aac

  def apply_user_info(payload)
    self.uid   ||= payload['sub']
    self.name  ||= payload['given_name']
    self.email ||= payload['email']
    self.logo  ||= payload['picture']
  end
end
