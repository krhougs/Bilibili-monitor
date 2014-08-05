require "./bili"
threads = []
puts "输入av号："
$avno = 1376960
puts "你的av号是：" + $avno.to_s + "如果输错了请按Ctrl+C退出程序"

puts "输入抓取时间间隔(ms)："
$time =( gets ).to_i
puts "你的抓取时间间隔：" + $time.to_s + "如果输错了请按Ctrl+C退出程序"
puts "开始工作了喵"

loop do 
  threads << Thread.new do
    Page.fetch $avno
  end
  sleep $time
end
threads.each { |t|t.join  }  

