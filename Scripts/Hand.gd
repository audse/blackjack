extends Node2D

class_name Hand
var Card = preload("res://Scenes/Card.tscn")
var _connect
signal _hand_reveal_finished
signal _discard_hand_finished

var cards:Array = []

var num_columns:int = 6
var overlap:Vector2 = Vector2(-5, -50)
var deal_direction:int = 1 # can be 1 (down) or -1 (up)

var margin:Vector2 = Vector2()

var total = 0

var hide_score = true

func _ready():
	pass 

func get_hand_value(partial_hand=cards):
	var hand = partial_hand
		
	var value = 0
	var num_aces = 0
	
	for card in hand:
		if card.character != "A":
			value += card.get_character_value(card.character)
		else:
			num_aces += 1
	for _ace in range(0, num_aces):
		if value <= 10:
			value += 11
		else:
			value += 1
	return value

func reveal_hand(quick=false):
	$Timer.start()
	
	# Show score box
	$Score.modulate_alpha(1)
	$Score.play("Enter")
	
	if not quick:
		# Show cards 1-by-1
		$Timer.wait_time = 0.75
		_connect = $Timer.connect("timeout", self, "_reveal_card", [cards[0]])
		
	else:
		# Show all cards
		for card in cards:
			if card.face_up:
				card.play("FlipInPlace")
			else:
				card.play("Flip")
		# Update score
		$Score.target_score = str(get_hand_value())
		_connect = $Score.connect("_on_animation_finished", self, "_hand_reveal_finished", [true])

func _reveal_card(card):
	$Timer.disconnect("timeout", self, "_reveal_card")
	
	# Flip next card (if there is one)
	var card_index = cards.find(card)
	if len(cards) > card_index + 1:
		var new_card = cards[card_index + 1]
		_connect = $Timer.connect("timeout", self, "_reveal_card", [new_card])
	# If not, the reveal is finished
	else:
		_connect = $Score.connect("_on_animation_finished", self, "_hand_reveal_finished", [false])
	
	# Update score
	var partial_hand = cards.slice(0, card_index)
	$Score.target_score = str(get_hand_value(partial_hand))
	if card.face_up:
		card.play("FlipInPlace")
	else:
		card.play("Flip")

func _hand_reveal_finished(_node=null, _anim_name=null, _quick_reveal=false):
	$Score.disconnect("_on_animation_finished", self, "_hand_reveal_finished")
	
	$Timer.wait_time = 1
	_connect = $Timer.connect("timeout", self, "_hand_revealed")

func _hand_revealed():
	$Score.modulate_alpha(0)
	emit_signal("_hand_reveal_finished")
	$Timer.disconnect("timeout", self, "_hand_revealed")

func discard_hand():
	hide_score = true
	for card in cards:
		_connect = card.connect("_on_animation_finished", self, "_discard_flip_finished")
		card.play("FlipDown")

func _discard_flip_finished(node, anim_name):
	if node in cards and anim_name == "FlipDown":
		var target_position = node.global_position
		target_position.x = -100
		node.move(target_position, 0.5)
	elif node in cards and anim_name == "Translate":
		cards.erase(node)
		node.queue_free()
		emit_signal("_discard_hand_finished")

func add_card(card:Card, current_position:Vector2, flip=true):
	cards.append(card)
	card.position = current_position
#	card.target_position = calculate_card_position()
	add_child(card)
	var target_position = calculate_card_position()
	card.move(target_position)
	
	total = get_hand_value()
	
	if (flip):
		card.play("Flip")
		card.face_up = true
	else:
		card.play("Move")
		card.face_up = false

func calculate_card_position():
	# There are 5 columns (default), and infinite rows
	
	# e.g. (15 cards / 5) means 3 rows
	# e.g. (9 cards / 5) rounded down means 2 rows
	var current_row:int = int(floor(len(cards) / float(num_columns)))
	
	# e.g. (3 cards % 5) means 3rd place
	# e.g. (6 cards % 5) means 1st place
	# subtract 1 for an index of 0, as len(cards) will always have at least one
	var current_column:int = (len(cards) % num_columns) - 1
	
	# when current column is -1, that means (cards % 5) has no remainder
	# ergo, it's the last card in the column
	# this also means that (cards / 5) is returning a perfect int,
	# so we round down
	if current_column == -1:
		current_row -= 1
		current_column = num_columns - 1
		
	# if column/row is 0, there is no offset
	# for greater values, the card is moved by into a grid based on dimensions
	var position_x:float = current_column * (Globals.CARD_WIDTH + overlap.x)
	var position_y:float = current_row * (Globals.CARD_HEIGHT + overlap.y) * deal_direction
	
	# The pivot point is in the center; move the cards to that they are in line
	# with the hand's corner pivot point
	position_x += 0.5*Globals.CARD_WIDTH
	position_y += 0.5*Globals.CARD_HEIGHT
	
	# As the rows increase, they move further right
	position_x += current_row * 10
	
	# Add stage margin
	position_x += margin.x
	position_y += margin.y
	
	return Vector2(position_x, position_y)

