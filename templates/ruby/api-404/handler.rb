def handler event
  response = {
    'message' => "Page Not Found. Edit the function 'catch-all/404' to customize this response."
  }
  render json: response, status: 404
end
