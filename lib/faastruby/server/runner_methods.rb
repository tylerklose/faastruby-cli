module FaaStRuby
  module RunnerMethods
    require 'yaml'
    def rendered!
      @rendered = true
    end
    def rendered?
      @rendered
    end

    def respond_with(body, status: 200, headers: {}, binary: false)
      raise FaaStRuby::DoubleRenderError.new("You called 'render/respond_with/redirect_to' twice in your handler method") if rendered?
      response = FaaStRuby::Response.new(body: body, status: status, headers: headers, binary: binary)
      rendered!
      response
    end

    def render(
        js: nil,
        css: nil,
        body: nil,
        inline: nil,
        html: nil,
        json: nil,
        yaml: nil,
        text: nil,
        data: nil,
        png: nil,
        svg: nil,
        jpeg: nil,
        gif: nil,
        icon: nil,
        status: 200, headers: {}, content_type: nil, binary: false
      )
      headers["Content-Type"] = content_type if content_type
      bin = false
      case
      when json
        headers["Content-Type"] ||= "application/json"
        resp_body = json.is_a?(String) ? json : Oj.dump(json)
      when html, inline
        headers["Content-Type"] ||= "text/html"
        resp_body = html || inline
      when text
        headers["Content-Type"] ||= "text/plain"
        resp_body = text
      when yaml
        headers["Content-Type"] ||= "application/yaml"
        resp_body = yaml.is_a?(String) ? yaml : YAML.load(yaml)
      when body
        headers["Content-Type"] ||= "application/octet-stream"
        bin = binary
        resp_body = bin ? Base64.urlsafe_encode64(body) : body
      when data
        headers["Content-Type"] ||= "application/octet-stream"
        resp_body = Base64.urlsafe_encode64(data, padding: false)
        bin = true
      when js
        headers["Content-Type"] ||= "text/javascript"
        resp_body = js
      when css
        headers["Content-Type"] ||= "text/css"
        resp_body = css
      when png
        headers["Content-Type"] ||= "image/png"
        resp_body = Base64.urlsafe_encode64(File.binread(png), padding: false)
        bin = true
      when svg
        headers["Content-Type"] ||= "image/svg+xml"
        resp_body = svg
      when jpeg
        headers["Content-Type"] ||= "image/jpeg"
        resp_body = Base64.urlsafe_encode64(File.binread(jpeg), padding: false)
        bin = true
      when gif
        headers["Content-Type"] ||= "image/gif"
        resp_body = Base64.urlsafe_encode64(File.binread(gif), padding: false)
        bin = true
      when icon
        headers["Content-Type"] ||= "image/x-icon"
        resp_body = Base64.urlsafe_encode64(File.binread(icon), padding: false)
        bin = true
      end
      respond_with(resp_body, status: status, headers: headers, binary: bin)
    end

    def render_nothing(status: 200, headers: {})
      respond_with(nil, status: status, headers: headers, binary: false)
    end

    def render_template(template_path, status: 200, headers: {}, variables: {})
      render html: FaaStRuby::Template.new(variables: variables).render(template_path), status: status, headers: headers
    end

    def redirect_to(function: nil, url: nil, status: 303)
      headers = {"Location" => function || url}
      respond_with(nil, status: status, headers: headers, binary: false)
    end

    def puts(msg)
      super "[#{@path}] #{msg}".green
    end

    # def publish(channel, data: nil)
    #   begin
    #     encoded_data = data ? Base64.urlsafe_encode64(data, padding: false) : ""
    #     payload = %(#{Base64.urlsafe_encode64(channel, padding: false)},#{encoded_data})
    #     EventHub.queue.push payload
    #     true
    #   rescue
    #     false
    #   end
    # end
  end
end