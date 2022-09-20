--[Made by Jozeni00]--
print("Jozeni00\'s Data Serializer Legacy loaded.")

--[[

	[API]
	
	----------------------------------------------------------------------------------
	--[DataSerializer]--
	
	PROPERTIES:
	
	*dictionary* DataSerializer.DataStores
	A dictionary list of DataStores in use.
	
	METHODS:
	
	*DataStore* DataSerializer:GetStore(name: string, options: DataStoreOptions)
	Gets the data store from DataStoreService.
	
	name: string (optional) (Default: "") The name of the Data Store.
	options: DataStoreOptions (optional)
	
	Returns a DataStore table with usable functions.
	
	*dictionary* DataSerializer:ListStores()
	Returns a single dictionary of GlobalDataStores currently in use.
		{
			[Name] = GlobalDataStore;
		}
	
	*void* DataSerializer:SetRetries(retries: int, delay: double)
	Sets the number of retries and the time of delay (in seconds) in between retries.
	
	retries: int (optional) (Default: 3)
	delay: double (optional) (Default: 2.0)
	
	----------------------------------------------------------------------------------
	--[DataStore]--
	
	PROPERTIES:
	
	*GlobalDataStore* DataStore.GlobalDataStore
	The GlobalDataStore currently being used.
	
	METHODS:
	
	*folder*, *dictionary*, *variant* DataStore:Get(plr: player, key: string, userids: array, options: DataStoreSetOptions)
	Initializes/gets the data store folder for the player. If the folder does not exist, it will be parented to the player. 
	If the player does not have old data, then PresetPlayerData will be set as the new default data for the player.
	plr:SetAttribute("DataStoreLoaded", folderName: string) is called after the player finishes loading, returns the name of Folder.
	
	plr: player
	Key: string
	userids: array (optional) Array of UserIds. Recommended for handling GDPR. i.e. {Player.UserId} or {123456}.
	options: DataStoreSetOptions (optional) DataStoreSetOptions object. Part of DataStore v2, metadata options.
	
	Returns the Folder of PlayerData that is parented to the player, a dictionary of serialized PlayerData, 
		and DataStoreKeyInfo object if the player has played before, or Version Identifier object if the player is new.
		If an error occured while retrieving Player data, then only the Folder will be returned.
	
	*void* DataStore:Update(plr: Player, key: string)
	Serializes the folder, then sends it to the Data Store.
	plr:SetAttribute("IsSavingData", true) is called first, while DataStore is updating data.
	plr:SetAttribute("IsSavingData", false) is called after the DataStore finishes updating data.
	
	plr: player
	Key: string
	
	*void* DataStore:CleanUpdate(plr: Player, key: string)
	Serializes the folder, then sends it to the Data Store. Also, cleans up debris.
		This is only recommended to use when the player leaves.
	plr:SetAttribute("IsSavingData", true) is called first, while DataStore is updating data.
	plr:SetAttribute("IsSavingData", false) is called after the DataStore finishes updating data.
		
	plr: player
	Key: string
	
	*dictionary*, *DataStoreKeyInfo* DataStore:Remove(key: string)
	Deletes the key associated with this DataStore.
		
	Key: string
	
	Returns a dictionary of the old deleted data, and DataStoreKeyInfo object.
	
]]

--[[
	
	How To Use:
	
	Insert a folder named "PresetPlayerData" into ServerStorage.
	Any instance under the folder will be serialized sent to DataStore.

]]

--[[
Prebuilt Script that utilizes this module:

--[Made by Jozeni00]--
--settings
local DataSettings = {
	--{DATA}--
	--Any changes made below are susceptible to a clean data wipe, or revert data to its previous.
	["Name"] = "DS_TestLV0-0-0"; --DataStore name for the entire game.
	["Key"] = "Plr_"; --prefix for key. Example: "Player_" is used for "Player_123456".

	--{FEATURES}--
	["AutoSave"] = true; --set to true to enable auto saving.
	["SaveTime"] = 1; --time (in minutes) how often it should automatically save.

	["UseStudioScope"] = true; --set to true to use a different Scope for Studio only.
	["DevName"] = "DEV/DS_TestLV0-0-0"; --Name of the Data Store for Studio if UseStudioScope is true.
	["DevKey"] = "Dev_"; --Key of the Data Store for Studio, if UseStudioScope is true.
}

--scripts
local ServerScriptService = game:GetService("ServerScriptService")
local dataModule = ServerScriptService:FindFirstChild("DataSerializer") -- DataSerializer Module Script.
local DataSerializer = require(dataModule)

--players
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--set scope
if DataSettings.UseStudioScope then
	if RunService:IsStudio() then
		DataSettings.Name = DataSettings.DevName
		DataSettings.Key = DataSettings.DevKey
	end
end

local DataStore = DataSerializer:GetStore(DataSettings.Name)

--on entered
function onPlayerEntered(Player)
	local key = DataSettings.Key .. Player.UserId
	
	--player data
	local PlayerData = DataStore:Get(Player, key, {Player.UserId})
	
	if DataStore and DataSettings.AutoSave then
		local isGame = true
		local plrRemove = nil
		if DataSettings.SaveTime < 1 then
			DataSettings.SaveTime = 1
		end
		local saveTimer = DataSettings.SaveTime * 60
		
		plrRemove = Players.PlayerRemoving:Connect(function(plr)
			if plr == Player then
				isGame = false
			end
		end)
		
		while Player and isGame do
			task.wait(saveTimer)
			
			--update
			DataStore:Update(Player, key)
		end
		
		if plrRemove and plrRemove.Connected then
			plrRemove:Disconnect()
		end
	end
end

--on removing
function onPlayerRemoving(Player)
	local key = DataSettings.Key .. Player.UserId
	DataStore:CleanUpdate(Player, key)
end

for i, v in pairs(Players:GetPlayers()) do
	if v:IsA("Player") then
		local onEnter = coroutine.wrap(function()
			onPlayerEntered(v)
		end)
		onEnter()
	end
end

--events
Players.PlayerAdded:Connect(onPlayerEntered)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	print("Closing...")
	for i, v in pairs(Players:GetPlayers()) do
		if v:IsA("Player") then
			v:Kick()
		end
	end
	task.wait(3)
	print("Name:", DataSettings.Name)
end)
--[Made by Jozeni00]--
]]

local loadData = script:FindFirstChild("LoadData")
local saveData = script:FindFirstChild("SaveData")

local LoadModule = require(loadData)
local SaveModule = require(saveData)

local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataStoreService = game:GetService("DataStoreService")
local DataSerializer = {
	["DataStores"] = {};
}

local fileName = "PlayerData"
local isSavingName = "IsSaving"
local loadedName = "DSLoaded"
local retryCount = 3
local retryWait = 2

local defaultRetry = 3
local defaultWait = 2

--make folders
local DataTempFile = ReplicatedStorage:FindFirstChild("DataTempFile")
if not DataTempFile then
	DataTempFile = Instance.new("Folder")
	DataTempFile.Name = "DataTempFile"
	DataTempFile.Parent = ReplicatedStorage
end

local PresetPlayerData = ServerStorage:FindFirstChild("PresetPlayerData")
if not PresetPlayerData then
	PresetPlayerData = Instance.new("Folder")
	PresetPlayerData.Parent = ServerStorage
end
PresetPlayerData.Name = fileName

function DataSerializer:GetStore(name: string?, options: DataStoreOptions?)
	if not name then
		name = ""
	end
	
	local DataStore = DataSerializer.DataStores[name]
	
	if not DataStore then
		DataSerializer.DataStores[name] = {}
		DataStore = DataSerializer.DataStores[name]
		
		local success, DataStoreResult = pcall(function()
			DataStore["GlobalDataStore"] = DataStoreService:GetDataStore(name, options)
			return DataStore["GlobalDataStore"]
		end)

		if not success then
			print(DataStoreResult)
		end

		--functions
		function DataStore:Get(plr: Player, key: string, userids: {any}?, dataOptions: DataStoreSetOptions?)
			--check for loaded data
			local PlayerData = nil
			if plr:GetAttribute(loadedName) then
				PlayerData = plr:FindFirstChild(plr:GetAttribute(loadedName))
			else
				PlayerData = PresetPlayerData:Clone()
				PlayerData.Name = fileName
				PlayerData.Parent = plr
				
				for i, v in pairs(PlayerData:GetDescendants()) do
					if v:IsA("ObjectValue") then
						if v.Value then
							--clone object
							local newObject = v.Value:Clone()
							newObject.Parent = DataTempFile

							--set new value
							v.Value = newObject
						end
					end
				end
			end

			local GlobalDataStore = DataStore.GlobalDataStore
			local data = nil
			local keyInfo = nil
			
			if GlobalDataStore then
				
				for i = 0, retryCount do
					local success, DataResult, info = pcall(function()
						--get data
						local Data, keyInfo = GlobalDataStore:GetAsync(key)

						--set data
						if not Data then
							print(plr.Name .. " is a new player, creating new save...")

							Data = SaveModule:CompileDataTable(PlayerData)
							local versionId = GlobalDataStore:SetAsync(key, Data, userids, dataOptions)
							keyInfo = versionId
						end

						return Data, keyInfo
					end)

					if success then
						data = DataResult
						keyInfo = info
						
						LoadModule:Load(plr, PlayerData, DataResult)
						print(plr.Name .. " loaded in the experience.")
						break
					else
						if DataResult:match("Studio access to APIs is not allowed.") then
							print(plr.Name .. " loaded in without Data Store API access.")
							break
						else
							if i == retryCount then
								warn(DataResult)
								plr:Kick("Internal server error, please rejoin.")
								break
							end
						end
					end

					task.wait(retryWait)
				end
			else
				print(plr.Name .. " loaded in offline mode.")
			end
			
			plr:SetAttribute(loadedName, fileName)
			return PlayerData, data, keyInfo
		end
		
		function DataStore:Update(plr: Player, key: string)
			if not plr:GetAttribute(loadedName) then
				print(plr.Name .. " tried to save while data is still deserializing. Did not overwrite save.")
				return
			end
			
			local GlobalDataStore = DataStore.GlobalDataStore
			if GlobalDataStore and plr:GetAttribute(loadedName) and not plr:GetAttribute(isSavingName) then
				plr:SetAttribute(isSavingName, true)

				--player data
				local PlayerData = plr:FindFirstChild(fileName)
				local serialize = SaveModule:CompileDataTable(PlayerData)

				local maxCache = 4000000 -- Max data is 4,000,000
				local dataCache = HttpService:JSONEncode(serialize)

				for i = 0, retryCount do

					--update data
					local success, result = pcall(function()
						GlobalDataStore:UpdateAsync(key, function(oldValue, keyInfo)
							local newValue = serialize or oldValue

							local userIDs = keyInfo:GetUserIds()
							local metadata = keyInfo:GetMetadata()
							return newValue, userIDs, metadata
						end)
					end)

					if not success then
						--if failed
						if i == retryCount then
							warn(result)
							break
						end
					else
						--print results
						print(plr.Name .. " saved:")
						print(fileName, serialize)
						print("Cache:", #dataCache .. " /" .. maxCache)
						if #dataCache > maxCache then
							warn("Cache exceeds limit, data may throttle.")
						end
						print("Key: " .. key)
						break
					end

					task.wait(retryWait)
				end
				
				--task.wait(6)
				plr:SetAttribute(isSavingName, false)
			end
		end

		--the final save
		function DataStore:CleanUpdate(plr: Player, key: string)
			local timeToRemove = retryCount * retryWait + 2

			if plr:GetAttribute(loadedName) then
				local PlayerData = plr:FindFirstChild(fileName)

				for i, v in pairs(PlayerData:GetDescendants()) do
					if v:IsA("ObjectValue") then
						if v.Value then
							Debris:AddItem(v.Value, timeToRemove)
						end
					end
				end
			end

			DataStore:Update(plr, key)
		end
		
		--remove data
		function DataStore:Remove(key: string)
			local GlobalDataStore = DataStore.GlobalDataStore
			
			for i = 0, retryCount do

				--update data
				local success, result, keyInfo = pcall(function()
					local oldData, keyInfo =  GlobalDataStore:RemoveAsync(key)
					return oldData, keyInfo
				end)

				if not success then
					--if failed
					if i == retryCount then
						warn(result)
						return nil
					end
				else
					--print results
					print("Old Data:", result)
					print("Key: " .. key .. " was successfully removed.")
					return result, keyInfo
				end

				task.wait(retryWait)
			end
		end
	end
	
	return DataStore
end

function DataSerializer:ListStores(): {}
	local list = {}
	
	for i, v in pairs(DataSerializer.DataStores) do
		if v.GlobalDataStore then
			list[i] = v.GlobalDataStore
		end
	end
	
	return list
end

function DataSerializer:SetRetries(retries: number, cool: number)
	--set retries
	if retries and type(retries) == "number" then
		if retries < 1 then
			retries = 1
		end
		retryCount = math.floor(retries)
	else
		retryCount = defaultRetry
	end
	
	--set cooldown
	if cool and type(cool) == "number" then
		if cool < 1 then
			cool = 1
		end
		retryWait = math.floor(cool)
	else
		retryWait = defaultWait
	end
end

return DataSerializer
--[Made by Jozeni00]--