extends Node2D

class_name Card
var _connect
var rand = RandomNumberGenerator.new()

signal _on_animation_started(node, anim_name)
signal _on_animation_finished(node, anim_name)

var character:String
var suit:String

var face_up = false

func setup(new_character:String, new_suit:String):
	character = new_character
	suit = new_suit
	rand.randomize()
	self.rotation_degrees = rand.randf_range(-3, 3)

func _ready():
	$AnimationPlayer.play("RESET")
	$Character.text = character
	$Character_Bottom.text = character
	$Suit.text = suit
	if suit in ["diamonds", "hearts"]:
		$Character.add_color_override("font_color", Color("#a92232"))
		$Character_Bottom.add_color_override("font_color", Color("#a92232"))
		$Suit.add_color_override("font_color", Color("#a92232"))
		
	$ParticleTimer.start()

func move(target_position, time=1, ease_type=Tween.EASE_IN_OUT):
	$Tween.interpolate_property(self, "global_position",
		global_position, target_position, time,
		Tween.TRANS_CUBIC, ease_type)
	$Tween.start()

func play_star_particles():
	_connect = $ParticleTimer.connect("timeout", self, "emit_star_particles")

func emit_star_particles():
	$StarParticles.emitting = true
	$ParticleTimer.disconnect("timeout", self, "emit_star_particles")

func get_name():
	return character + " " + suit

func get_character_value(current_character:String=character)->int:
	var character_value:int = int(current_character)
	
	if current_character in ["J", "Q", "K"]:
		character_value = 10
	
	if current_character == "A":
		character_value = 0
	
	return character_value

func play(anim_name):
	$AnimationPlayer.play(anim_name)

func _on_animation_started(anim_name):
	emit_signal("_on_animation_started", self, anim_name)

func _on_animation_finished(anim_name):
	emit_signal("_on_animation_finished", self, anim_name)

func _on_tween_started(_object, _key):
	emit_signal("_on_animation_started", self, "Translate")

func _on_tween_completed(_object, _key):
	emit_signal("_on_animation_finished", self, "Translate")
