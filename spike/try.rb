require 'hallon'

appkey_path = File.expand_path('./spotify_appkey.key')
hallon_appkey   = IO.read(appkey_path)
session = Hallon::Session.initialize(hallon_appkey) do
  on(:log_message) do |message|
    puts "[LOG] #{message}"
  end

  on(:credentials_blob_updated) do |blob|
    puts "[BLOB] #{blob}"
  end

  on(:connection_error) do |error|
    Hallon::Error.maybe_raise(error)
  end

  on(:logged_out) do
    abort "[FAIL] Logged out!"
  end
end
session.login!('bmoussaud', 'parabole')
puts "Successfully logged in!"

track = Hallon::Track.new("spotify:track:1ZPsdTkzhDeHjA5c2Rnt2I").load
artist = track.artist.load

puts "#{track.name} by #{artist.name}"

query = "[artist:\"Alain BASHUNG\" track:\"LA NUIT JE MENS\"]"
search = Hallon::Search.new(query)
puts "Searching for "#{query}"..."
search.load

if search.tracks.size.zero?
	puts "No results for "#{search.query}"."
end
	
tracks = search.tracks[0...10].map(&:load)
puts "Results for "#{search.query}": "

tracks.each_with_index do |track, index|
  puts "  [#{index + 1}] #{track.name} - #{track.artist.name} (#{track.to_link.to_str})"
end


puts "done"
