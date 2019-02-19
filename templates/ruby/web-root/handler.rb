def handler event
  render html: File.read('index.html')
end
