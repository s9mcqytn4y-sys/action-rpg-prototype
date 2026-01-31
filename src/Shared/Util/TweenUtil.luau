--!strict

local TweenService = game:GetService("TweenService")

local TweenUtil = {}

function TweenUtil.play(tweens: { [Instance]: Tween }?, instance: Instance?, info: TweenInfo, props)
	if not instance then
		return
	end
	if not tweens then
		tweens = {}
	end
	local old = tweens[instance]
	if old then
		old:Cancel()
	end
	local tw = TweenService:Create(instance, info, props)
	tweens[instance] = tw
	tw:Play()
end

function TweenUtil.cancelAll(tweens: { [Instance]: Tween })
	for _, tw in pairs(tweens) do
		tw:Cancel()
	end
end

return TweenUtil
