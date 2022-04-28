--[Made by Jozeni00]--
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TempFile = ReplicatedStorage:FindFirstChild("DataTempFile")
if not TempFile then
	TempFile = Instance.new("Folder")
	TempFile.Name = "DataTempFile"
	TempFile.Parent = ReplicatedStorage
end

local HttpService = game:GetService("HttpService")
local DataSettings = {}

local function setAttributes(obj, val)
	if val.Attributes then
		local attributes = HttpService:JSONDecode(val.Attributes)
		for i, v in pairs(attributes) do
			if type(v) == "string" or type(v) == "number" or type(v) == "boolean" then
				obj:SetAttribute(i, v)
			elseif type(v) == "table" then
				if v.MinX then
					obj:SetAttribute(i, Rect.new(v.MinX, v.MinY, v.MaxX, v.MaxY))
				elseif v.r then
					obj:SetAttribute(i, BrickColor.new(v.r, v.g, v.b))
				elseif v.R then
					obj:SetAttribute(i, Color3.new(v.R, v.G, v.B))
				elseif v.Min then
					obj:SetAttribute(i, NumberRange.new(v.Min, v.Max))
				elseif v.X then
					obj:SetAttribute(i, Vector3.new(v.X, v.Y, v.Z))
				elseif v.X2 then
					obj:SetAttribute(i, Vector2.new(v.X2, v.Y2))
				elseif v.Scale then
					obj:SetAttribute(i, UDim.new(v.Scale, v.Offset))
				elseif v.XU then
					obj:SetAttribute(i, UDim2.new(v.XU.Scale, v.XU.Offset, v.YU.Scale, v.YU.Offset))
				elseif v[1] and v[1].Envelope then
					local sequence = {}
					for t, p in pairs(v) do
						sequence[t] = NumberSequenceKeypoint.new(p.Time, p.Value, p.Envelope)
					end
					obj:SetAttribute(i, NumberSequence.new(sequence))
				elseif v[1] and v[1].Value and v[1].Value.R then
					local sequence = {}
					for t, p in pairs(v) do
						sequence[t] = ColorSequenceKeypoint.new(p.Time, Color3.new(p.Value.R, p.Value.G, p.Value.B))
					end
					obj:SetAttribute(i, ColorSequence.new(sequence))
				elseif v.dx then
					obj:SetAttribute(i, Ray.new(Vector3.new(v.x, v.y, v.z), Vector3.new(v.dx, v.dy, v.dz)))
				end
			end
		end
	end
end

local function propTable(prop)
	local Data = nil
	if type(prop) == "table" then
		if prop.MinX then
			Data = Rect.new(prop.MinX, prop.MinY, prop.MaxX, prop.MaxY)
		elseif prop.Min then
			Data = NumberRange.new(prop.Min, prop.Max)
		elseif prop.X then
			Data = Vector3.new(prop.X, prop.Y, prop.Z)
		elseif prop.X2 then
			Data = Vector2.new(prop.X2, prop.Y2)
		elseif prop.R00 then
			Data = CFrame.new(prop.x, prop.y, prop.z, prop.R00, prop.R01, prop.R02, prop.R10, prop.R11, prop.R12, prop.R20, prop.R21, prop.R22)
		elseif prop.R then
			Data = Color3.new(prop.R, prop.G, prop.B)
		elseif prop.r then
			Data = BrickColor.new(prop.r, prop.g, prop.b)
		elseif prop[1] then
			local sequence = {}
			if prop[1].Envelope then
				for i, v in pairs(prop) do
					sequence[i] = NumberSequenceKeypoint.new(v.Time, v.Value, v.Envelope)
				end
				Data = NumberSequence.new(sequence)
			elseif prop[1].Value and prop[1].Value.R then
				for i, v in pairs(prop) do
					sequence[i] = ColorSequenceKeypoint.new(v.Time, Color3.new(v.Value.R, v.Value.G, v.Value.B))
				end
				Data = ColorSequence.new(sequence)
			end
		elseif prop.Scale then
			Data = UDim.new(prop.Scale, prop.Offset)
		elseif prop.XU then
			Data = UDim2.new(prop.XU.Scale, prop.XU.Offset, prop.YU.Scale, prop.YU.Offset)
		elseif prop.AX ~= nil then
			local props = {}
			for i, v in pairs(prop) do
				if type(v) == "string" then
					table.insert(props, Enum.NormalId[v])
				end
			end
			Data = Axes.new(table.unpack(props))
		elseif prop.Top ~= nil then
			local props = {}
			for i, v in pairs(prop) do
				if type(v) == "string" then
					table.insert(props, Enum.NormalId[v])
				end
			end
			Data = Faces.new(table.unpack(props))
		end
	end
	return Data
end

local function setReference(newObj, parent, info, prop)
	local scanForReference = coroutine.wrap(function()
		if not parent.Parent then
			parent:GetPropertyChangedSignal("Parent"):Wait()
		end

		--find highest parented instance
		local highestParent = parent
		repeat
			if highestParent.Parent ~= nil then
				highestParent = highestParent.Parent
			end
		until highestParent.Parent == nil

		--split the location
		local splitLocations = info.Location:split(".")
		local lastParent = nil

		local startPos = 1
		local foundPos = false

		--uncover real location
		for i, v in pairs(splitLocations) do
			if v == highestParent.Name then
				startPos = i + 1
				foundPos = true
				break
			end
		end

		--find the location of reference
		if foundPos then
			for i, v in pairs(splitLocations) do
				if i == startPos then
					lastParent = highestParent:WaitForChild(v)
				elseif i > startPos then
					lastParent = lastParent:WaitForChild(v)
				end
			end
		else
			for i, v in pairs(splitLocations) do
				if i == 1 then
					lastParent = game:GetService(v)
				elseif i > 1 then
					lastParent = lastParent:WaitForChild(v)
				end
			end
		end

		--check if classname was not found
		if lastParent.ClassName ~= info.ClassName then
			local foundObj = false
			for i, v in pairs(highestParent:GetDescendants()) do
				if v:IsA(info.ClassName) then
					if v.Parent and v.Parent.Name == splitLocations[#splitLocations - 1] then
						if v.Name == splitLocations[#splitLocations] then
							lastParent = v
							foundObj = true
							break
						end
					end
				end
			end

			if not foundObj then
				local higherObj = lastParent.Parent
				local AddedChild = nil

				AddedChild = higherObj.ChildAdded:Connect(function(child)
					if foundObj then
						AddedChild:Disconnect()
						return
					end

					if child:IsA(info.ClassName) then
						if child.Name == splitLocations[#splitLocations] then
							lastParent = child
							foundObj = true
						end
					end
				end)

				repeat
					RunService.Heartbeat:Wait()
				until foundObj == true

				if AddedChild and AddedChild.Connected then
					AddedChild:Disconnect()
				end
			end
		end

		--set reference
		newObj[prop] = lastParent
	end)

	if info then
		scanForReference()
	end
end

function DataSettings:Load(Player, DataTable, fileName)
	local DataFolder = ServerStorage:FindFirstChild("PresetPlayerData"):Clone() or Instance.new("Folder")
	DataFolder.Name = fileName
	if DataTable ~= nil then
		local function Scan(Object, Data)
			if type(Data) == "table" then
				for i, v in pairs(Data) do
					if Object:FindFirstChild(i) == nil then
						local kindtomake = nil
						if type(v) == "table" then
							if v.ClassName then
								kindtomake = v.ClassName
							else
								kindtomake = "Folder"
							end
						else
							warn(i, v .. " is a " .. typeof(v))
							warn(Object, Data)
						end
						if kindtomake ~= nil then
							local ob = Instance.new(kindtomake)
							ob.Name = i
							ob.Parent = Object
						end
					end
					if Object[i]:IsA("IntValue") or Object[i]:IsA("BoolValue") or Object[i]:IsA("NumberValue") or (Object[i]:IsA("StringValue") and type(v.Value) == "string") then
						Object[i].Value = v.Value
						setAttributes(Object[i], v)
					elseif Object[i]:IsA("RayValue") then
						Object[i].Value = Ray.new(Vector3.new(v.x, v.y, v.z), Vector3.new(v.dx, v.dy, v.dz))
						setAttributes(Object[i], v)
					elseif Object[i]:IsA("Color3Value") then
						Object[i].Value = Color3.new(v.R, v.G, v.B)
						setAttributes(Object[i], v)
					elseif Object[i]:IsA("Vector3Value") then
						Object[i].Value = Vector3.new(v.X, v.Y, v.Z)
						setAttributes(Object[i], v)
					elseif Object[i]:IsA("CFrameValue") then
						Object[i].Value = CFrame.new(v.x, v.y, v.z, v.R00, v.R01, v.R02, v.R10, v.R11, v.R12, v.R20, v.R21, v.R22)
						setAttributes(Object[i], v)
					elseif Object[i]:IsA("ObjectValue") then
						local function scanObjects(OBJ, VAL)
							if VAL and VAL.Value then
								local objects = HttpService:JSONDecode(VAL.Value)
								local firstPart = nil
								--print(OBJ.Name, objects)
								local function createObj(info, parent, primarypart)
									if info then
										--print(info, parent)
										local newObj = Instance.new(info.ClassName)
										newObj.Archivable = info.Archivable
										newObj.Name = info.Name
										setAttributes(newObj, info)

										--main code
										local isPrimaryPart = nil
										if newObj:IsA("PVInstance") then
											if newObj:IsA("Model") then
												if info.PrimaryPart then
													isPrimaryPart = info.PrimaryPart
												end
												newObj:PivotTo(propTable(info.WorldPivot))
											elseif newObj:IsA("BasePart") then
												--Appearance
												newObj.CastShadow = info.CastShadow
												newObj.Color = propTable(info.Color)
												newObj.Material = Enum.Material[info.Material]
												newObj.Reflectance = info.Reflectance
												newObj.Transparency = info.Transparency
												--Data
												newObj.Locked = info.Locked
												newObj.CFrame = propTable(info.CFrame)
												--Collision
												newObj.CanCollide = info.CanCollide
												newObj.CanTouch = info.CanTouch
												newObj.CollisionGroupId = info.CollisionGroupId
												--Behavior
												newObj.Anchored = info.Anchored
												newObj.Massless = info.Massless
												newObj.RootPriority = info.RootPriority
												newObj.Size = propTable(info.Size)
												--Surface
												newObj.TopSurface = Enum.SurfaceType[info.TopSurface]
												newObj.BottomSurface = Enum.SurfaceType[info.BottomSurface]
												newObj.FrontSurface = Enum.SurfaceType[info.FrontSurface]
												newObj.BackSurface = Enum.SurfaceType[info.BackSurface]
												newObj.LeftSurface = Enum.SurfaceType[info.LeftSurface]
												newObj.RightSurface = Enum.SurfaceType[info.RightSurface]
												if newObj:IsA("Part") then
													newObj.Shape = Enum.PartType[info.Shape]
													if newObj:IsA("Seat") then
														newObj.Disabled = info.Disabled
													elseif newObj:IsA("SpawnLocation") then
														newObj.AllowTeamChangeOnTouch = info.AllowTeamChangeOnTouch
														newObj.Duration = info.Duration
														newObj.Enabled = info.Enabled
														newObj.Neutral = info.Neutral
														newObj.TeamColor = propTable(info.TeamColor)
													end
												elseif newObj:IsA("VehicleSeat") then
													newObj.Disabled = info.Disabled
													newObj.HeadsUpDisplay = info.HeadsUpDisplay
													newObj.MaxSpeed = info.MaxSpeed
													newObj.SteerFloat = info.SteerFloat
													newObj.ThrottleFloat = info.ThrottleFloat
													newObj.Torque = info.Torque
													newObj.TurnSpeed = info.TurnSpeed
												elseif newObj:IsA("TrussPart") then
													newObj.Style = Enum.Style[info.Style]
												elseif newObj:IsA("MeshPart") then
													local mesh = nil
													for i, v in pairs(ServerStorage:GetDescendants()) do
														if v:IsA("MeshPart") then
															if v.MeshId == info.MeshId and v.TextureID == info.TextureID then
																mesh = v
																newObj:ApplyMesh(v)
																break
															end
														end
													end
													if not mesh then
														warn("MeshPart: " .. newObj.Name .. " with MeshId: " .. info.MeshId .. " and TextureID: " .. info.TextureID .. " has not been found in ServerStorage." )
													end
												end
											end
										elseif newObj:IsA("DataModelMesh") then
											newObj.Offset = propTable(info.Offset)
											newObj.Scale = propTable(info.Scale)
											newObj.VertexColor = propTable(info.VertexColor)
											if newObj:IsA("SpecialMesh") then
												newObj.MeshType = Enum.MeshType[info.MeshType]
												newObj.MeshId = info.MeshId
												newObj.TextureId = info.TextureId
											end
										elseif newObj:IsA("Tool") then
											newObj.CanBeDropped = info.CanBeDropped
											newObj.Enabled = info.Enabled
											newObj.Grip = propTable(info.Grip)
											newObj.ManualActivationOnly = info.ManualActivationOnly
											newObj.RequiresHandle = info.RequiresHandle
											local success, result = pcall(function()
												newObj.TextureId = info.TextureId
											end)
											if not success then
												warn(result)
											end
											newObj.ToolTip = info.ToolTip
										elseif newObj:IsA("SurfaceAppearance") then
											local surfaceAppearance = nil
											for i, v in pairs(ServerStorage:GetDescendants()) do
												if v:IsA("SurfaceAppearance") then
													if v.AlphaMode == Enum.AlphaMode[info.AlphaMode] and v.ColorMap == info.ColorMap and v.MetalnessMap == info.MetalnessMap and v.NormalMap == info.NormalMap and v.RoughnessMap == info.RoughnessMap then
														surfaceAppearance = v
														newObj = v:Clone()
														newObj:ClearAllChildren()
														break
													end
												end
											end
											if not surfaceAppearance then
												warn("SurfaceAppearance: " .. newObj.Name .. " with: n\AlphaMode: " .. info.AlphaMode .. " n\ColorMap: " .. info.ColorMap .. " n\MetalnessMap: " .. info.MetalnessMap .. " n\NormalMap: " .. info.NormalMap .. " n\RoughnessMap: " .. info.RoughnessMap .. " n\has not been found in ServerStorage." )
											end
										elseif newObj:IsA("Accoutrement") then
											newObj.AttachmentPoint = propTable(info.AttachmentPoint)
											if newObj:IsA("Accessory") then
												newObj.AccessoryType = Enum.AccessoryType[info.AccessoryType]
											end
										elseif newObj:IsA("Camera") then
											newObj.CFrame = propTable(info.CFrame)
											setReference(newObj, parent, info.CameraSubject, "CameraSubject")
											newObj.CameraType = Enum.CameraType[info.CameraType]
											newObj.DiagonalFieldOfView = info.DiagonalFieldOfView
											newObj.FieldOfView = info.FieldOfView
											newObj.FieldOfViewMode = info.FieldOfViewMode
											newObj.Focus = propTable(info.Focus)
											newObj.HeadLocked = info.HeadLocked
											newObj.HeadScale = info.HeadScale
											newObj.MaxAxisFieldOfView = info.MaxAxisFieldOfView
										elseif newObj:IsA("Humanoid") then
											newObj.AutoJumpEnabled = info.AutoJumpEnabled
											newObj.AutoRotate = info.AutoRotate
											newObj.AutomaticScalingEnabled = info.AutomaticScalingEnabled
											newObj.BreakJointsOnDeath = info.BreakJointsOnDeath
											newObj.CameraOffset = propTable(info.CameraOffset)
											newObj.DisplayDistanceType = Enum.HumanoidDisplayDistanceType[info.DisplayDistanceType]
											newObj.DisplayName = info.DisplayName
											newObj.MaxHealth = info.MaxHealth
											newObj.Health = info.Health
											newObj.HealthDisplayDistance = info.HealthDisplayDistance
											newObj.HealthDisplayType = Enum.HumanoidHealthDisplayType[info.HealthDisplayType]
											newObj.HipHeight = info.HipHeight
											newObj.UseJumpPower = info.UseJumpPower
											newObj.RequiresNeck = info.RequiresNeck
											newObj.WalkSpeed = info.WalkSpeed
											newObj.JumpHeight = info.JumpHeight
											newObj.JumpPower = info.JumpPower
											newObj.MaxSlopeAngle = info.MaxSlopeAngle
											newObj.TargetPoint = propTable(info.TargetPoint)
											newObj.NameDisplayDistance = info.NameDisplayDistance
											newObj.NameOcclusion = Enum.NameOcclusion[info.NameOcclusion]
											newObj.PlatformStand = info.PlatformStand
											newObj.RigType = Enum.RigType[info.RigType]
											newObj.Sit = info.Sit
											newObj.WalkToPoint = propTable(info.WalkToPoint)
										elseif newObj:IsA("HumanoidDescription") then
											newObj.BackAccessory = info.BackAccessory
											newObj.BodyTypeScale = info.BodyTypeScale
											newObj.ClimbAnimation = info.ClimbAnimation
											newObj.DepthScale = info.DepthScale
											newObj.Face = info.Face
											newObj.FaceAccessory = info.FaceAccessory
											newObj.FallAnimation = info.FallAnimation
											newObj.FrontAccessory = info.FrontAccessory
											newObj.GraphicTShirt = info.GraphicTShirt
											newObj.HairAccessory = info.HairAccessory
											newObj.HatAccessory = info.HatAccessory
											newObj.Head = info.Head
											newObj.HeadColor = propTable(info.HeadColor)
											newObj.HeadScale = info.HeadScale
											newObj.HeightScale = info.HeightScale
											newObj.IdleAnimation = info.IdleAnimation
											newObj.JumpAnimation = info.JumpAnimation
											newObj.LeftArm = info.LeftArm
											newObj.LeftArmColor = propTable(info.LeftArmColor)
											newObj.LeftLeg = info.LeftLeg
											newObj.LeftLegColor = propTable(info.LeftLegColor)
											newObj.NeckAccessory = info.NeckAccessory
											newObj.Pants = info.Pants
											newObj.ProportionScale = info.ProportionScale
											newObj.RightArm = info.RightArm
											newObj.RightArmColor = propTable(info.RightArmColor)
											newObj.RightLeg = info.RightLeg
											newObj.RightLegColor = propTable(info.RightLegColor)
											newObj.RunAnimation = info.RunAnimation
											newObj.Shirt = info.Shirt
											newObj.ShouldersAccessory = info.ShouldersAccessory
											newObj.SwimAnimation = info.SwimAnimation
											newObj.Torso = info.Torso
											newObj.TorsoColor = propTable(info.TorsoColor)
											newObj.WaistAccessory = info.WaistAccessory
											newObj.WalkAnimation = info.WalkAnimation
											newObj.WidthScale = info.WidthScale
										elseif newObj:IsA("BodyColors") then
											newObj.HeadColor3 = propTable(info.HeadColor3)
											newObj.TorsoColor3 = propTable(info.TorsoColor3)
											newObj.LeftArmColor3 = propTable(info.LeftArmColor3)
											newObj.LeftLegColor3 = propTable(info.LeftLegColor3)
											newObj.RightArmColor3 = propTable(info.RightArmColor3)
											newObj.RightLegColor3 = propTable(info.RightLegColor3)
										elseif newObj:IsA("Clothing") then
											newObj.Color3 = propTable(info.Color3)
											if newObj:IsA("Shirt") then
												newObj.ShirtTemplate = info.ShirtTemplate
											elseif newObj:IsA("Pants") then
												newObj.PantsTemplate = info.PantsTemplate
											end
										elseif newObj:IsA("ShirtGraphic") then
											newObj.Color3 = propTable(info.Color3)
											newObj.Graphic = info.Graphic
										elseif newObj:IsA("WrapLayer") then
											newObj.BindOffset = propTable(info.BindOffset)
											newObj.Enabled = info.Enabled
											newObj.Order = info.Order
											newObj.Puffiness = info.Puffiness
											newObj.ReferenceMeshId = info.ReferenceMeshId
											newObj.ReferenceOrigin = propTable(info.ReferenceOrigin)
											newObj.ShrinkFactor = info.ShrinkFactor
										elseif newObj:IsA("WrapTarget") then
											newObj.Stiffness = info.Stiffness
										elseif newObj:IsA("JointInstance") then
											newObj.C0 = propTable(info.C0)
											newObj.C1 = propTable(info.C1)
											newObj.Enabled = info.Enabled
											setReference(newObj, parent, info.Part0, "Part0")
											setReference(newObj, parent, info.Part1, "Part1")
											if newObj:IsA("Motor") then
												newObj.CurrentAngle = info.CurrentAngle
												newObj.DesiredAngle = info.DesiredAngle
												newObj.MaxVelocity = info.MaxVelocity
												if newObj:IsA("Motor6D") then
													--newObj.Transform = propTable(info.Transform)
												end
											end
										elseif newObj:IsA("ForceField") then
											newObj.Visible = info.Visible
										elseif newObj:IsA("Animation") then
											newObj.AnimationId = info.AnimationId
										elseif newObj:IsA("ClickDetector") then
											newObj.CursorIcon = info.CursorIcon
											newObj.MaxActivationDistance = info.MaxActivationDistance
										elseif newObj:IsA("ProximityPrompt") then
											newObj.ActionText = info.ActionText
											newObj.AutoLocalize = info.AutoLocalize
											newObj.ClickablePrompt = info.ClickablePrompt
											newObj.Enabled = info.Enabled
											newObj.Exclusivity = Enum.ProximityPromptExclusivity[info.Exclusivity]
											newObj.GamepadKeyCode = Enum.KeyCode[info.GamepadKeyCode]
											newObj.HoldDuration = info.HoldDuration
											newObj.KeyboardKeyCode = Enum.KeyCode[info.KeyboardKeyCode]
											newObj.MaxActivationDistance = info.MaxActivationDistance
											newObj.ObjectText = info.ObjectText
											newObj.RequiresLineOfSight = info.RequiresLineOfSight
											setReference(newObj, parent, info.RootLocalizationTable, "RootLocalizationTable")
											newObj.Style = Enum.ProximityPromptStyle[info.Style]
											newObj.UIOffset = propTable(info.UIOffset)
										elseif newObj:IsA("Dialog") then
											newObj.BehaviorType = Enum.DialogBehaviorType[info.BehaviorType]
											newObj.ConversationDistance = info.ConversationDistance
											newObj.GoodbyeChoiceActive = info.GoodbyeChoiceActive
											newObj.GoodbyeDialog = info.GoodbyeDialog
											newObj.InUse = info.InUse
											newObj.InitialPrompt = info.InitialPrompt
											newObj.Purpose = Enum.DialogPurpose[info.Purpose]
											newObj.Tone = Enum.DialogTone[info.Tone]
											newObj.TriggerDistance = info.TriggerDistance
											newObj.UIOffset = propTable(info.UIOffset)
										elseif newObj:IsA("DialogChoice") then
											newObj.GoodbyeChoiceActive = info.GoodbyeChoiceActive
											newObj.GoodbyeDialog = info.GoodbyeDialog
											newObj.ResponseDialog = info.ResponseDialog
											newObj.UserDialog = info.UserDialog
										elseif newObj:IsA("PathfindingModifier") then
											newObj.Label = info.Label
											newObj.PassThrough = info.PassThrough
										elseif newObj:IsA("Sound") then
											newObj.Looped = info.Looped
											newObj.PlayOnRemove = info.PlayerOnRemove
											newObj.PlaybackSpeed = info.PlaybackSpeed
											newObj.Playing = info.Playing
											newObj.RollOffMaxDistance = info.RollOffMaxDistance
											newObj.RollOffMinDistance = info.RollOffMinDistance
											newObj.RollOffMode = Enum.RollOffMode[info.RollOffMode]
											newObj.SoundId = info.SoundId
											setReference(newObj, parent, info.SoundGroup, "SoundGroup")
											newObj.TimePosition = info.TimePosition
											newObj.Volume = info.Volume
											if newObj.Playing and not newObj.IsPlaying then
												if newObj.SoundId ~= "" then
													local playSound = coroutine.wrap(function()
														if not newObj.IsLoaded then
															newObj.Loaded:Wait()
														end
														newObj:Play()
													end)
													playSound()
												end
											end
										elseif newObj:IsA("SoundEffect") then
											newObj.Enabled = info.Enabled
											newObj.Priority = info.Priority
											if newObj:IsA("ChorusSoundEffect") then
												newObj.Depth = info.Depth
												newObj.Mix = info.Mix
												newObj.Rate = info.Rate
											elseif newObj:IsA("DistortionSoundEffect") then
												newObj.Level = info.Level
											elseif newObj:IsA("EchoSoundEffect") then
												newObj.Delay = info.Delay
												newObj.DryLevel = info.DryLevel
												newObj.Feedback = info.Feedback
												newObj.WetLevel = info.WetLevel
											elseif newObj:IsA("EqualizerSoundEffect") then
												newObj.HighGain = info.HighGain
												newObj.LowGain = info.LowGain
												newObj.MidGain = info.MidGain
											elseif newObj:IsA("PitchShiftSoundEffect") then
												newObj.Octave = info.Octave
											elseif newObj:IsA("ReverbSoundEffect") then
												newObj.DecayTime = info.DecayTime
												newObj.Density = info.Density
												newObj.Diffusion = info.Diffusion
												newObj.DryLevel = info.DryLevel
												newObj.WetLevel = info.WetLevel
											elseif newObj:IsA("TremoloSoundEffect") then
												newObj.Depth = info.Depth
												newObj.Duty = info.Duty
												newObj.Frequency = info.Frequency
											end
										elseif newObj:IsA("ParticleEmitter") then
											--Appearance
											newObj.Color = propTable(info.Color)
											newObj.LightEmission = info.LightEmission
											newObj.LightInfluence = info.LightInfluence
											newObj.Orientation = Enum.ParticleOrientation[info.Orientation]
											newObj.Size = propTable(info.Size)
											newObj.Squash = propTable(info.Squash)
											newObj.Texture = info.Texture
											newObj.Transparency = propTable(info.Transparency)
											newObj.ZOffset = info.ZOffset
											--Emission
											newObj.EmissionDirection = Enum.NormalId[info.EmissionDirection]
											newObj.Enabled = info.Enabled
											newObj.Lifetime = propTable(info.Lifetime)
											newObj.Rate = info.Rate
											newObj.Rotation = propTable(info.Rotation)
											newObj.RotSpeed = propTable(info.RotSpeed)
											newObj.Speed = propTable(info.Speed)
											newObj.SpreadAngle = propTable(info.SpreadAngle)
											--EmitterShape
											newObj.Shape = Enum.ParticleEmitterShape[info.Shape]
											newObj.ShapeInOut = Enum.ParticleEmitterShapeInOut[info.ShapeInOut]
											newObj.ShapeStyle = Enum.ParticleEmitterShapeStyle[info.ShapeStyle]
											--Motion
											newObj.Acceleration = propTable(info.Acceleration)
											--Particles
											newObj.Drag = info.Drag
											newObj.LockedToPart = info.LockedToPart
											newObj.TimeScale = info.TimeScale
											newObj.VelocityInheritance = info.VelocityInheritance
										elseif newObj:IsA("Beam") then
											newObj.Color = propTable(info.Color)
											newObj.Enabled = info.Enabled
											setReference(newObj, parent, info.Attachment0, "Attachment0")
											setReference(newObj, parent, info.Attachment1, "Attachment1")
											newObj.LightEmission = info.LightEmission
											newObj.LightInfluence = info.LightInfluence
											newObj.Texture = info.Texture
											newObj.TextureLength = info.TextureLength
											newObj.TextureMode = Enum.TextureMode[info.TextureMode]
											newObj.TextureSpeed = info.TextureSpeed
											newObj.Transparency = propTable(info.Transparency)
											newObj.ZOffset = info.ZOffset

											newObj.CurveSize0 = info.CurveSize0
											newObj.CurveSize1 = info.CurveSize1
											newObj.FaceCamera = info.FaceCamera
											newObj.Segments = info.Segments
											newObj.Width0 = info.Width0
											newObj.Width1 = info.Width1
										elseif newObj:IsA("Explosion") then
											newObj.BlastPreasure = info.BlastPreasure;
											newObj.BlastRadius = info.BlastRadius;
											newObj.DestroyJointRadiusPercent = info.DestroyJointRadiusPercent;
											newObj.ExplosionType = Enum.ExplosionType[info.ExplosionType];
											newObj.Position = propTable(info.Position);
											newObj.TimeScale = info.TimeScale;
											newObj.Visible = info.Visible;
										elseif newObj:IsA("Fire") then
											newObj.Color = propTable(info.Color);
											newObj.Enabled = info.Enabled;
											newObj.Heat = info.Heat;
											newObj.SecondaryColor = propTable(info.SecondaryColor);
											newObj.Size = info.Size;
											newObj.TimeScale = info.TimeScale;
										elseif newObj:IsA("Highlight") then
											setReference(newObj, parent, info.Adornee, "Adornee")
											newObj.DepthMode = Enum.HighlightDepthMode[info.DepthMode]
											newObj.Enabled = info.Enabled;
											newObj.FillColor = propTable(info.FillColor);
											newObj.FillTransparency = info.FillTransparency
											newObj.OutlineColor = propTable(info.OutlineColor);
											newObj.OutlineTransparency = info.OutlineTransparency
										elseif newObj:IsA("Smoke") then
											newObj.Color = propTable(info.Color);
											newObj.Enabled = info.Enabled;
											newObj.Opacity = info.Opacity;
											newObj.RiseVelocity = info.RiseVelocity;
											newObj.Size = info.Size;
											newObj.TimeScale = info.TimeScale;
										elseif newObj:IsA("Sparkles") then
											newObj.Color = propTable(info.Color);
											newObj.Enabled = info.Enabled;
											newObj.SparkleColor = propTable(info.SparkleColor);
											newObj.TimeScale = info.TimeScale;
										elseif newObj:IsA("Trail") then
											setReference(newObj, parent, info.Attachment0, "Attachment0")
											setReference(newObj, parent, info.Attachment1, "Attachment1")
											newObj.Brightness = info.Brightness;
											newObj.Color = propTable(info.Color);
											newObj.Enabled = info.Enabled;
											newObj.FaceCamera = info.FaceCamera;
											newObj.Lifetime = info.Lifetime;
											newObj.LightEmission = info.LightEmission;
											newObj.LightInfluence = info.LightInfluence;
											newObj.MaxLength = info.MaxLength;
											newObj.MinLength = info.MinLength;
											newObj.Texture = info.Texture;
											newObj.TextureLength = info.TextureLength;
											newObj.TextureMode = Enum.TextureMode[info.TextureMode];
											newObj.Transparency = propTable(info.Transparency);
											newObj.WidthScale = propTable(info.WidthScale);
										elseif newObj:IsA("Atmosphere") then
											newObj.Color = propTable(info.Color)
											newObj.Decay = propTable(info.Decay)
											newObj.Density = info.Density
											newObj.Glare = info.Glare
											newObj.Haze = info.Haze
											newObj.Offset = info.Offset
										elseif newObj:IsA("Clouds") then
											newObj.Color = propTable(info.Color)
											newObj.Cover = info.Cover
											newObj.Density = info.Density
											newObj.Enabled = info.Enabled
										elseif newObj:IsA("Sky") then
											newObj.CelestialBodiesShown = info.CelestialBodiesShown
											newObj.MoonAngularSize = info.MoonAngularSize
											newObj.MoonTextureId = info.MoonTextureId
											newObj.SkyboxBk = info.SkyboxBk
											newObj.SkyboxDn = info.SkyboxDn
											newObj.SkyboxFt = info.SkyboxFt
											newObj.SkyboxLf = info.SkyboxLf
											newObj.SkyboxRt = info.SkyboxRt
											newObj.SkyboxUp = info.SkyboxUp
											newObj.StarCount = info.StarCount
											newObj.SunAngularSize = info.SunAngularSize
											newObj.SunTextureId = info.SunTextureId
										elseif newObj:IsA("PostEffect") then
											newObj.Enabled = info.Enabled
											if newObj:IsA("BloomEffect") then
												newObj.Intensity = info.Intensity
												newObj.Size = info.Size
												newObj.Threshold = info.Threshold
											elseif newObj:IsA("BlurEffect") then
												newObj.Size = info.Size
											elseif newObj:IsA("ColorCorrectionEffect") then
												newObj.Brightness = info.Brightness
												newObj.Contrast = info.Contrast
												newObj.Saturation = info.Saturation
												newObj.TintColor = propTable(info.TintColor)
											elseif newObj:IsA("DepthOfFieldEffect") then
												newObj.FarIntensity = info.FarIntensity
												newObj.FocusDistance = info.FocusDistance
												newObj.InFocusRadius = info.InFocusRadius
												newObj.NearIntensity = info.NearIntensity
											elseif newObj:IsA("SunRaysEffect") then
												newObj.Intensity = info.Intensity
												newObj.Spread = info.Spread
											end
										elseif newObj:IsA("Light") then
											newObj.Brightness = info.Brightness
											newObj.Color = propTable(info.Color)
											newObj.Enabled = info.Enabled
											newObj.Shadows = info.Shadows
											if newObj:IsA("PointLight") then
												newObj.Range = info.Range
											elseif newObj:IsA("SurfaceLight") or newObj:IsA("SpotLight") then
												newObj.Range = info.Range
												newObj.Angle = info.Angle
												newObj.Face = Enum.NormalId[info.Face]
											end
										elseif newObj:IsA("Decal") then
											newObj.Color3 = propTable(info.Color3)
											newObj.Texture = info.Texture
											newObj.Transparency = info.Transparency
											newObj.ZIndex = info.ZIndex
											newObj.Face = Enum.NormalId[info.Face]
											if newObj:IsA("Texture") then
												newObj.OffsetStudsU = info.OffsetStudsU
												newObj.OffsetStudsV = info.OffsetStudsV
												newObj.StudsPerTileU = info.StudsPerTileU
												newObj.StudsPerTileV = info.StudsPerTileV
											end
										elseif newObj:IsA("Attachment") then
											newObj.Visible = info.Visible
											newObj.CFrame = propTable(info.CFrame)
											--newObj.WorldCFrame = propTable(info.WorldCFrame)
											if newObj:IsA("Bone") then
												newObj.Transform = propTable(info.Transform)
											end
										elseif newObj:IsA("ValueBase") then
											if newObj:IsA("CFrameValue") or newObj:IsA("Vector3Value") or newObj:IsA("RayValue") or newObj:IsA("Color3Value") or newObj:IsA("BrickColorValue") then
												newObj.Value = propTable(info.Value)
											elseif newObj:IsA("ObjectValue") then
												if info.Value then
													scanObjects(newObj, info.Value, nil, true)
												end
												--print(newObj.Name .. " is a ValueBase.")
											else
												newObj.Value = info.Value
											end
										elseif newObj:IsA("BaseScript") then
											newObj.Disabled = info.Disabled
											newObj.LinkedSource = info.LinkedSource
											local isScript = nil
											for i, v in pairs(ServerStorage:GetDescendants()) do
												if v:IsA(info.ClassName) then
													if v.Name == info.Name and v.LinkedSource == info.LinkedSource then
														isScript = v
														newObj:Destroy()
														newObj = v:Clone()
														newObj:ClearAllChildren()
														break
													end
												end
											end
											newObj.Disabled = info.Disabled
											if not isScript then
												warn(info.ClassName .. ": " .. info.Name .. " with LinkedSource: " .. info.LinkedSource .. " has not been found in ServerStorage." )
											end
										elseif newObj:IsA("ModuleScript") then
											newObj.LinkedSource = info.LinkedSource
											local isScript = nil
											for i, v in pairs(ServerStorage:GetDescendants()) do
												if v:IsA("ModuleScript") then
													if v.Name == info.Name and v.LinkedSource == info.LinkedSource then
														isScript = v
														newObj:Destroy()
														newObj = v:Clone()
														newObj:ClearAllChildren()
														break
													end
												end
											end
											if not isScript then
												warn(info.ClassName .. ": " .. info.Name .. " with LinkedSource: " .. info.LinkedSource .. " has not been found in ServerStorage." )
											end
										elseif newObj:IsA("Constraint") then
											newObj.Color = propTable(info.Color)
											newObj.Enabled = info.Enabled
											newObj.Visible = info.Visible
											setReference(newObj, parent, info.Attachment0, "Attachment0")
											setReference(newObj, parent, info.Attachment1, "Attachment1")
											if newObj:IsA("AlignOrientation") then
												newObj.AlignType = Enum.AlignType[info.AlignType]
												newObj.CFrame = propTable(info.CFrame)
												newObj.MaxAngularVelocity = info.MaxAngularVelocity
												newObj.MaxTorque = info.MaxTorque
												newObj.Mode = Enum.OrientationAlignmentMode[info.Mode]
												newObj.PrimaryAxis = propTable(info.PrimaryAxis)
												newObj.PrimaryAxisOnly = info.PrimaryAxisOnly
												newObj.ReactionTorqueEnabled = info.ReactionTorqueEnabled
												newObj.Responsiveness = info.Responsiveness
												newObj.RigidityEnabled = info.RigidityEnabled
												newObj.SecondaryAxis = propTable(info.SecondaryAxis)
											elseif newObj:IsA("AlignPosition") then
												newObj.ApplyAtCenterOfMass = info.ApplyAtCenterOfMass
												newObj.MaxForce = info.MaxForce
												newObj.MaxVelocity = info.MaxVelocity
												newObj.Mode = Enum.PositionAlignmentMode[info.Mode]
												newObj.Position = propTable(info.Position)
												newObj.ReactionForceEnabled = info.ReactionForceEnabled
												newObj.Responsiveness = info.Responsiveness
												newObj.RigidityEnabled = info.RigidityEnabled
											elseif newObj:IsA("AngularVelocity") then
												newObj.AngularVelocity = propTable(info.AngularVelocity)
												newObj.MaxTorque = info.MaxTorque
												newObj.ReactionTorqueEnabled = info.ReactionTorqueEnabled
												newObj.RelativeTo = Enum.ActuatorRelativeTo[info.RelativeTo]
											elseif newObj:IsA("BallSocketConstraint") then
												newObj.LimitsEnabled = info.LimitsEnabled
												newObj.MaxFrictionTorque = info.MaxFrictionTorque
												newObj.Radius = info.Radius
												newObj.Restitution = info.Restitution
												newObj.TwistLimitsEnabled = info.TwistLimitsEnabled
												newObj.TwistLowerAngle = info.TwistLowerAngle
												newObj.TwistUpperAngle = info.TwistUpperAngle
												newObj.UpperAngle = info.UpperAngle
											elseif newObj:IsA("SlidingBallConstraint") then
												newObj.ActuatorType = Enum.ActuatorType[info.ActuatorType]
												newObj.LimitsEnabled = info.LimitsEnabled
												newObj.LinearResponsiveness = info.LinearResponsiveness
												newObj.MotorMaxAcceleration = info.MotorMaxAcceleration
												newObj.MotorMaxForce = info.MotorMaxForce
												newObj.Restitution = info.Restitution
												newObj.ServoMaxForce = info.ServoMaxForce
												newObj.Size = info.Size
												newObj.Speed = info.Speed
												newObj.TargetPosition = info.TargetPosition
												newObj.UpperLimit = info.UpperLimit
												newObj.Velocity = info.Velocity
												if newObj:IsA("CylindricalConstraint") then
													newObj.AngularActuatorType = Enum.ActuatorType[info.AngularActuatorType]
													newObj.AngularLimitsEnabled = info.AngularLimitsEnabled
													newObj.AngularResponsiveness = info.AngularResponsiveness
													newObj.AngularRestitution = info.AngularRestitution
													newObj.AngularSpeed = info.AngularSpeed
													newObj.AngularVelocity = info.AngularVelocity
													newObj.InclinationAngle = info.InclinationAngle
													newObj.LowerAngle = info.LowerAngle
													newObj.MotorMaxAngularAcceleration = info.MotorMaxAngularAcceleration
													newObj.MotorMaxTorque = info.MotorMaxTorque
													newObj.RotationAxisVisible = info.RotationAxisVisible
													newObj.ServoMaxTorque = info.ServoMaxTorque
													newObj.TargetAngle = info.TargetAngle
													newObj.UpperAngle = info.UpperAngle
												end
											elseif newObj:IsA("HingeConstraint") then
												newObj.ActuatorType = Enum.ActuatorType[info.ActuatorType]
												newObj.AngularResponsiveness = info.AngularResponsiveness
												newObj.AngularSpeed = info.AngularSpeed
												newObj.AngularVelocity = info.AngularVelocity
												newObj.LimitsEnabled = info.LimitsEnabled
												newObj.LowerAngle = info.LowerAngle
												newObj.MotorMaxAcceleration = info.MotorMaxAcceleration
												newObj.MotorMaxTorque = info.MotorMaxTorque
												newObj.Radius = info.Radius
												newObj.Restitution = info.Restitution
												newObj.ServoMaxTorque = info.ServoMaxTorque
												newObj.TargetAngle = info.TargetAngle
												newObj.UpperAngle = info.UpperAngle
											elseif newObj:IsA("LinearVelocity") then
												newObj.LineDirection = propTable(info.LineDirection)
												newObj.LineVelocity = info.LineVelocity
												newObj.MaxForce = info.MaxForce
												newObj.PlaneVelocity = propTable(info.PlaneVelocity)
												newObj.PrimaryTangentAxis = propTable(info.PrimaryTangentAxis)
												newObj.RelativeTo = Enum.ActuatorRelativeTo[info.RelativeTo]
												newObj.SecondaryTangentAxis = propTable(info.SecondaryTangentAxis)
												newObj.VectorVelocity = propTable(info.VectorVelocity)
												newObj.VelocityConstraintMode = Enum.VelocityConstraintMode[info.VelocityConstraintMode]
											elseif newObj:IsA("LineForce") then
												newObj.ApplyAtCenterOfMass = info.ApplyAtCenterOfMass
												newObj.InverseSquareLaw = info.InverseSquareLaw
												newObj.Magnitude = info.Magnitude
												newObj.MaxForce = info.MaxForce
												newObj.ReactionForceEnabled = info.ReactionForceEnabled
											elseif newObj:IsA("RigidConstraint") then
												newObj.DestructionEnabled = info.DestructionEnabled
												newObj.DestructionForce = info.DestructionForce
												newObj.DestructionTorque = info.DestructionTorque
											elseif newObj:IsA("RodConstraint") then
												newObj.Length = info.Length
												newObj.LimitAngle0 = info.LimitAngle0
												newObj.LimitAngle1 = info.LimitAngle1
												newObj.LimitsEnabled = info.LimitsEnabled
												newObj.Thickness = info.Thickness
											elseif newObj:IsA("RopeConstraint") then
												newObj.Length = info.Length
												newObj.Restitution = info.Restitution
												newObj.Thickness = info.Thickness
												newObj.WinchEnabled = info.WinchEnabled
												newObj.WinchForce = info.WinchForce
												newObj.WinchResponsiveness = info.WinchResponsiveness
												newObj.WinchSpeed = info.WinchSpeed
												newObj.WinchTarget = info.WinchTarget
											elseif newObj:IsA("SpringConstraint") then
												newObj.Coils = info.Coils
												newObj.Damping = info.Damping
												newObj.FreeLength = info.FreeLength
												newObj.LimitsEnabled = info.LimitsEnabled
												newObj.MaxForce = info.MaxForce
												newObj.MaxLength = info.MaxLength
												newObj.MinLength = info.MinLength
												newObj.Radius = info.Radius
												newObj.Stiffness = info.Stiffness
												newObj.Thickness = info.Thickness
											elseif newObj:IsA("Torque") then
												newObj.RelativeTo = Enum.ActuatorRelativeTo[info.RelativeTo]
												newObj.Torque = propTable(info.Torque)
											elseif newObj:IsA("TorsionSpringConstraint") then
												newObj.Coils = info.Coils
												newObj.Damping = info.Damping
												newObj.LimitsEnabled = info.LimitsEnabled
												newObj.MaxAngle = info.MaxAngle
												newObj.MaxTorque = info.MaxTorque
												newObj.Radius = info.Radius
												newObj.Restitution = info.Restitution
												newObj.Stiffness = info.Stiffness
											elseif newObj:IsA("UniversalConstraint") then
												newObj.LimitsEnabled = info.LimitsEnabled
												newObj.MaxAngle = info.MaxAngle
												newObj.Radius = info.Radius
												newObj.Restitution = info.Restitution
											elseif newObj:IsA("VectorForce") then
												newObj.ApplyAtCenterOfMass = info.ApplyAtCenterOfMass
												newObj.Force = propTable(info.Force)
												newObj.RelativeTo = Enum.ActuatorRelativeTo[info.RelativeTo]
											end
										elseif newObj:IsA("NoCollisionConstraint") or newObj:IsA("WeldConstraint") then
											newObj.Enabled = info.Enabled
											setReference(newObj, parent, info.Part0, "Part0")
											setReference(newObj, parent, info.Part1, "Part1")
										elseif newObj:IsA("LocalizationTable") then
											newObj.SourceLocaleId = info.SourceLocaleId
										elseif newObj:IsA("GuiBase2d") then
											newObj.AutoLocalize = info.AutoLocalize
											setReference(newObj, parent, info.RootLocalizationTable, "RootLocalizationTable")
											if newObj:IsA("LayerCollector") then
												newObj.Enabled = info.Enabled
												newObj.ResetOnRespawn = info.ResetOnRespawn
												newObj.ZIndexBehavior = Enum.ZIndexBehavior[info.ZIndexBehavior]
												if newObj:IsA("ScreenGui") then
													newObj.DisplayOrder = info.DisplayOrder
													newObj.IgnoreGuiInset = info.IgnoreGuiInset
												elseif newObj:IsA("BillboardGui") then
													newObj.Active = info.Active
													setReference(newObj, parent, info.Adornee, "Adornee")
													newObj.AlwaysOnTop = info.AlwaysOnTop
													newObj.Brightness = info.Brightness
													newObj.ClipsDescendants = info.ClipsDescendants
													newObj.DistanceLowerLimit = info.DistanceLowerLimit
													newObj.DistanceStep = info.DistanceStep
													newObj.DistanceUpperLimit = info.DistanceUpperLimit
													newObj.ExtentsOffset = propTable(info.ExtentsOffset)
													newObj.ExtentsOffsetWorldSpace = propTable(info.ExtentsOffsetWorldSpace)
													newObj.LightInfluence = info.LightInfluence
													newObj.MaxDistance = info.MaxDistance
													if info.PlayerToHideFrom then
														newObj.PlayerToHideFrom = Player
													end
													newObj.Size = propTable(info.Size)
													newObj.SizeOffset = propTable(info.SizeOffset)
													newObj.StudsOffset = propTable(info.StudsOffset)
													newObj.StudsOffsetWorldSpace = propTable(info.StudsOffsetWorldSpace)
												elseif newObj:IsA("SurfaceGui") then
													newObj.Active = info.Active
													setReference(newObj, parent, info.Adornee, "Adornee")
													newObj.AlwaysOnTop = info.AlwaysOnTop
													newObj.Brightness = info.Brightness
													newObj.CanvasSize = propTable(info.CanvasSize)
													newObj.ClipsDescendants = info.ClipsDescendants
													newObj.Face = Enum.NormalId[info.Face]
													newObj.LightInfluence = info.LightInfluence
													newObj.PixelsPerStud = info.PixelsPerStud
													newObj.SizingMode = Enum.SurfaceGuiSizingMode[info.SizingMode]
													newObj.ToolPunchThroughDistance = info.ToolPunchThroughDistance
													newObj.ZOffset = info.ZOffset
												end
											elseif newObj:IsA("GuiObject") then
												newObj.Active = info.Active
												newObj.AnchorPoint = propTable(info.AnchorPoint)
												newObj.AutomaticSize = Enum.AutomaticSize[info.AutomaticSize]
												newObj.BackgroundColor3 = propTable(info.BackgroundColor3)
												newObj.BackgroundTransparency = info.BackgroundTransparency
												newObj.BorderColor3 = propTable(info.BorderColor3)
												newObj.BorderMode = Enum.BorderMode[info.BorderMode]
												newObj.BorderSizePixel = info.BorderSizePixel
												newObj.ClipsDescendants = info.ClipsDescendants
												newObj.LayoutOrder = info.LayoutOrder
												setReference(newObj, parent, info.NextSelectionDown, "NextSelectionDown")
												setReference(newObj, parent, info.NextSelectionLeft, "NextSelectionLeft")
												setReference(newObj, parent, info.NextSelectionRight, "NextSelectionRight")
												setReference(newObj, parent, info.NextSelectionUp, "NextSelectionUp")
												newObj.Position = propTable(info.Position)
												newObj.Rotation = info.Rotation
												newObj.Selectable = info.Selectable
												setReference(newObj, parent, info.SelectionImageObject, "SelectionImageObject")
												newObj.Size = propTable(info.Size)
												newObj.SizeConstraint = Enum.SizeConstraint[info.SizeConstraint]
												newObj.Transparency = info.Transparency
												newObj.Visible = info.Visible
												newObj.ZIndex = info.ZIndex
												if newObj:IsA("Frame") then
													newObj.Style = Enum.FrameStyle[info.Style]
												elseif newObj:IsA("ScrollingFrame") then
													newObj.AutomaticCanvasSize = Enum.AutomaticSize[info.AutomaticCanvasSize]
													newObj.BottomImage = Object.BottomImage
													newObj.CanvasPosition = propTable(Object.CanvasPosition)
													newObj.CanvasSize = propTable(Object.CanvasSize)
													newObj.ElasticBehavior = Enum.ElasticBehavior[info.ElasticBehavior]
													newObj.HorizontalScrollBarInset = Enum.ScrollBarInset[info.HorizontalScrollBarInset]
													newObj.MidImage = Object.MidImage
													newObj.ScrollBarImageColor3 = propTable(Object.ScrollBarImageColor3)
													newObj.ScrollBarImageTransparency = Object.ScrollBarImageTransparency
													newObj.ScrollBarThickness = Object.ScrollBarThickness
													newObj.ScrollVelocity = propTable(Object.ScrollVelocity)
													newObj.ScrollingDirection = Enum.ScrollingDirection[info.ScrollingDirection]
													newObj.ScrollingEnabled = Object.ScrollingEnabled
													newObj.TopImage = Object.TopImage
													newObj.VerticalScrollBarInset = Enum.ScrollBarInset[info.VerticalScrollBarInset]
													newObj.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition[info.VerticalScrollBarPosition]
												elseif newObj:IsA("TextLabel") or newObj:IsA("TextButton") then
													newObj.Font = Enum.Font[info.Font]
													newObj.LineHeight = info.LineHeight
													newObj.MaxVisibleGraphemes = info.MaxVisibleGraphemes
													newObj.RichText = info.RichText
													newObj.Text = info.Text
													newObj.TextColor3 = propTable(info.TextColor3)
													newObj.TextScaled = info.TextScaled
													newObj.TextSize = info.TextSize
													newObj.TextStrokeColor3 = propTable(info.TextStrokeColor3)
													newObj.TextStrokeTransparency = info.TextStrokeTransparency
													newObj.TextTransparency = info.TextTransparency
													newObj.TextTruncate = Enum.TextTruncate[info.TextTruncate]
													newObj.TextWrapped = info.TextWrapped
													newObj.TextXAlignment = Enum.TextXAlignment[info.TextXAlignment]
													newObj.TextYAlignment = Enum.TextYAlignment[info.TextYAlignment]
												elseif newObj:IsA("TextBox") then
													newObj.ClearTextOnFocus = info.ClearTextOnFocus
													newObj.CursorPosition = info.CursorPosition
													newObj.Font = Enum.Font[info.Font]
													newObj.LineHeight = info.LineHeight
													newObj.MaxVisibleGraphemes = info.MaxVisibleGraphemes
													newObj.MultiLine = info.MultiLine
													newObj.PlaceholderColor3 = propTable(info.PlaceholderColor3)
													newObj.RichText = info.RichText
													newObj.SelectionStart = info.SelectionStart
													newObj.ShowNativeInput = info.ShowNativeInput
													newObj.Text = info.Text
													newObj.TextColor3 = propTable(info.TextColor3)
													newObj.TextEditable = info.TextEditable
													newObj.TextScaled = info.TextScaled
													newObj.TextSize = info.TextSize
													newObj.TextStrokeColor3 = propTable(info.TextStrokeColor3)
													newObj.TextStrokeTransparency = info.TextStrokeTransparency
													newObj.TextTransparency = info.TextTransparency
													newObj.TextTruncate = Enum.TextTruncate[info.TextTruncate]
													newObj.TextWrapped = info.TextWrapped
													newObj.TextXAlignment = Enum.TextXAlignment[info.TextXAlignment]
													newObj.TextYAlignment = Enum.TextYAlignment[info.TextYAlignment]
												elseif newObj:IsA("ImageLabel") then
													newObj.Image = info.Image
													newObj.ImageColor3 = propTable(info.ImageColor3)
													newObj.ImageRectOffset = propTable(info.ImageRectOffset)
													newObj.ImageRectSize = propTable(info.ImageRectSize)
													newObj.ImageTransparency = info.ImageTransparency
													newObj.ResampleMode = Enum.ResamplerMode[info.ResampleMode]
													newObj.ScaleType = Enum.ScaleType[info.ScaleType]
													newObj.SliceCenter = propTable(info.SliceCenter)
													newObj.SliceScale = info.SliceScale
													newObj.TileSize = propTable(info.TileSize)
												elseif newObj:IsA("ImageButton") then
													newObj.HoverImage = info.HoverImage
													newObj.Image = info.Image
													newObj.ImageColor3 = propTable(info.ImageColor3)
													newObj.ImageRectOffset = propTable(info.ImageRectOffset)
													newObj.ImageRectSize = propTable(info.ImageRectSize)
													newObj.ImageTransparency = info.ImageTransparency
													newObj.PressedImage = info.PressedImage
													newObj.ResampleMode = Enum.ResamplerMode[info.ResampleMode]
													newObj.ScaleType = Enum.ScaleType[info.ScaleType]
													newObj.SliceCenter = propTable(info.SliceCenter)
													newObj.SliceScale = info.SliceScale
													newObj.TileSize = propTable(info.TileSize)
												elseif newObj:IsA("ViewportFrame") then
													newObj.Ambient = propTable(info.Ambient)
													--newObj.CurrentCamera
													newObj.ImageColor3 = propTable(info.ImageColor3)
													newObj.ImageTransparency = info.ImageTransparency
													newObj.LightColor = propTable(info.LightColor)
													newObj.LightDirection = propTable(info.LightDirection)
												elseif newObj:IsA("VideoFrame") then
													newObj.Looped = info.Looped
													newObj.Playing = info.Playing
													newObj.TimePosition = info.TimePosition
													newObj.Video = info.Video
													newObj.Volume = info.Volume
												end
											end
										elseif newObj:IsA("GuiBase3d") then
											newObj.Color3 = propTable(info.Color3)
											newObj.Transparency = info.Transparency
											newObj.Visible = info.Visible
											if newObj:IsA("PartAdornment") then
												setReference(newObj, parent, info.Adornee, "Adornee")
												if newObj:IsA("ArcHandles") then
													newObj.Axes = propTable(info.Axes)
												elseif newObj:IsA("Handles") then
													newObj.Faces = propTable(info.Faces)
													newObj.Style = Enum.HandlesStyle[info.Style]
												elseif newObj:IsA("SurfaceSelection") then
													newObj.TargetSurface = Enum.NormalId[info.TargetSurface]
												end
											elseif newObj:IsA("PVAdornment") then
												setReference(newObj, parent, info.Adornee, "Adornee")
												if newObj:IsA("HandleAdornment") then
													newObj.AdornCullingMode = Enum.AdornCullingMode[info.AdornCullingMode]
													newObj.AlwaysOnTop = info.AlwaysOnTop
													newObj.CFrame = propTable(info.CFrame)
													newObj.SizeRelativeOffset = propTable(info.SizeRelativeOffset)
													newObj.ZIndex = info.ZIndex
													if newObj:IsA("BoxHandleAdornment") then
														newObj.Size = propTable(info.Size)
													elseif newObj:IsA("ConeHandleAdornment") then
														newObj.Height = info.Height
														newObj.Radius = info.Radius
													elseif newObj:IsA("CylinderHandleAdornment") then
														newObj.Angle = info.Angle
														newObj.Height = info.Height
														newObj.InnerRadius = info.InnerRadius
														newObj.Radius = info.Radius
													elseif newObj:IsA("ImageHandleAdornment") then
														newObj.Image = info.Image
														newObj.Size = propTable(info.Size)
													elseif newObj:IsA("LineHandleAdornment") then
														newObj.Length = info.Length
														newObj.Thickness = info.Thickness
													elseif newObj:IsA("SphereHandleAdornment") then
														newObj.Radius = info.Radius
													end
												elseif newObj:IsA("SelectionSphere") then
													newObj.SurfaceColor3 = propTable(info.SurfaceColor3)
													newObj.SurfaceTransparency = info.SurfaceTransparency
												end
											elseif newObj:IsA("SelectionBox") then
												newObj.LineThickness = info.LineThickness
												newObj.SurfaceColor3 = propTable(info.SurfaceColor3)
												newObj.SurfaceTransparency = info.SurfaceTransparency
											end
										elseif newObj:IsA("PathfindingLink") then
											setReference(newObj, parent, info.Attachment0, "Attachment0")
											setReference(newObj, parent, info.Attachment1, "Attachment1")
											newObj.IsBidirectional = info.IsBidirectional
											newObj.Label = info.Label
										elseif newObj:IsA("PathfindingModifier") then
											newObj.Label = info.Label
											newObj.PassThrough = info.PassThrough
										elseif newObj:IsA("UIAspectRatioConstraint") then
											newObj.AspectRatio = info.AspectRatio
											newObj.AspectType = Enum.AspectType[info.AspectType]
											newObj.DominantAxis = Enum.DominantAxis[info.DominantAxis]
										elseif newObj:IsA("UICorner") then
											newObj.CornerRadius = propTable(info.CornerRadius)
										elseif newObj:IsA("UIGradient") then
											newObj.Color = propTable(info.Color)
											newObj.Enabled = info.Enabled
											newObj.Offset = propTable(info.Offset)
											newObj.Rotation = info.Rotation
											newObj.Transparency = propTable(info.Transparency)
										elseif newObj:IsA("UIGridStyleLayout") then
											newObj.FillDirection = Enum.FillDirection[info.FillDirection]
											newObj.HorizontalAlignment = Enum.HorizontalAlignment[info.HorizontalAlignment]
											newObj.SortOrder = Enum.SortOrder[info.SortOrder]
											newObj.VerticalAlignment = Enum.VerticalAlignment[info.VerticalAlignment]
											if newObj:IsA("UIGridLayout") then
												newObj.CellPadding = propTable(info.CellPadding)
												newObj.CellSize = propTable(info.CellSize)
												newObj.FillDirectionMaxCells = info.FillDirectionMaxCells
												newObj.StartCorner = Enum.StartCorner[info.StartCorner]
											elseif newObj:IsA("UIListLayout") then
												newObj.Padding = propTable(info.Padding)
											elseif newObj:IsA("UIPageLayout") then
												newObj.Animated = info.Animated
												newObj.Circular = info.Circular
												newObj.EasingDirection = Enum.EasingDirection[info.EasingDirection]
												newObj.EasingStyle = Enum.EasingStyle[info.EasingStyle]
												newObj.GamepadInputEnabled = info.GamepadInputEnabled
												newObj.Padding = propTable(info.Padding)
												newObj.ScrollWheelInputEnabled = info.ScrollWheelInputEnabled
												newObj.TouchInputEnabled = info.TouchInputEnabled
												newObj.TweenTime = info.TweenTime
											elseif newObj:IsA("UITableLayout") then
												newObj.FillEmptySpaceColumns = info.FillEmptySpaceColumns
												newObj.FillEmptySpaceRows = info.FillEmptySpaceRows
												newObj.MajorAxis = Enum.TableMajorAxis[info.MajorAxis]
												newObj.Padding = propTable(info.Padding)
											end
										elseif newObj:IsA("UIPadding") then
											newObj.PaddingBottom = propTable(info.PaddingBottom)
											newObj.PaddingLeft = propTable(info.PaddingLeft)
											newObj.PaddingRight = propTable(info.PaddingRight)
											newObj.PaddingTop = propTable(info.PaddingTop)
										elseif newObj:IsA("UIScale") then
											newObj.Scale = info.Scale
										elseif newObj:IsA("UISizeConstraint") then
											newObj.MaxSize = propTable(info.MaxSize)
											newObj.MinSize = propTable(info.MinSize)
										elseif newObj:IsA("UIStroke") then
											newObj.ApplyStrokeMode = Enum.ApplyStrokeMode[info.ApplyStrokeMode]
											newObj.Color = propTable(info.Color)
											newObj.Enabled = info.Enabled
											newObj.LineJoinMode = Enum.LineJoinMode[info.LineJoinMode]
											newObj.Thickness = info.Thickness
											newObj.Transparency = info.Transparency
										elseif newObj:IsA("UITextSizeConstraint") then
											newObj.MaxTextSize = info.MaxTextSize
											newObj.MinTextSize = info.MinTextSize
										end

										if parent then
											newObj.Parent = parent
											if parent:IsA("Model") then
												if primarypart and type(primarypart) == "string" and newObj.Name == primarypart then
													if parent.Name == info.Parent then
														parent.PrimaryPart = newObj
													end
												end
											end
										else
											--newObj.Parent = workspace
											firstPart = newObj
										end
										if info.Children then
											for i, v in pairs(info.Children) do
												createObj(v, newObj, isPrimaryPart)
											end
										end
									end
								end
								for i, v in pairs(objects) do
									createObj(v)
								end
								if firstPart then
									firstPart.Parent = TempFile
									if OBJ.Value and OBJ.Value ~= firstPart then
										OBJ.Value:Destroy()
									end
									OBJ.Value = firstPart
									--print(OBJ.Value, firstPart)
								end
							end
						end
						scanObjects(Object[i], v)
						setAttributes(Object[i], v)
					elseif Object[i]:IsA("BrickColorValue") then
						Object[i].Value = BrickColor.new(v.r, v.g, v.b)
						setAttributes(Object[i], v)
					else
						Scan(Object[i], v)
					end
				end
			end
		end
		Scan(DataFolder, DataTable)
	else
		warn("DataTable does not exist!")
	end
	DataFolder.Parent = Player
	return DataFolder
end

return DataSettings
--[Made by Jozeni00]--
