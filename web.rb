# -*- coding: utf-8 -*-

require 'sinatra'
require 'thin'
require 'oauth'
require 'uri'
require 'json'


consumer = OAuth::Consumer.new(ENV["CONSUMER_KEY"], ENV["CONSUMER_SECRET"], :site => "http://www.tumblr.com")
access = OAuth::AccessToken.new(consumer, ENV["ACCESS_TOKEN"], ENV["ACCESS_SECRET"])

get '/' do

  query_string = (params||{}).map{|k,v|
    if k == 'pages'
      URI.encode('offset') + "=" + URI.encode(((v.to_i-1)*20).to_s)
    else
      URI.encode(k.to_s) + "=" + URI.encode(v.to_s)
    end
  }.join("&")

  api = "http://api.tumblr.com/v2/user/dashboard" + (query_string.empty? ? "" : "?#{query_string}")

  response = access.get(api)
  str = "<html><head><title>dsbd</title></head><body>"
  str += "<p>#{api}</p>"
  dsbd = JSON.parse(response.body)
  
  dsbd["response"]["posts"].each{|p|

    if(p['type'] == 'text') 
      str += "<p>#{p['title']}</p>"
      str += "<p>#{p['body']}</p>"
    end

    if(p['type'] == 'quote') 
      str += p["text"]
    end

    if(p['type'] == 'photo')
      img = p['photos'][0]['alt_sizes'][-3]
      str += "<p><a href='#{p['post_url']}'><img src='#{img['url']}'  width='#{img['width']}' height='#{img['height']}'/></a></p>"
      str += "<p>#{p['source']}</p>"
    end
    str += "<p>#{p['caption']}</p>"
    if(p.key?('source_title')) 
      str += "<p>(Source: <a href='#{p['source_url']}'>#{p['source_title']},</a> via <a href='#{p['post_url']}'>#{p['blog_name']}</a>)</p>"
    end 
    str += "<p><a target='_blank' href='/reblog?id=#{p['id']}&reblog_key=#{p['reblog_key']}'>reblog</a></p>"
    str += "<p><a target='_blank' href='/like?id=#{p['id']}&reblog_key=#{p['reblog_key']}'>like</a></p>"
  }
  
  
  page = (!params.key?('pages') or params["pages"] == 1) ? 1 : params["pages"]
  str += "<a href='/?pages=#{page.to_i+1}'>next</a>"
  str += "</body></html>"
  str
end

get '/reblog' do
  access.post("http://api.tumblr.com/v2/blog/malmrashede.tumblr.com/post/reblog", "id"=>params["id"], "reblog_key"=>params["reblog_key"])
  '<html><head><title>rebloged</title></head><body>rebloged</body></html>'
end

get '/like' do
  access.post("http://api.tumblr.com/v2/user/like", "id"=>params["id"], "reblog_key"=>params["reblog_key"])
  '<html><head><title>liked</title></head><body>liked</body></html>'
end
