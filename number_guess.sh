#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

printf 'Enter your username: '
IFS= read -r username || exit 1
escaped_username=$(printf '%s' "$username" | sed "s/'/''/g")
user_stats=$($PSQL "SELECT games_played || '|' || best_game FROM users WHERE username = '$escaped_username';")

if [[ -n $user_stats ]]; then
  games_played=${user_stats%%|*}
  best_game=${user_stats#*|}
  printf 'Welcome back, %s! You have played %s games, and your best game took %s guesses.\n' "$username" "$games_played" "$best_game"
else
  printf 'Welcome, %s! It looks like this is your first time here.\n' "$username"
fi

secret_number=$(( RANDOM % 1000 + 1 ))
number_of_guesses=0
printf 'Guess the secret number between 1 and 1000:\n'

while true; do
  IFS= read -r guess || exit 1
  ((number_of_guesses++))

  if ! [[ $guess =~ ^[0-9]+$ ]]; then
    printf 'That is not an integer, guess again:\n'
    continue
  fi

  guess_number=$((10#$guess))
  if (( guess_number < secret_number )); then
    printf "It's higher than that, guess again:\n"
  elif (( guess_number > secret_number )); then
    printf "It's lower than that, guess again:\n"
  else
    printf 'You guessed it in %s tries. The secret number was %s. Nice job!\n' "$number_of_guesses" "$secret_number"
    $PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$escaped_username', 1, $number_of_guesses) ON CONFLICT (username) DO UPDATE SET games_played = users.games_played + 1, best_game = LEAST(users.best_game, EXCLUDED.best_game);" >/dev/null
    break
  fi
done
