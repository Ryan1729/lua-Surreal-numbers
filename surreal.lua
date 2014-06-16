-- Surreal Numbers Lua module
-- 
-- This module implements John H. Conway's Surreal numbers 
-- see here: http://en.wikipedia.org/wiki/Surreal_numbers
--

 
--we need our own copy of some function because defining our own envionment 
-- below will stop us from seeing global variables.
local unpack = unpack
--for debugging only
local print = print 

-- This next part is just so I don't have to type Surreal.foo internally
-- Found here: http://lua-users.org/wiki/ModulesTutorial
local Surreal = {}
if setfenv then
	setfenv(1, Surreal) -- for Lua 5.1
else
	_ENV = Surreal -- for Lua 5.2 and above
end

-- Here's the interesting part

function makeSurrealNumber(leftSet, rightSet)
    return {left = leftSet, right = rightSet}
end

------------------------------------------
-- Relation functions
------------------------------------------

--returns true if x <= y, false otherwise
function isLessThanOrEqual(x, y)
    -- the definition of <= for surreal numbers is as follows:
    -- A surreal number x is <= to a surreal number y iff 
    -- y is <= to no member of x's left set and no member of y's right set is <= x
    
    --the empty set satisfies no relation
    if x == nil or y == nil then
        return false
    end
    
    -- given we were actually passed numbers,
    -- first we check if y is <= to no member of x's left set
    
    if isLessThanOrEqual(y, x.left) then
        return false
    end
    
    -- then if we haven't already found that x > y,
    -- we check if no member of y's right set is <= x 
    
    if isLessThanOrEqual(y.right, x) then
        return false
    end
    
    return true
end

--returns false if x <= y, true otherwise
function isNotLessThanOrEqual(x, y)
    return not isLessThanOrEqual(x, y)
end

--returns true if x >= y, false otherwise
function isGreaterThanOrEqual(x, y)
    return isLessThanOrEqual(y, x)
end

--returns false if x >= y, true otherwise
function isNotGreaterThanOrEqual(x, y)
    return not isGreaterThanOrEqual(x, y)
end

--returns true if x < y, false otherwise
function isLessThan(x, y)
    return isLessThanOrEqual(x, y) and not isLessThanOrEqual(y, x)
end

--returns true if x > y, false otherwise
function isGreaterThan(x, y)
    return isLessThan(y, x)
end

--returns true if x = y, false otherwise
function isEqual(x, y)
    return isLessThanOrEqual(x, y) and isLessThanOrEqual(y, x)
end

--returns true if x != y, false otherwise
function isNotEqual(x, y)
    return not isEqual(x, y)
end

------------------------------------------
-- numericity testing functions
------------------------------------------

function isNumeric(x)
    -- Something with the form of a surreal number is numeric if the 
    -- intersection of its left and right sets is the empty set and
    -- each element of its right set is greater than every element of 
    -- its left set.
    
    if type(x) ~= "table" then
        --If it doesn't look like a surreal number, it's not a surreal number
        return false
    end
    
    for key1, value1 in pairs(x.right) do
        for key2, value2 in pairs(x.left) do
            if isNotGreaterThan(value1, value2) then
                return false
            end
        end
    end
    
    return true
end

function isNotNumeric(x)
    return not isNumeric(x)
end

------------------------------------------
-- Addition and Subtraction
------------------------------------------

-- this is a helper function which will not be visible except inside the module
local function nilFilter(set1,set2, comparsionFunction)

    if set1 ~= nil and set2 ~= nil then
        -- We only need one member of the new set to 
        -- keep the new number at the same value.
        if comparsionFunction(set1, set2) then 
            return set1
        else
            return set2
        end
    elseif set1 ~= nil then
        return set1
    else 
    -- this returns nil iff set1 and set2 are nil
        return set2
    end

end

-- returns the sum of x and y, i.e. x + y
function add(x, y)
    --the empty set + anything = the empty set
    if x == nil or y == nil then
        return nil
    end
    
    -- the definition of additon for surreal numbers is as follows:
    --a + b = { a.left + b, a + b.left | a.right + b, a + b.right}
    
    local result = {}
    
    local left1 = add(x.left, y)
    local left2 = add(x, y.left)
    local right1 = add(x.right, y)
    local right2 = add(x, y.right)
    
    -- We only need the largest member of the new left set to 
    -- keep the new number at the same value.
    result.left = nilFilter(left1, left2, isGreaterThan)
    
    -- We only need the smallest member of the new left set to 
    -- keep the new number at the same value.
    result.right = nilFilter(right1, right2, isLessThan)
    
    return result
end

-- returns the inverse of x, i.e. -x
function inverse(x)

    if x == nil then
    -- the empty set is its own inverse
        return nil
    end
    
    local result = {}
    -- the definition of unary minus for surreal numbers is:
    -- { -x.right | -x.left }
    result.left  = inverse(x.right)
    result.right = inverse(x.left)
    
    return result
end

-- returns the difference of x and y, i.e. x - y
function minus(x, y)
    return add(x, inverse(y))
end

------------------------------------------
-- Multiplication
------------------------------------------

-- returns the product of x and y, i.e. x * y
function times(x, y)
    --the empty set * anything = the empty set
    if x == nil or y == nil then
        return nil
    end
    
    -- the definition of additon for surreal numbers is as follows:
    --a * b = { a.left  * b + a * b.left  - (a.left  * b.left ), 
    --          a.right * b + a * b.right - (a.right * b.right) |
    --          a.left  * b + a * b.right - (a.left  * b.right),
    --          a.right * b + a * b.left  - (a.right * b.left ) }
    
     
    local left1 = add( 
                        add( times(x.left, y) , times(x, y.left) ), 
                        inverse( times(x.left, y.left) )
                     )
                     
    local left2 = add( 
                        add( times(x.right, y) , times(x, y.right) ), 
                        inverse( times(x.right, y.right) )
                     )
    
    local right1 = add( 
                        add( times(x.left, y) , times(x, y.right) ), 
                        inverse( times(x.left, y.right) )
                     )
                     
    local right2 = add( 
                        add( times(x.right, y) , times(x, y.left) ), 
                        inverse( times(x.right, y.left) )
                     )
    
    local result = {}
    
    -- We only need the largest member of the new left set to 
    -- keep the new number at the same value.
    result.left = nilFilter(left1, left2, isGreaterThan)
    
    -- We only need the smallest member of the new left set to 
    -- keep the new number at the same value.
    result.right = nilFilter(right1, right2, isLessThan)
    
    return result
end

return Surreal
