--[Made by Jozeni00]--
print("Jozeni00\'s Data Serializer Legacy loaded.")
local DataSettings = {
	--{DATA}--
	--Any changes made below are susceptible to a clean data wipe, or revert data to its previous.
	["Name"] = "DS_TestLV0-0-0"; --DataStore name for the entire game.
	["Scope"] = ""; --The scope of the datastore for a live game. Roblox officially discourages the use of Scope.
	["Key"] = "Plr_"; --prefix for key. Example: "Player_" is used for "Player_123456".

	--{FEATURES}--
	["FolderName"] = "PlayerData"; --Name of the folder that will appear under the Player.
	["LoadedName"] = "DataStoreLoaded"; --Name of attribute when the player successfully loads DataStore.

	["AutoSave"] = true; --set to true to enable auto saving.
	["SaveTime"] = 1; --time (in minutes) how often it should automatically save.

	["UseStudioScope"] = true; --set to true to use a different Scope for Studio only.
	["DevName"] = "DEV_DS_TestLV0-0-0"; --Name of the Data Store for Studio if UseStudioScope is true.
	["DevScope"] = ""; --Scope of the Data Store for Studio, if UseStudioScope is true.
	["DevKey"] = "Dev_"; --Key of the Data Store for Studio, if UseStudioScope is true.
}

--[[
	[LAST UPDATED]: 09 May 2022

	I appreciate you for using Jozeni00's DataStore script!

	Difference between Legacy and 2.0 versions:
	[Legacy]: Saving is strict, object names are required to be unique.
		- Good for most common needs.
		- Can only save values and folders (with the exception of ObjectValue, can save any object class).
		- Updating PresetPlayerData will not require you to use the command bar.

	[2.0]: Successor to Legacy version.
		- Unrestricted saving.
		- Can save any object class under PresetPlayerData.
		- Aimed towards hardcore RPG/Adventure games.
		- Updating PresetPlayerData will require you to use the command bar afterwards.
			- (Blame Roblox for disallowing developers readable access to object unique identifiers.)

	[Instructions]
	Studio API Services are no longer required for this script to operate.
	Enable Studio API services to grant Roblox Studio access to DataStore services. (Optional)
	1. Setting up folders:
		- Insert "PresetPlayerData" folder in ServerStorage. (optional)
			- Used for setting up default player data.
				- The "real" PlayerData should be found under each Player.
				- Attributes and Objects can be saved.
			- The folder will clone itself to the Player using the Scope's name.
			- All non-deprecated objects and custom attributes are supported.
			- For MeshParts and SurfaceAppearance to save, a copy of itself must be located within ServerStorage.
			- For Scripts, LocalScript and ModuleScript to save, a copy of that script with the same name
				must be found within ServerStorage.
			- Deprecated objects are not supported, but there may still be some that do fully save.
				For example, Accessories and Hats (deprecated) are both Accoutrements, meaning
					they share mostly the same properties.

			- Allowed instances to be placed under PresetPlayerData (and real PlayerData):
				- Folder
				- IntValue
				- NumberValue
				- StringValue
				- BoolValue
				- RayValue
				- CFrameValue
				- Vector3Value
				- Color3Value
				- BrickColorValue
				- ObjectValue

		- Insert "DataTempFile" folder in ReplicatedStorage. (optional)
			- `ObjectValue.Value` saves are automatically placed under this file.
			- It is recommended to use unique naming schemes for objects that use a reference to
				another object for the best results.

	2. A folder named, from DataSettings["Scope"] will appear under all Players.
		- The Player's data folder can always be edited from Server Scripts and Server-sided test play.
		- Any changes made under PlayerData will always save.
		- Changes made from a LocalScript or Client side will never save.

	4. To link data across all Places of this game, this Script and PresetPlayerData must be present
		in each Place.

	5. The DataStore's "Name" and "Scope" will appear in the output when the game closes after test-play.
		- The "Key" will also appear in the output when a player leaves the game.
		- A Player's ObjectValues will clean up while leaving.

	{PRO TIP}
	How to link DataStore across all Places:
	[Setting up a package link]
	- Right-click this script object to "Convert To Package..." and follow the process of converting to a package.
	- After, a link object should appear under the same script you converted to package.
	- In the link's properties, enable "AutoUpdate".
	- You may now copy this script object and paste it into all of the other Places within this game.

	[Usage basics]
	- Let's say you changed DataSettings["Name"] from "JozeniDS_V1.5" to "JozeniDS_V1.6", and applied changes.
	- Once done, right-click this script object and update package.
	- The change only applies within this place.
	- To update the other scripts with the same package link, you would have to go re-publish or re-save each Place
		via File --> Save (or Publish) for the changes to take affect per Place containing the updated DataStore script.

	How to convert a Union to a MeshPart:
	1. Right-click union, select "Export selection..."
	2. In Studio, click "VIEW" tab (at top screen), and enable "Asset Manager".
	3. In Asset Manager window, click the "upload" icon (appears like `[->`, but facing upwards).
	4. When it makes you select a file, select the `.obj` file to upload it.
	5. A new Mesh should appear in "Meshes" of Asset Manager.

	Referencing PlayerData Example:
	-----------------------------------------------------------------
		-- wait for datastore to load
		if not Player:GetAttribute("DataStoreLoaded") then
			Player:GetAttributeChangedSignal("DataStoreLoaded"):Wait() -- returns datastore folder name, "PlayerData"
		end

		--New Data:
		local PlayerData = Player:FindFirstChild(Player:GetAttribute("DataStoreLoaded"))
		local SavedData = PlayerData:FindFirstChild("SavedData")
		local Gold = SavedData:FindFirstChild("Gold")
		Gold.Value = 2600 --changing data from a LocalScript will not save because it is not Server-Sided.

		--Player on leaving... New Data has been saved.
	-----------------------------------------------------------------
	- "Instance:WaitForChild()" should be used sparingly in server Scripts because it adds actual "wait(default number)".
	- Emergency case example would be if an object's descendants count is too large.

	[Conclusion]
	"This is as efficient as it gets." -EthanTano (February 2022)
]]

--http
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local fileName = DataSettings.FolderName
local msSave = script:FindFirstChild("SaveData")
local msLoad = script:FindFirstChild("LoadData")

local saveModule = require(msSave)
local loadModule = require(msLoad)

--main code
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TempFile = ReplicatedStorage:FindFirstChild("DataTempFile")
if not TempFile then
	TempFile = Instance.new("Folder")
	TempFile.Name = "DataTempFile"
	TempFile.Parent = ReplicatedStorage
end

--storage
local ServerStorage = game:GetService("ServerStorage")
local PresetPlayerData = ServerStorage:FindFirstChild("PresetPlayerData")
if not PresetPlayerData then
	warn("folder PresetPlayerData does not exist in ServerStorage!")
	PresetPlayerData = Instance.new("Folder")
	PresetPlayerData.Name = "PresetPlayerData"
	PresetPlayerData.Parent = ServerStorage
end

--set scope
if DataSettings.UseStudioScope then
	if RunService:IsStudio() then
		DataSettings.Name = DataSettings.DevName
		DataSettings.Scope = DataSettings.DevScope
		DataSettings.Key = DataSettings.DevKey
	end
end
if DataSettings.Scope == "" then
	DataSettings.Scope = "global"
end

--data
local DataStoreService = game:GetService("DataStoreService")
local success, DataStoreResult = pcall(function()
	local PlayerDataStore = DataStoreService:GetDataStore(DataSettings.Name, DataSettings.Scope)
	return PlayerDataStore
end)
if not success then
	warn(DataStoreResult)
end

--update function
local function updateData(Player, PlayerKey, isAutoSave)
	if type(DataStoreResult) ~= "string" and not Player:GetAttribute("IsSavingData") then
		Player:SetAttribute("IsSavingData", true)
		--player data
		local PlayerData = Player:FindFirstChild(fileName)
		local serialize = saveModule:CompileDataTable(PlayerData)
		local dataCache = HttpService:JSONEncode(serialize)

		--update
		local maxRetries = 3
		for i = 1, maxRetries do
			local success, result = pcall(function()
				DataStoreResult:UpdateAsync(PlayerKey, function(oldValue)
					local newValue = serialize or oldValue
					return newValue, {Player.UserId}
				end)
			end)

			--results
			if success then
				if isAutoSave then
					print(Player.Name .. " autosaved successfully.")
				end
				local maxCache = 4000000 --official limit is 4,000,000
				print(Player.Name .. " saved: ")
				print(PlayerData.Name, serialize)
				if #dataCache <= maxCache then
					print("Cache: " .. #dataCache .. " /" .. maxCache)
				else
					warn("Cache exceeds limit: " .. #dataCache .. " /" .. maxCache)
				end
				print("Key: " .. PlayerKey)
				break
			else
				if i == maxRetries then
					warn(result)
				end
			end
			task.wait(2)
		end

		Player:SetAttribute("IsSavingData", false)
	end
end

--player entered
local function onPlayerEntered(Player)
	local PlayerKey = DataSettings.Key .. Player.UserId

	local PlayerData = PresetPlayerData:Clone()
	PlayerData.Name = fileName
	--check for objs
	for i, v in pairs(PlayerData:GetDescendants()) do
		if v:IsA("ObjectValue") then
			if v.Value then
				local newObj = v.Value:Clone()
				newObj.Parent = TempFile
				v.Value = newObj
			end
		end
	end
	PlayerData.Parent = Player

	--load data
	local maxRetries = 3
	for i = 1, maxRetries do
		local success, DataResult = pcall(function()
			if type(DataStoreResult) == "string" then
				return DataStoreResult
			else
				local DataTable = DataStoreResult:GetAsync(PlayerKey)
				if DataTable == nil then
					print(Player.Name .. " is a new player, creating save...")
					DataTable = saveModule:CompileDataTable(PlayerData)
					DataStoreResult:SetAsync(PlayerKey, DataTable, {Player.UserId})
				else
					--print(DataTable)
				end
				return DataTable
			end
		end)

		if success then
			if type(DataStoreResult) == "string" then
				print(Player.UserId .. " | " .. Player.Name .. " loaded in offline mode.")
			else
				loadModule:Load(Player, PlayerData, DataResult)
				print(Player.UserId .. " | " .. Player.Name .. " loaded in " .. DataSettings.Scope .. ".")
			end
			break
		else
			if DataResult:match("Studio access to APIs is not allowed.") then
				warn(DataResult)
				print(Player.UserId .. " | " .. Player.Name .. " loaded in without DataStore access.")
				break
			else
				if i == maxRetries then
					warn(DataResult)
					Player:Kick("Internal server error, please rejoin.")
				end
			end
		end
		task.wait(2)
	end

	Player:SetAttribute(DataSettings.LoadedName, DataSettings.FolderName)

	if DataSettings.AutoSave and type(DataStoreResult) ~= "string" then
		local isInGame = true
		local plrRemove = nil
		if DataSettings.SaveTime < 1 then
			DataSettings.SaveTime = 1
		end

		plrRemove = Players.PlayerRemoving:Connect(function(plr)
			if plr == Player then
				isInGame = false
			end
		end)

		while Player and isInGame == true do
			task.wait(DataSettings.SaveTime * 60)
			updateData(Player, PlayerKey, true)
		end

		if plrRemove and plrRemove.Connected then
			plrRemove:Disconnect()
		end
	end
end

--player removing
local function onPlayerRemoving(Player)
	local PlayerKey = DataSettings.Key .. Player.UserId
	local PlayerData = Player:FindFirstChild(fileName)
	if PlayerData then
		updateData(Player, PlayerKey)

		--remove extra objects
		for i, v in pairs(PlayerData:GetDescendants()) do
			if v:IsA("ObjectValue") then
				if v.Value then
					Debris:AddItem(v.Value, 4)
				end
			end
		end
	else
		warn(Player.Name, "PlayerData is nil!")
	end
end

--check current players
for i, v in pairs(Players:GetPlayers()) do
	local wrapPlrEntered = coroutine.wrap(function(plr)
		onPlayerEntered(plr)
	end)
	wrapPlrEntered(v)
end

--events
Players.PlayerAdded:Connect(onPlayerEntered)
Players.PlayerRemoving:Connect(onPlayerRemoving)

--bind to close
game:BindToClose(function()
	warn("Closing...")
	for i, v in pairs(Players:GetPlayers()) do
		v:Kick()
	end
	task.wait(3)
	print("Name: " .. DataSettings.Name)
	print("Scope: " .. DataSettings.Scope)
end)
--[Made by Jozeni00]--
