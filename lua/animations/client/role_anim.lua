local surface = surface
local draw = draw

-- fonts
surface.CreateFont("ReceivedRole", {font = "Trebuchet24", size = 52, weight = 1000})
surface.CreateFont("RoleTeam", {font = "Trebuchet18", size = 24, weight = 500})

local receivedRole
local receivedTeam
local roleIcon

local duration = 3
local animColor = Color(0, 0, 0, 120)
local animStart = 0

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

	local rd = ply:GetSubRoleData()
	local tmp = LANG.GetTranslation(rd.name)

	receivedRole = tmp
	receivedTeam = LANG.GetTranslation(ply:GetRealTeam())
	roleIcon = rd.iconMaterial
	
	animColor = rd.color
	animStart = CurTime()
end)

hook.Add("TTTEndRound", "TTT2ResetRoleAnimData", function()
	receivedRole = nil
	receivedTeam = nil
	roleIcon = nil
end)

hook.Add("HUDPaint", "TTT2PaintRoleAnim", function()
	local client = LocalPlayer()

	if client:IsActive() and receivedRole then
		local center = Vector(ScrW() * 0.5, ScrH() * 0.5, 0)
		local multiplicator = CubicBezier(0.1, 0.8, 0.9, 0.2, (CurTime() - animStart) / duration)

		local sx, ex = 0, ScrW()
		local y1, y2 = ScrH() / 9 * 1, ScrH() / 9 * 2 --height of the banner (y1 beeing topmost y2 being bottom most.)
		local yt = (y2 + y1) / 2 -- A helper value which centers the text height based on y1 and y2

		-- rect
		local a = animColor.a

		if multiplicator > 0.5 then
			a = a * (1 - multiplicator) * 1.5
		else
			a = a * multiplicator * 1.5
		end

		surface.SetDrawColor(animColor.r, animColor.g, animColor.b, a)
		surface.DrawRect(sx, y1, ex, y2 - y1)

		-- lines
		surface.SetDrawColor(255, 255, 255, math.floor(a))

		local thickness = 5
		local _tmp = ex * multiplicator

		-- improve calculations
		_tmp = math.floor(_tmp)

		ThickLine(sx, y1, _tmp, y1, thickness, true)
		ThickLine(ex, y2, ex - _tmp, y2, thickness, false)

		-- Draw current class state
		local roleY = yt - 40
		local teamY = yt + 20
		surface.SetFont("ReceivedRole")
		local textWidth, textHeight = surface.GetTextSize(text)
		ShadowedText(receivedRole, "ReceivedRole", center.x, roleY, Color(255, 255, 255, a), TEXT_ALIGN_CENTER)
		ShadowedText(receivedTeam, "RoleTeam", center.x, teamY, Color(255, 255, 255, a), TEXT_ALIGN_CENTER)
		
		-- draw icon
		local iconSize = 64
		local iconX = center.x - (iconSize / 2)
		local iconY = yt - (iconSize / 2)
		surface.SetMaterial(roleIcon)
		surface.DrawTexturedRect(iconX - textWidth - 64, iconY, iconSize, iconSize)
		surface.DrawTexturedRect(iconX + textWidth + 64, iconY, iconSize, iconSize)

		if animStart + duration <= CurTime() then
			receivedRole = nil
			receivedTeam = nil
			roleIcon = nil
		end
	end
end)
