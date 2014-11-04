require 'rubygems'
require 'bundler/setup'
require 'digest/md5'   
require "mongoid"
require "json"
require "sinatra/base"
require "open-uri"
require 'celluloid/autostart'

$appkey = "af999dd030914b02"
$app_secret = "53fbcaa8b938f3f85979967d3fca0b4c"



Mongoid.load!("./db.yml", :development)


class D
	include Mongoid::Document
	include Mongoid::Timestamps
	field :play
	field :comment
	field :coin
	field :title
	field :fav
	field :avno
end

class Page
	include Celluloid
    def self.get_sign key, pa
        m_data = []
        pa = pa.sort
        pa.each do |k, v|
            m_data << (k.to_s + '=' + URI.escape(v.to_s))
        end
        m_sign = m_data.join('&')
        {'sign' => Digest::MD5.hexdigest(m_sign + key).downcase, 'params' => m_sign}
    end
	def fetch av
		key_pair = Page.get_sign $app_secret , {
			:appkey => $appkey,
			:ts => Time.new.to_i,
			:id => av,
			:page => 1,
			:fav => 1
		}
		url = "http://api.bilibili.cn/view?" + "sign=#{key_pair["sign"]}&" + key_pair["params"]
		j = JSON.parse(open(url).read)
		@d = D.new(
			play: j["play"].to_i,
			comment: j["review"].to_i,
			coin: j["coins"].to_i,
			title: j["video_review"].to_i,
			fav: j["favorites"].to_i,
			avno: $avno
			)
		begin
			@d.save!
		rescue 
			@d.save
		end
		puts "Fetched..." + @d.created_at.to_s
	end
end

$time = 300
threads = []

class WS < Sinatra::Base
	get "/" do 
		t = []
		D.where(avno: $avno).each do |d|
			t<<"<tr><td>#{d.created_at.to_s}</td><td>#{d.play.to_s}</td><td>#{d.comment.to_s}</td><td>#{d.coin.to_s}</td><td>#{d.title.to_s}</td><td>#{d.fav.to_s}</td></tr>"
		end
		a = "<tr><td>时间</td><td>播放数</td><td>评论数</td><td>硬币数</td><td>弹幕数</td><td>收藏数</td></tr>"
		"<table>#{a + t.join}</table>"
	end
	get "/chart" do 
		@play = []
		@comment = []
		@coin = []
		@title = []
		@fav = []
		@soc = []
		D.where(avno: $avno).each do |d|
			@play<<{:x => d.created_at.strftime("%m.%d %H:%M"), :y => d.play.to_i}
			@comment<<{:x => d.created_at.strftime("%m.%d %H:%M"), :y => d.comment.to_i}
			@coin<<{:x => d.created_at.strftime("%m.%d %H:%M"), :y => d.coin.to_i}
			@title<<{:x => d.created_at.strftime("%m.%d %H:%M"), :y => d.title.to_i}
			@fav<<{:x => d.created_at.strftime("%m.%d %H:%M"), :y => d.fav.to_i}
		end
		@play = @play.to_json
		@comment = @comment.to_json
		@coin = @coin.to_json
		@title = @title.to_json
		@fav = @fav.to_json
		erb :chart
	end
end


