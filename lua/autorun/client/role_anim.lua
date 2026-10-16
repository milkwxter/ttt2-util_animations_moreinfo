if SERVER then return end

local surface = surface
local draw = draw

-- fonts
surface.CreateFont("ReceivedRole", {font = "Trebuchet24", size = 52, weight = 1000})
surface.CreateFont("RoleTeam", {font = "Trebuchet18", size = 24, weight = 500, italic = true})

-- client has all the data about the animation
local anim
local animStart = 0

-- colors
local textColor = Color(255, 255, 255, 255)

local function ShadowedText(text, font, x, y, color, xalign, yalign)
	draw.SimpleText(text, font, x + 2, y + 2, COLOR_BLACK, xalign, yalign)
	draw.SimpleText(text, font, x, y, color, xalign, yalign)
end

local function ThickLine(sx, sy, ex, ey, thickness, dir)
	for i = 0, thickness do
		surface.DrawLine(sx, dir and (sy + i) or (sy - i), ex, dir and (ey + i) or (ey - i))
	end
end

hook.Add("TTT2UpdateSubrole", "TTT2RoleAnim", function(ply, old, new)
	if ply ~= LocalPlayer() then return end
	
	-- return early if client has it disabled
	if not GetConVar("ttt2_role_anim_enabled"):GetBool() then return end

	local rd = ply:GetSubRoleData()
	
	local data = {
		role = LANG.GetTranslation(rd.name),
		team = LANG.GetTranslation(ply:GetRealTeam()),
		icon = rd.iconMaterial,
		color = rd.color,
	}
	
	surface.SetFont("ReceivedRole")
	data.textWidth = surface.GetTextSize(data.role)
	
	anim = data
	animStart = CurTime()
end)

hook.Add("TTTEndRound", "TTT2ResetRoleAnimData", function()
	anim = nil
end)

hook.Add("HUDPaint", "TTT2PaintRoleAnim", function()
	-- only render if there is a reason
	if not anim then return end
	
	-- only render if client is playing
	local client = LocalPlayer()
	if not client:IsActive() then return end
	
	-- only render if progress is not done
	local progress = (CurTime() - animStart) / GetConVar("ttt2_role_anim_duration"):GetFloat()
	if progress >= 1 then
		anim = nil
		return
	end
	
	-- store local coordinates for players screen
	local centerX = ScrW() * 0.5
	local startX, endX = 0, ScrW()
	local y1, y2 = ScrH() / 9, ScrH() / 9 * 2
	local centerY = (y2 + y1) / 2
	
	local multiplicator = CubicBezier(0.1, 0.8, 0.9, 0.2, progress)

	-- get the fade progress
	local a = anim.color.a
	if multiplicator > 0.5 then
		a = a * (1 - multiplicator) * 1.5
	else
		a = a * multiplicator * 1.5
	end
	a = math.Clamp(a, 0, 255)
	
	-- draw the colored rectangle background
	local c = anim.color
	surface.SetDrawColor(c.r, c.g, c.b, a)
	surface.DrawRect(startX, y1, endX, y2 - y1)
	
	-- add the progress bars on top and bottom
	surface.SetDrawColor(255, 255, 255, math.floor(a))
	local thickness = 5
	local lineLen = math.floor(endX * multiplicator)
	ThickLine(startX, y1, lineLen, y1, thickness, true)
	ThickLine(endX, y2, endX - lineLen, y2, thickness, false)
	
	-- actually add the text
	textColor.a = a
	ShadowedText(anim.role, "ReceivedRole", centerX, centerY - 20, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	ShadowedText(anim.team, "RoleTeam", centerX, centerY + 25, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	-- draw icon
	if anim.icon then
		local iconSize, gap = 64, 16
		local iconY = centerY - (iconSize / 2)
		local halfW = anim.textWidth / 2
		
		surface.SetMaterial(anim.icon)
		surface.DrawTexturedRect(centerX - halfW - gap - iconSize, iconY, iconSize, iconSize)
		surface.DrawTexturedRect(centerX + halfW + gap, iconY, iconSize, iconSize)
	end
end)
