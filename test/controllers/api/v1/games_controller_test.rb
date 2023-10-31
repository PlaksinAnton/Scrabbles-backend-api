require "test_helper"

class Api::V1::GamesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_games_index_url
    assert_response :success
  end

  test "should get show" do
    get api_v1_games_show_url
    assert_response :success
  end

  test "should get create" do
    get api_v1_games_create_url
    assert_response :success
  end

  test "should get update" do
    get api_v1_games_update_url
    assert_response :success
  end

  test "should get destroy" do
    get api_v1_games_destroy_url
    assert_response :success
  end
end
