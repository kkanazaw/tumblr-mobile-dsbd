# -*- coding: utf-8 -*-

require 'sinatra'
require 'thin'
require 'oauth'
require 'uri'
require 'json'
require 'erb'

use Rack::Auth::Basic do |username, password|
  username == ENV['BASIC_AUTH_USERNAME'] && password == ENV['BASIC_AUTH_PASSWORD']
end

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

  @api = "http://api.tumblr.com/v2/user/dashboard" + (query_string.empty? ? "" : "?#{query_string}")
  response = access.get(@api)
  @dsbd = JSON.parse(response.body)
  @page = (!params.key?('pages') or params["pages"] == 1) ? 1 : params["pages"]
  erb :index
end

get '/reblog' do
  access.post("http://api.tumblr.com/v2/blog/malmrashede.tumblr.com/post/reblog", "id"=>params["id"], "reblog_key"=>params["reblog_key"])
  '<html><head><title>rebloged</title></head><body>rebloged</body></html>'
end

get '/like' do
  access.post("http://api.tumblr.com/v2/user/like", "id"=>params["id"], "reblog_key"=>params["reblog_key"])
  '<html><head><title>liked</title></head><body>liked</body></html>'
end

helpers do
  include Rack::Utils; alias_method :h, :escape_html
end

__END__

@@ index
<html>
  <head>
  <title>dsbd</title>
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
</head>
  <body>
  <p><%= h @api %></p>
  <% @dsbd["response"]["posts"].each do |p| %>
    <% if(p['type'] == 'text') %>
      <p><%= p['title'] %></p>
      <p><%= p['body'] %></p>
    <% end %>

    <% if(p['type'] == 'quote') %>
      <%= p["text"] %>
    <% end %>

    <% if(p['type'] == 'photo') %>
      <% img = p['photos'][0]['alt_sizes'][-3] %>
<p><a href='<%= p['post_url'] %>'><img src='<%= img['url'] %>'  width='<%= img['width'] %>' height='<%= img['height'] %>'/></a></p>
      <p><%= p['source'] %></p>
    <% end %>
    <p><%= p['caption'] %></p>
    <% if(p.key?('source_title')) %>
      <p>(Source: <a href='<%= p['source_url'] %>'><%= p['source_title'] %>,</a> via <a href='<%= p['post_url'] %>'><%= p['blog_name'] %></a>)</p>
    <% end %>
    <p><a href='javascript:void(0);' onclick="$.get('http://<%= h ENV['BASIC_AUTH_USERNAME'] %>:<%= h ENV['BASIC_AUTH_PASSWORD'] %>@<%= h ENV['HOST_NAME'] %>/reblog?id=<%= h p['id'] %>&reblog_key=<%= h p['reblog_key'] %>');">reblog</a></p>
    <p><a href='javascript:void(0);' onclick="$.get('http://<%= h ENV['BASIC_AUTH_USERNAME'] %>:<%= h ENV['BASIC_AUTH_PASSWORD'] %>@<%= h ENV['HOST_NAME'] %>/like?id=<%= h p['id'] %>&reblog_key=<%= h p['reblog_key'] %>');">like</a></p>
  <% end %>
  <a rel='next' href='/?pages=<%= h (@page.to_i+1) %>'>next</a>
  </body>
</html>

