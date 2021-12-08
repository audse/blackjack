extends Node2D

var _connect

var score := '0'
var target_score := '0'
var score_target_position

func _ready():
	_connect = $HitButton.connect("mouse_entered", self, "_on_mouse_entered", [$HitButton])
	_connect = $HitButton.connect("mouse_exited", self, "_on_mouse_exited", [$HitButton])
	
	_connect = $HoldButton.connect("mouse_entered", self, "_on_mouse_entered", [$HoldButton])
	_connect = $HoldButton.connect("mouse_exited", self, "_on_mouse_exited", [$HoldButton])
	
	_connect = $GameOverMessage/Winner/OKButton.connect("mouse_entered", self, "_on_mouse_entered", [$GameOverMessage/Winner/OKButton])
	_connect = $GameOverMessage/Winner/OKButton.connect("mouse_exited", self, "_on_mouse_exited", [$GameOverMessage/Winner/OKButton])
	
	$GameOverMessage.visible = false

func show_results(player_won):
	modulate_alpha($DarkOverlay, 1, 1)
	if player_won:
		_connect = $Score.connect("_on_animation_finished", self, "_play_game_over", [player_won])
		$Score.play("Expand")
		$Score.move(Vector2(512, 260))
	else:
		_play_game_over(null, null, player_won)

func _play_game_over(_node, _anim_name, player_won):
	if player_won:
		$Score.disconnect("_on_animation_finished", self, "_play_game_over")
		$Particles2D.emitting = true
	modulate_alpha($Score, 0)
	$GameOverMessage.visible = true
	$GameOverMessage/AnimationPlayer.play("Show")
	$GameOverMessage/Winner/AnimationPlayer.play("Show")
		
func hide_results():
	$Score/Score.text = '0'
	$GameOverMessage/AnimationPlayer.play_backwards("Show")
	$GameOverMessage/Winner/AnimationPlayer.play_backwards("Show")
	$Score.play_backwards("Expand")
	$Score.move(Vector2(870, 70))
	modulate_alpha($DarkOverlay, 0)
	modulate_alpha($Score, 1)
	
func _on_mouse_entered(node):
	if node in [$HitButton, $HoldButton, $GameOverMessage/Winner/OKButton] and not node.disabled:
		node.get_node("AnimationPlayer").play("HoverStart")
	
func _on_mouse_exited(node):
	if node in [$HitButton, $HoldButton, $GameOverMessage/Winner/OKButton] and not node.disabled:
		node.get_node("AnimationPlayer").play("HoverEnd")

func disable_buttons():
	$HitButton.disabled = true
	modulate_alpha($HitButton, 0.5, 0.15)
	$HoldButton.disabled = true
	modulate_alpha($HoldButton, 0.5, 0.15)

func enable_buttons():
	$HitButton.disabled = false
	modulate_alpha($HitButton, 1, 0.15)
	$HoldButton.disabled = false
	modulate_alpha($HoldButton, 1, 0.15)

func modulate_alpha(node, target_alpha, time=0.5):
	$Tween.interpolate_property(node, "modulate:a",
		node.modulate.a, target_alpha, time,
		Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$Tween.start()

func _process(_delta):
	pass
