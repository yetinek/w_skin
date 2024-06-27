local changeElementsTo0 = {
	["tshirt_1"] = "tshirt_2",
	["torso_1"] = "torso_2",
	["decals_1"] = "decals_2",
	["arms"] = "arms_2",
	["pants_1"] = "pants_2",
	["shoes_1"] = "shoes_2",
	["mask_1"] = "mask_2",
	["bproof_1"] = "bproof_2",
	["chain_1"] = "chain_2",
	["helmet_1"] = "helmet_2",
	["glasses_1"] = "glasses_2",
	["watches_1"] = "watches_2",
	["bracelets_1"] = "bracelets_2",
	["bags_1"] = "bags_2",
	["ears_1"] = "ears_2",
}
local GlobalSubmitCb = nil
local GlobalCancelCb = nil
local GlobalIsNew = false
local GlobalElements = {}
local hairColors = {}
local makeupColors = {}
local LastSkin = nil
local CreatingCharacter = false
local cam = nil
local offsetZ = 0.0
local cam_offset = nil
local cam_coords = nil

function GetSkinElements(ped)
    local p = promise.new()

	TriggerEvent('skinchanger:getSkin', function(skin)
		LastSkin = skin
	end)
	
    TriggerEvent('skinchanger:getData', function(components, maxVals)
        local elements = {}
        local _components = {}

		for i=1, #components, 1 do
			_components[i] = components[i]
		end

        for i=1, #_components, 1 do
            local max         = nil
            local value       = _components[i].value
            local componentId = _components[i].componentId
            if componentId == 0 then
                value = GetPedPropIndex(PlayerPedId(), _components[i].componentId)
            end

            for k,v in pairs(maxVals) do
                if k == _components[i].name then
                    max = v
                end
            end

            elements[_components[i].name] = {
                label     = _components[i].label,
                name      = _components[i].name,
                value     = value,
                min       = _components[i].min,
                max       = max
            }
        end

        p:resolve(elements)
    end, ped)
    GlobalElements = Citizen.Await(p)
    return GlobalElements
end

function OpenSkinMenu(submitCb, cancelCb, type, title, desc, new, isped)
	GlobalIsNew = new
    GlobalSubmitCb = submitCb
    GlobalCancelCb = cancelCb

	SendNUIMessage({
		action = "UpdateColors",
		hairColors = hairColors,
		makeupColors = makeupColors
	})

    SendNUIMessage({
        action = "OpenSkinMenu",
        skinElements = GetSkinElements(isped),
        type = type,
        title = title,
        description = desc
    })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
	-- exports['w_hud']:ChangeHideResourceState(true)
    CreateSkinCam(new)
end

RegisterNUICallback('exit', function(data, cb)
	if GlobalIsNew then
		cb(false)
	else
		exports['w_hud']:OpenConfirmMenu({
			title = 'Czy napewno chcesz opuścić menu skina?',
			desc = 'Po opuszczeniu skin zostanie cofnięty',
		}, function(callback)
			if callback then
				SetNuiFocus(false, false)
				SetNuiFocusKeepInput(false)
				DeleteSkinCam()
				TriggerEvent('skinchanger:loadSkin', LastSkin)
				if GlobalCancelCb then
					GlobalCancelCb()
				end
				cb(true)
			else
				cb(false)
			end
		end)
	end
end)

CheckDefaultSkin = function()
	local torso = nil
	local pants = nil
	local shoes = nil
	local total = 0
	TriggerEvent('skinchanger:getSkinElement', function(cb)
		torso = cb
		if torso == 0 then
			total += 1
		end
	end, 'torso_1')
	TriggerEvent('skinchanger:getSkinElement', function(cb)
		pants = cb
		if pants == 0 then
			total += 1
		end
	end, 'pants_1')
	TriggerEvent('skinchanger:getSkinElement', function(cb)
		shoes = cb
		if shoes == 0 then
			total += 1
		end
	end, 'shoes_1')
	return total >= 2
end

Citizen.CreateThread(function()
	for i = 0, GetNumHairColors()-1 do
		local outR, outG, outB= GetPedHairRgbColor(i)
		hairColors[i] = {outR, outG, outB}
	end
	for i = 0, GetNumMakeupColors()-1 do
		local outR, outG, outB= GetPedMakeupRgbColor(i)
		makeupColors[i] = {outR, outG, outB}
	end
end)

RegisterNUICallback('changeColor', function(data)
	TriggerEvent('skinchanger:change', data.name, tonumber(data.color))
end)

RegisterNUICallback("changeSkin", function(data)
    TriggerEvent('skinchanger:change', data.name, tonumber(data.value))
    TriggerEvent('skinchanger:getData', function(components, maxVals)
        for _, element in pairs(GlobalElements) do
            if changeElementsTo0[data.name] then
				if element.name == changeElementsTo0[data.name] then
					TriggerEvent('skinchanger:change', element.name, element.min)
					element.value = element.min
					local newmin = element.min
					local newmax = maxVals[element.name]
					SendNUIMessage({
						action = "UpdateSkinVals",
						name = element.name,
						max = newmax,
						min = newmin,
						value = element.value
					})
                    break
				end
			end
        end
    end)
end)

local ZoomParts = {
	["sex"] = {offsetZ = 0.0, fov = 72.0},
	["face"] = {offsetZ = 0.75, fov = 15.0},
	["skin"] = {offsetZ = 0.38, fov = 44.5},
	["bodyb_1"] = {offsetZ = 0.25, fov = 40.0},
	["eye_color"] = {offsetZ = 0.75, fov = 15.0},
	["nose_1"] = {offsetZ = 0.75, fov = 15.0},
	["cheeks_1"] = {offsetZ = 0.75, fov = 15.0},
	["jaw_1"] = {offsetZ = 0.75, fov = 15.0},
	["chimp_1"] = {offsetZ = 0.75, fov = 15.0},
	["neck"] = {offsetZ = 0.75, fov = 15.0},
	["lipstick_1"] = {offsetZ = 0.75, fov = 15.0},
	["lips"] = {offsetZ = 0.75, fov = 15.0},
	["makeup_1"] = {offsetZ = 0.75, fov = 15.0},
	["blush_1"] = {offsetZ = 0.75, fov = 15.0},
	["blemishes_1"] = {offsetZ = 0.75, fov = 15.0},
	["sun_1"] = {offsetZ = 0.75, fov = 15.0},
	["moles_1"] = {offsetZ = 0.75, fov = 15.0},
	["age_1"] = {offsetZ = 0.75, fov = 15.0},
	["complexion_1"] = {offsetZ = 0.75, fov = 15.0},

	["hair_1"] = {offsetZ = 0.75, fov = 17.5},
	["chest_1"] = {offsetZ = 0.32, fov = 35.0},
	["eyebrows_1"] = {offsetZ = 0.75, fov = 15.0},
	["beard_1"] = {offsetZ = 0.75, fov = 15.0},

	["tshirt_1"] = {offsetZ = 0.25, fov = 40.0},
	["torso_1"] = {offsetZ = 0.25, fov = 40.0},
	["arms"] = {offsetZ = 0.25, fov = 40.0},
	["pants_1"] = {offsetZ = -0.33, fov = 40.0},
	["shoes_1"] = {offsetZ = -0.75, fov = 30.0},
	["mask_1"] = {offsetZ = 0.75, fov = 15.0},
	["bproof_1"] = {offsetZ = 0.25, fov = 40.0},
	["helmet_1"] = {offsetZ = 0.75, fov = 25.0},
	["glasses_1"] = {offsetZ = 0.75, fov = 15.0},
	["bags_1"] = {offsetZ = 0.25, fov = 45.0},

	["decals_1"] = {offsetZ = 0.25, fov = 50.0},
	["chain_1"] = {offsetZ = 0.6, fov = 20.0},
	["watches_1"] = {offsetZ = -0.06, fov = 30.0},
	["bracelets_1"] = {offsetZ = -0.06, fov = 30.0},
	["ears_1"] = {offsetZ = 0.75, fov = 15.0},
}

RegisterNUICallback('changeClothes', function(data)
	if not cam then return end
	local index = data.index
	offsetZ = ZoomParts[index].offsetZ
	SetCamCoord(cam, cam_offset.x, cam_offset.y, cam_offset.z + offsetZ)
	PointCamAtCoord(cam, cam_coords.x, cam_coords.y, cam_coords.z + offsetZ)
	SetCamFov(cam, ZoomParts[index].fov)
end)

RegisterNUICallback("saveSkin", function(data, cb)
	if not data.InPedMenu and CheckDefaultSkin() then
		cb({close = false, error = "Utwórz charakterystyczny wygląd postaci"})
	else
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)
		exports['w_hud']:ChangeHideResourceState(false)
		DeleteSkinCam()
		if GlobalSubmitCb then
			GlobalSubmitCb()
		end
		cb({close = true})
	end
end)

RegisterNuiCallback('handsup', function()
	exports['w_animations']:ToggleHandsUp()
end)

function OpenSaveableMenu(submitCb, cancelCb, new)
    OpenSkinMenu(function()
		TriggerEvent('skinchanger:getSkin', function(skin)
			TriggerServerEvent('w_skin:save', skin)
            if submitCb ~= nil then
                submitCb()
            end
        end)
    end, cancelCb, nil, "Edycja Postaci", "Zmień wygląd swojej postaci.", new)
end
RegisterNetEvent("w_skin:openSaveableMenu", OpenSaveableMenu)
exports("openSaveableMenu", OpenSaveableMenu)

RegisterNetEvent('w_skin:openRestrictedMenu')
AddEventHandler('w_skin:openRestrictedMenu', function(submitCb, cancelCb, restrict)
	OpenSkinMenu(submitCb, cancelCb, restrict, "Edycja Postaci", "Zmień wygląd swojej postaci.")
end)

exports("OpenShopMenu", function(submitCb, cancelCb, type, title, desc)
    OpenSkinMenu(submitCb, cancelCb, type, title, desc)
end)

function CreateSkinCam(new)
	local playerPed = ESX.PlayerData.ped
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(cam, true)
	RenderScriptCams(true, true, 500, true, true)
    SetCamRot(cam, 0.0, 0.0, 270.0, true)
	cam_coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.0, -0.1)
	cam_offset = GetOffsetFromEntityInWorldCoords(playerPed, 0.1, 1.4, 0.1)
	SetCamCoord(cam, cam_offset.x, cam_offset.y, cam_offset.z)
	PointCamAtCoord(cam, cam_coords.x, cam_coords.y, cam_coords.z)
    SetCamFov(cam, 72.0)
    offsetZ = 0.0
    while cam do
        DisableAllControlActions(0)
		if not CreatingCharacter then
			EnableControlAction(0, 249, true)
		end
		if IsDisabledControlPressed(0, 44) and offsetZ < 0.75 then -- GÓRA
			offsetZ = offsetZ + 0.01
			SetCamCoord(cam, cam_offset.x, cam_offset.y, cam_offset.z + offsetZ)
			PointCamAtCoord(cam, cam_coords.x, cam_coords.y, cam_coords.z + offsetZ)
		end
		if IsDisabledControlPressed(0, 38) and offsetZ > -0.75 then -- DOŁ
			offsetZ = offsetZ - 0.01
			SetCamCoord(cam, cam_offset.x, cam_offset.y, cam_offset.z + offsetZ)
			PointCamAtCoord(cam, cam_coords.x, cam_coords.y, cam_coords.z + offsetZ)
		end
		if IsDisabledControlPressed(0, 32) and GetCamFov(cam) > 15.0 then -- PRZYBLIZENIE
			SetCamFov(cam, GetCamFov(cam) - 0.2)
		end
		if IsDisabledControlPressed(0, 33) and GetCamFov(cam) < 72.0 then -- ODDALENIE
			SetCamFov(cam, GetCamFov(cam) + 0.2)
		end
		if IsDisabledControlPressed(0, 34) then -- OBRÓT LEWO
			SetEntityHeading(playerPed, GetEntityHeading(playerPed) - 1.0)
		end
		if IsDisabledControlPressed(0, 35) then -- OBRÓT PRAWO
			SetEntityHeading(playerPed, GetEntityHeading(playerPed) + 1.0)
		end
        Wait(0)
    end
end

function DeleteSkinCam()
    SetCamActive(cam, false)
	RenderScriptCams(false, true, 500, true, true)
    cam = nil
end

local CreatingCharacterCoords = vector4(-1449.880859375, -549.10107421875, 72.843719482422, 122.34545898438)
local Markers = {
	{coords = vector3(-1455.7796630859, -548.22674560547, 72.84375), action = 'exit', text = 'Naciśnij   ~INPUT_CONTEXT~, aby wyjść z domku'},
	{coords = vector3(-1458.650390625, -551.33862304688, 72.878921508789), action = 'skin', text = 'Naciśnij   ~INPUT_CONTEXT~, aby zmienić wygląd postaci'},
	{coords = vector3(-1456.8656005859, -549.98956298828, 72.878921508789), action = 'data', text = 'Naciśnij   ~INPUT_CONTEXT~, aby poprawić dane postaci'}
}
local InRoom = false

NearToSpawn = function(coords)
	return #(vec3(coords.x, coords.y, coords.z) - vec3(CreatingCharacterCoords[1], CreatingCharacterCoords[2], CreatingCharacterCoords[3])) < 20.0
end

exports('InRoom', function()
	return InRoom
end)

exports('LoadPlayer', function(skin, coords)
	if skin == nil or NearToSpawn(coords) then
		CreatingCharacter = true
		InRoom = true
		exports['ox_target']:ToggleTarget(false)
		SetPlayerInvincible(PlayerId(), 1)

		Citizen.CreateThread(function()
			while InRoom do
				SetLocalPlayerVisibleLocally(true)
				DisableControlAction(2, 25) -- celowanie
				for _, player in ipairs(GetActivePlayers()) do
					if player ~= PlayerId() then
						local ped = PlayerPedId()
						local _ped = GetPlayerPed(player)
						SetEntityNoCollisionEntity(ped, _ped, true)
						SetEntityNoCollisionEntity(_ped, ped, true)
					end
				end
				Citizen.Wait(0)
			end
		end)

		TriggerEvent('skinchanger:loadSkin', {sex = 0})
		Citizen.Wait(1000)

		local ped = PlayerPedId()
		FreezeEntityPosition(ped, true)
		SetEntityCoords(ped, CreatingCharacterCoords[1], CreatingCharacterCoords[2], CreatingCharacterCoords[3] - 1.0)
		SetEntityHeading(ped, CreatingCharacterCoords[4])
		Citizen.Wait(1000)
		DoScreenFadeIn(1000)

		Citizen.CreateThread(function()
			OpenSaveableMenu(function()
				CreatingCharacter = false
			end, function()
				CreatingCharacter = false
			end, true)
		end)

		while CreatingCharacter do
			Citizen.Wait(0)
		end

		FreezeEntityPosition(PlayerPedId(), false)

		Citizen.CreateThread(function()
			while true do
				Citizen.Wait(0)
				local doors = GetClosestObjectOfType(-1455.654419, -547.158936, 72.993340, 1.0, 34120519, false, false, false)
				FreezeEntityPosition(doors, true)
				for _, v in pairs(Markers) do
					local distance = #(GetEntityCoords(ESX.PlayerData.ped) - v.coords)
					if distance <= 10 then
						ESX.DrawMarker(27, vec3(v.coords[1], v.coords[2], v.coords[3]-0.95), {1.5, 1.5, 1.5})
						sleep = false
						if distance <= 1.0 then
							ESX.ShowFloatingHelpNotification(v.text, v.coords)
							if IsControlJustReleased(0, 38) then
								if v.action == 'exit' then
									exports['w_hud']:OpenConfirmMenu({
										title = 'Czy napewno chcesz opuścić menu kreator postaci?',
										desc = 'Po opuszczeniu nie będziesz mógł wrócić oraz zmienić danych oraz wyglądu swojej postaci',
									}, function(callback)
										if callback then
											exports['w_characters']:SpawnSelector()
										end
									end)
								elseif v.action == 'skin' then
									OpenSaveableMenu()
								elseif v.action == 'data' then
									exports['w_characters']:ChangeData()
								end
							end
						end
					end
				end
			end
		end)
	else
		TriggerEvent('skinchanger:loadSkin', skin)
		SetPlayerForGame(coords, PlayerPedId(), false)
	end
end)

RegisterNuiCallback('SelectSpawnAndVehicle', function(data)
	InRoom = false
	exports['ox_target']:ToggleTarget(true)
	local _data = ESX.GetConfig().StartData
	TriggerServerEvent('w_skin:WelcomePlayer', data.vehicle)
	DoScreenFadeOut()
	SetPlayerForGame(_data.Spawns[data.spawn].coords, PlayerPedId(), true)
end)

SetPlayerForGame = function(coords, ped, IsNew)
	Citizen.Wait(1500)
	FreezeEntityPosition(PlayerPedId(), true)
	SetEntityVisible(PlayerPedId(), true)
	SetPlayerInvincible(PlayerId(), false)
	RequestCollisionAtCoord(coords.x, coords.y, coords.z)
	SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
	SetEntityHeading(PlayerPedId(), coords.h)
	Citizen.Wait(500)
	TriggerServerEvent("w_characters:BucketState", false)
	SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
	SetEntityHeading(PlayerPedId(), coords.h)
	if #(GetEntityCoords(PlayerPedId()) - vec3(CreatingCharacterCoords[1], CreatingCharacterCoords[2], CreatingCharacterCoords[3])) < 15.0 then
		ESX.ShowNotification('defaultNotify', (ESX.PlayerData.charinfo.sex == 'm' and 'Zostałeś przeteleportowany' or 'Zostałaś przeteleportowana') .. ' na spawn')
		SetEntityCoords(PlayerPedId(), -206.75531005859, -1015.3074951172, 30.138122558594)
	end
	if IsNearAnyArena() then
		ESX.ShowNotification('defaultNotify', (ESX.PlayerData.charinfo.sex == 'm' and 'Zostałeś przeteleportowany' or 'Zostałaś przeteleportowana') .. ' na spawn')
		SetEntityCoords(PlayerPedId(), -206.75531005859, -1015.3074951172, 30.138122558594)
	end
	FreezeEntityPosition(PlayerPedId(), false)
	Citizen.Wait(500)
	DoScreenFadeIn(1000)
	TriggerEvent('w_core:PlayerLoaded')
	if IsNew then
		exports['w_characters']:Welcome()
	end
end

IsNearAnyArena = function()
	local coords = GetEntityCoords(PlayerPedId())
	for _, v in pairs(exports['w_arenas']:GetArenas()) do
		for _, d in pairs(v) do
			if #(coords - vec3(d[1], d[2], d[3])) < 75.0 then
				return true
			end
		end
	end
	return false
end

local AntytrollPlayers = {}
local AntytrollTime = 0

RegisterNetEvent('w_skin:Antytroll:AddPlayer', function(player)
	AntytrollPlayers[player] = true
	local _net = GetPlayerFromServerId(player)
	if _net == -1 or _net == 0 or _net == nil then
		return
	end
	SetEntityAlpha(GetPlayerPed(_net), 204, false)
end)

RegisterNetEvent('w_skin:Antytroll:RemovePlayer', function(player)
	AntytrollPlayers[player] = nil
	local _net = GetPlayerFromServerId(player)
	if _net == -1 or _net == 0 or _net == nil then
		return
	end
	ResetEntityAlpha(GetPlayerPed(_net))
	if player == GetPlayerServerId(PlayerId()) then
		AntytrollTime = 0
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)
		local ped = ESX.PlayerData.ped
		for player, _ in pairs(AntytrollPlayers) do
			player = NetworkGetPlayerIndexFromPed(GetPlayerPed(GetPlayerFromServerId(player)))
			if player ~= PlayerId() then
				veh2 = GetVehiclePedIsIn(GetPlayerPed(player), false)
				if veh2 ~= 0 then
					SetEntityNoCollisionEntity(ped, veh2, true)
					SetEntityNoCollisionEntity(veh2, ped, true)
				end
			end
		end
	end
end)

StartAntytrollWhile = function()
	ESX.TriggerServerCallback("w_skin:Antytroll:Check", function(CallbackTime)
		AntytrollTime = CallbackTime
		if AntytrollTime > 0 then
			local PlayerID = PlayerId()
			Citizen.CreateThread(function()
				while true do
					Citizen.Wait(1)
					local ped = ESX.PlayerData.ped
					if AntytrollTime > 0 then
						Draw2DText(0.51, 0.83, 1.0, 1.0, 0.4, 'Anty Troll będzie jeszcze aktywny przez '..AntytrollTime..' minut', 255, 255, 255, 255)
						-- SetEntityCanBeDamaged(ped, false)
						SetPlayerInvincible(PlayerID, 1)
						DisableControlAction(2, 25) -- celowanie
						for _, player in pairs(GetActivePlayers()) do
							if player ~= PlayerID then
								veh2 = GetVehiclePedIsIn(GetPlayerPed(player), false)
								if veh2 ~= 0 then
									SetEntityNoCollisionEntity(ped, veh2, true)
									SetEntityNoCollisionEntity(veh2, ped, true)
								end
							end
						end
					else
						SetEntityCanBeDamaged(ped, true)
						SetPlayerInvincible(PlayerID, 0)
						TriggerServerEvent('w_skin:Antytroll:RemovePlayer')
						break
					end
				end
			end)

			Citizen.CreateThread(function()
				while true do
					if AntytrollTime > 0 then
						Citizen.Wait(60000)
						AntytrollTime = AntytrollTime - 1
						TriggerServerEvent('w_skin:Antytroll:SavePlayer', AntytrollTime)
					else
						break
					end
				end
			end)
		end
	end)
end

Draw2DText = function(x, y, width, height, scale, text, r, g, b, a)
	SetTextFont(0)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextDropshadow(0, 0, 0, 0,255)
	SetTextDropShadow()
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(x - width/2, y - height/2 + 0.005)
end

RegisterNetEvent('w_skin:openSaveableMenuPed', function(submitCb, cancelCb)
	OpenSkinMenu(function()
		TriggerEvent('skinchanger:getSkin', function(skin)
			TriggerServerEvent('w_skin:save', skin)
			if submitCb ~= nil then
				submitCb()
			end
		end)
	end, cancelCb, 'pedMenu', "Edycja Postaci", "Zmień wygląd swojej postaci.", false, true)
end)

RegisterCommand('tests', function()
	TriggerEvent("w_skin:openSaveableMenu", _source)
end)