require "test_helper"

class QuizControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get quiz_index_url
    assert_response :success
  end

  test "should get show" do
    get quiz_show_url
    assert_response :success
  end

  test "should get result" do
    get quiz_result_url
    assert_response :success
  end
end
