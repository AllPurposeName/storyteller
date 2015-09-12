require 'faraday'
require 'yaml'
require 'json'

class Storyteller
  attr_reader :env, :file_path
  attr_accessor :repos, :labels

  def initialize(file_path = "./test/support/test_story.yml")
    @file_path = file_path
    connection.basic_auth(env["GITHUB_USERNAME"], env["GITHUB_PASSWORD"])
    run
  end

  def run
    yaml = YAML.load_file(file_path)
    @repos = yaml["repositories"].gsub("#{base_url}/", "").split(", ")
    stories = yaml["stories"]
    stories.each do |s|
      title, body, label = s[1]["title"], s[1]["body"], s[1]["label"]
      add_labels(label)
      post_issue(title, body)
    end
  end

  def post_issue(title, msg)
    labels = @labels || []
    repos.map do |repo|
      connection.post("#{api_url}/repos/#{repo}/issues", {"title": title,
                                                          "body": msg,
                                                            "labels": labels}.to_json)
    end
  end

  def add_labels(labels)
    @labels = [labels].flatten
    @labels.map do |label|
      repos.map do |repo|
        connection.post("#{api_url}/repos/#{repo}/labels", label.to_json)
      end
    end
  end

  def connection
    @connection ||= Faraday.new(url: api_url)
  end

  def base_url
    env["BASE_URL"]
  end

  def api_url
    env["API_URL"]
  end

  def env
    @env ||= YAML.load_file("./config/application.yml")
  end
end

if __FILE__ == $0
  Storyteller.new(ARGV[0])
end
