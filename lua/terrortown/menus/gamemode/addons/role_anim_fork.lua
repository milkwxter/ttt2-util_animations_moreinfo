-- clientside menu
CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"

CLGAMEMODESUBMENU.priority = 0
CLGAMEMODESUBMENU.title = "submenu_addons_role_anim_title"

function CLGAMEMODESUBMENU:Populate(parent)
	local form = vgui.CreateTTT2Form(parent, "header_addons_role_anim")

	enabled = form:MakeCheckBox({
		label = "label_role_anim_enable",
		convar = "ttt2_role_anim_enabled"
	})

	form:MakeSlider({
		label = "label_role_anim_duration",
		convar = "ttt2_role_anim_duration",
		min = 0.1,
		max = 5,
		decimal = 1,
		master = enabled,
	})
end
