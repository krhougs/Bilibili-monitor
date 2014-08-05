require 'rubygems'
require 'bundler/setup'
require 'digest/md5'   
require "mongoid"
require "json"
require "sinatra/base"
require "open-uri"

$appkey = "af999dd030914b02"
$app_secret = "53fbcaa8b938f3f85979967d3fca0b4c"

puts "输入av号："
$avno =( gets ).to_i
puts "你的av号是：" + $avno.to_s + "如果输错了请按Ctrl+C退出程序"

puts "输入抓取时间间隔(ms)："
$time =( gets ).to_i
puts "你的抓取时间间隔：" + $time.to_s + "如果输错了请按Ctrl+C退出程序"
puts "开始工作了喵"

Mongoid.load!("./db.yml", :development)


class D
	include Mongoid::Document
	include Mongoid::Timestamps
	field :play
	field :comment
	field :coin
	field :title
	field :fav
	field :soc
	field :avno
end

class Page
    def self.get_sign key, pa
        m_data = []
        pa = pa.sort
        pa.each do |k, v|
            m_data << (k.to_s + '=' + URI.escape(v.to_s))
        end
        m_sign = m_data.join('&')
        {'sign' => Digest::MD5.hexdigest(m_sign + key).downcase, 'params' => m_sign}
    end
	def self.fetch av
		key_pair = self.get_sign $app_secret , {
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
			soc: j["credit"].to_i,
			avno: $avno
			)
		begin
			@d.save!
		rescue 
			@d.save
		end
		puts "Fetched..." + @d.created_at
	end
end

time = 300
threads = []

class WS < Sinatra::Base
	get "/" do 
		t = []
		D.where(avno: $avno).each do |d|
			t<<"<tr><td>#{d.created_at.to_s}</td><td>#{d.play.to_s}</td><td>#{d.comment.to_s}</td><td>#{d.coin.to_s}</td><td>#{d.title.to_s}</td><td>#{d.fav.to_s}</td><td>#{d.soc.to_s}</td></tr>"
		end
		a = "<tr><td>时间</td><td>播放数</td><td>评论数</td><td>硬币数</td><td>弹幕数</td><td>收藏数</td><td>积分数</td></tr>"
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
			@soc<<{:x => d.created_at.strftime("%m.%d %H:%M"), :y => d.soc.to_i}
		end
		@play = @play.to_json
		@comment = @comment.to_json
		@coin = @coin.to_json
		@title = @title.to_json
		@fav = @fav.to_json
		@soc = @soc.to_json

		erb :chart
	end
end

threads << Thread.new do
	WS.run!
end

loop do 
  threads << Thread.new do
    Page.fetch $avno
  end
  sleep $time
end
threads.each { |t|t.join  }  



