module TokenHelper

  @@jwks = nil  
  JWKS_URL = "#{ENV['AAC_HOST']}/jwk".freeze  
  ADMIN_MAIL = 'admin@api'

  def validate_token
    associate_identity(decoded_auth_token)
  end

  def existing_user(email)
    puts email
    @existing_user ||= User.verified.find_by(email: email)
  end

  # check token info: if client token, should match the Client ID. In this case becomes an admin user. 
  # If user token, becomes the user (should exist). 
  def associate_identity(tokeninfo)
    if tokeninfo && !current_user.presence
        user = nil
        if is_admin_call(tokeninfo)
          user = existing_user(ADMIN_MAIL)
        else 
          user = existing_user(tokeninfo[0]["preferred_username"])
        end
        sign_in(user)
        flash[:notice] = t(:'devise.sessions.signed_in')
    elsif tokeninfo && is_admin_call(tokeninfo)
      create_or_read_admin
    end
  end

  def is_admin_call(tokeninfo)
    tokeninfo[0]['sub'] == ENV['AAC_APP_KEY']
  end

  def create_or_read_admin
    user = User.verified.find_by(email: ADMIN_MAIL)
    if !user
      user = User.create(name: 'api admin', email: ADMIN_MAIL, email_verified: true, is_admin: true) 
    end
    EventBus.broadcast('registration_create', user)
    sign_in(user)
    flash[:notice] = t(:'devise.sessions.signed_in')
  end


  def decoded_auth_token
    if http_auth_header
        @decoded_auth_token ||= decode(http_auth_header)
    end
  end

  def decode(token)
    begin 
      return JWT.decode(
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
    rescue
      return nil
    end  
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