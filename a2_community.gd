extends Node

## This is an example of how to do online high scores with arcade2000!
## You can test it right away using the public test game
## with nickname "community_test_game" and secret key "60FrtHQBhVLcL5Yg".
##
## Go to https://arcade2000.io/a2/community_games_quickstart/ to set up your own game!
##
## This class handles communicating with arcade2000.
## You could drop this code into your game as is.
## It needs to be an actual node in the scene so it can create
## HTTPRequest children.
class_name A2Community


# MIT LICENSE:
# Copyright March 2026, Ultimate Walrus LLC.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.




const A2_SERVER = "http://arcade2000.io/"


static var inst : A2Community

func _ready() -> void:
	inst = self
func _exit_tree() -> void:
	if inst == self:
		inst = null



## Get the proper URL to submit a score with the provided parameters.
## Will push_error and return "" if parameters are malformed.
static func get_score_submission_url(
	game_nickname:String, 
	version:String, 
	score:int, 
	frame_length:int, 
	username:String,
	game_secret_key:String,
	subscores:String = "",
	achievements:String = "",
	level:String="", 
	local_score_id:String="") -> String:
		
		# Validate parameters
		for mystr in [game_nickname, version, username, game_secret_key, level, local_score_id]:
			if !string_valid(mystr):
				push_error(mystr + " contains special characters, can't get_score_submission_url!")
				return ""
		
		# Validate achievements/subscores (allow , and : in the list)
		for mystr in [subscores,achievements]:
			if !list_valid(mystr):
				push_error(mystr + " contains special characters, can't get_score_submission_url!")
				return ""
		
		var ret : String = A2_SERVER + "a2/api/submit-score-easy/?"   # proper endpoint for score submission
		
		var query : String = ""  # build this separately so we can hash it
		
		# Build query string: mandatory parameters
		query += "game=" + game_nickname + "." + version   # important, hash string does NOT include the question mark
		query += "&score=" + str(score)
		query += "&frame_length=" + str(frame_length)
		query += "&username=" + username
		
		# source device_id from Godot's OS.get_unique_id()
		query += "&device_id=" + OS.get_unique_id().uri_encode()   # uri_encode is necessary to handle the special chars 
		
		# Build query string: optional parameters
		if subscores:
			query += "&subscores=" + subscores
		if achievements:
			query += "&achievements=" + achievements
		if level:
			query += "&level=" + level
		if local_score_id:
			query += "&local_score_id=" + local_score_id
		
		
		# We now use the trick with the game's secret key to create a secure hash.
		# This ensures nobody can just type in a URL to submit a score.
		var hash_param := (query + game_secret_key).md5_text()
		
		# Append the hash to the query
		ret += query + "&hash=" + hash_param
				
		return ret
		
		
## Submits an actual score to the arcade2000 servers.
## The result will be printed to the console.
func submit_score(
	game_nickname:String, 
	version:String, 
	score:int, 
	frame_length:int, 
	username:String,
	game_secret_key:String,
	subscores:String = "",
	achievements:String = "",
	level:String="", 
	local_score_id:String="") -> void:
		# Get the URL for submission
		var url := get_score_submission_url(game_nickname, version, score, frame_length, username, game_secret_key, subscores, achievements, level, local_score_id)
		if url == "":   # it must have been badly formatted.
			return
		
		print("Submitting to " + url)
		
		# Create an HTTPRequest (node that must be parented under us)
		var http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.request_completed.connect(self._http_request_completed)

		# Perform a GET request.
		var error = http_request.request(url)
		if error != OK:
			push_error("An error occurred in the HTTP request.")


# Called when the HTTP request is completed.
func _http_request_completed(_result, _response_code, _headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()

	if response == null:
		var _response_text = body.get_string_from_utf8()
		push_error("Server did not return JSON, this is likely because of a server error. You can put a breakpoint here and send the _response_text to admin@arcade2000.io")
	elif 'error' in response:   # this should always be true if the submission failed.
		push_error("arcade2000 responded with error: " + response['error'])

	elif 'score_id' in response:  # this should always be true if the submission succeeded.
		print("Submission succeeded!")
		if 'local_score_id' in response && response['local_score_id']:   # if you want, you can use this to tell the different score submissions apart.
			print("Local score id was " + response['local_score_id'])
	else:
		print("Unknown response from server.")


## Opens the score chart in a browser and soft-logins the player using the device ID.
static func open_score_chart(
		game_nickname:String, 
		version:String, 
		username:String) -> void:

		# Validate parameters
		for mystr in [game_nickname, version, username]:
			if !string_valid(mystr):
				push_error(mystr + " contains special characters, can't open score chart!")
				return

		
		var url := A2_SERVER + "game/" + game_nickname + "?"
		
		var query : String = ""  # build this separately so we can hash it
		
		# Build query string
		query += "game=" + game_nickname
		query += "&game_version_identifier=" + version
		query += "&username=" + username
		
		# source device_id from Godot's OS.get_unique_id()
		query += "&device_id=" + OS.get_unique_id().uri_encode()   # uri_encode is necessary to handle the special chars 
		
		# open the URL in a browser
		OS.shell_open(url + query)
		
		


## Convert a subscore or achievement dictionary to something you can put in a query parameter.
static func dict_to_query_param(mydict:Dictionary) -> String:
	var ret := ""
	
	var first := true
	for key in mydict:
		if !A2Community.string_valid(key) || !(mydict[key] is int):
			push_error("Invalid characters put into dict_to_query_param: " + key + " " + mydict[key])
			return ""
			
		if !first:
			ret += ","
		first = false
		
		ret += key + ":" + str(mydict[key])
		
	return ret
		
		
		
## Ensures a string is a-z,A-Z,0-9,and _
static func string_valid(mystr:String, valid_chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"):
	for i in len(mystr):
		var found := false
		for j in len(valid_chars):   # look for matching valid character
			if mystr[i] == valid_chars[j]:
				found = true
				break
		if !found:
			return false    # invalid char
	
	return true # no invalid chars found

## Allows the subscore1:123,subscore2:234 format
static func list_valid(mystr:String):
	return string_valid(mystr, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_,:")
