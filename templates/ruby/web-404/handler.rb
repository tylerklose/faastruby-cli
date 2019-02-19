def handler event
  render html: File.read('404.html')
end
