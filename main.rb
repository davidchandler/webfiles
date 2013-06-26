require 'rubygems'
require 'sinatra'
set :sessions, true
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
end
before do

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
  erb :new_player
end
post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end
get '/game' do
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
  erb :game
end
post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    @success = "Congratulations! #{session[:player_name]} hit blackjack!"
    @show_player_hit_or_stay_buttons = false
  elsif player_total > 21
    @error = "Sorry, it looks like #{session[:player_name]} busted."
    @show_player_hit_or_stay_buttons = false
  end
  erb :game
end
post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_player_hit_or_stay_buttons = false

  redirect '/dealerturn' 

end

get '/dealerturn' do

  @show_player_hit_or_stay = false
  @show_dealer_hit_or_stay = true

#  session[:dealer_cards] << session[:deck].pop
  dealer_total = calculate_total(session[:dealer_cards])

  #if dealer_total >= 17
  #  redirect '/comparehands' 
  #end

  if dealer_total == 21
    @success = "Congratulations! Dealer hit blackjack!"
    @show_dealer_hit_or_stay_buttons = false
  elsif dealer_total > 21
    @error = "Sorry, it looks like Dealer busted."
    @show_dealer_hit_or_stay_buttons = false
  end

  erb :game
end


post '/game/dealer/hit' do

 # if dealer_total >= 17
 #   redirect '/comparehands' 
 # end

  session[:dealer_cards] << session[:deck].pop
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == 21
    @success = "Congratulations! Dealer hit blackjack!"
    @show_dealer_hit_or_stay_buttons = false
  elsif dealer_total > 21
    @error = "Sorry, it looks like Dealer busted."
    @show_dealer_hit_or_stay_buttons = false
  end
  
  erb :game
end

post '/game/dealer/stay' do
  @success = "Dealer has chosen to stay."
  @show_dealer_hit_or_stay_buttons = false

  redirect '/comparehands' 
end

get '/comparehands' do






end  



