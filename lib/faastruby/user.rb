module FaaStRuby
  class User < BaseObject
    def self.create(email:, password:)
      api = API.new
      user = User.new(email: email)
      response = api.signup(email: email, password: password)
      user.status_code = response.code
      if response.errors.any?
        user.errors += response.errors
        return user
      end
      case response.code
      when 422
        user.errors += ['(422) Unprocessable Entity', response.body]
      when 200, 201
        true
      else
        user.errors << "(#{response.code}) Error"
      end
      return user
    end

    attr_accessor :email, :password, :status_code, :errors, :api_key, :api_secret, :confirmation_token

    def logout(all: false)
      response = @api.logout(api_key: @api_key, api_secret: @api_secret, all: all)
      @status_code = response.code
      @errors += response.errors if response.errors.any?
      self
    end

    def login
      response = @api.login(email: @email, password: @password)
      @status_code = response.code
      if response.errors.any?
        @errors += response.errors
        return self
      end
      if response.body['credentials']
        @api_key = response.body['credentials']['api_key']
        @api_secret = response.body['credentials']['api_secret']
      end
      self
    end

    def has_credentials?
      @api_key && @api_secret
    end

    def confirm_account!
      response = @api.confirm_account(@confirmation_token)
      @status_code = response.code
      if response.errors.any?
        @errors += response.errors
        return self
      end
      if response.body['credentials']
        @api_key = response.body['credentials']['api_key']
        @api_secret = response.body['credentials']['api_secret']
      end
      self
    end

    def send_confirmation_code
      response = @api.send_confirmation_code(@email)
      @status_code = response.code
      @errors += response.errors if response.errors.any?
      self
    end

    def save_credentials
      credentials_file = NewCredentials::CredentialsFile.new
      credentials_file.save(email: @email, api_key: @api_key, api_secret: @api_secret)
    end

  end
end