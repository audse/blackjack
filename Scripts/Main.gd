extends Node

var Hand = preload("res://Scenes/Hand.tscn")

enum PLAYERS { HOUSE, USER }

var player_hand:Hand
var house_hand:Hand

var currently_dealing = PLAYERS.HOUSE
var winner = null

func _init():
	house_hand = Hand.instance()
	house_hand.margin = Vector2(50, 50)
	
	player_hand = Hand.instance()
	player_hand.deal_direction = -1
	player_hand.margin = Vector2(50, Globals.HEIGHT - Globals.CARD_HEIGHT - 50)

func _ready():
	$Deck.position = Vector2(
			Globals.WIDTH - (Globals.CARD_WIDTH / 2.0) - 100,
			(Globals.HEIGHT / 2.0) - ((Globals.NUM_DECKS * 51) / 2.0) - 30
		)
	
	add_child(house_hand)
	add_child(player_hand)
	
	$Interface.disable_buttons()
	$Interface/HitButton.connect("pressed", self, "draw_card")
	$Interface/HoldButton.connect("pressed", self, "end_game")
	
	# Begin dealing
	$Deck.connect("_on_deck_landed", self, "start_game")

func start_game():
	$DealTimer.connect("timeout", self, "deal")
	$Interface/Score.play("Enter")

func deal():
	if currently_dealing == PLAYERS.HOUSE:
		if len(house_hand.cards) < 2:
			draw_card(PLAYERS.HOUSE)
		else:
			currently_dealing = PLAYERS.USER
	else:
		if len(player_hand.cards) < 2:
			draw_card(PLAYERS.USER)
		else:
			currently_dealing = null
			$DealTimer.disconnect("timeout", self, "deal")
			$DealTimer.connect("timeout", self, "house_play")
			$Interface.enable_buttons()

func house_play():
	var current_hand_value = house_hand.get_hand_value()
	if current_hand_value < 17:
		draw_card(PLAYERS.HOUSE)
	else:
		$DealTimer.disconnect("timeout", self, "house_play")

func draw_card(player=PLAYERS.USER):
	if len($Deck.deck) > 0:
		var original_card = $Deck.get_top_card()
		var new_card = original_card.duplicate()
		new_card.setup(original_card.character, original_card.suit)
		
		if player == PLAYERS.HOUSE:
			var to_flip = false
			if len(house_hand.cards) > 0 and len(house_hand.cards) < 2:
				to_flip = true
			house_hand.add_card(new_card, original_card.global_position, to_flip)
		elif player == PLAYERS.USER:
			player_hand.add_card(new_card, original_card.global_position, true)
			new_card.play_star_particles()
			update_score()
			
		$Deck.remove_top_card()

func update_score():
	$Interface/Score.target_score = str(player_hand.total)
	if player_hand.total > 21:
		end_game()
	elif player_hand.total == 21:
		end_game()
	

func end_game():
	$Interface.disable_buttons()
	house_hand.connect("_hand_reveal_finished", self, "show_results")
	house_hand.reveal_hand()
	var winnerMessage
	var message
	
	if house_hand.total > 21 and player_hand.total > 21:
		winner = PLAYERS.HOUSE
		winnerMessage = "HOUSE ALWAYS WINS!"
		message = "You both BUST!"
	elif house_hand.total > 21:
		winner = PLAYERS.USER
		message = "Dealer BUSTS!"
		winnerMessage = "YOU WIN!"
	elif player_hand.total > 21:
		winner = PLAYERS.HOUSE
		message = "BUST!"
		winnerMessage = "DEALER WINS!"
	elif house_hand.total > player_hand.total and house_hand.total == 21:
		winner = PLAYERS.HOUSE
		message = "BLACKJACK!"
		winnerMessage = "DEALER WINS!"
	elif house_hand.total > player_hand.total:
		winner = PLAYERS.HOUSE
		message = "Dealer is CLOSER!"
		winnerMessage = "DEALER WINS!"
	elif house_hand.total == player_hand.total:
		winner = PLAYERS.HOUSE
		message = "It's a TIE!"
		winnerMessage = "HOUSE ALWAYS WINS!"
	elif player_hand.total == 21:
		winner = PLAYERS.USER
		message = "BLACKJACK"
		winnerMessage = "YOU WIN!"
	else:
		winner = PLAYERS.USER
		message = "You are CLOSER!"
		winnerMessage = "YOU WIN!"
	
	$Interface/GameOverMessage.text = message
	$Interface/GameOverMessage/Winner.text = winnerMessage

func show_results():
	var player_won = false
	if winner == PLAYERS.USER:
		player_won = true
	$Interface.show_results(player_won)
