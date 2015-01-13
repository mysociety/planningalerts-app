require 'fileutils'

# namespace :ts do
#   # Make Thinking Sphinx play nicely with Foreman
#   desc "Run searchd in the foreground"
#   task :run_in_foreground => :environment do
#     ts = ThinkingSphinx::Configuration.instance
#     exec "#{ts.bin_path}#{ts.searchd_binary_name} --pidfile --config #{ts.config_file} --nodetach"
#   end
# end

# the ts namespaced tasks are aliases of the thinking_sphinx tasks
# so fixing these should fix them all

before "thinking_sphinx:configure" do
  backup_current_config_files(ThinkingSphinx::Configuration.instance)
end

after "thinking_sphinx:configure" do
  fix_config_file(ThinkingSphinx::Configuration.instance)
end

after "thinking_sphinx:index" do
  unless ENV["INDEX_ONLY"] == "true"
    fix_config_file(ThinkingSphinx::Configuration.instance)
  end
end

before "thinking_sphinx:rebuild" do
  config = ThinkingSphinx::Configuration.instance
  config_file = config.config_file
  searchd_file = config.config_file.gsub("sphinx", "searchd")
  Rake::Task["thinking_sphinx:configure"].invoke
  if !file_changed?(config_file) and !file_changed?(searchd_file)
    abort("Config files haven't changed, searchd not restarted")
  end
end


# split the generated config file into a shared searchd file
# and a per-app conf file, discarding the indexer portion
def fix_config_file(config)
  # open the generated config file
  config_file = File.open(config.config_file)
  searchd_file = config.config_file.gsub("sphinx", "searchd")
  lines = config_file.readlines

  # we know what the generated file looks like
  # and that we're unlikely to upgrade the gem
  # so we can (relatively) safely make some assumptions

  # discard the empty indexer block
  lines = lines[5..-1]

  # copy the searchd block into an array
  searchd_lines = []
  current_line = 0
  while lines[current_line].strip != "}"
    searchd_lines << lines[current_line]
    current_line += 1
  end
  searchd_lines << "}\n"
  current_line += 1

  # remove the searchd block from the main array
  # and what's left should be the app-specific config
  lines = lines[current_line..-1]

  # write the searchd conf to its own file
  File.open(searchd_file, "w") { |file| file.write (searchd_lines.join(""))}

  # overwrite the generated config with our simplified version
  File.open(config_file, "w") { |file| file.write (lines.join(""))}
end

def backup_current_config_files(config)
  searchd_file = config.config_file.gsub("sphinx", "searchd")

  if File.exists?(searchd_file)
    FileUtils.mv(searchd_file, "#{searchd_file}.bak")
  end

  if File.exists?(config.config_file)
    FileUtils.cp(config.config_file, "#{config.config_file}.bak")
  end
end

# compares the contents of the current config file
# with the contents of the corresponding .bak file (if present)
def file_changed?(file_path)
  backup_file = "#{file_path}.bak"
  return true unless File.exists?(backup_file)
  current_contents = File.open(file_path).read
  old_contents = File.open(backup_file).read
  current_contents != old_contents
end
