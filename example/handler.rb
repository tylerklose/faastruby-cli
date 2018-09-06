# require 'cool-gem'
require 'json'

# 1) If you don't have a workspace, create one by running:
# faastruby create-workspace WORKSPACE_NAME
# 2) To deploy this function, cd into its folder and run:
# faastruby deploy WORKSPACE_NAME
def handler event
  headers = {
    'Content-Type' => 'text/plain',
    'My-Custom-Header' => 'Value'
  }
  data = event.body ? JSON.parse(event.body) : {}
  # The response must be a Hash, Array or String.
  response = "Hello, #{data['name'] || 'World'}!"
  respond_with response, status: 200, headers: headers
end
