--Client file
include("../sh_zombieSurvivor.lua")

local zombiesList = {"Normal Zombie Torso", "Normal Zombie", "Fast Zombie Torse", "Antlion", "Barnacle", "Normal Headcrab", "Fast Headcrab", "Fast Zombie", "Poison Headcrab", "Poison Zombie"}
local zombieSpawn = {"npc_zombie_torso","npc_zombie","npc_fastzombie_torse","npc_antlion", "npc_barnacle", "npc_headcrab","npc_headcrab_fast","npc_fastzombie","npc_headcrab_poison","npc_poisonzombie"}


--Handles Preround resets on clientside
local function preround()
	isZombKing = false
end

--Determines if the local player is the zombie king
net.Receive("king", function()
	if net.ReadBool() then
		isZombKing = true
		selectedZomb = zombiesList[1]
	else
		preround()
	end
end)

--Makes player invisible if they're the king
hook.Add("PrePlayerDraw", "invis", function(ply, fgs)
	if isZombKing then
		return true
	else
		return false
	end
end)

--Draws new and better HUD for game
hook.Add("HUDPaint", "survivorHud", function()
	if not isZombKing then
		--Draws stats box
		local scW, scH = ScrW(), ScrH()
		local height, width = scH*.2, scW*.25
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0 , scH-height, width, height)
	
		--Draws health bar 
		local healthBarYPos = scH-.8*height
		local backgroundYPos = scH-.85*height
		local backgroundXPos = width*.5/20
		local backgroundWidth = width - 2*backgroundXPos
	
		--Draws health bar background
		surface.SetDrawColor(255,255,255)
		local backgroundHeight = 2*healthBarYPos - 2*backgroundYPos +height*.25
		surface.DrawRect(backgroundXPos, backgroundYPos, backgroundWidth, backgroundHeight)
	
	
		--Health Bar
		local ply = LocalPlayer()
		local hth, maxHth = ply:Health(), ply:GetMaxHealth()
		surface.SetDrawColor(255, 0, 0, 255)
		local healthWidth = (hth/maxHth)*width*.9
		surface.DrawRect(width/20, scH-.8*height, healthWidth, height*.25)
	
	
		--Draws health title
		surface.SetFont("Trebuchet24")
		surface.SetTextColor(255, 255, 255)
		surface.SetTextPos(width/20, scH-.95*height)
		surface.DrawText("Health:")
	
		--Ammo title
		surface.SetTextPos(width/20, scH-.5*height)
		surface.DrawText("Ammo:")
	
		--Current Gun Ammo Count
		surface.SetTextPos(width/20, scH-.4*height)
		if IsValid(ply:GetActiveWeapon()) then
			local curWep = ply:GetActiveWeapon()
			surface.DrawText(ply:GetAmmoCount(curWep:GetPrimaryAmmoType()))
		end
	else
		local scW, scH = ScrW(), ScrH()
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0, scH*.9, scW*.1, scH*.1)
		
		surface.SetTextColor(255,255,0, 255)
		surface.SetTextPos(scW*.02, scH*.9)
		surface.SetFont("Trebuchet24")
		surface.DrawText("Zombie Points:")
		
		--[[surface.SetTextPos(scW*.02, scH*.93)
		surface.DrawText(LocalPlayer())]]
		
		--[[surface.SetTextPos(scW*.05, scH*.95)
		surface.DrawText]]
	end
	
end)

--Turns off default hud elements
hook.Add("HUDShouldDraw", "hideHealth", function(element)
	if (element == "CHudHealth" or element == "CHudBattery" or element == "CHudAmmo" or element == "CHudCrosshair") and not isZombKing then
		return false
	elseif isZombKing and element == "CHudHealth" then
		return false
	else
		return true
	end
end)

--Calls server to handle loadout system
local function wepDiscard(wp)
	net.Start("weaponPickup")
	net.WriteType(wp)
	net.SendToServer()
end


--Handles Loadout Restrictions
hook.Add("HUDWeaponPickedUp", "weaponDiscordEquip", function(wep)
	local ply = LocalPlayer()
	local weps = ply:GetWeapons()
	local pWep = wep:GetPrimaryAmmoType()
	local pWepN = game.GetAmmoName(pWep)
	
	
	
	for _, _wep in ipairs(weps) do
		local chW = _wep:GetPrimaryAmmoType()
		local curW = game.GetAmmoName(chW)
		if _wep != wep and IsValid(wep) and curW != nil then
			if pWepN == "Pistol" or pWepN == "357" then
				if curW == "Pistol" or curW == "357" then
					wepDiscard(_wep)
				else
					continue
				end
			else
				if curW != "Pistol" and curW != "357" then
					wepDiscard(_wep)
				else
					continue
				end
			end
		end
	end
end)

local function zombShop(toggle)
	if toggle then
		local scrw, scrh = ScrW(), ScrH()
		shop = vgui.Create("DFrame")
		shop:ShowCloseButton(false)
		shop:SetDraggable(true)
		shop:SetSize(scrw*.8, scrh*.8)
		shop:Center()
		shop:SetTitle("")
		shop:MakePopup()
		shop:SetSizable(true)
		
		
		local scroll = vgui.Create("DScrollPanel", shop)
		scroll:Dock( FILL )
		scroll:SetSize(scrw*.8,scrh*.8)
		
		local incX, incY = scrw*.05, scrh*.2
		local ini_x, ini_y = scrw*.03, scrh*.06
		local cur_X, cur_Y = ini_x, ini_y
		local ini_costX, ini_costY = scrw*.03, scrh*.05
		local costXChange, costYChange = scrw*.3, scrh*.3
		local costX, costY = ini_costX, ini_costY
		local row, column = 1, 1
		local xChange, yChange = scrw*.22, scrh*.22
		
		--local catalog = vgui.Create("DPanel", shop)
		
		for k, v in ipairs(zombiesList) do
			local zomb = scroll:Add("DPanel")
			local purchaseButton = vgui.Create("DImageButton", zomb)
			local cost = vgui.Create("DLabel", zomb)
			purchaseButton:SetImage("zombShopIcons/"..tostring(k) .. ".jpg")
			if column == 4 then
				row = row + 1
				column = 1
				
				cur_X = ini_x
				cur_Y = cur_Y + yChange
				
				costX = ini_costX
				costY = costY + costYChange
			end
			
			
			zomb:SetPos(cur_X, cur_Y)
			zomb:SetSize(scrw*.2, scrh*.2)
			
			purchaseButton:SetSize(zomb:GetWide()*.99, zomb:GetTall()*.99)
			purchaseButton:Center()
			
			cost:SetText("Cost: ".. tostring(k))
			cost:SetColor(Color(255,255,0,255))
			cost:Dock(TOP)
			cost:SetFont("Trebuchet24")
			
			cur_X = cur_X + xChange
			
			costX = costX + costXChange
			
			column = column + 1
			
			
			
			function purchaseButton:DoClick()
				selectedZomb = k
			end
			
		end
		
		shop.Paint = function(self, width, height)
			surface.SetDrawColor(0,0,0,120)
			surface.DrawRect(0,0,width,height)
			
			surface.SetFont("Trebuchet24")
			surface.SetTextPos(0,0)
			surface.DrawText("Zombie Shop")
			
			surface.SetTextPos(0,shop:GetWide()*.03)
			surface.DrawText("Click a zombie to choose, then exit the menu & left click to purchase & spawn")
		end
	else
		shop:Remove()
	end
end

--Shows player's extended inventory
local function inventoryDraw(toggle)
	if toggle then
		local scw, sch = ScrW(), ScrH()
		invSc = vgui.Create("DFrame")
		invSc:ShowCloseButton(false)
		invSc:SetDraggable(false)
		invSc:SetSize(scw*.9, sch* .1)
		invSc:Center()
		invSc:SetTitle("")
		invSc.Paint = function(self, width, height)
			surface.SetDrawColor(0,0,0,200)
			surface.DrawRect(0,0,width,height)
			surface.SetFont("Trebuchet24")
			surface.SetTextPos(0,0)
			surface.DrawText("Inventory")
			
			
			
			
			local ply = LocalPlayer()
			local s = 1/10
			local addNum = width*.13
			for k,v in pairs(ply:GetAmmo()) do
				if game.GetAmmoName(k) != "AR2AltFire" and game.GetAmmoName(k) != "GaussEnergy" then
					surface.SetTextPos(width/90 + s, height*.3)
					surface.DrawText(game.GetAmmoName(k))
					s = s + addNum
				elseif game.GetAmmoName(k) == "GaussEnergy" then
					surface.SetTextPos(width/90 + s, height*.3)
					surface.DrawText("Medkits")
					s = s + addNum
				elseif game.GetAmmoName(k) == "SniperPenetratedRound" then
					surface.SetTextPos(width/90 + s, height*.3)
					surface.DrawText("Sniper")
					s = s + addNum
				end
			end
			
			
			s = 1/10
			for k,v in pairs(ply:GetAmmo()) do
				if game.GetAmmoName(k) != "AR2AltFire" then
					surface.SetTextPos(width/90 + s, height*.5)
					surface.DrawText(v)
					s = s + addNum	
		end
	end
		end
	else 
		invSc:Remove()
	end
end

--Used for inventory display controls
hook.Add("ScoreboardShow", "invent", function()
	if not isZombKing then
		inventoryDraw(true)
	else
		zombShop(true)
	end
	return true
end)

hook.Add("ScoreboardHide", "noInv", function()
	if not isZombKing then
		inventoryDraw(false)
	else
		zombShop(false)
	end
end)



hook.Add("KeyPress", "_enemSpawner", function(ply, ky)
	if ky == IN_USE and isZombKing then
		local location = LocalPlayer():GetEyeTrace().HitPos
		local spawnData = {location, zombieSpawn[selectedZomb]}
		net.Start("zombieSpawn")
		net.WriteTable(spawnData)
		net.SendToServer()
	end
end)


net.Receive("zPoints", function(ln, py)
	print("Points: " .. net.ReadInt())

end)