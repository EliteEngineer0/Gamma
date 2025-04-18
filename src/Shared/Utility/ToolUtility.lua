local ToolUtility = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local AssetsDealer = require(ReplicatedStorage.AssetsDealer)

function ToolUtility.GetModel(tool: Tool)
    local model = tool:FindFirstChild("Model")

    if model then
        return model :: Model
    else
        warn(`Tool has no model`)
        return nil
    end
end

function ToolUtility.GetAsset(toolName: string, mode: ("Clone" | nil)?)
    local asset = AssetsDealer.Get("Tools", toolName, mode)
    if asset then
        return asset
    else
        error(`Tool asset not found with name {toolName}`)
        return nil
    end
end

function ToolUtility.GetFromName(toolName: string,clone: boolean)
    local asset = ToolUtility.GetAsset(toolName)
    local tool = asset:FindFirstChild("Rig"):FindFirstChildOfClass("Tool")

    if tool then
        if clone then
            tool = tool:Clone()
            tool.Name = toolName
        end
        return tool :: Tool
    else
        warn(`Tool not found in asset with name {toolName}`)
        return nil
    end
end


return ToolUtility