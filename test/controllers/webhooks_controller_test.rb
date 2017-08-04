require 'test_helper'

class WebhooksControllerTest < ActionController::TestCase
  test "should get create_payment" do
    get :create_payment
    assert_response :success
  end

end
