#!/usr/bin/ruby
require 'set'
require 'rubygems'
require 'json'
require 'yaml'
require 'pp'

def check_file_exits(file)
	if !File.file?(file)
		puts "file #{file} does not exist"
		exit
	end
end

def generate_playlist_id(playlist_ids)
  (1..12345678).each do |id|
    if !playlist_ids.include?(id.to_s)
      return id.to_s
    end
  end
end

if ARGV.length != 3
	puts "usage: killer-app <input-file> <changes-file> <output-file>"
	exit
end

input_file_name = ARGV[0]
check_file_exits(input_file_name)

changes_file_name = ARGV[1]
check_file_exits(changes_file_name)

# read input
input_json = File.read(input_file_name)
data = JSON.parse(input_json)

# read changes
changes = YAML.load_file(changes_file_name)

playlist_ids = Set.new()
data["playlists"].each {|p| playlist_ids.add(p["id"])}

# process changes
changes.each do |cmd|
  case cmd["command"]
  when "add_song_to_playlist"
    song_id = cmd["song_id"]
    playlist_id = cmd["playlist_id"]
    playlists = data["playlists"].select { |p| p["id"] == playlist_id.to_s }
    if !playlists.empty?
      playlist = playlists.first()
      song_ids = playlist["song_ids"]
      if !song_ids.include?(song_id)
        song_ids << song_id
      end
    end
  when "new_playlist"
  	song_ids = Set.new()
    user_id = cmd["user_id"]
    playlist_id = generate_playlist_id(playlist_ids)
    playlist = {"id" => playlist_id, "user_id" => user_id.to_s}
    songs = cmd["songs"]
    songs.each {|song| song_ids << song["song_id"].to_s}
    playlist["song_ids"] = song_ids.to_a
    data["playlists"] << playlist
    playlist_ids.add(playlist_id)
  when "delete_playlist"
    id = cmd["id"]
    data["playlists"].delete_if { |p|  p["id"] == id.to_s}
    playlist_ids.delete(playlist_id)
  end
end

# write output
File.open(ARGV[2], "w") { |f| f.puts JSON.pretty_generate(data)}