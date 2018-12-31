require "./spec_helper"

describe "handler(event)" do
  body = {"name" => "Ruby"}.to_json
  event_hash = {
    "body" => body,
    "context" => nil,
    "headers" => {"Content-Type" => "application/json"},
    "query_params" => {} of String => String
  }
  event = Event.from_json(event_hash.to_json)

  it "should return String" do
    body = handler(event).body
    body.class.should eq(String)
  end
  it "should add the name to the response string" do
    body = handler(event).body
    body.should eq("Hello, Ruby!\n")
  end
  it "should say Hello, World! when name is not present" do
    event_hash["body"] = nil
    event = Event.from_json(event_hash.to_json)
    body = handler(event).body
    body.should eq("Hello, World!\n")
  end
end
