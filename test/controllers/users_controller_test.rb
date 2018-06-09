require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should get polls" do
    get :polls
    assert_response :success
  end

end
