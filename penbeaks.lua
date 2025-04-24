local autohunt = false
local regions = {}
local sortBy = "Bucks"

local gameData = {
    birdsData = require(game:GetService("ReplicatedStorage").Configuration.Birds),
    mutationData = require(game:GetService("ReplicatedStorage").Configuration.Birds.Mutations),
    goldenData = require(game:GetService("ReplicatedStorage").Configuration.Birds.Golden),
    shinyData = require(game:GetService("ReplicatedStorage").Configuration.Birds.Shiny),
    gunData = require(game:GetService("ReplicatedStorage").Configuration.Guns),
    dataController = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Controllers.DataController),
}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "PenBeaks",
    Icon = 0,
    LoadingTitle = "Beaks Script",
    LoadingSubtitle = "by Penguin",
    Theme = "Default",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
       Enabled = false,
       FolderName = "penbeaks",
       FileName = "config"
    },

    Discord = {
       Enabled = true,
       Invite = "fWncS2vFx",
       RememberJoins = true,
    },

    KeySystem = false,
    KeySettings = {
       Title = "Untitled",
       Subtitle = "Key System",
       Note = "No method of obtaining the key is provided",
       FileName = "Key",
       SaveKey = true,
       GrabKeyFromSite = false,
       Key = {"Hello"}
    }
})

local HomeTab = Window:CreateTab("Home")

local HomeButton1 = HomeTab:CreateButton({
    Name = "Join discord (/fWncS2vFxn)",
    Callback = function()
        setclipboard("discord.gg/fWncS2vFxn")
        Rayfield:Notify({
            Title = "Discord",
            Content = "discord.gg/fWncS2vFxn",
            Duration = 5,
            Image = nil,
        })
    end,
})

local HomeButton2 = HomeTab:CreateButton({
    Name = "Close GUI (Destroy)",
    Callback = function()
        if runTask then
           task.cancel(runTask)
           runTask = nil
        end
        if shootTask then
            task.cancel(shootTask)
            shootTask = nil
        end
        if sellTask1 then
            task.cancel(sellTask1)
            sellTask1 = nil
        end
        if sellTask2 then
            task.cancel(sellTask2)
            sellTask2 = nil
        end
        if fullbright then
            fullbright:Disconnect()
            fullbright = nil
        end
        Rayfield:Destroy()
    end,
})

local ToolsTab = Window:CreateTab("Tools")

local function fullbrightfunc()
    local Lighting = game:GetService("Lighting")
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end

local ToolsToggle1 = ToolsTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "ToolsToggle1",
    Callback = function(Value)
        if Value then
            fullbright = game:GetService("RunService").RenderStepped:Connect(fullbrightfunc)
        else
            if not fullbright then return end
            fullbright:Disconnect()
            fullbright = nil
        end
    end
})

local HuntTab = Window:CreateTab("Hunt")

local HuntLabel1 = HuntTab:CreateLabel("Status: Waiting")

local HuntToggle1 = HuntTab:CreateToggle({
    Name = "Auto Hunt",
    CurrentValue = false,
    Flag = "HuntToggle1",
    Callback = function(Value)
        autohunt = Value
    end,
})

local HuntDropdown1 = HuntTab:CreateDropdown({
    Name = "Farm Areas",
    Options = {"Beakwoods", "Deadlands", "Mount Beaks", "Quill Lake"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "HuntDropdown1",
    Callback = function(Option)
        regions = Option
    end,
})

local HuntDropdown2 = HuntTab:CreateDropdown({
    Name = "Sort By",
    Options = {"None", "Bucks", "XP"},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "HuntDropdown2",
    Callback = function(Option)
        sortBy = Option[1]
    end,
})

local function getServerBird(regions, id)
    local reg = game:GetService("Workspace").Regions
    for _, regname in pairs(regions) do
        local region = reg:FindFirstChild(regname)
        if region then
            local server = region.ServerBirds
            for _, serverBird in ipairs(server:GetChildren()) do
                local attributes = serverBird:GetAttributes()
                if attributes.Id == id then
                    return serverBird
                end
            end
        end
    end
end

local function getBird(regions)
    local bird = {
        Value = 0,
        XP = 0,
        Attributes = {},
        Client = nil,
        Server = nil,
    }

    local reg = game:GetService("Workspace").Regions
    for _, regname in pairs(regions) do
        local region = reg:FindFirstChild(regname)
        if region then
            local client = region.ClientBirds
            for _, clientBird in ipairs(client:GetChildren()) do
                local serverBird = getServerBird(regions, clientBird:GetAttribute("Id"))
                if not serverBird then
                    --warn("Server bird not found for client bird: " .. clientBird:GetAttribute("Id"))
                else
                    local attributes = serverBird:GetAttributes()
                    local value = gameData.birdsData[attributes.Region][attributes.Bird]["SellPrice"]
                    if attributes.Mutation then
                        if attributes.Mutation == "Black & White" then
                            attributes.Mutation = "B&W"
                        end
                        if gameData.mutationData[attributes.Mutation] == nil then
                            warn("Mutation not found in data: " .. attributes.Mutation)
                        else
                            value = value * gameData.mutationData[attributes.Mutation].PriceMultiplier
                        end
                    end
                    if attributes.Golden then
                        value = value * gameData.goldenData.PriceMultiplier
                    end
                    if attributes.Shiny then
                        value = value * gameData.shinyData.PriceMultiplier
                    end
                    local xp = gameData.birdsData[attributes.Region][attributes.Bird]["XP"]

                    if sortBy == "Bucks" then
                        if value > bird.Value then
                            bird.Value = value
                            bird.XP = xp
                            bird.Attributes = attributes
                            bird.Server = serverBird
                            bird.Client = clientBird
                        end
                    elseif sortBy == "XP" then
                        if xp > bird.XP then
                            bird.Value = value
                            bird.XP = xp
                            bird.Attributes = attributes
                            bird.Server = serverBird
                            bird.Client = clientBird
                        end
                    else
                        bird.Value = value
                        bird.XP = xp
                        bird.Attributes = attributes
                        bird.Server = serverBird
                        bird.Client = clientBird
                        return bird
                    end
                end
            end
        else
            warn("Region not found: " .. regname)
        end
    end

    return bird
end

local gun
local firerate = 0.5
local shooting = false
local guncast = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Controllers.GunController.GunFastCast)
local function hunt()
    local bird = getBird(regions)
    if not bird.Server then
        warn("Missing bird server!")
        return
    end
    if not bird.Client then
        warn("Missing bird client!")
        return
    end
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = bird.Server.CFrame
    local ts1 = 0
    local ts2 = tick()
    shootTask = task.spawn(function()
        shooting = true
        while bird.Client.Parent ~= nil and bird.Client:GetAttribute("Health") and bird.Client:GetAttribute("Health") > 0 do
            local string = "Status: Hunting "
            if bird.Attributes.Shiny then string = string .. "Shiny " end
            if bird.Attributes.Golden then string = string .. "Golden " end
            if bird.Attributes.Mutation then string = string .. bird.Attributes.Mutation .. " " end
            string = string .. bird.Attributes.BirdName .. " " .. "HP: " .. bird.Client:GetAttribute("Health") .. "/" .. bird.Attributes.MaxHealth .. " Bucks: " .. bird.Value .. " XP: " .. bird.XP
            HuntLabel1:Set(string)
            task.wait()
            game.Players.LocalPlayer.Character.HumanoidRootPart.Position = bird.Client.WorldPivot.Position + Vector3.new(0, 10, 0)
            if tick() - ts1 > firerate then
                ts1 = tick()
                local func = guncast.new(gun)
                local pos
                if bird.Client:FindFirstChild("Torso") and bird.Client.Torso:FindFirstChild("RootPart") then
                    pos = bird.Client.Torso.RootPart.Position
                elseif bird.Client:FindFirstChild("Beak") and bird.Client.Beak:FindFirstChild("PrimaryBeak") then
                    pos = bird.Client.Beak.PrimaryBeak.Position
                elseif bird.Client.PrimaryPart then
                    pos = bird.Client.PrimaryPart.Position
                else
                    pos = bird.Client.WorldPivot.Position
                end
                func(pos)
            end
            if tick() - ts2 > 120 or gun == nil then
                shooting = false
                HuntLabel1:Set("Status: Waiting")
                return
            end
        end
        shooting = false
        HuntLabel1:Set("Status: Waiting")
    end)
end

if runTask then
   task.cancel(runTask)
   runTask = nil
end

if shootTask then
    task.cancel(shootTask)
    shootTask = nil
end

runTask = task.spawn(function()
    while task.wait() do
        if autohunt then
            gun = game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if gun and gun:FindFirstChild("Gun") then
                firerate = gameData.gunData[gun.Name].Stats["Fire Rate"]
                if not shooting then hunt() end
            end
        else
            task.wait(0.5)
        end
    end
end)

local InventoryTab = Window:CreateTab("Inventory")

local InventorySection1 = InventoryTab:CreateSection("Sell")

local sellAll = false
local sellAllDelay = 15
local InventoryToggle1 = InventoryTab:CreateToggle({
    Name = "Auto Sell All",
    CurrentValue = false,
    Flag = "InventoryToggle1",
    Callback = function(Value)
        if sellTask1 then
            task.cancel(sellTask1)
            sellTask1 = nil
        end
        sellAll = Value
        sellTask1 = task.spawn(function()
            while sellAll do
                game:GetService("ReplicatedStorage").Util.Net["RF/SellInventory"]:InvokeServer("All")
                task.wait(sellAllDelay)
            end
        end)
    end,
})

local InventorySlider1 = InventoryTab:CreateSlider({
    Name = "Sell All Delay",
    Range = {10, 60},
    Increment = 1,
    Suffix = "sec",
    CurrentValue = 15,
    Flag = "InventorySlider1",
    Callback = function(Value)
        sellAllDelay = Value
    end,
})

local sellHand = false
local InventoryToggle2 = InventoryTab:CreateToggle({
    Name = "Auto Sell Hand",
    CurrentValue = false,
    Flag = "InventoryToggle2",
    Callback = function(Value)
        if sellTask2 then
            task.cancel(sellTask2)
            sellTask2 = nil
        end
        sellHand = Value
        sellTask2 = task.spawn(function()
            while sellHand do
                game:GetService("ReplicatedStorage").Util.Net["RF/SellInventory"]:InvokeServer("Selected")
                task.wait()
            end
        end)
    end,
})

local InventorySection2 = InventoryTab:CreateSection("Buy Gun")

local gunTable = {}
for i, _ in pairs(gameData.gunData) do
    table.insert(gunTable, i)
end

local selectedBuyGun = ""
local allowDupe = false
local InventoryDropdown1 = InventoryTab:CreateDropdown({
    Name = "Select Gun",
    Options = gunTable,
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "InventoryDropdown1",
    Callback = function(Option)
        selectedBuyGun = Option[1]
    end,
})

local InventoryToggle3 = InventoryTab:CreateToggle({
    Name = "Allow Duplicates",
    CurrentValue = false,
    Flag = "InventoryToggle3",
    Callback = function(Value)
        allowDupe = Value
    end,
})

local function contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

local InventoryButton1 = InventoryTab:CreateButton({
    Name = "Buy Gun",
    Callback = function()
        if not gameData.gunData[selectedBuyGun] then
            Rayfield:Notify({
                Title = "Buy Gun",
                Content = "Select a gun to buy!",
                Duration = 5,
                Image = nil,
            })
            return
        end
        local data = gameData.dataController:GetPlayerData()
        if allowDupe or not contains(data.Equipment.Guns.Owned, selectedBuyGun) then
            game:GetService("ReplicatedStorage").Util.Net["RF/GunShop"]:InvokeServer("BuyGun", selectedBuyGun)
            Rayfield:Notify({
                Title = "Buy Gun",
                Content = "Attempted to buy " .. selectedBuyGun,
                Duration = 5,
                Image = nil,
            })
        else
            Rayfield:Notify({
                Title = "Buy Gun",
                Content = "You already own this gun!",
                Duration = 5,
                Image = nil,
            })
        end
    end,
})