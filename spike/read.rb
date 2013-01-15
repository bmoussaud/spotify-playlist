thefile='sample.txt'
tracks=[]
IO.foreach(thefile) do |line|
	if line =~ /^\n$/
		next
	end
	if line.length < 10
		next
	end
	line=line.gsub(/\n/," ")
    timestamp, artist, track = line.split("    ")
	puts "#{line} --> (#{timestamp})(#{artist}),(#{track.strip})"
	entry = {:timestamp => timestamp, :artist => artist, :track => track.strip}
	puts entry
	tracks <<  entry
end
puts "---"
#puts tracks
tracks.each do |t|
	puts t
end
puts "done"

