--!strict
local types = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Modules
local TypeRig = require(script.Parent.TypeRig)
local Signal = require(ReplicatedStorage.Packages.signal)

-- Extends type model
export type BaseAnima = {
    player: Player,
    userId: number,
    character: TypeRig.Rig,
    humanoid: Humanoid,
    root: BasePart,
    height: number,
    moving: boolean,
    events: {
        Removed: Signal<nil>,
        Added: Signal<BaseAnima>,
        CharacterAdded: Signal<TypeRig.Rig>,
        EntityDied: Signal<nil>
    }
}

return types
