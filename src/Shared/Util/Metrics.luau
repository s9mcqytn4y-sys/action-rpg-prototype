--!strict

export type CounterMap = { [string]: number }

local Metrics = {}
Metrics.__index = Metrics

export type Metrics = typeof(setmetatable({} :: {
	_counters: CounterMap,
	_enabled: boolean,
}, Metrics))

function Metrics.new(enabled: boolean): Metrics
	return setmetatable({
		_counters = {},
		_enabled = enabled,
	}, Metrics)
end

function Metrics:SetEnabled(enabled: boolean)
	self._enabled = enabled
end

function Metrics:Increment(key: string, amount: number?)
	if not self._enabled then
		return
	end
	local delta = amount or 1
	local current = self._counters[key] or 0
	self._counters[key] = current + delta
end

function Metrics:Get(key: string): number
	return self._counters[key] or 0
end

function Metrics:Snapshot(): CounterMap
	local copy: CounterMap = {}
	for key, value in pairs(self._counters) do
		copy[key] = value
	end
	return copy
end

return Metrics
