module TokenHelper

  @@jwks = nil  
  JWKS_URL = "#{ENV['AAC_HOST']}/jwk".freeze  

  def validate_token
    user
  end

  def user
    associate_identity(decoded_auth_token)
  end

  def existing_user(tokeninfo)
    @existing_user ||= User.verified.find_by(email: tokeninfo[0]["preferred_username"])
  end

  def associate_identity(tokeninfo)
    if tokeninfo && !current_user.presence
        if user = existing_user(tokeninfo)
        sign_in(user)
        flash[:notice] = t(:'devise.sessions.signed_in')
        end
    end
  end

  def decoded_auth_token
    if http_auth_header
        @decoded_auth_token ||= decode(http_auth_header)
    end
  end

  def decode(token)
    JWT.decode(
        token,
        nil,
        true, # Verify the signature of this token
        algorithms: ["RS256"],
        iss: "#{ENV['AAC_HOST']}",
        verify_iss: true,
        aud: nil,
        verify_aud: false,
        jwks: @@jwks || fetch_jwks,
      )
  end

  def fetch_jwks
    puts('direct call')
    response = HTTP.get(JWKS_URL)
    if response.code == 200
      @@jwks = JSON.parse(response.body.to_s)
      @@jwks
    end
  end

  
  def http_auth_header
    if request.headers.present? and request.headers['Authorization'].present?
        return request.headers['Authorization'].split(' ').last
    end
    nil
  end
end