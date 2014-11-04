require "./bili"
threads = []
puts "输入av号："
$avno = 1676617
puts "你的av号是：" + $avno.to_s + "如果输错了请按Ctrl+C退出程序"

puts "输入抓取时间间隔(sec)："
$time = 30
puts "你的抓取时间间隔：" + $time.to_s + "如果输错了请按Ctrl+C退出程序"
puts "开始工作了喵"

p = Page.new
loop do 
  f = p.future.fetch($avno)
  sleep $time
end


