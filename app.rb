require 'garb'
require 'active_support/time'
require 'sinatra'
require 'sinatra/json'

class PageView
  extend Garb::Model

  metrics :pageviews
end

get '/yesterday-pageviews' do
  Garb::Session.login(ENV['GOOGLE_ACCOUNT'], ENV['GOOGLE_PASSWORD'])

  profile = Garb::Management::Profile.all.detect { |p| p.web_property_id == ENV['WEB_PROPERTY_ID'] }

  now = Time.now
  analytics = profile.page_view(
    start_date: now.yesterday.beginning_of_day,
    end_date:   now.yesterday.end_of_day,
  )

  json :pageviews => analytics.first.pageviews
end
