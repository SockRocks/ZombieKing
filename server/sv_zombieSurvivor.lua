--Server file
include("../sh_zombieSurvivor.lua")


util.AddNetworkString("weaponPickup")
util.AddNetworkString("weaponPickButt")
util.AddNetworkString("king")
util.AddNetworkString("zombieSpawn")
util.AddNetworkString("zPoints")

previousSpawn = Vector(0,0,0)
zombClass = {npc_zombie_torso=1, npc_zombie=2, npc_fastzombie_torso=3, npc_antlion=4, npc_barnacle=5, npc_headcrab=6, npc_headcrab_fast=7,npc_fastzombie=8,npc_headcrab_poison=9, npc_poisonzombie=10}
curTime = os.clock()
allowedWeapons = {}
wepsSorted = {}
survivors = {}
preroundCall = false
local wepList = weapons.GetList()
for k, v in ipairs(wepList) do
	if string.sub(v.ClassName, 1, 3)  == "m9k" then
		table.insert(allowedWeapons, v)
	end
		
end
	
local curW = nil
for k, v in ipairs(allowedWeapons) do

	if wepsSorted[v.Primary.Damage] then
		table.insert(wepsSorted[v.Primary.Damage], v)
	else
		wepsSorted[v.Primary.Damage] = {v}
	end
		
end



local function updateZPoints()
	if zombPoints[zombieKing] then
		net.Start("zPoints")
		local kPoints = zombPoints[zombieKing]
		net.WriteInt(zombPoints[zombieKing])
		net.Send(zombieKing)
	end
end


--Establishes preround conditions e.g. zero zomb points for all players
local function preRound()
	zombieKing = nil
	zombPoints = {}
	for k, v in pairs(player.GetHumans()) do
		zombPoints[v] = 2
	end
	
	--[[local wepList = weapons.GetList()
	for k, v in ipairs(wepList) do
		if string.sub(v.ClassName, 1, 3)  == "m9k" then
			table.insert(allowedWeapons, v)
		end
		
	end
	
	local curW = nil
	for k, v in ipairs(allowedWeapons) do

		if wepsSorted[v.Primary.Damage] then
			table.insert(wepsSorted[v.Primary.Damage], v)
		else
			wepsSorted[v.Primary.Damage] = {v}
		end
		
	end]]
	
	for k, v in pairs(player.GetHumans()) do
		if v != zombKing then
			table.insert(survivors, v)
		end
	end
	
	preRoundCall = true
end

--Handles Loadout system
net.Receive("weaponPickup", function(tim, ply)
	local wep = net.ReadType()
	ply:DropWeapon(wep)
end)



function setup(ply)
	--ply:SetNoTarget(true)
	--ply:GodEnable()
end


function changeKing(ply)
	ply:GodDisable()
	ply:SetNoTarget(false)
end



--Gives zombie points to players
hook.Add("OnNPCKilled", "plyerPointTrack", function(zomb, ply, inf)
	local matched = false
	for k, v in pairs(player.GetHumans()) do
		if v == ply then
			matched = true
		end
	end
	
	if matched then
		local zombType = zomb:GetClass()
		local points = 0
		if zombType == "npc_zombie_torso" then
			points = 1
		elseif zombType == "npc_zombie" then
			points = 2
		elseif zombType == "npc_fastzombie_torso" then
			points = 3
		elseif zombType == "npc_antlion" then
			points = 4
		elseif zombType == "npc_barnacle" then
			points = 5
		elseif zombType == "npc_headcrab" then
			points = 6
		elseif zombType == "npc_headcrab_fast" then
			points = 7
		elseif zombType == "npc_fastzombie" then
			points = 8
		elseif zombType == "npc_headcrab_poison" then
			points = 9
		elseif zombType == "npc_poisonzombie" then
			points = 10
		end
		
		zombPoints[ply] = zombPoints[ply] + points
		PrintTable(zombPoints)
	end
end)


--Developer Commands
hook.Add("PlayerSay", "com", function(ply, msg, tm)
	if msg == "!preround" then
		preRound()
		PrintTable(zombPoints)
		wepSpawn = false
	elseif msg == "!zombKing" then
		zombieKing = ply
		net.Start("king")
		net.WriteBool(true)
		net.Send(ply)
		setup(ply)
	elseif msg == "!nozombking" then
		changeKing(ply)
		net.Start("king")
		net.WriteBool(false)
		net.Send(ply)
	end
end)

net.Receive("zombieSpawn", function(tm, ply)
	local spawnData = net.ReadTable()
	if ply == zombieKing and zombPoints[ply] >= zombClass[spawnData[2]] then
		zombPoints[ply] = zombPoints[ply] - zombClass[spawnData[2]]
		if (math.abs(spawnData[1].x) >= math.abs(previousSpawn.x + 40) or math.abs(spawnData[1].y) >= math.abs(previousSpawn.z + 40)) and spawnData[2] then
			local zomb = ents.Create(spawnData[2])
			zomb:SetPos(spawnData[1])
			zomb:Spawn()
			previousSpawn = spawnData[1]
		end
	end
end)


--[[hook.Add("PlayerTick", "autoPoints", function(ply, v)
	if (os.clock() - curTime) >= 180 and preRoundCall then
		
		local randomPlayer = survivors[math.random(#survivors)]
		local damageQ = 2
		local curRan = nil
		local comp = {}
		for k, v in pairs(wepsSorted) do
			curRan = math.random(100)
			if curRan >= (50 + k)-(zombPoints[randomPlayer]) then
				table.insert(comp, k)
			end
		end
		
		if #comp != 0 then
			damageQ = comp[math.random(#comp)]
		else 
			damageQ = 2
		end
		
		local _selWep = wepsSorted[damageQ]
		local selWep = _selWep[math.random(#(wepsSorted[damageQ]))]
		local wep = ents.Create(selWep.ClassName)
		wep:SetPos(ply:GetPos() + Vector(-90, -90, 10))
		wep:Spawn()
		curTime = os.clock()
	elseif (os.clock() - curTime) >= 30 and preRoundCall then
		zombPoints[zombieKing] = zombPoints[zombieKing] + 2
		
	end

end)]]

hook.Add("EntityTakeDamage", "giveKingPts", function(py, dg)
	if py:IsPlayer() then
		local zombS = false
		for k, v in pairs(zombClass) do
			if k == dg:GetAttacker():GetClass() then
				zombS = true
			end
		end
		
		if zombS then
			zombPoints[zombieKing] = zombPoints[zombieKing] + zombClass[dg:GetAttacker():GetClass()]
			print(zombPoints[zombieKing])
			updateZPoints()
		end
	end

end)