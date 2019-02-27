def handler event
  response = {
    'message' => "Welcome to FaaStRuby Local! Edit the function 'root' to customize this response."
  }
  render json: response
end
