require 'spec_helper'
require 'handler'

describe 'handler(event)' do
  let(:event) {Event.new(
    body: nil,
    query_params: {},
    headers: {},
    context: nil
  )}

  it 'should return a String' do
    body = handler(event).body
    expect(body).to be_a(String)
  end
  it 'should reply Hello, World!' do
    body = handler(event).body
    expect(body).to be == "Hello, World!\n"
  end
end
