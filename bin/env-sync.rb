#!/usr/bin/env ruby
require "open3"

# 1. get project name
# 1. get env file from local dir
# 2. upload to sucicada/etc/project/{project}/env/
# 3. download from sucicada/etc/project/{project}/env/
def get_repo_name
  repo_url = `git config --get remote.origin.url`
  if repo_url.empty?
    puts "No remote origin found"
    exit 1
  end
  repo_name = repo_url.split("/").last.gsub(".git", "").strip
  repo_name
end

def upload_to_s3(project, file)
  s3_path = "sucicada/etc/project/#{project}/env/#{File.basename(file)}"
  `aws s3 cp #{file} s3://#{s3_path}`

  puts "Uploaded #{file} to #{s3_path}"
end

def download_from_s3(project)
  s3_path = "sucicada/etc/project/#{project}/env/"
  `aws s3 cp s3://#{s3_path} . --recursive`
  puts "Download   to #{s3_path}"
end

def get_local_env_files
  Dir.glob(".env.*")
end

PROJECT = get_repo_name

def upload_env_files
  env_files = get_local_env_files
  puts "project name: #{PROJECT}"
  puts "env files: #{env_files}"
  env_files.each do |file|
    upload_to_s3(PROJECT, file)
  end

  # env_files.each do |file|
  #   download_from_s3(project, File.basename(file))
  # end
end

def download_env_files
  download_from_s3(PROJECT)
end

if PROJECT.empty?
  puts "No project found"
  exit 1
end

action = ARGV[0]
puts "ARGV #{ARGV}"
case action
when "upload"
  upload_env_files
when "download"
  download_env_files
else
  puts "Usage: env-sync.rb [upload|download]"
  exit 1
end



=begin
todo:
1. add action "check": calc md5 of local and s3 files
=end