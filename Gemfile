source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.4'
gem 'mysql2', '0.4.9'
gem 'oj', '3.3.8'
gem 'rake', '12.3.0'

gem 'dalli', '2.7.6'

gem 'sanitize', '4.5.0'
gem 'exception_notification', '4.2.2'

gem 'aws-sdk-kms', '1.4.0'
gem 'aws-sdk-s3', '1.8.0'

gem 'sidekiq', '5.0.5'
gem 'redis-namespace', '1.6.0'

gem 'listen', '>= 3.0.5', '< 3.2'

gem 'http', '3.0.0'

gem 'jwt', '2.1.0'

# gem 'ost-sdk-ruby', path: '/Users/PpuneetKhushwani/work/SimpleToken/ost-sdk-ruby'
gem 'ost-sdk-ruby', git: "https://github.com/OpenSTFoundation/ost-sdk-ruby.git", :branch => "v1_api_changes"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'
group :development, :test do
  # Use Puma as the app server
  gem 'puma', '~> 3.7'

  gem 'pry'

  gem 'letter_opener'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # gem 'listen', '>= 3.0.5', '< 3.2'
  # # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  # gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
