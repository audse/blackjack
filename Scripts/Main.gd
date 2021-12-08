extends Node

var Hand = preload("res://Scenes/Hand.tscn")

enum PLAYERS { HOUSE, USER }
enum ACTIONS { HIT, STAND }
enum STATE { 
	READY,
	DEALING_HOUSE,
	DEALING_PLAYER,
	PLAYER_TURN,
	HOUSE_TURN,
	HOUSE_FINAL_TURN,
	REVEAL_HOUSE,
	RESULTS,
	DISCARD_HANDS,
	DECK_EMPTY
}

var player_hand:Hand
var house_hand:Hand

var winner
var _connect

var state = STATE.READY

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
	_connect = $Interface/HitButton.connect("pressed", self, "player_turn", [ACTIONS.HIT])
	_connect = $Interface/HoldButton.connect("pressed", self, "player_turn", [ACTIONS.STAND])
	_connect = $Interface/GameOverMessage/Winner/OKButton.connect("pressed", self, "play_again")
	
	# Begin dealing
	_connect = $Deck.connect("_on_deck_landed", self, "start_game")

func start_game():
	var deck_length = len($Deck.deck)
	if deck_length > 4:
		state = STATE.DEALING_HOUSE
		$Interface/Score.play("Enter")
		_connect = house_hand.connect("_hand_reveal_finished", self, "_hand_reveal_finished")
		_connect = house_hand.connect("_discard_hand_finished", self, "_discard_hand_finished")

func deal():
	if state == STATE.DEALING_HOUSE:
		if len(house_hand.cards) < 2:
			draw_card(PLAYERS.HOUSE)
		else:
			state = STATE.DEALING_PLAYER
			
	elif state == STATE.DEALING_PLAYER:
		if len(player_hand.cards) < 2:
			draw_card(PLAYERS.USER)
		else:
			state = STATE.PLAYER_TURN

func player_turn(action):
	if action == ACTIONS.HIT and state == STATE.PLAYER_TURN:
		$Interface.disable_buttons()
		state = STATE.HOUSE_TURN
		draw_card(PLAYERS.USER)
			
	# End game on stand
	elif action == ACTIONS.STAND and state == STATE.PLAYER_TURN:
		$Interface.disable_buttons()
		state = STATE.HOUSE_FINAL_TURN
		
func house_turn():
	var current_hand_value = house_hand.get_hand_value()
	if state == STATE.HOUSE_FINAL_TURN:
		if current_hand_value < 17:
			$Interface.disable_buttons()
			draw_card(PLAYERS.HOUSE)
		else:
			state = STATE.REVEAL_HOUSE
	elif state == STATE.HOUSE_TURN:
		if current_hand_value < 17:
			$Interface.disable_buttons()
			draw_card(PLAYERS.HOUSE)
		state = STATE.PLAYER_TURN

func _hand_reveal_finished():
	house_hand.disconnect("_hand_reveal_finished", self, "_hand_reveal_finished")
	$Interface.modulate_alpha($Interface/GameOverMessage/Winner/OKButton, 0)
	state = STATE.RESULTS
	
func _discard_hand_finished():
	house_hand.disconnect("_discard_hand_finished", self, "_discard_hand_finished")
	$Interface.modulate_alpha($Interface/GameOverMessage/Winner/OKButton, 1)
	state = STATE.READY

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
		
			# Update score
			$Interface/Score.target_score = str(player_hand.total)
			
			# End game on blackjack or bust
			if player_hand.total > 21 or player_hand.total == 21:
				if player_hand.total == 21:
					$Interface/Score/StarParticles.emitting = true
				state = STATE.HOUSE_FINAL_TURN
			
		$Deck.remove_top_card()

func get_winner():
	var new_winner
	
	var house = house_hand.total
	var player = player_hand.total
	
	if player > 21: # Player BUST
		new_winner = [PLAYERS.HOUSE, "You BUST!", "HOUSE WINS!", true]
		
	elif player == 21: # Player BLACKJACK
		if house == 21: # House BLACKJACK
			new_winner = [PLAYERS.HOUSE, "Both BLACKJACK!", "HOUSE WINS!", true]
		else:
			new_winner = [PLAYERS.USER, "BLACKJACK!", "YOU WIN!", false]
			
	else: # Player UNDER
		if house > 21: # House BUST
			new_winner = [PLAYERS.USER, "House BUST!", "YOU WIN!", false]
		elif house == 21: # House BLACKJACK
			new_winner = [PLAYERS.HOUSE, "House BLACKJACK!", "HOUSE WINS!", false]
		elif player > house: # Player CLOSER
			new_winner = [PLAYERS.USER, "You're CLOSER!", "YOU WIN!", false]
		elif player == house: # Tie
			new_winner = [PLAYERS.HOUSE, "Both CLOSE!", "HOUSE WINS!", false]
		else: # House CLOSER
			new_winner = [PLAYERS.HOUSE, "House CLOSER!", "HOUSE WINS!", false]
	
	# Array [ winning_player, win_message, winner_message, quick_reveal]
	return new_winner

func show_results():
	var player_won = false
	if winner and len(winner) == 4:
		if winner[0] == PLAYERS.USER:
			player_won = true
		$Interface/GameOverMessage.text = winner[1]
		$Interface/GameOverMessage/Winner.text = winner[2]
		$Interface.show_results(player_won)

func play_again():
	if state == STATE.READY:
		$Interface.hide_results()
		house_hand.get_node("Score/Score").text = '0'
		winner = null
		start_game()

var delay_beats = 1
func _on_timeout():
	if state == STATE.DEALING_HOUSE:
		deal()
		
	elif state == STATE.DEALING_PLAYER:
		deal()
		
	elif state == STATE.PLAYER_TURN:
		$Interface.enable_buttons()
		
	elif state == STATE.HOUSE_TURN:
		if delay_beats == 0:
			delay_beats = 1
			house_turn()
		else:
			delay_beats -= 1
			
	elif state == STATE.HOUSE_FINAL_TURN:
		if delay_beats == 0:
			delay_beats = 1
			house_turn()
		else:
			delay_beats -= 1
		
	elif state == STATE.REVEAL_HOUSE:
		winner = get_winner()
		house_hand.reveal_hand(winner[3])
		state = STATE.READY
		
	elif state == STATE.RESULTS:
		show_results()
		state = STATE.DISCARD_HANDS
		
	elif state == STATE.DISCARD_HANDS:
		player_hand.discard_hand()
		house_hand.discard_hand()
		state = STATE.READY
		delay_beats = 1
