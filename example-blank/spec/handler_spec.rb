require 'spec_helper'
require 'handler'

describe 'handler(event)' do
  let(:event) {SpecHelper::Event.new}

  it 'should return Hash, String or Array' do
    body = handler(event).body
    expect([String, Hash, Array].include? body.class).to be true
  end
end
