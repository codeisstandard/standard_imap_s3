require 'test_helper'

class ProcessControllerTest < ActionController::TestCase
  test "should get imap" do
    get :imap
    assert_response :success
  end

end
