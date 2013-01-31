require 'garb'
require 'active_support/time'
require 'sinatra'
require 'sinatra/json'

class PageView
  extend Garb::Model
  metrics :pageviews
end

configure do
  Garb::Session.login(ENV['GOOGLE_ACCOUNT'], ENV['GOOGLE_PASSWORD'])
  profile = Garb::Management::Profile.all.detect { |p| p.web_property_id == 'UA-2927688-13' }
  set :profile, profile
end

get '/' do
  yesterday = Time.now.yesterday
  analytics = settings.profile.page_view(
    start_date: yesterday.beginning_of_day,
    end_date:   yesterday.end_of_day,
  )
  yesterday_pageviews = analytics.first.pageviews

  analytics = settings.profile.page_view(
    start_date: yesterday.prev_week,
    end_date:   yesterday,
  )
  last_week_pageviews = analytics.first.pageviews

  analytics = settings.profile.page_view(
    start_date: yesterday.prev_month,
    end_date:   yesterday,
  )
  last_month_pageviews = analytics.first.pageviews

  json pageviews: {
    yesterday: yesterday_pageviews,
    last_week: last_week_pageviews,
    last_month: last_month_pageviews
  }
end
