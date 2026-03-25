extends Node
## Handles the example UI for submitting scores.
## You probably don't want to include this in your game.
## Note absolute paths to all UI so if you change any names
## in the inspector, it won't work anymore.
class_name A2CommunityExampleUI

@onready var a2_community : A2Community = $"../A2Community"

func _on_submit_score_button_pressed() -> void:
	a2_community.submit_score(
		$VBoxContainer/HBoxContainer/LEGame.text,
		$VBoxContainer/HBoxContainer2/LEVersion.text,
		int($VBoxContainer/HBoxContainer4/LEScore.text),
		int($VBoxContainer/HBoxContainer5/LEFrameLength.text),
		$VBoxContainer/HBoxContainer6/LEUsername.text,
		$VBoxContainer/HBoxContainer9/LEGameSecretKey.text,
		$VBoxContainer/HBoxContainer7/LESubscores.text,
		$VBoxContainer/HBoxContainer8/LEAchievements.text,
		$VBoxContainer/HBoxContainer3/LELevel.text,
		$VBoxContainer/HBoxContainer10/LEScore.text	
	)
	
	$VBoxContainer/StatusLabel.text = "Submitted request. Check log for response."



func _on_open_chart_button_pressed() -> void:
	A2Community.open_score_chart(
		$VBoxContainer/HBoxContainer/LEGame.text,
		$VBoxContainer/HBoxContainer2/LEVersion.text,
		$VBoxContainer/HBoxContainer6/LEUsername.text
	)
