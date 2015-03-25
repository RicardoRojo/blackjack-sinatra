require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?

SUITS = ["clubs","spades","diamonds","hearts"]
CARD_VALUE = ["2","3","4","5","6","7","8","9","10","ace","jack","queen","king"]
BLACKJACK = 21
DEALER_MIN_TO_STAY = 17
PLAYER_BROKE = 0

configure :development do   
  set :bind, '0.0.0.0'   
  set :port, 3000 # Not really needed, but works well with the "Preview" menu option
end
set :sessions, true

helpers do
  def give_card(deck)
    deck << session[:deck].pop
  end

  def show_card_image(card)
    source = "/images/cards/#{card[0]}_#{card[1]}.jpg"
    alt = "#{card[0]} #{card[1]}"
    "<img src=#{source} alt=#{alt} class='card'>"
  end

  def calculate_total(deck)
    total = 0
    aces = 0
    deck.each do |card|
      if card[1].to_i == 0
        if card[1] == "ace"
          total += 1
          aces += 1
        else
          total += 10
        end
      else
        total += card[1].to_i
      end
    end
    if aces > 0 && total + 10 <= BLACKJACK
      total += 10
    end
    total
  end

  def player_win?(deck)
    calculate_total(deck) == BLACKJACK
  end

  def player_is_busted?(deck)
    calculate_total(deck) > BLACKJACK
  end

  def dealer_stays?
    calculate_total(session[:dealer_deck]) >= DEALER_MIN_TO_STAY
  end

  def compare_decks
    total_player = calculate_total(session[:player_deck])
    total_dealer = calculate_total(session[:dealer_deck])
    if total_player > total_dealer
      @winner = "#{session[:player_name]} Wins!!. Your total was #{total_player}, dealer total was #{total_dealer}"
      increase_player_money(session[:bet]*2)
    elsif total_player < total_dealer
      @loser = "Sorry, you lose. Your total was #{total_player}, dealer total was #{total_dealer}"
    else
      @loser = "Is a tie to #{total_player}"
      increase_player_money(session[:bet])
    end
  end

  def increase_player_money(money)
    session[:money_available] += money
  end

  def reset_bet
    session[:bet] = 0
  end

  def game_ended!
    @game_ended = true
    reset_bet
  end

  def check_player_win
    if player_win?(session[:player_deck])
      @winner = "#{session[:player_name]} Wins!!"
      increase_player_money(session[:bet]*2)
      game_ended!
    end
  end

  def check_dealer_win
    if player_win?(session[:dealer_deck])
      @loser = "Sorry, dealer wins!!"
      game_ended!
    end
  end
end

# end of helpers

before do
  @game_ended = false
end

get '/' do
  if session[:player_name] && session[:money_available] > PLAYER_BROKE
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  session[:money_available] = 500
  erb :new_player
end

post '/new_player' do
  session[:player_name] = params[:player_name].capitalize
  if session[:player_name].empty?
    @error = "name is required"
    halt (erb :new_player)
  end
  redirect '/bet'
end

get '/game' do
  session[:deck] = SUITS.product(CARD_VALUE).shuffle!
  session[:player_deck] = []
  session[:dealer_deck] = []
  session[:current_player] = 'player'

  give_card(session[:player_deck])
  give_card(session[:dealer_deck])
  give_card(session[:player_deck])
  give_card(session[:dealer_deck])

  check_player_win

  erb :game
end

post '/player/hit' do
  give_card(session[:player_deck])
  check_player_win

  if player_is_busted?(session[:player_deck])
    @loser = "Sorry, #{session[:player_name]} is busted!!"
    game_ended!
  end

  erb :game, layout: false
end

post '/player/stay' do
  session[:current_player] = "dealer"

  check_dealer_win

  if dealer_stays?
    compare_decks
    game_ended!
  end
  erb :game, layout: false
end

post '/dealer/hit' do
  give_card(session[:dealer_deck])
  check_dealer_win

  if player_is_busted?(session[:dealer_deck])
    @winner = "#{session[:player_name]} Wins. Dealer busted"
    increase_player_money(session[:bet]*2)
    game_ended!
  elsif dealer_stays?
    compare_decks
    game_ended!
  end
  erb :game, layout: false
end

get '/game_over' do
  erb :game_over
end

get '/bet' do
  if session[:money_available] == 0
    redirect '/game_over'
  end
  erb :bet
end

post '/bet' do

  if params[:bet].to_i.between?(1,session[:money_available])
    session[:bet] = params[:bet].to_i
    session[:money_available] -= params[:bet].to_i
    redirect '/game'
  else
    @error = "wrong bet"
    erb :bet
  end
end

