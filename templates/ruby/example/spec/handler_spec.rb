require 'spec_helper'
require 'handler'

describe 'handler(event)' do
  let(:event) {SpecHelper::Event.new}

  it 'should return a String' do
    body = handler(event).call.body
    expect(body).to be_a(String)
  end
  it 'should reply Hello, World!' do
    body = handler(event).call.body
    expect(body).to be == "Hello, World!\n"
  end
end
