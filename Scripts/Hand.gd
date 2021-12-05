extends Node2D

class_name Hand
var Card = preload("res://Scenes/Card.tscn")

signal _hand_reveal_finished

var cards:Array = []

var num_columns:int = 6
var overlap:Vector2 = Vector2(-5, -50)
var deal_direction:int = 1 # can be 1 (down) or -1 (up)

var margin:Vector2 = Vector2()

var total = 0

func _ready():
	pass 

func get_hand_value(partial_hand=null):
	var hand = partial_hand
	# If no hand provided, just use all cards
	if not partial_hand:
		hand = cards
		
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

func reveal_hand():
	# Show score box
	$Score.connect("_on_animation_finished", self, "_reveal_hand_animation_finished")
	$Score.play("Enter")
	
	for card in cards:
		card.connect("_on_animation_finished", self, "_reveal_hand_animation_finished")

func _reveal_hand_animation_finished(node, anim_name):
	
	# After the hand's score box appears
	if node == $Score and anim_name == "Enter":
		print("score enter finished")
		if len(cards) > 0:
			# Flip the first card
			$Score.target_score = str(get_hand_value([cards[0]]))
			cards[0].play("Flip")
	
	# After flipping a card
	elif node in cards and (anim_name == "Flip" or anim_name == "FlipInPlace"):
		var card_index = cards.find(node)
		
		# Update the score
		if card_index != -1 and card_index < (len(cards) - 1):
			var next_card = cards[card_index + 1]
			
			var current_hand_value = get_hand_value(cards.slice(0, card_index + 1))
			$Score.target_score = str(current_hand_value)
			
			# Flip the next card
			if next_card.face_up:
				next_card.play("FlipInPlace")
			else:
				next_card.play("Flip")
		
		# If all cards are flipped, update to the final score
		elif card_index == (len(cards) - 1):
			$Score.target_score = str(get_hand_value())
	
	# After updating the score for the final time
	elif node == $Score and anim_name == "Update" and $Score.score == str(get_hand_value()):
		emit_signal("_hand_reveal_finished")

func add_card(card:Card, current_position:Vector2, flip=true):
	cards.append(card)
	card.position = current_position
	card.target_position = calculate_card_position()
	add_child(card)
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
