extends Node2D

var score := '0'
var target_score := '0'
var game_over = false
var score_target_position

func _ready():
	$HitButton.connect("mouse_entered", self, "_on_mouse_entered", [self])
	$HitButton.connect("mouse_exited", self, "_on_mouse_exited", [self])
	
	$HoldButton.connect("mouse_entered", self, "_on_mouse_entered", [self])
	$HoldButton.connect("mouse_exited", self, "_on_mouse_exited", [self])
	
	$GameOverMessage.visible = false

func show_results(player_won):
	game_over = true
	score_target_position = Vector2(450, 200)
	$Score.connect("_on_animation_finished", self, "_play_game_over", [player_won])
	$Score.play("Expand")

func _play_game_over(node, anim_name, player_won):
	$GameOverMessage.visible = true
	$GameOverMessage/AnimationPlayer.play("Show")
	$GameOverMessage/Winner/AnimationPlayer.play("Show")
	if player_won:
		$Particles2D.emitting = true
	
func _on_mouse_entered(node):
	if node in [$HitButton, $HoldButton] and not node.disabled:
		node.get_node("AnimationPlayer").play("HoverStart")
	
func _on_mouse_exited(node):
	if node in [$HitButton, $HoldButton] and not node.disabled:
		node.get_node("AnimationPlayer").play("HoverEnd")

func disable_buttons():
	$HitButton.modulate.a *= 0.5
	$HitButton.disabled = true
	$HoldButton.modulate.a *= 0.5
	$HoldButton.disabled = true

func enable_buttons():
	$HitButton.modulate.a *= 2
	$HitButton.disabled = false
	$HoldButton.modulate.a *= 2
	$HoldButton.disabled = false

func _process(delta):
	
	if game_over and $DarkOverlay.modulate.a < 1:
		$DarkOverlay.modulate.a += 0.025
	
	if score_target_position and game_over:
		var speed = ($Score.position.distance_to(score_target_position) / 10) * 100
		var velocity = $Score.position.direction_to(score_target_position) * speed
		
		if $Score.position.distance_to(score_target_position) > 10:
			$Score.translate(velocity * delta)
			
		elif $Score.modulate.a > 0:
			$Score.modulate.a -= 0.01
