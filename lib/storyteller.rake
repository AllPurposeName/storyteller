require "capybara/poltergeist"
require 'pry'
require 'launchy'
require 'YAML'
require 'ostruct'

class Issuer
  attr_reader :session,
              :stories,
              :repository,
              :labels

  COLORS = {0 => "#207de5",
            1 => "#009800",
            2 => "#fbca04",
            3 => "#eb6420"}

  def initialize(stories_path)
    @labels = []
    @session = Capybara::Session.new(:poltergeist)
    @repository, @stories = parse_stories(stories_path)
    run
  end

  private

  def run
    login
    post_issues
    final_message
  end

  def post_issues
    puts "Posting issues...\n"
    stories.each do |_, label, issue|
      add_label(label)
      post_issue(issue)
    end
  end

  def add_label(label)
    unless labels.include?(label)
      session.visit(url.new_label)
      session.save_and_open_page
      session.click_button("New label")
      session.fill_in("label[name]", with: label)
      session.fill_in("label[color]", with: COLORS[labels.count])
      session.click_button("Create label")
      labels << label
      puts "Created label: #{label}.\n"
    end
  end

  def post_issue(issue)
    session.visit(url.new_issue)
    session.fill_in("issue[title]", with: issue["title"])
    session.fill_in("issue[body]", with: issue["body"])
    session.click_button("Submit new issue")
    puts "Posted issue #{issue['title']}.\n"
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

  def final_message
    puts "Issues finished posting."
  end

  def domain
    "https://github.com"
  end

  def url
    OpenStruct.new(login: "#{domain}/login",
                   new_issue: "#{domain}/#{repository}/issues/new",
                   new_label: "#{domain}/#{repository}/labels")
  end

  def env
    @env ||= OpenStruct.new(YAML.load_file("./config/application.yml"))
  end
end

Issuer.new("./test/support/test_stories.yml")
