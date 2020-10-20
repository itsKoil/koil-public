
local debugEnabled = false

local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

RegisterNetEvent("hud:enabledebug")
AddEventHandler("hud:enabledebug",function()
	debugEnabled = not debugEnabled
    if debugEnabled then
        print("Debug: Enabled")
    else
        print("Debug: Disabled")
    end
end)

local inFreeze = false
local lowGrav = false

function drawTxt(x,y ,width,height,scale, text, r,g,b,a)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(0.25, 0.25)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end

function DrawText3Ds(coords, text)
    local onScreen,_x,_y=World3dToScreen2d(coords.x, coords.y, coords.z)
    -- local px,py,pz=table.unpack(GetGameplayCamCoords())
	
	if onScreen then
		SetTextScale(0.35, 0.35)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 215)
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
		DrawText(_x,_y)
		-- local factor = (string.len(text)) * 0.0025
		-- DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
	end
end

local objTable = {}

function updateObjTable()
	objTable = {}

	for obj in EnumerateObjects() do
		if obj ~= 0 then
			objTable[#objTable+1] = obj
		end
	end
end

local vehTable = {}

function updateVehTable()
	vehTable = {}
	for veh in EnumerateVehicles() do
		if veh ~= 0 then
			vehTable[#vehTable+1] = veh
		end
	end
end

local pedTable = {}

function updatePedTable()
	pedTable = {}
	for ped in EnumeratePeds() do
		if ped ~= 0 and ped ~= PlayerPedId() then
			pedTable[#pedTable+1] = ped
		end
	end
end


local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end

        enum.destructor = nil
        enum.handle = nil
    end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()

        if not id or id == 0 then
            disposeFunc(iter)

            return
        end

        local enum = {
            handle = iter,
            destructor = disposeFunc
        }

        setmetatable(enum, entityEnumerator)
        local next = true
        repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
        until not next
        enum.destructor, enum.handle = nil, nil
        disposeFunc(iter)
    end)
end

function EnumerateObjects()
    return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
    return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumeratePickups()
    return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end

local relationships = {
	[GetHashKey("PLAYER")] = "PLAYER",
	[GetHashKey("CIVMALE")] = "CIVMALE",
	[GetHashKey("CIVFEMALE")] = "CIVFEMALE",
	[GetHashKey("COP")] = "COP",
	[GetHashKey("SECURITY_GUARD")] = "SECURITY_GUARD",
	[GetHashKey("PRIVATE_SECURITY")] = "PRIVATE_SECURITY",
	[GetHashKey("FIREMAN")] = "FIREMAN",
	[GetHashKey("GANG_1")] = "GANG_1",
	[GetHashKey("GANG_2")] = "GANG_2",
	[GetHashKey("GANG_9")] = "GANG_9",
	[GetHashKey("GANG_10")] = "GANG_10",
	[GetHashKey("AMBIENT_GANG_LOST")] = "AMBIENT_GANG_LOST",
	[GetHashKey("AMBIENT_GANG_MEXICAN")] = "AMBIENT_GANG_MEXICAN",
	[GetHashKey("AMBIENT_GANG_FAMILY")] = "AMBIENT_GANG_FAMILY",
	[GetHashKey("AMBIENT_GANG_BALLAS")] = "AMBIENT_GANG_BALLAS",
	[GetHashKey("AMBIENT_GANG_MARABUNTE")] = "AMBIENT_GANG_MARABUNTE",
	[GetHashKey("AMBIENT_GANG_CULT")] = "AMBIENT_GANG_CULT",
	[GetHashKey("AMBIENT_GANG_SALVA")] = "AMBIENT_GANG_SALVA",
	[GetHashKey("AMBIENT_GANG_WEICHENG")] = "AMBIENT_GANG_WEICHENG",
	[GetHashKey("AMBIENT_GANG_HILLBILLY")] = "AMBIENT_GANG_HILLBILLY",
	[GetHashKey("DEALER")] = "DEALER",
	[GetHashKey("HATES_PLAYER")] = "HATES_PLAYER",
	[GetHashKey("HEN")] = "HEN",
	[GetHashKey("WILD_ANIMAL")] = "WILD_ANIMAL",
	[GetHashKey("SHARK")] = "SHARK",
	[GetHashKey("COUGAR")] = "COUGAR",
	[GetHashKey("NO_RELATIONSHIP")] = "NO_RELATIONSHIP",
	[GetHashKey("SPECIAL")] = "SPECIAL",
	[GetHashKey("MISSION2")] = "MISSION2",
	[GetHashKey("MISSION3")] = "MISSION3",
	[GetHashKey("MISSION4")] = "MISSION4",
	[GetHashKey("MISSION5")] = "MISSION5",
	[GetHashKey("MISSION6")] = "MISSION6",
	[GetHashKey("MISSION7")] = "MISSION7",
	[GetHashKey("MISSION8")] = "MISSION8",
	[GetHashKey("ARMY")] = "ARMY",
	[GetHashKey("GUARD_DOG")] = "GUARD_DOG",
	[GetHashKey("AGGRESSIVE_INVESTIGATE")] = "AGGRESSIVE_INVESTIGATE",
	[GetHashKey("MEDIC")] = "MEDIC",
	[GetHashKey("CAT")] = "CAT",
}


local currentStreetName = ""

local lastTableUpdate = 0
Citizen.CreateThread( function()

    while true do 
        
        Citizen.Wait(0)
        
		if true then
			local ply = PlayerPedId()
            local pos = GetEntityCoords(ply)

            local forPos = GetOffsetFromEntityInWorldCoords(ply, 0, 1.0, 0.0)
            local backPos = GetOffsetFromEntityInWorldCoords(ply, 0, -1.0, 0.0)
            local LPos = GetOffsetFromEntityInWorldCoords(ply, 1.0, 0.0, 0.0)
            local RPos = GetOffsetFromEntityInWorldCoords(ply, -1.0, 0.0, 0.0) 

            local forPos2 = GetOffsetFromEntityInWorldCoords(ply, 0, 2.0, 0.0)
            local backPos2 = GetOffsetFromEntityInWorldCoords(ply, 0, -2.0, 0.0)
            local LPos2 = GetOffsetFromEntityInWorldCoords(ply, 2.0, 0.0, 0.0)
            local RPos2 = GetOffsetFromEntityInWorldCoords(ply, -2.0, 0.0, 0.0)    

			local x, y, z = table.unpack(GetEntityCoords(ply, true))
			
			
			local plyHeading = GetEntityHeading(ply)
			local attachedEnt = GetEntityAttachedTo(ply)
			local plyHealth = GetEntityHealth(ply)
			local hag = GetEntityHeightAboveGround(ply)
			local plyModel = GetEntityModel(ply)
			local speed = GetEntitySpeed(ply)

			-- tried to make this readable, don't think it worked.
			drawTxt(0.8, 0.50, 0.4,0.4,0.30, 
				"\nHeading: " .. plyHeading ..
				"\nCoords: " .. pos ..
				"\nAttached Ent: " .. attachedEnt
				, 55, 155, 55, 255)
			drawTxt(0.8, 0.55, 0.4,0.4,0.30, 
				"\nHealth: " .. plyHealth ..
				"\nH a G: " .. hag .. 
				"\nModel: " .. plyModel ..
				"\nSpeed: " .. speed, 55, 155, 55, 255)
			drawTxt(0.8, 0.615, 0.4,0.4,0.30, 
				"\nFrame Time: " .. GetFrameTime() ..
				"\nStreet: " .. currentStreetName, 55, 155, 55, 255)
            
            
            DrawLine(pos,forPos, 255,0,0,115)
            DrawLine(pos,backPos, 255,0,0,115)

            DrawLine(pos,LPos, 255,255,0,115)
            DrawLine(pos,RPos, 255,255,0,115)           

            DrawLine(forPos,forPos2, 255,0,255,115)
            DrawLine(backPos,backPos2, 255,0,255,115)

            DrawLine(LPos,LPos2, 255,255,255,115)
            DrawLine(RPos,RPos2, 255,255,255,115)     

			if lastTableUpdate < GetGameTimer() then
				-- print("update tables")
				updatePedTable()
				updateVehTable()
				updateObjTable()

				local currentStreetHash, intersectStreetHash = GetStreetNameAtCoord(pos.x, pos.y, pos.z, currentStreetHash, intersectStreetHash)
				currentStreetName = GetStreetNameFromHashKey(currentStreetHash)
				lastTableUpdate = GetGameTimer() + 1000
			end
			
			for i = 1, #pedTable do
				local ped = pedTable[i]
				local pedCoords = GetEntityCoords(ped)
				local plyPed = PlayerPedId()
				local plyCoords = GetEntityCoords(plyPed)

				if #(pedCoords - plyCoords) < 15.0 then
					if IsEntityTouchingEntity(plyPed, ped) then
						DrawText3Ds(pedCoords, "Ped: " .. ped .. " Model: " .. GetEntityModel(ped) .. " Relationship: " .. relationships[GetPedRelationshipGroupHash(ped)] .. " TOUCHING" )
					else
						DrawText3Ds(pedCoords, "Ped: " .. ped .. " Model: " .. GetEntityModel(ped) .. " Relationship: " .. relationships[GetPedRelationshipGroupHash(ped)] )
					end
				end

				if lowGrav then
					SetPedToRagdoll(ped, 511, 511, 0, 0, 0, 0)
					SetEntityCoords(ped, pedCoords + vector3(0, 0, 0.1))
				end
				FreezeEntityPosition(ped, inFreeze)

			end

			for i = 1, #objTable do
				local obj = objTable[i]
				local objCoords = GetEntityCoords(obj)
				local plyPed = PlayerPedId()
				local plyCoords = GetEntityCoords(plyPed)

				if #(objCoords - plyCoords) < 15.0 then
					if IsEntityTouchingEntity(plyPed, obj) then
						DrawText3Ds(objCoords + vector3(0,0,1), "Obj: " .. obj .. " Model: " .. GetEntityModel(obj) .. " IN CONTACT" )
					else
						DrawText3Ds(objCoords + vector3(0,0,1), "Obj: " .. obj .. " Model: " .. GetEntityModel(obj) .. "" )
					end
				end

				if lowGrav then
					SetEntityCoords(obj, objCoords + vector3(0,0,0.1))
					FreezeEntityPosition(obj, false)
				end
				FreezeEntityPosition(obj, inFreeze)
			end

			for i = 1, #vehTable do
				local veh = vehTable[i]
				local vehCoords = GetEntityCoords(veh)
				local plyPed = PlayerPedId()
				local plyCoords = GetEntityCoords(plyPed)

				if #(vehCoords - plyCoords) < 15.0 then
					if IsEntityTouchingEntity(plyPed, ped) then
						DrawText3Ds(vehCoords + vector3(0,0,1), "Veh: " .. veh .. " Model: " .. GetDisplayNameFromVehicleModel(GetEntityModel(veh)) .. " IN CONTACT" )
					else
						DrawText3Ds(vehCoords + vector3(0,0,1), "Veh: " .. veh .. " Model: " .. GetDisplayNameFromVehicleModel(GetEntityModel(veh)) .. "" )
					end
				end
				if lowGrav then
					SetEntityCoords(veh,vehCoords + vector3(0,0,5))
				end
				FreezeEntityPosition(veh, inFreeze)
			end

            if IsControlJustReleased(0, 38) then
                if inFreeze then
                    inFreeze = false
                    TriggerEvent("DoShortHudText",'Freeze Disabled',3)          
                else
                    inFreeze = true             
                    TriggerEvent("DoShortHudText",'Freeze Enabled',3)               
                end
            end

            if IsControlJustReleased(0, 47) then
                if lowGrav then
                    lowGrav = false
                    TriggerEvent("DoShortHudText",'Low Grav Disabled',3)            
                else
                    lowGrav = true              
                    TriggerEvent("DoShortHudText",'Low Grav Enabled',3)                 
                end
            end

        else
            Citizen.Wait(500)
        end
    end
end)