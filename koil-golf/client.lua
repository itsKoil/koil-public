--# Written by koil
--# Web - nopixel.net
--# Twitch - twitch.tv/koil
--# Twitter - twitter.com/itskoil
--# Contact - koiltwitch@gmail.com
--# You can modify, do what you wish with it just dont claim it as your own. (not that its worthy)

local golfhole = 0
local golfstrokes = 0
local totalgolfstrokes = 0
golfplaying = false

-- ballstate, 1 = in hole, 0 out of hole.
local ballstate = 1
local balllocation = 0

-- golfstate, 2 on ball ready to swing, 1 free roam
local golfstate = 1

-- 0 for putter, 1 iron, 2 wedge, 3 driver.
local golfclub = 1

-- am i in idle loop mode
local inLoop = false
local inTask = false
local power = 0.1
-- golfball object, only used while hitting.
local mygolfball = 0

--SetFocusEntity(entity)

RegisterNetEvent('beginGolf')
AddEventHandler('beginGolf', function()
	startGolf()
	Citizen.Trace("1")
end)

RegisterNetEvent('beginGolfHud')
AddEventHandler('beginGolfHud', function()
	startGolfHud()
	Citizen.Trace("HUD started")
end)

Citizen.CreateThread(function()
	addblipGC()
	while true do
		Citizen.Wait(1)
		local playerLoc = GetEntityCoords(GetPlayerPed(-1))
		local distance = GetDistanceBetweenCoords(-1332.7823486328,128.18229675293,56.032329559326, playerLoc.x,playerLoc.y,playerLoc.z, false)
		--if distance < 30.0 then
		DrawMarker(27,-1332.7823486328,128.18229675293,56.032329559326, 0, 0, 0, 0, 0, 0, 1.5, 1.5, 10.3, 0, 519, 0, 105, 0, 0, 2, 0, 0, 0, 0)
		--end

		if distance > 500 and golfplaying then
			endgame()
		end
		if distance < 1.5 then

			if golfplaying then
				DisplayHelpText("Press ~g~~INPUT_CONTEXT~~s~ to end golf.")
			else
				DisplayHelpText("Press ~g~~INPUT_CONTEXT~~s~ to start golf ($100).")
			end
			if (IsControlJustReleased(1, 38)) then

				if (golfplaying) then
					endgame()
				else
					Citizen.Trace("a1")

					spawnCart()
					startGolf() -- If you plan to have it cost money, you need to remove this and only call it when they paid
					TriggerEvent("customNotification","Press E to swing, A-D to rotate, Y to swap club.")
				end
			end
			--if (IsControlJustPressed(1, 38) and golfplaying) then
				--endgame()
			--end
		end
	end
end)

function spawnCart()
	Citizen.Trace("Spawn Cart")
	local vehicle = GetHashKey("caddy")
	RequestModel(vehicle)

	while not HasModelLoaded(vehicle) do
		Citizen.Wait(0)
	end
	local spawned_car = CreateVehicle(vehicle, -1332.7823486328,128.18229675293,56.032329559326, 180, true, false)
	SetVehicleOnGroundProperly(spawned_car)
	SetPedIntoVehicle(GetPlayerPed(-1), spawned_car, - 1)
	SetModelAsNoLongerNeeded(vehicle)
	plate = GetVehicleNumberPlateText(spawned_car)
end

function DisplayHelpText(str)
    SetTextComponentFormat("STRING")
    AddTextComponentString(str)
    DisplayHelpTextFromStringLabel(0, 0, 0, -1)
end

function startGolfHud()
	while golfplaying do
		Citizen.Wait(0)
		DrawRect(0.5,0.93,0.2,0.04,0,0,0,140) -- header
		if golfhole ~= 0 then
			local distance = math.ceil(GetDistanceBetweenCoords(GetEntityCoords(mygolfball), holes[golfhole]["x2"],holes[golfhole]["y2"],holes[golfhole]["z2"], true))
			drawGolfTxt(0.9193, 1.391, 1.0,1.0,0.4, "~s~" .. golfstrokes .. "~r~ - ~s~" .. totalgolfstrokes .. "~r~ - ~s~" .. clubname .. "~r~ - ~s~" .. distance .. " m", 255, 255, 255, 255)
		end
	end
end

function startGolf()
	Citizen.Trace("Start Golf")
	--endgame()
	StopAllScreenEffects()
	--StartScreenEffect("MinigameTransitionIn", 5, 0);
	inTask = false
	SetCurrentPedWeapon(GetPlayerPed(-1), 0xA2719263)
	golfplaying = true
	Citizen.Trace("3")
	TriggerEvent("beginGolfHud")
	Citizen.Trace("4")
	Citizen.CreateThread(function()
		while golfplaying do
			Citizen.Wait(1000)
			local playerLoc = GetEntityCoords(GetPlayerPed(-1))
			local distance = GetDistanceBetweenCoords(-1332.7823486328,128.18229675293,57.032329559326, playerLoc.x,playerLoc.y,playerLoc.z, false)

			if ballstate == 1 then
				golfhole = golfhole + 1
				if golfhole == 10 then
					endgame()
				else
					startHole()
				end
			else
				if golfstate == 2 and not inTask and not doingdrop then
					idleShot()
				elseif golfstate == 1 and not inTask and not doingdrop then
					MoveToBall()
				end
			end
		end
		Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(spawned_car))
	end)
end

function rotateShot(moveType)
	local curHeading = GetEntityHeading(mygolfball)
	if curHeading >= 360.0 then
		curHeading = 0.0
	end
	if moveType then
		SetEntityHeading(mygolfball, curHeading-0.7)
	else
		SetEntityHeading(mygolfball, curHeading+0.7)
	end
end

function createBall(x,y,z)
	Citizen.Trace("Creating Ball")
	DeleteObject(mygolfball)
	mygolfball = CreateObject(GetHashKey("prop_golf_ball"), x, y, z, true, true, false)

	SetEntityRecordsCollisions(mygolfball,true)
	addBallBlip()
	SetEntityCollision(mygolfball, true, true)
	SetEntityHasGravity(mygolfball, true)
	FreezeEntityPosition(mygolfball, true)
	local curHeading = GetEntityHeading(GetPlayerPed(-1))
	SetEntityHeading(mygolfball, curHeading)
end

function endgame()
	TriggerEvent("destroyProp")
	if startblip ~= nil then
		RemoveBlip(startblip)
		RemoveBlip(endblip)
	end
	if ballBlip ~= nil then
		RemoveBlip(ballBlip)
	end
	removeAttachedProp()
	DeleteObject(mygolfball)
	Citizen.Trace("Ending Game")
	golfhole = 0
	golfstrokes = 0
	golfplaying = false
	ballstate = 1
	balllocation = 0
	golfstate = 1
	golfclub = 1
	inLoop = false
	inTask = false
end

function MoveToBall()
	Citizen.Trace("Moving to Ball")
	while golfstate == 1 do
		Citizen.Wait(0)
		if GetVehiclePedIsIn(GetPlayerPed(-1), false) == 0 then
			local ballLoc = GetEntityCoords(mygolfball)
			local playerLoc = GetEntityCoords(GetPlayerPed(-1))
			local distance = GetDistanceBetweenCoords(ballLoc.x,ballLoc.y,ballLoc.z, playerLoc.x,playerLoc.y,playerLoc.z, true)
			if distance < 50.0 then
				DisplayHelpText("Move to your ball, press ~g~E~s~ to ball drop if you are stuck.")
				if ( IsControlJustReleased(1, 38) ) then
					dropShot()
				end

				if (distance < 5.0) and not doingdrop then
					golfstate = 2
					ballstate = 0
				end
			end
		end
	end
end

function endShot()
	Citizen.Trace("Ending Shot")
	TriggerEvent("attachItem","golfbag01")
	inTask = false
	golfstrokes = golfstrokes + 1
	local ballLoc = GetEntityCoords(mygolfball)
	local distance = GetDistanceBetweenCoords(ballLoc.x,ballLoc.y,ballLoc.z, holes[golfhole]["x2"],holes[golfhole]["y2"],holes[golfhole]["z2"], true)
	if distance < 1.5 then
		TriggerEvent("customNotification","You got the ball with in range!")
		totalgolfstrokes = golfstrokes + totalgolfstrokes
		golfstrokes = 0
		ballstate = 1
	end
	if golfstrokes > 12 then
		TriggerEvent("customNotification","You took too many shots..")
		totalgolfstrokes = golfstrokes + totalgolfstrokes
		golfstrokes = 0
		ballstate = 1
	end

	Citizen.Trace("Ball seemed to have landed on: " .. GetCollisionNormalOfLastHitForEntity(mygolfball) )
end

local doingdrop = false
function dropShot()
	Citizen.Trace("Droping Shot")
	doingdrop = true
	while doingdrop do

		Citizen.Wait(0)
		local distance = GetDistanceBetweenCoords(GetEntityCoords(mygolfball), GetEntityCoords(GetPlayerPed(-1)), true)
		local distanceHole = GetDistanceBetweenCoords(holes[golfhole]["x2"],holes[golfhole]["y2"],holes[golfhole]["z2"], GetEntityCoords(GetPlayerPed(-1)), true)
		if distance < 50.0 and distanceHole > 50.0 then
			DisplayHelpText("Press ~g~E~s~ to drop here.")
			if ( IsControlJustReleased(1, 38) ) then
				doingdrop = false
				x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1)))
				createBall(x,y,z-1)
				golfstrokes = golfstrokes + 1
			end
		else
			DisplayHelpText("Press ~g~E~s~ to drop - ~r~ too far from ball or to close to hole.")
		end
	end
end

clubname = "None"
function attachClub()

	if golfclub == 3 then
		TriggerEvent("attachItem","golfdriver01")
		clubname = "Wood"
	elseif golfclub == 2 then
		TriggerEvent("attachItem","golfwedge01")
		clubname = "Wedge"
	elseif golfclub == 1 then
		TriggerEvent("attachItem","golfiron01")
		clubname = "1 Iron"
	elseif golfclub == 4 then
		TriggerEvent("attachItem","golfiron03")
		clubname = "3 Iron"
	elseif golfclub == 5 then
		TriggerEvent("attachItem","golfiron05")
		clubname = "5 Iron"
	elseif golfclub == 6 then
		TriggerEvent("attachItem","golfiron07")
		clubname = "7 Iron"
	else
		TriggerEvent("attachItem","golfputter01")
		clubname = "Putter"
	end
end

function addBallBlip()
	ballBlip = AddBlipForEntity(mygolfball)
	SetBlipAsFriendly(ballBlip, true)
	SetBlipSprite(ballBlip, 161)
	BeginTextCommandSetBlipName("STRING");
	AddTextComponentString(tostring("Ball"))
	EndTextCommandSetBlipName(ballBlip)
end

function drawGolfTxt(x,y ,width,height,scale, text, r,g,b,a)
    SetTextFont(2)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.025)
end

function idleShot()
	Citizen.Trace("Idle Shot Enabled")
	power = 0.1

	local distance = GetDistanceBetweenCoords(GetEntityCoords(mygolfball), holes[golfhole]["x2"],holes[golfhole]["y2"],holes[golfhole]["z2"], true)
	if distance >= 200.0 then
		golfclub = 3 -- wood 200m-250m
	elseif distance >= 150.0 and distance < 200.0 then
		golfclub = 1 -- iron 1 140m-180m
	elseif distance >= 120.0 and distance < 250.0 then
		golfclub = 4 -- iron 3 -- 120m-150m
	elseif distance >= 90.0 and distance < 120.0 then
		golfclub = 5 -- -- iron 5 -- 70m-120m
	elseif distance >= 50.0 and distance < 90.0 then
		golfclub = 6 -- iron 7 -- 50m-100m
	elseif distance >= 20.0 and distance < 50.0 then
		golfclub = 2 --  wedge 50m-80m
	else
		golfclub = 0 -- else putter
	end

	attachClub()
	RequestScriptAudioBank("GOLF_I", 0)
	while golfstate == 2 do

		Citizen.Wait(0)

		if (IsControlPressed(1, 38)) then
			addition = 0.5

			if power > 25 then
				addition = addition + 0.1
			end
			if power > 50 then
				addition = addition + 0.2
			end
			if power > 75 then
				addition = addition + 0.3
			end
			power = power + addition
			if power > 100.0 then
				power = 1.0
			end
		end



		local box = (power * 2) / 1000

		--DrawRect(0.506,0.93,0.2,0.04,0,0,0,140) -- header
		if power > 90 then
			DrawRect(0.5,0.93,box,0.02,255,22,22,210) -- header
		else
			DrawRect(0.5,0.93,box,0.02,22,235,22,210) -- header
		end

		--DrawRect(x, y, width, height, r, g, b, a)

		local offsetball = GetOffsetFromEntityInWorldCoords(mygolfball, (power) - (power*2), 0.0, 0.0)

		DrawLine(GetEntityCoords(mygolfball), holes[golfhole]["x2"],holes[golfhole]["y2"],holes[golfhole]["z2"], 222, 111, 111, 0.2)

		DrawMarker(27,holes[golfhole]["x2"],holes[golfhole]["y2"],holes[golfhole]["z2"], 0, 0, 0, 0, 0, 0, 0.5, 0.5, 10.3, 212, 189, 0, 105, 0, 0, 2, 0, 0, 0, 0)

		--

		if (IsControlJustPressed(1, 246)) then
			local newclub = golfclub+1
			Citizen.Trace(golfclub)
			if newclub > 6 then
				newclub = 0
			end
			Citizen.Trace(golfclub .. " | " .. newclub)
			golfclub = newclub
			Citizen.Trace(golfclub)
			attachClub()
		end

		if (IsControlPressed(1, 34)) then
			rotateShot(true)
		end
		if (IsControlPressed(1, 9)) then
			rotateShot(false)
		end

		if golfclub == 0 then
			AttachEntityToEntity(GetPlayerPed(-1), mygolfball, 20, 0.14, -0.62, 0.99, 0.0, 0.0, 0.0, false, false, false, false, 1, true)
		elseif golfclub == 3 then
			AttachEntityToEntity(GetPlayerPed(-1), mygolfball, 20, 0.3, -0.92, 0.99, 0.0, 0.0, 0.0, false, false, false, false, 1, true)
		elseif golfclub == 2 then
			AttachEntityToEntity(GetPlayerPed(-1), mygolfball, 20, 0.38, -0.79, 0.94, 0.0, 0.0, 0.0, false, false, false, false, 1, true)
		else
			AttachEntityToEntity(GetPlayerPed(-1), mygolfball, 20, 0.4, -0.83, 0.94, 0.0, 0.0, 0.0, false, false, false, false, 1, true)
		end
		if (IsControlJustReleased(1, 38)) then
			if golfclub == 0 then
				playAnim = puttSwing["puttswinglow"]
			else
				playAnim = ironSwing["ironswinghigh"]
				playGolfAnim(playAnim)
				playAnim = ironSwing["ironswinglow"]
				playGolfAnim(playAnim)
				playAnim = ironSwing["ironswinglow"]
			end

			golfstate = 1
			inLoop = false
			DetachEntity(GetPlayerPed(-1), true, false)
		else
			if not inLoop then
				TriggerEvent("loopStart")
			end
		end
	end

	PlaySoundFromEntity(-1, "GOLF_SWING_FAIRWAY_IRON_LIGHT_MASTER", GetPlayerPed(-1), 0, 0, 0)

	playGolfAnim(playAnim)
	swing()

	Citizen.Wait(3380)
	endShot()
end
--DetachEntity(GetPlayerPed(-1), true, false)


function swing()
	Citizen.Trace("Swing Enabled")
	if golfclub ~= 0 then
		ballCam()
	end
	if not HasNamedPtfxAssetLoaded("scr_minigamegolf") then
		RequestNamedPtfxAsset("scr_minigamegolf")
		while not HasNamedPtfxAssetLoaded("scr_minigamegolf") do
			Wait(0)
		end
	end
	SetPtfxAssetNextCall("scr_minigamegolf")
	StartParticleFxLoopedOnEntity("scr_golf_ball_trail", mygolfball, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)

	local enabledroll = false

	dir = GetEntityHeading(mygolfball)
	local x,y = quickmafs(dir)
	FreezeEntityPosition(mygolfball, false)
	local rollpower = power / 3

	if golfclub == 0 then -- putter
		power = power / 3
		local check = 5.0
		while check < power do
			SetEntityVelocity(mygolfball, x*check,y*check,-0.1)
			Citizen.Wait(20)
			check = check + 0.3
		end

		power = power
		while power > 0 do
			SetEntityVelocity(mygolfball, x*power,y*power,-0.1)
			Citizen.Wait(20)
			power = power - 0.3
		end

	elseif golfclub == 1 then -- iron 1 140m-180m
		power = power * 1.85
		airpower = power / 2.6
		enabledroll = true
		rollpower = rollpower / 4
	elseif golfclub == 3 then -- wood 200m-250m
		power = power * 2.0
		airpower = power / 2.6
		enabledroll = true
		rollpower = rollpower / 2
	elseif golfclub == 2 then -- wedge -- 50m-80m
		power = power * 1.5
		airpower = power / 2.1
		enabledroll = true
		rollpower = rollpower / 4.5
	elseif golfclub == 4 then -- iron 3 -- 110m-150m
		power = power * 1.8
		airpower = power / 2.55
		enabledroll = true
		rollpower = rollpower / 5
	elseif golfclub == 5 then -- iron 5 -- 70m-120m
		power = power * 1.75
		airpower = power / 2.5
		enabledroll = true
		rollpower = rollpower / 5.5
	elseif golfclub == 6 then -- iron 7 -- 50m-100m
		power = power * 1.7
		airpower = power / 2.45
		enabledroll = true
		rollpower = rollpower / 6.0
	end

	while power > 0 do
		SetEntityVelocity(mygolfball, x*power,y*power,airpower)
		Citizen.Wait(0)
		power = power - 1
		airpower = airpower - 1
	end

	if enabledroll then
		while rollpower > 0 do
			SetEntityVelocity(mygolfball, x*rollpower,y*rollpower,0.0)
			Citizen.Wait(5)
			rollpower = rollpower - 1
		end
	end

	Citizen.Wait(2000)

	SetEntityVelocity(mygolfball,0.0,0.0,0.0)
	if golfclub ~= 0 then
		ballCamOff()
	end
	local x,y,z = table.unpack(GetEntityCoords(mygolfball))
	createBall(x,y,z)
	--SetEntityCoords(GetPlayerPed(-1),GetEntityCoords(mygolfball))
	FreezeEntityPosition(mygolfball, true)
end


function quickmafs(dir)
	local x = 0.0
	local y = 0.0
	local dir = dir
	if dir >= 0.0 and dir <= 90.0 then
		local factor = (dir/9.2) / 10
		x = -1.0 + factor
		y = 0.0 - factor
	end

	if dir > 90.0 and dir <= 180.0 then
		dirp = dir - 90.0
		local factor = (dirp/9.2) / 10
		x = 0.0 + factor
		y = -1.0 + factor
	end

	if dir > 180.0 and dir <= 270.0 then
		dirp = dir - 180.0
		local factor = (dirp/9.2) / 10
		x = 1.0 - factor
		y = 0.0 + factor
	end

	if dir > 270.0 and dir <= 360.0 then
		dirp = dir - 270.0
		local factor = (dirp/9.2) / 10
		x = 0.0 - factor
		y = 1.0 - factor
	end
	return x,y
end

RegisterNetEvent('loopStart')
AddEventHandler('loopStart', function()
	inLoop = true
	Citizen.Trace("Idle Enabled")
	while inLoop do
		Citizen.Wait(0)
		idleLoop()
	end
end)

function idleLoop()
	if golfclub == 0 then
		playAnim = puttSwing["puttidle"]
	else
		if (IsControlPressed(1, 38)) then
			playAnim = ironSwing["ironidlehigh"]
		else
			playAnim = ironSwing["ironidle"]
		end
	end
	playGolfAnim(playAnim)
	Citizen.Wait(1200)
end


function reactBad()
	if golfclub == 0 then
		playAnim = reactBadPutt[math.random(10)]
	else
		playAnim = reactBadSwing[math.random(10)]
	end
	playGolfAnim(playAnim)
end



function playGolfAnim(anim)
	--ClearPedSecondaryTask(GetPlayerPed(-1))
	loadAnimDict( "mini@golf" )
	if IsEntityPlayingAnim(lPed, "mini@golf", anim, 3) then

	else
		length = GetAnimDuration("mini@golf", anim)
		TaskPlayAnim( GetPlayerPed(-1), "mini@golf", anim, 1.0, -1.0, length, 0, 1, 0, 0, 0)
		Citizen.Wait(length)
	end
--	ClearPedSecondaryTask(GetPlayerPed(-1))
end


function ballCam()
	ballcam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
	--AttachCamToEntity(ballcam, mygolfball, -2.0,0.0,-2.0, false)
	SetCamFov(ballcam, 90.0)
	RenderScriptCams(true, true, 3, 1, 0)

	TriggerEvent("camFollowBall")
end

RegisterNetEvent('camFollowBall')
AddEventHandler('camFollowBall', function()
	local timer = 20000
	while timer > 0 do
		Citizen.Wait(5)
		x,y,z = table.unpack(GetEntityCoords(mygolfball))
		SetCamCoord(ballcam, x,y-10,z+9)
		PointCamAtEntity(ballcam, mygolfball, 0.0, 0.0, 0.0, true)
		timer = timer - 1
	end
end)



function ballCamOff()
	RenderScriptCams(false, false, 0, 1, 0)
	DestroyCam(ballcam, false)
end


function loadAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 5 )
    end
end

ironSwing = {
	["ironshufflehigh"] = "iron_shuffle_high",
	["ironshufflelow"] = "iron_shuffle_low",
	["ironshuffle"] = "iron_shuffle",
	["ironswinghigh"] = "iron_swing_action_high",
	["ironswinglow"] = "iron_swing_action_low",
	["ironidlehigh"] = "iron_swing_idle_high",
	["ironidlelow"] = "iron_swing_idle_low",
	["ironidle"] = "iron_shuffle",
	["ironswingintro"] = "iron_swing_intro_high"
}


puttSwing = {
	["puttshufflelow"] = "iron_shuffle_low",
	["puttshuffle"] = "iron_shuffle",
	["puttswinglow"] = "putt_action_low",
	["puttidle"] = "putt_idle_low",
	["puttintro"] = "putt_intro_low",
	["puttintro"] = "putt_outro"
}

function startHole()
	Citizen.Trace("Start Hole")
	BlipsStartEnd()
	ballstate = 0
	golfstate = 1
end

function BlipsStartEnd()
	if startblip ~= nil then
		RemoveBlip(startblip)
		RemoveBlip(endblip)
	end
	startblip = AddBlipForCoord(holes[golfhole]["x"],holes[golfhole]["y"],holes[golfhole]["z"])
	SetBlipAsFriendly(startblip, true)
	SetBlipSprite(startblip, 161)
	BeginTextCommandSetBlipName("STRING");
	AddTextComponentString(tostring("Start of Hole"))
	EndTextCommandSetBlipName(startblip)
	endblip = AddBlipForCoord(holes[golfhole]["x2"],holes[golfhole]["y2"],holes[golfhole]["z2"])
	SetBlipAsFriendly(endblip, true)
	SetBlipSprite(endblip, 109)
	BeginTextCommandSetBlipName("STRING");
	AddTextComponentString(tostring("End of Hole"))
	EndTextCommandSetBlipName(endblip)
	createBall(holes[golfhole]["x"],holes[golfhole]["y"],holes[golfhole]["z"])
end


function addblipGC()
	gcblip = AddBlipForCoord(-1332.7823486328,128.18229675293,56.032329559326)
	SetBlipAsFriendly(gcblip, true)
	SetBlipSprite(gcblip, 109)
	SetBlipColour(gcblip, 68)
	SetBlipAsShortRange(gcblip,true)
	BeginTextCommandSetBlipName("STRING");
	AddTextComponentString(tostring("Golf Course"))
	EndTextCommandSetBlipName(gcblip)
end

holes = {
	[1] = { ["par"] = 5, ["x"] = -1371.3370361328, ["y"] = 173.09497070313, ["z"] = 57.013027191162, ["x2"] = -1114.2274169922, ["y2"] = 220.8424987793, ["z2"] = 63.8947830200},
	[2] = { ["par"] = 4, ["x"] = -1107.1888427734, ["y"] = 156.581298828, ["z"] = 62.03958129882, ["x2"] = -1322.0944824219, ["y2"] = 158.8779296875, ["z2"] = 56.80027008056},
	[3] = { ["par"] = 3, ["x"] = -1312.1020507813, ["y"] = 125.8329391479, ["z"] = 56.4341888427, ["x2"] = -1237.347412109, ["y2"] = 112.9838562011, ["z2"] = 56.20140075683},
	[4] = { ["par"] = 4, ["x"] = -1216.913208007, ["y"] = 106.9870910644, ["z"] = 57.03926086425, ["x2"] = -1096.6276855469, ["y2"] = 7.780227184295, ["z2"] = 49.73574447631},
	[5] = { ["par"] = 4, ["x"] = -1097.859619140, ["y"] = 66.41466522216, ["z"] = 52.92545700073, ["x2"] = -957.4982910156, ["y2"] = -90.37551879882, ["z2"] = 39.2753639221},
	[6] = { ["par"] = 3, ["x"] = -987.7417602539, ["y"] = -105.0764007568, ["z"] = 39.585887908936, ["x2"] = -1103.506958007, ["y2"] = -115.2364349365, ["z2"] = 40.55868911743},
	[7] = { ["par"] = 4, ["x"] = -1117.0194091797, ["y"] = -103.8586044311, ["z"] = 40.8405838012, ["x2"] = -1290.536499023, ["y2"] = 2.7952194213867, ["z2"] = 49.34057998657},
	[8] = { ["par"] = 5, ["x"] = -1272.251831054, ["y"] = 38.04283142089, ["z"] = 48.72544860839, ["x2"] = -1034.80187988, ["y2"] = -83.16706085205, ["z2"] = 43.0353431701},
	[9] = { ["par"] = 4, ["x"] = -1138.319580078, ["y"] = -0.1342505216598, ["z"] = 47.98218917846, ["x2"] = -1294.685913085, ["y2"] = 83.5762557983, ["z2"] = 53.92817306518}
}

function playAudio(num)
	RequestScriptAudioBank("GOLF_I", 0)
	PlaySoundFromEntity(-1, sounds[num], GetPlayerPed(-1), 0, 0, 0)
end

sounds = {
	[1] = "GOLF_SWING_GRASS_LIGHT_MASTER",
	[2] = "GOLF_SWING_GRASS_PERFECT_MASTER",
	[3] = "GOLF_SWING_GRASS_MASTER",
	[4] = "GOLF_SWING_TEE_LIGHT_MASTER",
	[5] = "GOLF_SWING_TEE_PERFECT_MASTER",
	[6] = "GOLF_SWING_TEE_MASTER",
	[7] = "GOLF_SWING_TEE_IRON_LIGHT_MASTER",
	[8] = "GOLF_SWING_TEE_IRON_PERFECT_MASTER",
	[9] = "GOLF_SWING_TEE_IRON_MASTER",
	[10] = "GOLF_SWING_FAIRWAY_IRON_LIGHT_MASTER",
	[11] = "GOLF_SWING_FAIRWAY_IRON_PERFECT_MASTER",
	[12] = "GOLF_SWING_FAIRWAY_IRON_MASTER",
	[13] = "GOLF_SWING_ROUGH_IRON_LIGHT_MASTER",
	[14] = "GOLF_SWING_ROUGH_IRON_PERFECT_MASTER",
	[15] = "GOLF_SWING_ROUGH_IRON_MASTER",
	[16] = "GOLF_SWING_SAND_IRON_LIGHT_MASTER",
	[17] = "GOLF_SWING_SAND_IRON_PERFECT_MASTER",
	[18] = "GOLF_SWING_SAND_IRON_MASTER",
	[19] = "GOLF_SWING_CHIP_LIGHT_MASTER",
	[20] = "GOLF_SWING_CHIP_PERFECT_MASTER",
	[21] = "GOLF_SWING_CHIP_MASTER",
	[22] = "GOLF_SWING_CHIP_GRASS_LIGHT_MASTER",
	[23] = "GOLF_SWING_CHIP_GRASS_MASTER",
	[24] = "GOLF_SWING_CHIP_SAND_LIGHT_MASTER",
	[25] = "GOLF_SWING_CHIP_SAND_PERFECT_MASTER",
	[26] = "GOLF_SWING_CHIP_SAND_MASTER",
	[27] = "GOLF_SWING_PUTT_MASTER",
	[28] = "GOLF_FORWARD_SWING_HARD_MASTER",
	[29] = "GOLF_BACK_SWING_HARD_MASTER"
}


function removeAttachedProp()
	DeleteEntity(attachedProp)
	attachedProp = 0
end


-- attach bull shit

RegisterNetEvent('customNotification')
AddEventHandler('customNotification', function(response)
	TriggerEvent('chatMessage', 'GOLF: ', { 0, 11, 0 }, response)
end)

RegisterNetEvent('destroyProp')
AddEventHandler('destroyProp', function()
	removeAttachedProp()
end)

RegisterNetEvent('attachProp')
AddEventHandler('attachProp', function(attachModelSent,boneNumberSent,x,y,z,xR,yR,zR)
	removeAttachedProp()
	attachModel = GetHashKey(attachModelSent)
	boneNumber = boneNumberSent
	SetCurrentPedWeapon(GetPlayerPed(-1), 0xA2719263)
	local bone = GetPedBoneIndex(GetPlayerPed(-1), boneNumberSent)
	--local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))
	RequestModel(attachModel)
	while not HasModelLoaded(attachModel) do
		Citizen.Wait(100)
	end
	attachedProp = CreateObject(attachModel, 1.0, 1.0, 1.0, 1, 1, 0)
	AttachEntityToEntity(attachedProp, GetPlayerPed(-1), bone, x, y, z, xR, yR, zR, 1, 1, 0, 0, 2, 1)
end)

attachPropList = {

	["golfbag01"] = {
		["model"] = "prop_golf_bag_01", ["bone"] = 24816, ["x"] = 0.12,["y"] = -0.3,["z"] = 0.0,["xR"] = -75.0,["yR"] = 190.0, ["zR"] = 92.0
	},

	["golfputter01"] = {
		["model"] = "prop_golf_putter_01", ["bone"] = 57005, ["x"] = 0.0,["y"] = -0.05,["z"] = 0.0,["xR"] = 90.0,["yR"] = -118.0, ["zR"] = 44.0
	},

	["golfiron01"] = {
		["model"] = "prop_golf_iron_01", ["bone"] = 57005, ["x"] = 0.125,["y"] = 0.04,["z"] = 0.0,["xR"] = 90.0,["yR"] = -118.0, ["zR"] = 44.0
	},
	["golfiron03"] = {
		["model"] = "prop_golf_iron_01", ["bone"] = 57005, ["x"] = 0.126,["y"] = 0.041,["z"] = 0.0,["xR"] = 90.0,["yR"] = -118.0, ["zR"] = 44.0
	},
	["golfiron05"] = {
		["model"] = "prop_golf_iron_01", ["bone"] = 57005, ["x"] = 0.127,["y"] = 0.042,["z"] = 0.0,["xR"] = 90.0,["yR"] = -118.0, ["zR"] = 44.0
	},
	["golfiron07"] = {
		["model"] = "prop_golf_iron_01", ["bone"] = 57005, ["x"] = 0.128,["y"] = 0.043,["z"] = 0.0,["xR"] = 90.0,["yR"] = -118.0, ["zR"] = 44.0
	},
	["golfwedge01"] = {
		["model"] = "prop_golf_pitcher_01", ["bone"] = 57005, ["x"] = 0.17,["y"] = 0.04,["z"] = 0.0,["xR"] = 90.0,["yR"] = -118.0, ["zR"] = 44.0
	},

	["golfdriver01"] = {
		["model"] = "prop_golf_driver", ["bone"] = 57005, ["x"] = 0.14,["y"] = 0.00,["z"] = 0.0,["xR"] = 160.0,["yR"] = -60.0, ["zR"] = 10.0
	}

}

RegisterNetEvent('attachItem')
AddEventHandler('attachItem', function(item)
	TriggerEvent("attachProp",attachPropList[item]["model"], attachPropList[item]["bone"], attachPropList[item]["x"], attachPropList[item]["y"], attachPropList[item]["z"], attachPropList[item]["xR"], attachPropList[item]["yR"], attachPropList[item]["zR"])
end)

