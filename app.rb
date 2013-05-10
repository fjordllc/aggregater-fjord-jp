# encoding: utf-8
require 'garb'
require 'active_support/time'
require 'sinatra'
require 'sinatra/json'
require 'rexml/document'
require 'mechanize'
require 'openssl'
require 'certified'
require 'mixpanel_client'

class PageView
  extend Garb::Model
  metrics :pageviews
end

get '/' do
  Garb::Session.login('office@fjord.jp', 'officefjord')
  profile = Garb::Management::Profile.all.detect { |p| p.web_property_id == 'UA-2927688-13' }

  yesterday = Time.now.yesterday
  analytics = profile.page_view(
    start_date: yesterday.beginning_of_day,
    end_date:   yesterday.end_of_day
  )
  yesterday_pageviews = analytics.first.pageviews

  analytics = profile.page_view(
    start_date: yesterday.prev_week,
    end_date:   yesterday
  )
  last_week_pageviews = analytics.first.pageviews

  analytics = profile.page_view(
    start_date: yesterday.prev_week.prev_week,
    end_date:   yesterday.prev_week
  )
  two_weeks_ago_pageviews = analytics.first.pageviews

  growth_per_week = (last_week_pageviews.to_f / two_weeks_ago_pageviews.to_f * 100.0 - 100.0).round(2)

  analytics = profile.page_view(
    start_date: yesterday.prev_month,
    end_date:   yesterday
  )
  last_month_pageviews = analytics.first.pageviews

  json pageviews: {
    yesterday:  yesterday_pageviews,
    last_week:  last_week_pageviews,
    last_month: last_month_pageviews,
    two_weeks_ago_pageviews: two_weeks_ago_pageviews,
    growth_per_week: growth_per_week
  }
end

get '/profit' do
  result = {}

  a = Mechanize.new
  a.get('https://www.nend.net/admin/login') do |page|
    home_page = page.form_with(name: 'loginform') do |f|
      f['data[User][mail]'] = 'komagata@gmail.com'
      f['data[User][pass]'] = 'komagatafjord'
    end.submit
  end

  yesterday = Time.now.yesterday

  range = CGI.escape(yesterday.prev_month.strftime('%Y/%m/%d')) +
          '+-+' +
          CGI.escape(yesterday.strftime('%Y/%m/%d'))

  a.get("https://www.nend.net/m/report/search/m?search_date=#{range}") do |page|
    result['impression'] = page.search('.impression_graph p').last.content.gsub(/,/, '').to_i
    result['click'] = page.search('.click_graph p').last.content.gsub(/,/, '').to_i
    result['ctr'] = page.search('.ctr_graph p').last.content.gsub(/,/, '').to_f
    result['cpm'] = page.search('.cpm_graph p').last.content.gsub(/[￥,]/, '').to_f
    result['payment'] = page.search('.payment_graph p').last.content.gsub(/[￥,]/, '').to_i
  end

  # last week
  range = CGI.escape(yesterday.prev_week.strftime('%Y/%m/%d')) +
          '+-+' +
          CGI.escape(yesterday.strftime('%Y/%m/%d'))

  a.get("https://www.nend.net/m/report/search/m?search_date=#{range}") do |page|
    result['last_week_payment'] = page.search('.payment_graph p').last.content.gsub(/[￥,]/, '').to_i
  end

  # two weeks ago
  range = CGI.escape(yesterday.prev_week.prev_week.strftime('%Y/%m/%d')) +
          '+-+' +
          CGI.escape(yesterday.prev_week.strftime('%Y/%m/%d'))

  a.get("https://www.nend.net/m/report/search/m?search_date=#{range}") do |page|
    result['two_weeks_ago_payment'] = page.search('.payment_graph p').last.content.gsub(/[￥,]/, '').to_i
  end

  result['growth_per_week'] = (result['last_week_payment'].to_f / result['two_weeks_ago_payment'].to_f * 100.0 - 100.0).round(2)

  json result
end

get '/share' do
  client = Mixpanel::Client.new(
    api_key: '222ed9530f1b66cee8811f32551f5687',
    api_secret: '6e78d6fb8c5bc79ca04e05388a8f654e'
  )

  data = client.request('events', {
    event:     '["Share","Signed up","Posted story"]',
    type:      'general',
    unit:      'day',
    interval:   30,
  })

  result = []
  datapoints = []

  data["data"]["series"].each do |date|
    datapoints << [data["data"]["values"]["Share"][date], Time.parse(date).to_i]
  end

  result << {'target' => 'share', 'datapoints' => datapoints}

  json result
end

get '/value' do
  json "value" => "8", "label" => "aaaaaaaaaaaa"
end
