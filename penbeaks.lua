local autohunt = false
local regions = {}
local sortBy = "Bucks"

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

local MainTab = Window:CreateTab("Main")

local MainLabel1 = MainTab:CreateLabel("Status: Waiting")

local MainToggle1 = MainTab:CreateToggle({
    Name = "Auto Hunt",
    CurrentValue = false,
    Flag = "MainToggle1",
    Callback = function(Value)
        autohunt = Value
    end,
})

local MainDropdown1 = MainTab:CreateDropdown({
    Name = "Farm Areas",
    Options = {"Beakwoods", "Deadlands", "Mount Beaks", "Quill Lake"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "MainDropdown1",
    Callback = function(Option)
        regions = Option
    end,
})

local MainDropdown2 = MainTab:CreateDropdown({
    Name = "Sort By",
    Options = {"None", "Bucks", "XP"},
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "MainDropdown2",
    Callback = function(Option)
        sortBy = Option[1]
    end,
})


local gameData = {
    birdsData = require(game:GetService("ReplicatedStorage").Configuration.Birds),
    mutationData = require(game:GetService("ReplicatedStorage").Configuration.Birds.Mutations),
    goldenData = require(game:GetService("ReplicatedStorage").Configuration.Birds.Golden),
    shinyData = require(game:GetService("ReplicatedStorage").Configuration.Birds.Shiny),
    gunData = require(game:GetService("ReplicatedStorage").Configuration.Guns),
}


local function getClientBird(regions, id)
    local reg = game:GetService("Workspace").Regions
    for _, regname in pairs(regions) do
        local region = reg:FindFirstChild(regname)
        if region then
            local client = region.ClientBirds
            for _, clientBird in pairs(client:GetChildren()) do
                local attributes = clientBird:GetAttributes()
                if attributes.Id == id then
                    return clientBird
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
        Server = nil,
    }

    local reg = game:GetService("Workspace").Regions
    for _, regname in pairs(regions) do
        local region = reg:FindFirstChild(regname)
        if region then
            local server = region.ServerBirds
            for _, serverBird in pairs(server:GetChildren()) do
                local attributes = serverBird:GetAttributes()
                local value = gameData.birdsData[attributes.Region][attributes.Bird]["SellPrice"]
                if attributes.Mutation then
                    value = value * gameData.mutationData[attributes.Mutation].PriceMultiplier
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
                    end
                elseif sortBy == "XP" then
                    if xp > bird.XP then
                        bird.Value = value
                        bird.XP = xp
                        bird.Attributes = attributes
                        bird.Server = serverBird
                    end
                else
                    bird.Value = value
                    bird.XP = xp
                    bird.Attributes = attributes
                    bird.Server = serverBird
                    return
                end
                bird.Attributes = attributes
                bird.Server = serverBird
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
        warn("No server bird")
        return
    end
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = bird.Server.CFrame
    task.wait(0.1)
    local clientBird = getClientBird(regions, bird.Attributes.Id)
    if not clientBird then
        task.wait(0.3)
        clientBird = getClientBird(regions, bird.Attributes.Id)
        if not clientBird then
            warn("No client bird")
            bird.Server:Destroy()
            return
        end
    end
    local ts1 = 0
    local ts2 = tick()
    shootTask = task.spawn(function()
        shooting = true
        while clientBird.Parent ~= nil and clientBird:GetAttribute("Health") > 0 do
            MainLabel1:Set("Status: Hunting " .. bird.Attributes.BirdName .. " " .. "HP: " .. clientBird:GetAttribute("Health") .. "/" .. bird.Attributes.MaxHealth .. " Bucks: " .. bird.Value .. " XP: " .. bird.XP)
            task.wait()
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(clientBird.WorldPivot.Position + Vector3.new(0, -5, 0))
            if tick() - ts1 > firerate then
                ts1 = tick()
                local func = guncast.new(gun)
                func(clientBird.Torso.RootPart.Position)
            end
            if tick() - ts2 > 120 or gun == nil then
                shooting = false
                MainLabel1:Set("Status: Waiting")
                return
            end
        end
        shooting = false
        MainLabel1:Set("Status: Waiting")
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
        end
    end
end)