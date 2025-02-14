def upload_to_s3(file, s3_path)
  puts "Uploading: #{file} => #{s3_path}"
  # s3_path = "#{S3_BUCKET}/etc/project/#{project}/env/#{File.basename(file)}"
  if system_echo("aws s3 cp #{file} s3://#{s3_path}")
    # puts "Uploaded #{file} to #{s3_path}"
  else
    puts "Failed to upload #{file} to #{s3_path}: #{$?}"
    exit 1
  end
end


def download_from_s3(s3_path, file)
  puts "Downloading: from #{s3_path} => #{file}"
  if system_echo("aws s3 cp s3://#{s3_path} #{file} --recursive")
    # puts "Downloaded from #{s3_path}"
  else
    puts "Failed to download from #{s3_path}: #{$?}"
    exit 1
  end
end
