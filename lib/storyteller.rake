require "capybara/poltergeist"
require 'pry'
require 'launchy'
require 'YAML'
require 'ostruct'

class Issuer
  attr_reader :session
  def initialize
    @session = Capybara::Session.new(:poltergeist)
    run
  end

  def run
    login
  end

  private

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

Issuer.new
