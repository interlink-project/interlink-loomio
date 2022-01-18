class Clients::Aac < Clients::Base

  def fetch_access_token(code, uri)
    post "oauth/token", params: { code: code, redirect_uri: uri, grant_type: :authorization_code }
  end

  def fetch_user_info
    get "userinfo", headers: {} 
  end

  def scope
    %w(email profile openid).freeze
  end

  private

  def authorization_headers
    { 'Authorization' => "Bearer #{@token}" }
  end

  def common_headers
    { 'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8' }
  end

  def default_headers
    if @token
      common_headers.merge(authorization_headers)
    else
      common_headers
    end
  end

  def token_name
    :oauth_token
  end

  def default_host
    ENV['AAC_HOST']
  end
end
