#!/usr/bin/env ruby
require "open3"
require 'time'

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

S3_BUCKET = ENV["S3_BUCKET"]

def upload_to_s3(project, file)
  s3_path = "#{S3_BUCKET}/etc/project/#{project}/env/#{File.basename(file)}"
  `aws s3 cp #{file} s3://#{s3_path}`

  puts "Uploaded #{file} to #{s3_path}"
end

def download_from_s3(project)
  s3_path = "#{S3_BUCKET}/etc/project/#{project}/env/"
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

=begin
1. add action "check": calc md5 of local and s3 files
=end
def check_env_files
  env_files = get_local_env_files
  env_files.each do |file|
    local_md5 = `md5 -q #{file}`.strip
    s3_cmd_prefix = "aws s3api head-object --bucket #{S3_BUCKET} --key etc/project/#{PROJECT}/env/#{File.basename(file)}"
    s3_md5 = `#{s3_cmd_prefix} --query ETag --output text`.gsub('"', '').strip
    if local_md5 == s3_md5
      puts "\e[32m#{file} :is up to date\e[0m"  # Green text
    else

      local_time = File.mtime(file)
      s3_time = `#{s3_cmd_prefix} --query LastModified --output text`.strip
      if local_time > Time.parse(s3_time)
        puts "\e[33m#{file} :is newer\e[0m"  # Yellow text
      else
        puts "\e[31m#{file} :is outdated\e[0m"  # Red text
      end
    end
  end
end


action = ARGV[0]
puts "ARGV #{ARGV}"
case action
when "upload"
  upload_env_files
when "download"
  download_env_files
when "check"
  check_env_files
else
  puts "Usage: env-sync.rb [upload|download|check]"
  exit 1
end



