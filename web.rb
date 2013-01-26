# -*- coding: utf-8 -*-

require 'sinatra'
require 'thin'
require 'oauth'
require 'uri'
require 'json'
require 'erb'

enable :sessions

use Rack::Auth::Basic do |username, password|
  username == ENV['BASIC_AUTH_USERNAME'] && password == ENV['BASIC_AUTH_PASSWORD']
end

consumer = OAuth::Consumer.new(ENV["CONSUMER_KEY"], ENV["CONSUMER_SECRET"], :site => "http://www.tumblr.com")
access = OAuth::AccessToken.new(consumer, ENV["ACCESS_TOKEN"], ENV["ACCESS_SECRET"])


get '/' do
  if !params.key?('pages')
      session['reblog'] = 0
  end

  query_string = (params||{}).map{|k,v|
    if k == 'pages'
      offset = (v.to_i-1)*20 + session['reblog'].to_i
      URI.encode('offset') + "=" + URI.encode(offset.to_s)
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
  EM::defer do
    access.post("http://api.tumblr.com/v2/blog/malmrashede.tumblr.com/post/reblog", "id"=>params["id"], "reblog_key"=>params["reblog_key"])
    session["reblog"] += 1
  end
  '<html><head><title>rebloged</title></head><body>rebloged</body></html>'
end

get '/like' do
  EM::defer do
  access.post("http://api.tumblr.com/v2/user/like", "id"=>params["id"], "reblog_key"=>params["reblog_key"])
  end
  '<html><head><title>liked</title></head><body>liked</body></html>'
end

helpers do
  include Rack::Utils; alias_method :h, :escape_html
end

__END__

@@ index
<!DOCTYPE html>
<html lang="ja">
  <head>
    <title>dsbd</title>
    <link rel="stylesheet" type="text/css" href="./dsbd.css" />
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
  </head>
  <body>
    <h1><a href="http://guarded-caverns-4389.herokuapp.com/">dsbd <%= session["reblog"] %></a></h1>
    <div id="content">
    <div class="autopagerize_page_element">
    <% @dsbd["response"]["posts"].each do |p| %>
      <div class="post xfolkentry taggedlink">
        <div class="<%= h(p['type']) %>">
        <% if(p['type'] == 'text') %>
          <p><%= p['title'] %></p>
          <p><%= p['body'] %></p>
        <% end %>

        <% if(p['type'] == 'quote') %>
          <div class="quote_text">
            <span class="short">
              <%= p["text"] %>
            </span>
          </div>
        <% end %>

        <% if(p['type'] == 'photo') %>
          <% img = p['photos'][0]['alt_sizes'][2] %>
    <p><a href='javascript:void(0);' onclick="$.get('http://<%= h ENV['HOST_NAME'] %>/reblog?id=<%= h p['id'] %>&reblog_key=<%= h p['reblog_key'] %>');"><img src='<%= img['url'] %>'/></a></p>
      <p><%= p['source'] %></p>
        <% end %>
        <div class="caption">
            <p><%= p['caption'] %></p>
            <% if(p.key?('source_title')) %>
              <p>(Source: <a href='<%= p['source_url'] %>'><%= p['source_title'] %>,</a> via <a href='<%= p['post_url'] %>'><%= p['blog_name'] %></a>)</p>
            <% end %>
        </div>
      <p class="reblog"><a href='javascript:void(0);' onclick="$.get('http://<%= h ENV['HOST_NAME'] %>/reblog?id=<%= h p['id'] %>&reblog_key=<%= h p['reblog_key'] %>');">Reblog</a></p>
      <p class="like"><a href='javascript:void(0);' onclick="$.get('http://<%= h ENV['HOST_NAME'] %>/like?id=<%= h p['id'] %>&reblog_key=<%= h p['reblog_key'] %>');">&hearts;</a></p>
        </div>
      </div>
  <% end %>
    </div>
    <div class="autopagerize_insert_before"></div>
    <div id="footer">
      <a rel="next" href='/?pages=<%= h (@page.to_i+1) %>'>Next&gt;&gt;</a>
      <p><%= h @api %></p>
    </div>
  </div>
  </body>
</html>

