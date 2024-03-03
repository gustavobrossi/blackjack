Card = {}

function Card.create(suit, value)
    local self = setmetatable({}, Card)
    self.suit = suit
    self.value = value
    self.img = love.graphics.newImage( "img/" .. self.value .. "-of-" .. self.suit .. ".png" )
    return self
end
