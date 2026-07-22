Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], {
    scope: "email,profile",
    prompt: "consent"
  }

  provider :facebook, ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_APP_SECRET"], {
    scope: "email,public_profile",
    info_fields: "email,name,picture"
  }
end

OmniAuth.config.allowed_request_methods = [
  "localhost:3000",
  "localhost:5000",
  ENV["DOMAIN"] || "localhost:3000"
]

OmniAuth.config.silence_get_warning = true
