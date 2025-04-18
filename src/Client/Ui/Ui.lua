--!strict
local Ui = {}

Ui.Dependencies = { "ClientAnima" }

-- Services
local Players = game:GetService("Players")
local StarterGUI = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- Modules
local ClientAnima = require(script.Parent.Parent.Main.Player.ClientAnima)
local ClientBackpack = require(script.Parent.Parent.Main.Entities.ClientBackpack)
local Fusion = require(ReplicatedStorage.Packages.fusion)
local Signal = require(ReplicatedStorage.Packages.signal)
local Trove = require(ReplicatedStorage.Packages.trove)
-- Variables
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local function disableCoreUi()
    repeat
        local success = pcall(function() 
            -- Disable resetting (client side)
            StarterGUI:SetCore("ResetButtonCallback", RunService:IsStudio()) 
            -- Disable backpack 
            StarterGUI:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)
        task.wait() 
    until success
end

local function initializeCharacterDependantModule(module)
	task.spawn(function()
		-- Prepare a utility for character dependant ui modules 
		local utility = Ui.GetUtility(true)
		local trove = module.InitUi(utility, Player.Character)
		-- Make sure it's initialized again when the character respawns
		Player.CharacterAdded:Connect(function(character)
			trove:Destroy()
			module.InitUi(utility, character)
		end)
	end)
end

local function initiliazeModules()
    local Modules = script.Parent.Modules
    for _,module in pairs(Modules:GetChildren()) do
        if module:IsA("ModuleScript") then
			local success, err = pcall(function()
				local module = require(module)
				if module.CharacterDependant then
					initializeCharacterDependantModule(module)
				else
					local utility = Ui.GetUtility(false)
					module.InitUi(utility)
				end
			end)
			if success then
				print(`🖼️ Loaded "{module.Name}" ui module`)
			else
				error(`❌ Failed to load "{module.Name}" ui module: {err}`)
			end
        end
    end
end

-- local function setupIris()
-- 	local Iris = require(game:GetService("ReplicatedStorage").Packages.iris).Init()
-- 	Iris:Connect(function()
-- 		Iris.Window({"My First Window!"})
-- 			Iris.Text({"Hello, World"})
-- 			Iris.Button({"Save"})
-- 			Iris.InputNum({"Input"})
-- 		Iris.End()
-- 	end)
-- end

local function setup()
    disableCoreUi()
    initiliazeModules()
	-- setupIris()
end

function Ui.GetUtility(characterDependant: boolean)
    local utility = {}

    utility.player = Player
    utility.mouse = Mouse
    utility.playerGui = Player:WaitForChild("PlayerGui")

    -- Components
	utility.anima = ClientAnima:get()

    utility.Value = Fusion.Value
    utility.Computed = Fusion.Computed
	utility.Hydrate = Fusion.Hydrate
	utility.Spring = Fusion.Spring

    utility.GetGui = function(name)
        return utility.playerGui:WaitForChild(name)
    end

    utility.MakeTemplate = function(uiElement)
        local clone = uiElement:Clone()
        uiElement:Destroy()
        return clone
	end
	
	utility.events = {
		ToolAdded = Signal.new(),
		ToolRemoved = Signal.new(),
		ToolEquip = Signal.new(),
		ToolUnequip = Signal.new(),
	}

	-- Update the character backpack
	local trove
	local function updateBackpack(backpack)
		if trove then trove:Destroy() end
		trove = Trove.new()

		utility.backpack = backpack

		trove:Add(backpack.events.ToolAdded:Connect(function(tool: Tool, index: number)
			utility.events.ToolAdded:Fire(tool,index)
		end))

		trove:Add(backpack.events.ToolRemoved:Connect(function(tool: Tool, index: number)
			utility.events.ToolRemoved:Fire(tool,index)
		end))

		trove:Add(backpack.events.ToolEquip:Connect(function(tool: Tool, index: number)
			utility.events.ToolEquip:Fire(tool,index)
		end))

		trove:Add(backpack.events.ToolUnequip:Connect(function(tool: Tool, index: number)
			utility.events.ToolUnequip:Fire(tool,index)
		end))
	end

	if ClientBackpack.LocalPlayerInstance then
		updateBackpack(ClientBackpack.LocalPlayerInstance)
	end
	
	ClientBackpack.GlobalAdded:Connect(function(backpack)
		if not backpack.isLocalPlayerInstance then return end

		updateBackpack(backpack)
	end)

    return utility
end

function Ui.Init()
    setup()
end

return Ui