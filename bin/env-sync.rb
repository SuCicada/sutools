#!/usr/bin/env ruby
require "open3"
require 'time'
require 'optparse'
require_relative '../utils/git'
require_relative '../utils/file'
require 'dotenv'

# 1. get project name
# 1. get env file from local dir
# 2. upload to sucicada/etc/project/{project}/env/
# 3. download from sucicada/etc/project/{project}/env/

S3_BUCKET = ENV["S3_BUCKET"]
# $PROJECT = ""
HOME = ENV["HOME"]

# action = ARGV[0]
# STDIN.flush
# =========================================================================================
# =============================== argv ====================================================
puts "ARGV #{ARGV}"
options = {
  yes: false, # 默认情况下，不自动回答 yes
  global: false,
  action: nil # 将要执行的命令（upload、download、check）
}

# 定义命令行解析器
OptionParser.new do |opts|
  opts.banner = "Usage: env-sync.rb [upload|download|check]"
  # 定义 -y 或 --yes 选项
  opts.on("-y", "--yes", "Answer yes to all questions") do
    options[:yes] = true
  end
  opts.on("-g", "--global", "upload/download global files?") do
    options[:global] = true
  end
end.parse!

# 提取命令
options[:action] = ARGV.shift
ARGV.clear # Ruby 在处理命令行参数时，将 ARGV 中的内容解释为文件输入，因为在调用 gets 时，没有指定标准输入。
OPTIONS = options
# =========================================================================================

def system_echo(cmd)
  puts cmd
  system(cmd)
end

# def get_local_env_files
#   Dir.glob([".env", ".env.*"]) # Match only .env and .env.*
# end

def get_env_files(dir = ".")
  Dir.chdir(dir) do
    Dir.glob(%w[.env .env.*]) # Match only .env and .env.*
  end
end

def upload_env_files
  if OPTIONS[:global]
    upload_files("#{HOME}/etc/env", "#{S3_BUCKET}/etc")
  else
    puts "project name: #{PROJECT}"
    upload_files(".", "#{S3_BUCKET}/etc/project/#{PROJECT}")
  end
end

def upload_files(env_file_dir, s3_dir)
  env_files = get_env_files(env_file_dir)
  puts "env files: #{env_files}"
  env_files.each do |file|
    s3_path = "#{s3_dir}/env/#{File.basename(file)}"
    local_file = "#{env_file_dir}/#{file}"
    upload_to_s3(local_file, s3_path)
  end

  # sync other files
  get_env_sync_files.each do |file|
    s3_path = "#{s3_dir}/#{file}"
    upload_to_s3(file, s3_path)
  end
end

def get_env_sync_files(env_file = ".env")
  if File.exist?(env_file)
    Dotenv.load(env_file)
    env_sync_files = ENV["env_sync_files"]
    unless env_sync_files.nil?
      env_sync_files = env_sync_files.strip
      puts "env_sync_files: #{env_sync_files}"
      return env_sync_files.split("\n").map(&:strip)
    end
  end
  []
end

def download_env_files
  # s3_path = "#{S3_BUCKET}/etc/project/#{PROJECT}/env/"
  # download_from_s3(s3_path, '.')
  #
  # get_env_sync_files.each do |file|
  #   s3_path = "#{S3_BUCKET}/etc/project/#{PROJECT}/#{file}"
  #   download_from_s3(s3_path, '.')
  # end
  if OPTIONS[:global]
    download_files("#{HOME}/etc/env", "#{S3_BUCKET}/etc")
  else
    download_files(".", "#{S3_BUCKET}/etc/project/#{PROJECT}")
  end
end

def download_files(local_dir, s3_dir)
  s3_env_dir = "#{s3_dir}/env/"
  download_from_s3(s3_env_dir, local_dir)

  env_file = File.join(local_dir, ".env")
  get_env_sync_files(env_file).each do |file|
    s3_path = "#{s3_dir}/#{file}"
    download_from_s3(s3_path, '.')
  end
end

=begin
1. add action "check": calc md5 of local and s3 files
=end
def check_env_files
  env_files = get_local_env_files.map { |file| { file: file, path: "etc/project/#{PROJECT}/env/#{File.basename(file)}" } }
  env_sync_files = get_env_sync_files.map { |file| { file: file, path: "etc/project/#{PROJECT}/#{file}" } }
  files = env_files + env_sync_files
  files.each do |map|
    file = map[:file]
    path = map[:path]
    local_md5 = `md5 -q #{file}`.strip
    s3_cmd_prefix = "aws s3api head-object --bucket #{S3_BUCKET} --key #{path}"

    s3_md5, status = Open3.capture2e("#{s3_cmd_prefix} --query ETag --output text")
    if status.success?
      s3_md5 = s3_md5.gsub('"', '').strip
    else
      puts "\e[31m#{file} => Failed to get S3 ETag: #{status}\e[0m"
      next
    end

    if local_md5 == s3_md5
      puts "\e[32m#{file} => is up to date\e[0m" # Green text
    else

      local_time = File.mtime(file)
      s3_time = `#{s3_cmd_prefix} --query LastModified --output text`.strip
      if local_time > Time.parse(s3_time)
        puts "\e[33m#{file} => is newer\e[0m" # Yellow text
      else
        puts "\e[31m#{file} => is outdated\e[0m" # Red text
      end
    end
  end
end

unless options[:global]
  PROJECT = get_repo_name
  if PROJECT.empty?
    puts "No project found"
    exit 1
  end
end

case options[:action]
when "upload"
  upload_env_files

when "download"
  # check_env_files
  if options[:yes]
    download_env_files
  else
    puts "Are you sure to download env files? (y/n)"
    input = gets.chomp
    puts "input: #{input}"
    if input.downcase == "y"
      download_env_files
    end
  end
when "check"
  check_env_files
else
  puts "Usage: env-sync.rb [upload|download|check]
  -y, --yes    # answer yes to all questions
  # .env
  env_sync_files=\"xxxxxx\"  # allow multi line files
"
  exit 1
end



