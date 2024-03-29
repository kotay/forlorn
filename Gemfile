source 'https://rubygems.org'

gem 'rails'
gem 'mysql2'
gem 'devise'
gem 'rails_admin'
gem 'kaminari'
gem 'bootstrap-kaminari-views'
gem "rufus-scheduler", :require => false
gem 'json', '>= 1.7.7'
gem 'jsonpath'
gem 'twilio-ruby'

gem 'delayed_job', :git => 'https://github.com/wok/delayed_job' # Until the YAML issues are fixed in master.
gem 'delayed_job_active_record', "~> 0.3.3" # newer was giving a strange MySQL error
gem "daemons"
gem "delayed_job_web"

gem 'foreman'
gem 'dotenv-rails', :groups => [:development, :test]

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'select2-rails'
  gem 'jquery-rails'
end

gem 'geokit-rails3'
gem 'kramdown'
gem "typhoeus"
gem 'nokogiri'
gem 'wunderground'

gem "twitter"
gem 'twitter-stream', '>=0.1.16'
gem 'em-http-request'

platforms :ruby_18 do
  gem 'system_timer'
  gem 'fastercsv'
end

group :development do
  gem 'pry'
  gem 'pry-remote'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'rspec'
  gem 'shoulda-matchers'
  gem 'rr'
  gem 'webmock', :require => false
  gem 'rake'
end

gem 'sirportly'
