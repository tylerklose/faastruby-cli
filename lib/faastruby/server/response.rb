module FaaStRuby
  class Response
    attr_accessor :body, :status, :headers, :binary
    def initialize(body:, status: 200, headers: {}, binary: false)
      @body = body
      @status = status
      @headers = headers
      @binary = binary
    end

    def binary?
      @binary
    end
  end
end