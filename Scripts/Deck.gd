extends Node2D

var Card = preload("res://Scenes/Card.tscn")
var rand = RandomNumberGenerator.new()
var _connect

signal _on_deck_landed

var deck:Array

func _init():
	randomize()
	deck = create_deck()
	deck.shuffle()

func _ready():
	_connect = $Timer.connect("timeout", self, "animate_deck_graphic")
	$Timer.start()

func get_top_card():
	var length = len(deck)
	if length > 0:
		return deck[length-1]

func remove_top_card():
	var length = len(deck)
	if length > 0:
		deck[length-1].queue_free()
		deck.pop_back()

func create_deck()->Array:
	var face_characters:Dictionary = {
		1: "A",
		11: "J",
		12: "Q",
		13: "K"
	}
	
	var new_deck:Array = []
	
	for suit in ["spades", "hearts", "clubs", "diamonds"]:
		for value in range(1, 14):
			var character:String
			if value in face_characters.keys():
				character = face_characters[value]
			else:
				character = str(value)
			
			var new_card = Card.instance()
			new_card.setup(character, suit)
			new_deck.append(new_card)
			
	return new_deck

func add_deck_graphic():
	var i:int = 0
	for card in deck:
		
		# Stack draws bottom-to-top: each card moves upward
		# to simulate 3D
		card.position = Vector2(0, (Globals.NUM_DECKS * 51))
		card.position.y -= i
		
		# Slightly randomize position to give a just-shuffled look
		rand.randomize()
		card.position.x += rand.randf_range(-5, 5)
		card.position.y += rand.randf_range(-2, 2)
		
		add_child(card)
		i += 1

func animate_deck_graphic():
	$Timer.disconnect("timeout", self, "animate_deck_graphic")
	
	var deck_length = len(deck)
	
	var i:int = 0
	for card in deck:
		card.position.x = 0
		card.position.y = -(Globals.HEIGHT) - (Globals.CARD_HEIGHT * i * 2)

		rand.randomize()
		
		var target_position = to_global(Vector2(
				0,
				deck_length
			))
		target_position.y -= i
		target_position.x += rand.randf_range(-5, 5)
		target_position.y += rand.randf_range(-2, 2)
		
		var animation_time = 0.25 + (0.025 * i)
		
		add_child(card)
		card.move(target_position, animation_time, Tween.EASE_OUT)
		
		if i == 51:
			_connect = card.connect("_on_animation_finished", self, "_on_deck_landed")
		i += 1

func _on_deck_landed(node, anim_name):
	if node in deck and anim_name == "Translate":
		node.disconnect("_on_animation_finished", self, "_on_deck_landed")
		emit_signal("_on_deck_landed")
