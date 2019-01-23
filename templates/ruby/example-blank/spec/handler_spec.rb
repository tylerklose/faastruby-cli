require 'spec_helper'
require 'handler'

describe 'handler(event)' do
  let(:event) {Event.new(
    body: nil,
    query_params: {},
    headers: {},
    context: nil
  )}

  xit 'write some tests here' do
    # function_return = handler(event).call
    expect(true).to eq(false)
  end
end
