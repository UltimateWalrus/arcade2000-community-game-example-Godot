extends Node2D

## An example of how you could submit scores from your game.
## You could just adapt this script to your game if you want.
class_name GameExample


const GAME_NICKNAME = 'community_test_game'
const GAME_VERSION = 'v1'
const GAME_SECRET_KEY = '60FrtHQBhVLcL5Yg'

var score := 0
var frame_length := 0

var subscores = {
	"number_of_clicks":0
}  # example subscore dictionary

var achievements = {}  # example achievement dictionary

var game_over := false
var _increase_score_button_held := false

func _on_increase_score_button_button_down() -> void:
	_increase_score_button_held = true

func _on_increase_score_button_button_up() -> void:
	_increase_score_button_held = false


func _physics_process(delta: float) -> void:
	if game_over:
		return   # skip game logic
	
	if Input.is_action_just_pressed("click"):   # track example subscore
		subscores['number_of_clicks'] += 1
	
	# increase score while the button is held
	if _increase_score_button_held:
		score += 1
	
	frame_length += 1   # frame length is always increasing
	
	# show score and achievements
	$GameScreen/ScoreLabel.text = "SCORE: " + str(score)
	
	if 'ach1' in achievements:
		$GameScreen/Ach1Label.visible = true
		$GameScreen/Ach1Label.text = "Got ach1 at frame: " + str(achievements['ach1'])
	if 'ach2' in achievements:
		$GameScreen/Ach2Label.visible = true
		$GameScreen/Ach2Label.text = "Got ach2 at frame: " + str(achievements['ach2'])	
	


func _on_game_over_button_pressed() -> void:
	# Go to game over screen
	$GameScreen.visible = false
	$GameOverScreen.visible = true
	
	$GameOverScreen/GotScoreLabel.text = "You got score: " + str(score) + " with " + str(subscores['number_of_clicks']) + " clicks"
	game_over = true
	
	# prefill username if they typed one already
	var file = FileAccess.open("user://username.txt", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		$GameOverScreen/LEUsername.text = content.strip_edges()
		file.close()
	


func _on_submit_button_pressed() -> void:
	# Check if the username uses allowed characters
	var username : String = $GameOverScreen/LEUsername.text
	username = username.strip_edges()  # trim whitespace on the edges
	if !A2Community.string_valid(username):
		$GameOverScreen/ErrorLabel.visible = true
		$GameOverScreen/ErrorLabel.text = "Username can't contain spaces or special characters."
		return
	
	# save username so we can prefill it later
	var file = FileAccess.open("user://username.txt", FileAccess.WRITE)
	if file:
		file.store_string(username)
		file.close()
	
	
	# Submit the score!
	A2Community.inst.submit_score(
		GAME_NICKNAME,
		GAME_VERSION,
		score,
		frame_length,
		username,
		GAME_SECRET_KEY,
		A2Community.dict_to_query_param(subscores),
		A2Community.dict_to_query_param(achievements)
	)
	
	# Open main menu
	$GameOverScreen.visible = false
	$MainMenu.visible = true
	

func _on_scoreboard_button_pressed() -> void:
	# open score chart in browser, soft logging in the user so they can edit their profile
	A2Community.open_score_chart(
		GAME_NICKNAME,
		GAME_VERSION,
		$GameOverScreen/LEUsername.text.strip_edges()
	)


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()


# Achievements
func _on_get_ach_1_button_pressed() -> void:
	if !'ach1' in achievements:
		achievements['ach1'] = frame_length   # set the achievement to the current frame timestamp.
func _on_get_ach_2_button_pressed() -> void:
	if !'ach2' in achievements:
		achievements['ach2'] = frame_length

	
