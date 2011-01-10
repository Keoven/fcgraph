require 'spec_helper'

describe GraphsController do

  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'generate'" do
    it "should be successful" do
      get 'generate'
      response.should be_success
    end
  end

end
