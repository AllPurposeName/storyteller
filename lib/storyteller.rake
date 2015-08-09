require "capybara/poltergeist"
require 'pry'
require 'launchy'
require 'YAML'
require 'ostruct'

class Issuer
  attr_reader :session, :stories, :repository
  def initialize(stories_path)
    @session = Capybara::Session.new(:poltergeist)
    @repository, @stories = parse_stories(stories_path)
    run
  end

  def run
    login
    post_issues
    final_message
  end

  private

  def final_message
    puts "Issues finished posting."
  end

  def post_issues
    puts "Posting issues...\n"
    stories.each do |_, issue|
      post_issue(issue)
    end
  end

  def post_issue(issue)
    session.visit(url.new_issue)
    session.fill_in("issue[title]", with: issue["title"])
    session.fill_in("issue[body]", with: issue["body"])
    session.click_button("Submit new issue")
    puts "Issue #{issue['title']} posted.\n"
  end

  def parse_stories(file_path)
    yaml = YAML.load_file(file_path)
    repo = yaml["repositoryName"].sub("#{domain}/", "")
    stories = yaml["stories"]
    [repo, stories]
  end

  def login
    session.visit(url.login)
    session.fill_in("login",    with: (env.GITHUB_USERNAME))
    session.fill_in("password", with: (env.GITHUB_PASSWORD))
    session.click_button("Sign in")
    puts "Logged in as #{env.GITHUB_USERNAME}.\n"
  end

  def domain
    "https://github.com"
  end

  def url
    OpenStruct.new(login: "#{domain}/login",
                  new_issue: "#{domain}/#{repository}/issues/new")
  end

  def env
    @env ||= OpenStruct.new(YAML.load_file("./config/application.yml"))
  end
end

Issuer.new("./test/support/test_stories.yml")
