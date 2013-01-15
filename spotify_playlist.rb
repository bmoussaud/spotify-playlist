require 'hallon'
require 'optparse'

class PlaylistMaker

	attr_accessor :session, :tracks, :spotify_tracks, :missing_tracks

	def initialize(username,password)
		appkey_path = File.expand_path('./spotify_appkey.key')
		unless File.exists?(appkey_path)
		  abort <<-ERROR
Your Spotify application key could not be found at the path: #{appkey_path}. You may download your application key from: https://developer.spotify.com/en/libspotify/application-key/
		  ERROR
		end

		hallon_appkey   = IO.read(appkey_path)
		@session = Hallon::Session.initialize(hallon_appkey) do
		  on(:log_message) do |message|
			#puts "[LOG] #{message}"
		  end

		  on(:credentials_blob_updated) do |blob|
			#puts "[BLOB] #{blob}"
		  end

		  on(:connection_error) do |error|
			Hallon::Error.maybe_raise(error)
		  end

		  on(:logged_out) do
			abort "[FAIL] Logged out!"
		  end
		end
		@session.login!(username, password)
		puts "Successfully logged in using '#{username}'"
		@tracks=[]
		@spotify_tracks=[]
		@missing_tracks=[]
	end

	def close()
		puts "Goodbye !"
		@session.logout!()
	end


	def collect()
		@spotify_tracks=@tracks.collect{ |e| 
			self.query_track(e[:track_name].gsub("&",","))
		}
	end

	def query_track(query)
		puts "#{query} .... "
		track = nil
		search = Hallon::Search.new(query,tracks: 10)
		search.load
		if search.tracks.size > 0
			track = search.tracks[0] 
		else
			@missing_tracks << query
		end
		puts "#{query} [#{search.tracks.size}] "
		track
	end

	def load(file)
		puts "Load file #{file}"
		IO.foreach(file) do |line|
			#puts line
			if line =~ /^\n$/
				next
			end
			if line.length < 10
				next
			end
			line=line.gsub(/\n/," ")
			entry = {:timestamp => line[0..7], :track_name => line[8..-1].strip}
			if entry[:timestamp].include? ":"
				@tracks <<  entry
			end
		end
		@tracks
	end

	def save_to(playlist_name)
		puts "Save the tracks under new playlist '#{playlist_name}'"
		playlist = session.container.add(playlist_name, true)
		position = 0
		playlist.insert(position, @spotify_tracks.compact)
		puts "Uploading playlist changes to Spotify back-end!"
		playlist.upload
	end
end


options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: spotifypl [OPTIONS]"
  opt.separator  ""
  opt.separator  "Options"
  opt.on("-u","--username USERNAME","spotify username") do |username|
  	puts username
    options[:username] = username
  end
  opt.on("-p","--password PASSWORD","spotify password") do |password|
    options[:password] = password
  end
  opt.on("-t","--title TITLE","playlist title") do |title|
    options[:title] = title
  end
  opt.on("-f","--file INPUTFILE","input file") do |inputfile|
    options[:inputfile] = inputfile
  end
  opt.on("-h","--help","help") do
    puts opt_parser
  end
end

begin
	opt_parser.parse!
	mandatory = [:username, :password, :inputfile, :title]
	missing = mandatory.select{ |param| options[param].nil? }  
	if not missing.empty?                                            
		puts "Missing options: #{missing.join(', ')}"                
		puts opt_parser
		exit                                                        
end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument     
  puts $!.to_s                                                       
  puts opt_parser
  exit                                                             
end   

plm = PlaylistMaker.new(options[:username],options[:password])
plm.load(options[:inputfile])
plm.collect()
plm.spotify_tracks.compact.each_with_index do |track, index|
	if track == nil
		puts "  [#{index + 1}] NIL "
	else
		puts "  [#{index + 1}] #{track.name} - #{track.artist.name} (#{track.to_link.to_str})"
	end
end

plm.missing_tracks.each_with_index do | entry, index| 
	puts "  Missing [#{index + 1}] #{entry}"
end


plm.save_to(options[:title])
plm.close()

puts "done"
