extends Node2D

signal _on_animation_started(node, anim_name)
signal _on_animation_finished(node, anim_name)

var score = '0'
var target_score = '0'

func _process(_delta):
	var is_animating = $AnimationPlayer.is_playing()
	var current_animation = $AnimationPlayer.current_animation
	if score != target_score and current_animation != "Update":
		score = target_score
		play("Update")
	elif is_animating and current_animation == "Update":
		var elapsed_time = $AnimationPlayer.current_animation_position
		if elapsed_time > 0.44 and elapsed_time < 0.46:
			$Score.text = score

func play(anim_name):
	$AnimationPlayer.play(anim_name)

func _on_animation_finished(anim_name):
	emit_signal("_on_animation_finished", self, anim_name)

func _on_animation_started(anim_name):
	emit_signal("_on_animation_finished", self, anim_name)
