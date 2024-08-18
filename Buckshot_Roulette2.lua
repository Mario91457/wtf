local Tools = {"Handcuffs", "Cigarettes", "Inverter", "Knife", "Magnifier"}
local Help = {
    Handcuffs = "Gives you another try",
    Cigarettes = "+1 Health",
    Inverter = "Invert the shell's type",
    Knife = "2 Damage per Shot",
    Magnifier = "View current round"
}
local MaxTools = 8
local userHealth = 6
local botHealth = 6
local Turn = "User"

-- Gun
local Blank = 0
local Live = 0
local Rounds = {}

-- Stats
local gunDamage = 1
local userHandcuffed = false
local botHandcuffed = false
local userTools = {}
local botTools = {}

math.randomseed(os.time())

local function printStats()
    print("---------------------------------")
    print(string.format("Your lives left: %d\nBot lives left: %d\n", userHealth, botHealth))
    print("---------------------------------")
end

local function getRandomNumber(x, d)
    return math.random(x, d)
end

local function input(expected_type, min, max)
    local val
    local limitEnabled = (min ~= nil and max ~= nil)

    repeat
        -- Read user input
        val = io.read()

        -- Convert to the expected type if necessary
        if expected_type == "number" then
            val = tonumber(val)
        end

        -- Check type
        if type(val) ~= expected_type then
            print("Invalid type. Expected type: " .. expected_type)
            val = nil
        elseif limitEnabled then
            -- Apply limits if min and max are both provided
            if expected_type == "number" and (val < min or val > max) then
                print(string.format("Value must be between %d and %d.", min, max))
                val = nil
            end
        end
    until val ~= nil and type(val) == expected_type

    return val
end

local function generateRounds(num)
    repeat
        Live = 0
        Blank = 0
        Rounds = {}
        for i = 1, num do
            local random = getRandomNumber(0, 10)
            if random > 5 then
                Live = Live + 1
                table.insert(Rounds, "Live")
            else
                Blank = Blank + 1
                table.insert(Rounds, "Blank")
            end
        end
    until Live ~= 0 and Blank ~= 0
end

local function generateTools(num, mergeTo)
    for i = 1, num do
        if #mergeTo == MaxTools then return end
        local random = getRandomNumber(1, #Tools)
        table.insert(mergeTo, Tools[random])
    end
end

local function handleTools(toolTable, toolIndex, who)
    local tool = toolTable[toolIndex]
    
    if tool == "Handcuffs" then
        if who == "Bot" then
            userHandcuffed = true
        else
            botHandcuffed = true
        end
    elseif tool == "Cigarettes" then
        if who == "User" then
            userHealth = userHealth + 1
        else
            botHealth = botHealth + 1
        end
    elseif tool == "Inverter" then
        if #Rounds > 0 then
            for i, v in ipairs(Rounds) do
                Rounds[i] = (v == "Live") and "Blank" or "Live"
            end
        end
    elseif tool == "Knife" then
        gunDamage = 2
    elseif tool == "Magnifier" then
        if who == "User" then
            print("---------------------------------")
            print("Magnifier: " .. Rounds[#Rounds])
            print("---------------------------------")
        else
            return Rounds[#Rounds]
        end
    end
end

local function handleBotAttack(target)
    print("---------------------------------")
    if target == "User" then
        if Rounds[#Rounds] == "Live" then
            print("Bot shot you with a: Live round")
            userHealth = userHealth - gunDamage
        else
            print("Bot shot you with a: Blank round")
        end
        gunDamage = 1
        if not userHandcuffed then
            Turn = "User"
        else
            userHandcuffed = false
        end
    elseif target == "Bot" then
        if Rounds[#Rounds] == "Live" then
            print("Bot shot himself with a: Live round")
            botHealth = botHealth - gunDamage
        else
            print("Bot shot himself with a: Blank round")
        end
        gunDamage = 1
        Turn = "User"
    end
    printStats()
    print("---------------------------------")
end

local function newMatch()
    while userHealth > 0 and botHealth > 0 do
        if #Rounds == 0 then
            generateRounds(getRandomNumber(3, 8))
            local rand = getRandomNumber(1, 4)
            generateTools(rand, userTools)
            generateTools(rand, botTools)
            print("---------------------------------")
            print(string.format("Live Rounds: %d\nBlank Rounds: %d", Live, Blank))
            print("---------------------------------")
        end

        if Turn == "User" then
            print("---------------------------------")
            print("[1]: Use Gun\n[2]: Use Tools\n[3]: Tool Help")
            print("---------------------------------")
            local choice = input("number", 1, 3)
            if choice == 1 then
                print("\nWho do you want to shoot?\n[Bot]: 1\n[Yourself]: 2")
                local whoToShoot = input("number", 1, 2)
                local target = (whoToShoot == 1) and "Bot" or "User"

                if Rounds[#Rounds] == "Live" then
                    print("---------------------------------")
                    print("\nLive round")
                    if target == "Bot" then
                        botHealth = botHealth - gunDamage
                    else
                        userHealth = userHealth - gunDamage
                    end
                else
                    print("\nBlank round")
                end

                gunDamage = 1
                if target == "Bot" then
                    if not botHandcuffed then
                        Turn = "Bot"
                    else
                        botHandcuffed = false
                    end
                elseif target == "User" then
                    Turn = "Bot"
                end

                printStats()
                table.remove(Rounds, #Rounds)
                print("---------------------------------")
            elseif choice == 2 then
                if #userTools == 0 then
                    print("---------------------------------")
                    print("No tools left")
                    print("---------------------------------")
                else
                    print("\nChoose an item")
                    for i, v in ipairs(userTools) do
                        print(string.format("[%d]: %s", i, v))
                    end
                    print("\n")

                    local toolIndex = input("number", 1, #userTools)
                    if userTools[toolIndex] ~= "Handcuffs" or not botHandcuffed then
                        print("---------------------------------")
                        print("Used: " .. userTools[toolIndex])
                        print("---------------------------------")
                        handleTools(userTools, toolIndex, "User")
                        table.remove(userTools, toolIndex)
                    else
                        print("---------------------------------")
                        print("Bot already handcuffed")
                        print("---------------------------------")
                    end
                end
            elseif choice == 3 then
                print("---------------------------------")
                for i, v in pairs(Help) do
                    print(string.format("[%s]: %s", i, v))
                end
                print("\n")
                print("---------------------------------")
            end
        elseif Turn == "Bot" then
            local Magnifier
            for i, v in ipairs(botTools) do
                local rand = (getRandomNumber(0, 1) == 1)

                if v == "Handcuffs" then
                    handleTools(botTools, i, "Bot")
                    print("---------------------------------")
                    print("Bot used: Handcuffs")
                    print("---------------------------------")
                elseif v == "Cigarettes" then
                    handleTools(botTools, i, "Bot")
                    print("---------------------------------")
                    print("Bot used: Cigarettes")
                    print("---------------------------------")
                elseif v == "Inverter" and rand then
                    handleTools(botTools, i, "Bot")
                    print("---------------------------------")
                    print("Bot used: Inverter")
                    print("---------------------------------")
                elseif v == "Magnifier" and not Magnifier then
                    Magnifier = handleTools(botTools, i, "Bot")
                    print("---------------------------------")
                    print("Bot used: Magnifier")
                    print("---------------------------------")
                elseif v == "Knife" and (Blank == 0 and Live > 0 or Magnifier == "Live") then
                    handleTools(botTools, i, "Bot")
                    print("---------------------------------")
                    print("Bot used: Knife")
                    print("---------------------------------")
                end
                table.remove(botTools, i)
            end

            if Magnifier == "Live" then
                handleBotAttack("User")
            elseif Magnifier == "Blank" then
                handleBotAttack("Bot")
            elseif Live > 0 and Blank == 0 then
                handleBotAttack("User")
            else
                handleBotAttack((getRandomNumber(0, 1) == 1) and "User" or "Bot")
            end
        end
    end
end

newMatch()
