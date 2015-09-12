require 'minitest/autorun'
require 'minitest/pride'
require './lib/storyteller'
require 'json'

class StorytellerTest < Minitest::Test
  TEST_REPO      = ["AllPurposeName/test-stories", "AllPurposeName/test-story"]
  TEST_LABEL     = "TestLabel#{rand(10)}"
  TEST_NEW_LABEL = "new_label#{rand(10)}"
  attr_reader :steller, :test_label, :test_new_label

  def setup
    @steller = Storyteller.new
    @steller.repos = TEST_REPO
  end

  def teardown
    clear_new_label
  end

  def env
    @env ||= YAML.load_file("./config/application.yml")
  end

  def url
    "https://api.github.com"
  end

  def clear_new_label
    [TEST_LABEL, TEST_NEW_LABEL].each do |labl|
      steller.connection.delete("repos/#{TEST_REPO[0]}/labels/#{labl}")
      steller.connection.delete("repos/#{TEST_REPO[1]}/labels/#{labl}")
    end
  end

  def either_repo
    TEST_REPO.shuffle.first
  end

  def test_it_exists
    assert Storyteller
    assert_equal Faraday::Connection, Storyteller.new.connection.class
  end

  def test_it_has_correct_credentials
    assert steller.connection.get("/").success?
    steller.connection.basic_auth(env["GITHUB_USERNAME"], env["GITHUB_PASSWORD"])
    assert_equal "ClassicRichard", JSON.parse(steller.connection.get("#{url}/users/ClassicRichard").body)["login"]
  end

  def test_it_can_post_an_issue
    title  ="test it can post an issue"
    msg    = "this issue should be posted in the test-stories repo for AllPurpName"
    posts  = steller.post_issue(title, msg)
    repo   = either_repo

    assert posts.first.success?, 'status 200 should be true for the first repo'
    assert posts.last.success?,  'status 200 should be true for the second repo'
    assert steller.connection.get("repos/#{repo}/issues").body.include?(title)
    assert steller.connection.get("repos/#{repo}/issues").body.include?(msg)
  end

  def test_it_can_add_a_label_whether_existing_or_not
    label_name  = TEST_LABEL
    label_color = rand(1048576..16777216).to_s(16)
    label       = {name: label_name, color: label_color}
    repo        = either_repo

    new_label_posts = steller.add_labels(label)

    assert new_label_posts.first.first.success?, 'status 200 should be true before anything else'
    assert new_label_posts.last.last.success?,   'status 200 should be true before anything else'

    label_responses = JSON.parse(steller.connection.get("repos/#{repo}/labels").body)
    assert label_responses.map(&:values).one? { |values| values.include?(label_name) },   "This issues name should appear in the response"
    assert label_responses.map(&:values).one? { |values| values.include?(label_color) },  "This issues color should appear in the response"
  end

  def test_issues_are_posted_with_labels_whether_they_previously_exist_or_not
    title          = "Labels should work"
    msg            = "I really hope labels are working"
    new_label      = TEST_NEW_LABEL
    existing_label = "duplicate"
    repo           = either_repo

    #assert the repo has the labels we think it has
    label_responses = JSON.parse(steller.connection.get("repos/#{repo}/labels").body)
    assert label_responses.map(&:values).one? { |values| values.include?(existing_label) }, "This repo SHOULD have the exisiting label already"

    assert label_responses.map(&:values).none? { |values| values.include?(new_label) }, "This repo SHOULD NOT have the new label yet"

    label_responses.each do |label_response|
      refute_equal label_response["name"], new_label, "None of the current labels should share the random name"
    end
    assert label_responses.find do |label_response|
      label_response["name"] == existing_label
    end

    steller.labels  = [new_label, existing_label]
    label_posts     = steller.post_issue(title, msg)

    assert label_posts.first.success?, 'status 200 should be true before anything else'
    assert label_posts.last.success?, 'status 200 should be true before anything else'
    issue_number = JSON.parse(steller.connection.get("repos/#{repo}/issues").body).first["number"]
    label_responses = JSON.parse(steller.connection.get("repos/#{repo}/issues/#{issue_number}/labels").body)
    assert label_responses.map(&:values).one? {|values| values.include?(existing_label) }, "This issue SHOULD have the exisiting label"
    assert label_responses.map(&:values).one? {|values| values.include?(new_label) },      "This issue SHOULD have the new label"
  end
end
