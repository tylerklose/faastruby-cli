def handler event
  render js: File.read('main.js')
end
