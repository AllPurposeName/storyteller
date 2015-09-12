Dir.glob('./*.rake').each { |r| load r }
task default: %w[storyteller]

task :storyteller, :file_path do |t, file_path|
  path = file_path[:file_path] || ARGV[1]
  if TaskHelper.exist?(path)
    ruby "./lib/storyteller.rb ./stories/#{path}.yml"
  else
    abort "Story #{path + ' ' if path}not found.\nPlease specify the story to use"
  end
end

task :test do
  ruby "./test/storyteller_test.rb"
end

class TaskHelper
  def self.exist?(file_path)
    File.exist?("./stories/#{file_path}}.yml") ||
    Dir.new("stories/").include?("#{file_path}.yml")
  end
end
