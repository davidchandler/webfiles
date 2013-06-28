require 'rubygems'
require 'sinatra'
set :sessions, true
BLACKJACK_AMOUNT = 21
helpers do
  def calculate_total(cards) # cards is [["H", "3"], ["D", "J"], ... ]
    arr = cards.map{|element| element[1]}
    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end
    #correct for Aces
    arr.select{|element| element == "A"}.count.times do
      break if total <= 21
      total -= 10
    end
    total
  end
  def card_image(card) # ['H', '4']
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end
    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @loser = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @winner = "<strong>It's a tie!</strong> #{msg}"
  end


end
before do
  @play_again = true
  @show_player_hit_or_stay = true
  @show_dealer_hit_or_stay = false
  @show_player_hit_or_stay_buttons = true
  @show_dealer_hit_or_stay_buttons = true
end
get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end
get '/new_player' do
  session[:player_pot] = 500
  erb :new_player
end
post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
 
  redirect '/bet'
end

get '/bet' do
 session[:player_bet] = nil
 erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount cannot be greater than what you have ($#{session[:player_pot]})"
    halt erb(:bet)
  else #happy path
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end


get '/game' do
  session[:turn] = session[:player_name]
  # create a deck and put it in session
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle! # [ ['H', '9'], ['C', 'K'] ... ]
  # deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  session[:show_player_hit_or_stay] = true
  session[:show_dealer_hit_or_stay] = false
  erb :game
end
post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} 1hit blackjack.")
    #@success = "Congratulations! #{session[:player_name]} hit blackjack!"
    @show_player_hit_or_stay_buttons = false
  elsif player_total > BLACKJACK_AMOUNT
    loser!("It looks like #{session[:player_name]} 2busted at #{player_total}.")
    #@error = "Sorry, it looks like #{session[:player_name]} busted."
    @show_player_hit_or_stay_buttons = false
  end
  erb :game, layout: false
end
post '/game/player/stay' do
  @success = "#{session[:player_name]} 3has chosen to stay."
  @show_player_hit_or_stay_buttons = false
  @show_dealer_hit_or_stay_buttons = false

    redirect '/dealerturn'

end

get '/dealerturn' do

  session[:turn] = "dealer"

  session[:show_player_hit_or_stay] = false
  session[:show_dealer_hit_or_stay] = true

  @show_player_hit_or_stay = false
  @show_dealer_hit_or_stay = true

#  session[:dealer_cards] << session[:deck].pop
  dealer_total = calculate_total(session[:dealer_cards])

 
  if dealer_total == BLACKJACK_AMOUNT
   loser!("4Dealer hit blackjack.")
#    @success = "Dealer hit blackjack!"
    @show_dealer_hit_or_stay_buttons = false
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("5Dealer busted at #{dealer_total}.")
   # @error = "It looks like Dealer busted. You Win"
    @show_dealer_hit_or_stay_buttons = false
  end

   if dealer_total >= 17
     @show_dealer_hit_or_stay_buttons = false
     redirect '/game/compare'
   end

  erb :game
end


post '/game/dealer/hit' do

 

  session[:dealer_cards] << session[:deck].pop
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
   loser!("6Dealer hit blackjack.")
   # @success = "Congratulations! Dealer hit blackjack!"
    @show_dealer_hit_or_stay_buttons = false
  elsif dealer_total > BLACKJACK_AMOUNT
     winner!("7Dealer busted at #{dealer_total}.")
#    @error = "Sorry, it looks like Dealer busted."
    @show_dealer_hit_or_stay_buttons = false
  end

  if dealer_total >= 17
    @show_dealer_hit_or_stay_buttons = false
    redirect '/game/compare'
  end
 
  erb :game
end

post '/game/dealer/stay' do
  @success = "8Dealer has chosen to stay."
  @show_dealer_hit_or_stay_buttons = false
  redirect '/game/compare'
end

get '/game/compare' do

  playervalue = calculate_total(session[:player_cards])
  dealervalue = calculate_total(session[:dealer_cards])
 
  if playervalue < dealervalue
    loser!("#{session[:player_name]} 9stayed at #{playervalue}, and the dealer stayed at #{dealervalue}.")
    #@error = "Sorry, you lost."
  elsif playervalue > dealervalue
    winner!("#{session[:player_name]} 10stayed at #{playervalue}, and the dealer stayed at #{dealervalue}.")
    #@success = "Congrats, you won!"
  else
    tie!("Both #{session[:player_name]} 11and the dealer stayed at #{playervalue}.")
    #@success = "It's a tie!"
  end
  #erb :game, layout: false
end

get 'game_over' do

erb  :game_over

end

 