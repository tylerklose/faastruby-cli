require 'spec_helper'
require 'handler'

describe 'handler(event)' do
  let(:event) {SpecHelper::Event.new(body: '{"name": "Ruby"}')}

  it 'should return Hash, String or Array' do
    body = handler(event).call.body
    expect([String, Hash, Array].include? body.class).to be true
  end
  it 'should add the name to the response string' do
    body = handler(event).call.body
    expect(body).to be == 'Hello, Ruby!'
  end
  it 'should say Hello, World! when name is not present' do
    event = SpecHelper::Event.new(body: nil)
    body = handler(event).call.body
    expect(body).to be == 'Hello, World!'
  end
end
