--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UIViewport = require(Shared:WaitForChild("UI"):WaitForChild("UIViewport") :: ModuleScript)

local Client = script.Parent.Parent
local State = Client:WaitForChild("State") :: Folder
local store = require(State:WaitForChild("Store") :: ModuleScript)
local Actions = require(State:WaitForChild("Actions") :: ModuleScript)

local UIController = Knit.CreateController({
	Name = "UIController",
})

function UIController:KnitInit()
	self._janitor = Janitor.new()
	self._cameraJanitor = Janitor.new()
	self._lastClass = nil
	self._lastSize = nil
end

function UIController:KnitStart()
	self._janitor:Add(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		self:_bindCamera(Workspace.CurrentCamera)
	end), "Disconnect")

	self:_bindCamera(Workspace.CurrentCamera)
end

function UIController:_bindCamera(camera: Camera?)
	self._cameraJanitor:Cleanup()
	if not camera then
		return
	end

	self:_pushViewport(camera.ViewportSize)
	self._cameraJanitor:Add(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		self:_pushViewport(camera.ViewportSize)
	end), "Disconnect")
end

function UIController:_pushViewport(size: Vector2)
	if self._lastSize and self._lastSize == size then
		return
	end

	local info = UIViewport.makeInfo(size)
	if self._lastClass == info.Class and self._lastSize and self._lastSize == size then
		return
	end

	self._lastClass = info.Class
	self._lastSize = size

	store:dispatch(Actions.SetViewport(info.Size, info.Class, info.Short, info.Long, info.Scale))
end

return UIController
