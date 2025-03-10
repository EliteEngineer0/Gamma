local Greedy = {}

-- royal0959 implementation but better

-- Services
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Constants
local AXIS_ENUMS = Enum.Axis:GetEnumItems()

local function canMerge(part1: BasePart, part2: BasePart, excludeAxis: string?)
	local equalAxises = 0

	local equalPosAxises = 0

	for _, axisEnum in pairs(Enum.Axis:GetEnumItems()) do
		local axis = axisEnum.Name

		local diff = math.abs(part1.CFrame:ToObjectSpace(part2.CFrame).Position[axis])

		if diff <= 0.02 then
			equalPosAxises += 1

			if equalPosAxises == 2 then
				break
			end
		end
	end

	if equalPosAxises < 2 then
		return
	end

	for _, axisEnum in pairs(Enum.Axis:GetEnumItems()) do
		local axis = axisEnum.Name

		if axis == excludeAxis then
			continue
		end

		local diff = math.abs(part1.Size[axis] - part2.Size[axis])

		-- check if each of these properties are equal on both parts
		local compareProps = { "Color", "Material", "Transparency", "Shape" }

		local propsEqual = 0
		for _, prop in pairs(compareProps) do
			if part1[prop] ~= part2[prop] then
				break
			end

			propsEqual += 1
		end

		local isPartOfSameGroup = propsEqual == #compareProps

		if diff <= 0.1 and isPartOfSameGroup then
			equalAxises += 1

			if equalAxises == 2 then
				return true
			end
		end
	end
end

function Greedy:MergeNearby(part: BasePart, OP: OverlapParams, mergeProperties: { [string]: any })
	if not part.Parent then
		return
	end

	-- if no overlap params is supplied, merge with anything
	if not OP then
		OP = OverlapParams.new()
		OP.FilterType = Enum.RaycastFilterType.Include
		OP.FilterDescendantsInstances = { workspace }
	end

	mergeProperties = mergeProperties or {}

	for _, axisEnum in AXIS_ENUMS do
		local axis = axisEnum.Name

		for _, mult in { -1, 1 } do
			local extend = CFrame.new(
				axis == "X" and part.Size.X / 2 * mult or 0,
				axis == "Y" and part.Size.Y / 2 * mult or 0,
				axis == "Z" and part.Size.Z / 2 * mult or 0
			)

			local cfOrientation = CFrame.Angles(math.rad(part.Orientation.X), math.rad(part.Orientation.Y), math.rad(part.Orientation.Z))
			local origin = part.CFrame * (extend * cfOrientation)

			local boundSize = mergeProperties.BoundSize or Vector3.new(0.001, 0.001, 0.001)
			local touching = workspace:GetPartBoundsInBox(origin, boundSize, OP)

			for i = 1, #touching do
				local touchPart = touching[i]

				if touchPart == part then
					continue
				end

				if not touchPart:IsA("Part") then
					continue
				end

				if not canMerge(part, touchPart, axis, mergeProperties) then
					continue
				end

				if mergeProperties.Filter then
					if not mergeProperties.Filter(part, touchPart, axis) then
						continue
					end
				end

				local mergeSize = Vector3.new(
					axis == "X" and touchPart.Size.X or 0,
					axis == "Y" and touchPart.Size.Y or 0,
					axis == "Z" and touchPart.Size.Z or 0
				)

				local mergePosition = Vector3.new(
					axis == "X" and -touchPart.Size.X / 2 * -mult or 0,
					axis == "Y" and -touchPart.Size.Y / 2 * -mult or 0,
					axis == "Z" and -touchPart.Size.Z / 2 * -mult or 0
				)

				part.CFrame *= CFrame.new(mergePosition)
				part.Size += mergeSize

				touchPart:Destroy()

				self:MergeNearby(part, OP, mergeProperties)

				return
			end
		end
	end
end

function Greedy:MergeParts(parts: { BasePart }, mergeProperties: { [string]: any }? )
	local OP = OverlapParams.new()
	OP.FilterType = Enum.RaycastFilterType.Include
	OP.FilterDescendantsInstances = { parts }

	for p, part in parts do
        if p%1000 == 0 then
            RunService.Heartbeat:Wait()
        end
        
        --if random:NextInteger(1, 10) ~= 1 then continue end -- For performance; TODO: Reconsider.

		self:MergeNearby(part, OP, mergeProperties)
	end
end

return Greedy
