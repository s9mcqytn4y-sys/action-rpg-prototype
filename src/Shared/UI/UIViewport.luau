--!strict

export type ViewportClass = "Phone" | "Tablet" | "Desktop"

export type ViewportInfo = {
	Size: Vector2,
	Short: number,
	Long: number,
	Class: ViewportClass,
	Scale: number,
}

local UIViewport = {}

UIViewport.Breakpoints = {
	PhoneMax = 700,
	TabletMax = 1024,
}

function UIViewport.getSides(size: Vector2): (number, number)
	local short = math.min(size.X, size.Y)
	local long = math.max(size.X, size.Y)
	return short, long
end

function UIViewport.classify(size: Vector2): ViewportClass
	local short = math.min(size.X, size.Y)
	if short <= UIViewport.Breakpoints.PhoneMax then
		return "Phone"
	end
	if short <= UIViewport.Breakpoints.TabletMax then
		return "Tablet"
	end
	return "Desktop"
end

function UIViewport.getScale(size: Vector2): number
	local short = math.min(size.X, size.Y)
	local raw = short / 900
	return math.clamp(raw, 0.78, 1)
end

function UIViewport.makeInfo(size: Vector2): ViewportInfo
	local short, long = UIViewport.getSides(size)
	return {
		Size = size,
		Short = short,
		Long = long,
		Class = UIViewport.classify(size),
		Scale = UIViewport.getScale(size),
	}
end

return UIViewport
