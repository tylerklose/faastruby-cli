require "yaml"
require "json"
require "base64"

module FaaStRuby
  class Event
    JSON.mapping(
      body: String?,
      headers: Hash(String, String),
      context: String?,
      query_params: Hash(String, String)
    )
  end
  class Response
    @@rendered = false
    property "body"
    property "status"
    property "headers"
    property "io"
    def initialize(@body : String?, @status : Int32, @headers : Hash(String, String))
      @io = nil
    end

    def initialize(@io : Bytes, @status : Int32, @headers : Hash(String, String))
    end

    def payload
      if io
        hash = {
          "response" => Base64.encode(io.not_nil!),
          "status" => status,
          "headers" => headers
        }
      else
        hash = {
          "response" => body,
          "status" => status,
          "headers" => headers
        }
      end
      hash
    end
  end

  def respond_with(body : String? = nil, status : Int32 = 200, headers : Hash(String, String) = {} of String => String)
    Response.new(body: body, status: status, headers: headers)
  end

  def respond_with(io : Bytes, status : Int32 = 200, headers : Hash(String, String) = {} of String => String)
    Response.new(io: io, status: status, headers: headers)
  end

  def render(io : Bytes? = nil, js : String? = nil, inline : String? = nil, html : String? = nil, json : String? = nil, yaml : String? = nil, text : String? = nil, status : Int32 = 200, headers : Hash(String, String) = {} of String => String, content_type : String? = nil)
    headers["Content-Type"] = content_type if content_type
    case
    when json
      headers["Content-Type"] ||= "application/json"
      resp_body = json
    when html, inline
      headers["Content-Type"] ||= "text/html"
      resp_body = html
    when text
      headers["Content-Type"] ||= "text/plain"
      resp_body = text
    when yaml
      headers["Content-Type"] ||= "text/yaml"
      resp_body = yaml
    when js
      headers["Content-Type"] ||= "text/javascript"
      resp_body = js
    when io
      headers["Content-Type"] ||= "application/octet-stream"
      return respond_with(io: io, status: status, headers: headers)
    end
    respond_with(body: resp_body, status: status, headers: headers)
  end
end
