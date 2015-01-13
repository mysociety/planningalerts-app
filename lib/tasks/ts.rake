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

# replace start task with a custom version to launch searchd
# using the standard config file rather than the local path
before "thinking_sphinx:start" do
  start_process
  # don't let the original rake task run
  abort
end

# replace stop task with a custom version that doesn't have a
# dependence on the local config file path
before "thinking_sphinx:stop" do
  stop_process
  # don't let the original rake task run
  abort
end

# replace restart task with a custom version otherwise
# the abort statements from the overrides will make a mess
before "thinking_sphinx:restart" do
  stop_process
  start_process
  abort
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

def start_process
  config = ThinkingSphinx::Configuration.instance
  raise RuntimeError, "searchd is already running." if sphinx_running?

  Dir["#{config.searchd_file_path}/*.spl"].each { |file| File.delete(file) }

  cmd = "#{config.bin_path}#{config.searchd_binary_name} --pidfile"
  if ENV["NODETACH"] == "true"
    cmd << " --nodetach" if options[:nodetach]
  end

  `#{cmd}`

  sleep(1)

  if sphinx_running?
    puts "Started successfully (pid #{ThinkingSphinx.sphinx_pid})."
  else
    puts "Failed to start searchd daemon. Check #{config.searchd_log_file}"
    puts "Be sure to run thinking_sphinx:index before thinking_sphinx:start"
  end
end

def stop_process
  unless sphinx_running?
    puts "searchd is not running"
  else
    config = ThinkingSphinx::Configuration.instance
    pid  = ThinkingSphinx.sphinx_pid

    stop_flag = 'stopwait'
    stop_flag = 'stop' if Riddle.loaded_version.split('.').first == '0'
    cmd = %(#{config.bin_path}#{config.searchd_binary_name} --pidfile --#{stop_flag})

    `#{cmd}`

    # use abort rather than puts so that the original rake task isn't run
    if sphinx_running?
      puts "Failed to stop search daemon (pid #{pid})."
    else
      puts "Stopped search daemon (pid #{pid})."
    end
  end
end

def sphinx_running?
  pid = ThinkingSphinx.sphinx_pid
  !!pid && !!Process.kill(0, pid.to_i)
rescue
  false
end
