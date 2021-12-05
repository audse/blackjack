extends Node2D

class_name Card
var rand = RandomNumberGenerator.new()

signal _on_animation_started(node, anim_name)
signal _on_animation_finished(node, anim_name)

var character:String
var suit:String

var velocity:Vector2
var target_position
var speed_factor = 200
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

func play_star_particles():
	$ParticleTimer.connect("timeout", self, "emit_star_particles")

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

func _process(delta):
	if target_position:
		emit_signal("_on_animation_started", self, "Translate")
		var speed = (global_position.distance_to(target_position) / 10) * speed_factor
		
		if $AnimationPlayer.is_playing():
			speed *= $AnimationPlayer.current_animation_position
			
			if $AnimationPlayer.current_animation_position < 0.1:
				speed *= 0
			
		velocity = global_position.direction_to(target_position) * speed
		if global_position.distance_to(target_position) > 5:
			global_translate(velocity * delta)
		else:
			emit_signal("_on_animation_finished", self, "Translate")
			target_position = null

func play(anim_name):
	$AnimationPlayer.play(anim_name)

func _on_animation_started(anim_name):
	emit_signal("_on_animation_started", self, anim_name)

func _on_animation_finished(anim_name):
	emit_signal("_on_animation_finished", self, anim_name)
