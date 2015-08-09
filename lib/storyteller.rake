require "capybara/poltergeist"
require 'pry'
require 'launchy'
require 'YAML'
require 'ostruct'

class Issuer
  attr_reader :session
  def initialize(stories_path)
    @session = Capybara::Session.new(:poltergeist)
    @stories = parse_stories(stories_path)
    run
  end

  def run
    login
  end

  private

  def parse_stories(file_path)
    YAML.load_file(file_path)
  end

  def login
    session.visit(url.login)
    session.fill_in("login",    with: (env.GITHUB_USERNAME))
    session.fill_in("password", with: (env.GITHUB_PASSWORD))
    session.click_button("Sign in")
  end

  def domain
    "https://github.com"
  end

  def url
    OpenStruct.new(login: "#{domain}/login")
  end

  def env
    @env ||= OpenStruct.new(YAML.load_file("./config/application.yml"))
  end
end

Issuer.new("./test/support/test_stories.yml")
