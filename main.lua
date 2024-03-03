require("card")

-- Encapsulate window settings in a table to keep the global namespace
local windowSettings = {
    width = 900,
    height = 600,
    scale = 0.66,
    padding = 36, -- Computed as 900 * 0.04, but directly assigning to improve readability
    slotWidth = 0 -- Will be calculated based on card width, initialized here for clarity
}

-- Players table to manage player and computer states separately for better game logic encapsulation
local players = {
    human = {
        hand = {}, -- Cards in hand
        score = 0, -- Total score
        hold = false -- Flag to indicate if the player holds
    },
    computer = {
        hand = {},
        score = 0,
        hold = false
    }
}

-- Dealer table to manage the deck, including suits, values, and the deck itself
local dealer = {
    suits = { "hearts", "spades", "clubs", "diamonds" },
    values = { "Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King" },
    deck = {} -- Empty table to be filled with cards
}

-- Initialize the game window with title and dimensions from windowSettings
love.window.setTitle('Blackjack') -- Set the window title for the game
love.window.setMode(windowSettings.width, windowSettings.height) -- Set window dimensions

-- Function to create and shuffle a deck of cards
local function createDeck()
    dealer.deck = {} -- Reset the deck to an empty table before populating it

    -- Populate the deck with all possible combinations of suits and values
    for _, suit in ipairs(dealer.suits) do
        for _, value in ipairs(dealer.values) do
            -- Create a new card with the given suit and value, using a more descriptive method name if available
            local card = Card.create(suit, value) -- Assuming Card.create is a method that initializes card objects
            table.insert(dealer.deck, card) -- Insert the created card into the deck
        end
    end

    -- Shuffle the deck to ensure a random distribution of cards
    math.randomseed(os.time()) -- Seed the RNG with current time to get different shuffle results
    for i = #dealer.deck, 2, -1 do -- Loop backward through the deck
        local j = math.random(i) -- Select a random index from 1 to i
        dealer.deck[i], dealer.deck[j] = dealer.deck[j], dealer.deck[i] -- Swap the current card with the randomly selected card
    end
    print("Deck created and shuffled") -- Log the completion of deck creation and shuffling
end

-- Function to generate a random card from the deck
local function generateRandomCard()
    if #dealer.deck == 0 then
        print("The deck is empty. Cannot generate a new card.")
        return nil -- Early return if the deck is empty to avoid errors
    end

    local randomIndex = math.random(1, #dealer.deck) -- Select a random index in the deck
    local card = table.remove(dealer.deck, randomIndex) -- Remove the card from the deck to prevent duplicates
    return card -- Return the randomly selected card
end

-- Function to determine the numeric value of a card's face
local function getCardValue(face)
    -- Handle face cards (Jack, Queen, King) which are all worth 10 points
    if face == "Jack" or face == "King" or face == "Queen" then
        return 10
    elseif face == "Ace" then
        -- Return 11 for Aces, but calling code will need to adjust based on context
        return 11
    else
        -- For numbered cards, convert the face to a number
        return tonumber(face)
    end
end

-- Function to reset the game to its initial state
local function resetGame()
    -- Reset player states to their initial values
    for _, player in pairs(players) do
        player.score = 0
        player.hand = {}
        player.hold = false
    end

    createDeck() -- Reinitialize the deck for a new game
    print("Game reset") -- Log the reset action for debugging purposes
end

-- Function to determine the winner of the game based on blackjack rules
local function determineWinner()
    local winner

    -- Check if both players have exceeded 21, resulting in a bust
    if players.human.score > 21 and players.computer.score > 21 then
        winner = "Bust"
    -- Check if the human player has a score of 21 or less and has a higher score than the computer, or if the computer has busted
    elseif players.human.score <= 21 and (players.human.score > players.computer.score or players.computer.score > 21) then
        winner = "You"
    -- Check for a tie if both players have the same score and it's 21 or under
    elseif players.human.score == players.computer.score and players.human.score <= 21 then
        winner = "Tie"
    -- If none of the above conditions are met, the computer wins
    else
        winner = "Computer"
    end

    return winner
end

-- Function to dynamically adjust the value of an Ace card
local function adjustAceValue(playerScore, card)
    -- Check if the drawn card is an Ace
    if card.value == "Ace" then
        -- If adding 11 keeps the score at 21 or below, count the Ace as 11; otherwise, count it as 1
        if playerScore + 11 <= 21 then
            return 11
        else
            return 1
        end
    else
        -- For non-Ace cards, return the normal card value
        return getCardValue(card.value)
    end
end

-- Handles mouse release events in the Love2D game window
function love.mousereleased(x, y, button)
    -- Reset the game if both players have decided to hold and the human player's score is more than 1
    if players.human.hold and players.computer.hold and players.human.score > 1 then
        resetGame() -- Reset game for another round
    end

    -- If the human player has not yet decided to hold
    if not players.human.hold then
        -- Check if the left mouse button was clicked within the designated area or if it's the start of the game
        if button == 1 and ((x > windowSettings.width - windowSettings.slotWidth - windowSettings.padding and y < windowSettings.slotWidth * 1.5) or players.human.score == 0) then
            local card = generateRandomCard() -- Draw a randomly generated card
            table.insert(players.human.hand, card) -- Add the drawn card to the human player's hand
            local cardValue = adjustAceValue(players.human.score, card)
            -- Update the human player's score with the value of the drawn card
            players.human.score = players.human.score + cardValue
            print("Player drew a card: " .. card.value .. " of " .. card.suit .. " (" .. players.human.score .. ")")
        else
            -- The player chooses to hold
            players.human.hold = true
        end
    end

    -- Invoke the computer's turn to draw a card
    computerDraw()
end

-- Function for the computer's turn to draw cards based on AI logic
function computerDraw()
    -- If the human player has decided to hold, evaluate if the computer should also hold
    if players.human.hold and not players.computer.hold then
        -- Computer decides to hold if it has a higher score than the human or if its score is over 17 and not busted
        if players.computer.score > players.human.score or (players.computer.score > 17 and players.human.score < 22) then
            players.computer.hold = true
            return -- Early return to skip drawing a card
        end
    end

    -- If the computer has not decided to hold, draw a card
    if not players.computer.hold then
        local card = generateRandomCard() -- Draw a randomly generated card
        table.insert(players.computer.hand, card) -- Adding the drawn card to the computer's hand
        local cardValue = adjustAceValue(players.computer.score, card)
        -- Update the computer's score with the value of the drawn card
        players.computer.score = players.computer.score + cardValue
        print("Computer drew a card: " .. card.value .. " of " .. card.suit .. " (" .. players.computer.score .. ")")

        -- Re-evaluate if the computer should hold after drawing
        if players.human.hold and (players.computer.score > players.human.score or players.computer.score > 17) then
            players.computer.hold = true
        end
    end
end

function love.load()
    -- Initialize the deck of cards for the game
    createDeck() -- Create and shuffle a whole new deck of card

    -- Load the back of a card as a placeholder for the deck
    -- Updated to reflect a more descriptive method name, assuming `Card.create` is used for initializing card objects
    playback = Card.create("card", "back") -- This assumes Card.create returns a card object with an 'img' property

    -- Calculate the slot width based on the card back image and the window scale
    windowSettings.slotWidth = playback.img:getWidth() * windowSettings.scale

    -- Set the background color of the game window to a green resembling a traditional card table
    love.graphics.setBackgroundColor(0.3, 0.5, 0.3)

    -- Load and set the game's font for drawing text on the screen
    font = love.graphics.newFont("font/Sniglet-webfont.ttf", 42) -- Corrected method name for setting a new font

    print("Game loaded") -- Log message indicating the game has loaded successfully
end

function love.draw()
    -- Set the previously loaded font for drawing text
    love.graphics.setFont(font)

    -- Instructions for the player
    love.graphics.printf("Click deck to deal.", windowSettings.padding, 66, windowSettings.width, 'left')
    love.graphics.printf("Click anywhere to hold.", windowSettings.padding, 122, windowSettings.width, 'left')

    -- Draw the deck's back image indicating where to click to draw a card
    love.graphics.draw(playback.img, windowSettings.width - windowSettings.slotWidth - windowSettings.padding, windowSettings.padding, 0, windowSettings.scale, windowSettings.scale)

    -- Draw the human player's hand
    for i, card in ipairs(players.human.hand) do
        love.graphics.draw(card.img, windowSettings.padding * i, windowSettings.padding * i, 0, windowSettings.scale, windowSettings.scale)
    end

    -- Draw the computer's hand with a different color to distinguish it
    for i, card in ipairs(players.computer.hand) do
        love.graphics.setColor(0.7, 0.8, 0.7) -- Set color for computer's cards
        love.graphics.draw(card.img, (windowSettings.width * 0.33) + (76) + (windowSettings.padding * i), windowSettings.padding * i, 0, windowSettings.scale, windowSettings.scale)
        love.graphics.setColor(1, 1, 1) -- Reset color to default after drawing
    end

    -- Display the current scores or the winner, depending on the game state
    if not players.human.hold or not players.computer.hold then
        love.graphics.printf("You: " .. players.human.score .. " vs. Computer: " .. players.computer.score, 0, windowSettings.height - 76, windowSettings.width, 'center')
    else
        local winnerText = determineWinner() -- Determine the winner for the round
        love.graphics.printf("Winner: " .. winnerText .. "!!!", 0, windowSettings.height - 76, windowSettings.width, 'center')
    end
end

function love.update(dt)
    -- Check if either player has reached or exceeded a score of 21
    if players.human.score >= 21 or players.computer.score >= 21 then
        -- If so, both players should hold to stop drawing cards
        players.human.hold = true
        players.computer.hold = true
    end

    -- If the computer's score is over 17 and higher than the human's score,
    -- or if the human has already held, the computer will also hold
    if players.computer.score > 17 and players.computer.score > players.human.score then
        players.computer.hold = true
    end

    -- If the human player has held and the computer has not, and the computer's score is less than the human's,
    -- the computer will draw another card, attempting to improve its score
    if players.human.hold and not players.computer.hold and players.computer.score < players.human.score then
        computerDraw() -- Call the function for the computer to draw a card
    end
end
