local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local SprintController = Knit.CreateController({
	Name = "SprintController",
})

function SprintController:KnitInit()
	self._janitor = Janitor.new()
	self._wantsSprint = false
	self._lastWTime = 0
	self._doubleTapWindow = 0.25
	self._service = nil
end

function SprintController:KnitStart()
	self._service = Knit.GetService("SprintService")

	self._janitor:Add(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.W then
			-- Double-tap W to request sprint.
			local now = os.clock()
			if now - self._lastWTime <= self._doubleTapWindow then
				self:_setSprint(true)
			end
			self._lastWTime = now
		end
	end), "Disconnect")

	self._janitor:Add(UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.W then
			self:_setSprint(false)
		end
	end), "Disconnect")
end

function SprintController:SetSprint(wantsSprint: boolean)
	self:_setSprint(wantsSprint)
end

function SprintController:_setSprint(wantsSprint: boolean)
	if self._wantsSprint == wantsSprint then
		return
	end
	self._wantsSprint = wantsSprint
	if self._service then
		self._service:RequestSprint(wantsSprint)
	end
end

return SprintController
