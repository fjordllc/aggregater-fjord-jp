# encoding: utf-8
require 'garb'
require 'active_support/time'
require 'sinatra'
require 'sinatra/json'
require 'mechanize'
require 'openssl'
require 'certified'

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
    start_date: yesterday.prev_month,
    end_date:   yesterday
  )
  last_month_pageviews = analytics.first.pageviews

  json pageviews: {
    yesterday:  yesterday_pageviews,
    last_week:  last_week_pageviews,
    last_month: last_month_pageviews
  }
end

get '/profit' do
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  result = {}

  a = Mechanize.new
  a.get('https://www.nend.net/admin/login') do |page|
    home_page = page.form_with(name: 'loginform') do |f|
      f['data[User][mail]'] = 'komagata@gmail.com'
      f['data[User][pass]'] = 'komagatafjord'
    end.submit
  end

  a.get('https://www.nend.net/m/report/search/m') do |page|
    result['impression'] = page.search('.impression_graph p').last.content.gsub(/,/, '').to_i
    result['click'] = page.search('.click_graph p').last.content.gsub(/,/, '').to_i
    result['ctr'] = page.search('.ctr_graph p').last.content.gsub(/,/, '').to_f
    result['cpm'] = page.search('.cpm_graph p').last.content.gsub(/[￥,]/, '').to_f
    result['payment'] = page.search('.payment_graph p').last.content.gsub(/[￥,]/, '').to_i
  end

  json result
end
