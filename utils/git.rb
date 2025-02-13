def get_repo_name
  repo_url = `git config --get remote.origin.url`
  if repo_url.empty?
    puts "No remote origin found"
    exit 1
  end
  repo_name = repo_url.split("/").last.gsub(".git", "").strip
  repo_name
end