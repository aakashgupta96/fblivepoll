require 'test_helper'

class LoopVideoControllerTest < ActionController::TestCase
  test "should get new" do
    get :new
    assert_response :success
  end

  test "should get create" do
    get :create
    assert_response :success
  end

  test "should get submit" do
    get :submit
    assert_response :success
  end

end
