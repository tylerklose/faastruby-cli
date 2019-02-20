def handler event
  response = {
    'message' => "Welcome to FaaStRuby LocalKit! Edit the function 'root' to customize this response."
  }
  render json: response
end
