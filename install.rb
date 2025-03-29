# install this project:
# 1. clone from github at $home/.sutools
# 1. check current shell, then add "source  $home/.sutools/profile" if not exist

require "fileutils"

HOME_DIR = ENV["HOME"]
PROJECT_DIR = File.join(HOME_DIR, ".sutools")

def clone_project
  repo_url = "https://github.com/SuCicada/sutools.git"

  unless Dir.exist?(PROJECT_DIR)
    system("git clone #{repo_url} #{PROJECT_DIR}")
    puts "Cloned project to #{PROJECT_DIR}"
  else
    puts "Project already exists at #{PROJECT_DIR}"
  end
end

def get_profile
  shell_name =  ENV["SHELL"]
  if shell_name.nil?
    shell_name = $0
  end
  profile_file =
    case shell_name
    when /bash/ then File.join(HOME_DIR, ".bashrc")
    when /zsh/ then File.join(HOME_DIR, ".zshrc")
    else
      puts "Unsupported shell"
      File.join(HOME_DIR, ".bashrc")
    end
  profile_file
end

def update_shell_profile(profile_file)
  puts "Profile file: #{profile_file}"
  source_line = "source #{File.join(PROJECT_DIR, "profile")}"
  unless File.exist?(profile_file)
    `touch #{profile_file}`
    puts "Created #{profile_file}"
  end
  unless File.readlines(profile_file).grep(/#{Regexp.escape(source_line)}/).any?
    File.open(profile_file, "a") do |file|
      file.puts "\n"
      file.puts source_line
    end
    puts "Updated #{profile_file} with source line"
  else
    puts "Source line already exists in #{profile_file}"
  end
end

def install_lib()
  `#{PROJECT_DIR}/bin/sutools update`
  `gem install bundler`
  `cd #{PROJECT_DIR} && bundle install`
end

clone_project
update_shell_profile(get_profile)
install_lib()
# update_shell_profile(File.join(HOME_DIR, ".profile"))
# 