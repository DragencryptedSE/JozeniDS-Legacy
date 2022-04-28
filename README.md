# JozeniDS Legacy
Data serializer created using Roblox Studio. The goal is to save everything under a single folder. Legacy version is aimed for general use and reliability.

# Saving Features
- Object attributes.
- All insertable objects from Roblox Studio's Insert Object widget. Everything, including scripts and meshparts, not kidding.
- Ability to manipulate data with ease, especially if using a DataStore editor plugin.
- Auto saving support, but is not recommended because DataStore throttling.
- Offline data testing supported.
- Studio-only DataStore Scope support.

# Use case examples
General unique purposes:
- A player building a custom house at any position of the workspace. 
- The player creating and selling their in-game custom weapon to the game's marketplace feature for other players to purchase and keep.

# Installation
1. Get the model here: https://www.roblox.com/library/9229651282/Jozeni-Data-Serializer-Legacy
2. Insert the script in ServerScriptService.

# Instructions
For setting up player data.

1. Insert a folder named "PresetPlayerData" in ServerStorage. Insert as many objects as prefered under the folder (see limitations), set their attributes and go crazy with it. During gameplay, this folder will be renamed to the "Scope" you set in the script. By default, the folder is renamed to "PlayerData" because it is the name of the DataStore's scope, so use `ServerStorage:WaitForChild("PlayerData")` in scripts. For the player's data, use `Player:WaitForChild("PlayerData")`.
* However, for best results, this code sample will wait for the Player's data to be loaded, and it provides an attribute with the name of the folder:
```
-- check if DataStoreLoaded is an attribute of Player.
if not Player:GetAttribute("DataStoreLoaded") then
	Player:GetAttributeChangedSignal("DataStoreLoaded"):Wait() -- waits for data to be loaded, returns string "PlayerData".
end

--Player data
local PlayerData = Player:WaitForChild(Player:GetAttribute("DataStoreLoaded")) -- returns folder named "PlayerData".
```
2. To live test DataStores, be sure to enable Studio API Services.
3. Change up the player's PlayerData in-game, then rejoin to see if it saved.

# Limitations
- Objects under PlayerData only accepts Values, Folders, and attributes. (For unrestricted saving, use JozeniDS 2.0 instead.)
- Under PlayerData, objects with matching names with the same `Parent` will cause an error. Objects referenced under `ObjectValue.Value` are not affected by this circumstance. (To save objects with matching names within PlayerData, use JozeniDS 2.0 instead.)
- For objects containing references (i.e. Beam.Attachment0, BillboardGui.Adornee, WeldConstraint.Part1, etc.), it is recommended to utilize unique naming schemes for better results.
- To save a script, a copy of it with the same name and sourceId must be present within ServerStorage.
- To save a MeshPart or SurfaceAppearance, a copy of it must be present within ServerStorage.
- Deprecated objects are not fully supported, but there may be some that are superseded carrying the same type. (i.e. Hat is superseded by Accessory, both are Accoutrements.)

# Repositories
JozeniDS 2.0: https://github.com/DragencryptedSE/JozeniDS-2.0
