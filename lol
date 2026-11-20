local getgenv = getgenv or function()
    return _G
end

local __VelocityFns = {}

if not game:IsLoaded() then
    game.Loaded:Wait()
end


if getgenv().__UWUFriendEditionLoaded == true then
    return
end


local function safeLoadRemote(url)
    local ok, result = pcall(function()
        local source = game:HttpGet(url)
        local chunk = assert(loadstring(source))
        return chunk()
    end)
    return ok and result or nil
end

local LinoriaRepo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = safeLoadRemote(LinoriaRepo .. "Library.lua")
local ThemeManager = safeLoadRemote(LinoriaRepo .. "addons/ThemeManager.lua")
local SaveManager = safeLoadRemote(LinoriaRepo .. "addons/SaveManager.lua")

if not Library or not ThemeManager or not SaveManager then
    warn("[UWU] Official Linoria or addons unavailable; exiting without binding gameplay input")
    return
end

Library.AccentColor = Color3.fromRGB(155, 94, 245)


local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    CoreGui = game:GetService("CoreGui")
}

local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage
local Workspace = Services.Workspace
local UserInputService = Services.UserInputService
local RunService = Services.RunService
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local Drawing = Drawing
local LiveFolder = Workspace:FindFirstChild("Live") or Workspace:WaitForChild("Live", 12)
if not LiveFolder then return end

local function clamp(value, minValue, maxValue)
    return math.min(math.max(value, minValue), maxValue)
end

local function safeDisconnect(signal)
    if signal then
        pcall(function()
            signal:Disconnect()
        end)
    end
end

local function safeDestroy(instance)
    if instance then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local Runtime = {
    connections = {},
    cleanup = {},
    config = {}
}

local function registerConnection(connection)
    if connection then
        table.insert(Runtime.connections, connection)
    end
    return connection
end

local function ensureGlobalTable(name, defaults)
    local env = getgenv()
    env[name] = env[name] or {}
    for key, value in pairs(defaults or {}) do
        if env[name][key] == nil then
            env[name][key] = value
        end
    end
    return env[name]
end

local function initializeRuntimeConfig()
    getgenv().AimbotSettings = ensureGlobalTable("AimbotSettings", {
        Enabled = false,
        Npc = false,
        InputMode = "Hold",
        TrackingMode = "Instant",
        ControllerR3Lock = false,
        ViewStyle = "Classic",
        OverheadPitch = 10,
        CycleTarget = false,
        DirectionalSwitch = false,
        Bone = "HumanoidRootPart",
        AimOffsetY = 0.35,
        FOV = 120,
        ShowFov = false,
        AlignCharacterYaw = false,
        Team_Check = false,
    })
    -- Ignore old private-version response choices on every load.
    getgenv().AimbotSettings.TrackingMode = "Instant"

    getgenv().UI = ensureGlobalTable("UI", {
        Streamproof = false,
    })
    getgenv().Performance = ensureGlobalTable("Performance", {
        StabilityMode = true,
        EspUpdateInterval = 0.25,
        NoRender = false,
        Quality = 0,
        FpsCap = 0,
    })

    getgenv().AutoParry = ensureGlobalTable("AutoParry", {
        Enabled = false,
        Range = 25,
        MinDMG = 0.3,
        MaxDMG = 15,
        TriggerCooldown = 0.2,
        RequireBlockHeld = true,
        RequireNearbyTarget = false,
        IgnoreTeammates = false,
        TargetType = "Both",
        GroundOnly = false,
        FollowUp = "M1",
        SpacePolicy = "Physical",
        ReleaseDelay = 0.025,
        RecoveryDelay = 0.055,
        ControllerGuardButton = "X / Square",
        ControllerJumpButton = "A / Cross",
        ControllerToggleButton = "D-Pad Down",
        ControllerToggleEnabled = true,
        UseControllerSupport = false, -- physical controller input support
        ControllerOnePunchPerBurst = true, -- prevent repeat M1 from chained HP events
        ControllerBurstGap = 0.85, -- seconds of quiet HP before another punch is allowed
        DebugEnabled = false, -- event-based diagnostic overlay
        Indicator = { Visible = false },
    })

    getgenv().Force_Jump = ensureGlobalTable("Force_Jump", {
        Enabled = false,
        Key = "C",
        Upward = 35,
        Interval = 0.0045,
        Duration = 0.15
    })

    getgenv().Script = getgenv().Script or {}
    getgenv().Script.Attach_To_Back = getgenv().Script.Attach_To_Back or {
        Enabled = false,
        NPC = false,
        IgnoreTeammates = false,
        Bone = "HumanoidRootPart",
        AttachKey = Enum.KeyCode.X,
        MaxAttachDistance = 7000,
        Interval = 1,
        BodyPosition = {
            MaxForce = Vector3.new(5e6, 8e5, 5e6),
            P = 5e9,
            D = 23000,
            Name = "StickToBackBodyPosition"
        },
        Offset = {
            Side = 0,
            Back = 0.31,
            Height = 4.45
        }
    }

    getgenv().Macro = getgenv().Macro or {
        Gojo = {
            TripleBlue = false,
            WithM1 = false,
            Key = Enum.KeyCode.V
        },
        Mob = {
    Barrage = false,
    Key1 = Enum.KeyCode.B,
    WeakRepel = false,
    KeyWeakRepel = Enum.KeyCode.N,
},
        Zabuza = {
            Clone = false,
            Auto_Perform_Jump = false,
            Mode = "Legit",
            Key = Enum.KeyCode.Z
        },
        Rikka = {
            Uptilt = false,
            Key = Enum.KeyCode.Z
        },
        ForceUptilt = {
            Enabled = false,
            Jump = false,
            Key = Enum.KeyCode.Z
        },
        Kiri = {
            Knife = false,
            Key = Enum.KeyCode.Z
        },
        Vegeta = {
            Evasive = false,
            Key = Enum.KeyCode.B
        },
        Stark = {
            Uptilt = false,
            Key = Enum.KeyCode.Z
        },
        Dio = {
            Uptilt = false,
            Key = Enum.KeyCode.Z
        },
        Ryoko = {
            Enabled = false,
            Key = Enum.KeyCode.Z
        }
    }

    getgenv().Macro.InfinityBlue = getgenv().Macro.InfinityBlue or {}
    for key, value in pairs({ Enabled = false, Key = Enum.KeyCode.H,
        PreQDelayMs = 0, QToBlueFrames = 1, QHoldMs = 35, BlueHoldMs = 30 }) do
        if getgenv().Macro.InfinityBlue[key] == nil then getgenv().Macro.InfinityBlue[key] = value end
    end

    getgenv().BlackFlash = ensureGlobalTable("BlackFlash", {
        Nanami = false,
        Nanami_Hitchance = 100,
    })

    getgenv().Esp = ensureGlobalTable("Esp", {
        Self = {
            Enabled = false,
            Healthbar = false,
            Health = false,
            Names = false,
            Distance = false,
            Ultimatives = false,
            Moves = false,
            Info = false,
            Team_Check = false,
            Scaling = false,
            Scale_Size = 1,
            Box = false,
            MaxDistance = 0
        },
        Others = {
            Enabled = false,
            Healthbar = false,
            Health = false,
            Names = false,
            Distance = false,
            Ultimatives = false,
            Moves = false,
            Info = false,
            Team_Check = false,
            Scaling = false,
            Scale_Size = 1,
            Box = false,
            MaxDistance = 0
        }
    })

end

initializeRuntimeConfig()
if getgenv().AimbotSettings.InputMode ~= "Toggle" then
    getgenv().AimbotSettings.InputMode = "Hold"
end

function __VelocityFns.getInputRemote()
    local backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer:WaitForChild("Backpack")
    if not backpack then
        return nil
    end
    return backpack:FindFirstChild("Input") or backpack:WaitForChild("Input")
end

function __VelocityFns.getForceJumpKey(config)
    local key = config and config.Key
    if typeof(key) == "EnumItem" then
        return key
    end
    if type(key) == "string" then
        return Enum.KeyCode[key] or Enum.KeyCode.C
    end
    return Enum.KeyCode.C
end

function __VelocityFns.getTargetRoot(model, boneName)
    if not model or not model:IsA("Model") then
        return nil
    end
    return model:FindFirstChild(boneName or "HumanoidRootPart")
end

function __VelocityFns.getHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

function __VelocityFns.getCharacterRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

function __VelocityFns.getTargetPart(character)
    local boneName = getgenv().AimbotSettings.Bone or "Head"
    local part = character and character:FindFirstChild(boneName)
    if part and part:IsA("BasePart") then
        return part
    end
    local root = __VelocityFns.getCharacterRoot(character)
    if root and root:IsA("BasePart") then
        return root
    end
    local head = character and character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head
    end
    return nil
end

function __VelocityFns.getAimPositionFromPosition(position)
    local aimPosition = position
    local boneName = getgenv().AimbotSettings.Bone or "HumanoidRootPart"
    local offsetY = tonumber(getgenv().AimbotSettings.AimOffsetY) or 0.35
    if boneName == "Head" then
        aimPosition += Vector3.new(0, -0.35 + offsetY * 0.25, 0)
    else
        aimPosition += Vector3.new(0, offsetY, 0)
    end
    return aimPosition
end

function __VelocityFns.getAimbotAimPosition(character)
    local bone = __VelocityFns.getTargetPart(character)
    if not bone then
        return nil
    end
    return __VelocityFns.getAimPositionFromPosition(bone.Position)
end

registerConnection(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end))

function __VelocityFns.isStreamproof()
    return getgenv().UI and getgenv().UI.Streamproof == true
end

local NewAttachConfig = getgenv().Script and getgenv().Script.Attach_To_Back
if not NewAttachConfig then
    return
end


NewAttachConfig.V2 = NewAttachConfig.V2 or {}
for key, default in pairs({
    Enabled = true,
    Prediction = 0.045,
    MaxLead = 5,
    Smoothing = 0.88,
    AdaptiveTracking = true,
    VelocityDamping = 0.35,
    MaxRecoveryDistance = 90,
    RecoveryGrace = 0.16,
    PhysicsMode = "Classic",
    BehindTarget = false,
    SnapOnDash = true,
    SnapThreshold = 8,
    CatchUpDistance = 4,
}) do
    if NewAttachConfig.V2[key] == nil then NewAttachConfig.V2[key] = default end
end

local Attached = false
local AttachConnection, AttachBodyPosition, AttachTarget
local AttachKeyConn, AttachCharacterConn

function __VelocityFns.cleanupAttach()
    Attached = false
    AttachTarget = nil
    if AttachConnection then
        safeDisconnect(AttachConnection)
        AttachConnection = nil
    end
    if AttachBodyPosition then
        safeDestroy(AttachBodyPosition)
        AttachBodyPosition = nil
    end
    if NewAttachConfig.__AlignPosition then
        safeDestroy(NewAttachConfig.__AlignPosition)
        NewAttachConfig.__AlignPosition = nil
    end
    if NewAttachConfig.__Attachment then
        safeDestroy(NewAttachConfig.__Attachment)
        NewAttachConfig.__Attachment = nil
    end
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end
end

function __VelocityFns.getAllValidNPCs()
    local npcs = {}
    for _, model in ipairs(LiveFolder:GetChildren()) do
        if not Players:GetPlayerFromCharacter(model) and model:IsA("Model") then
            local humanoid = __VelocityFns.getHumanoid(model)
            local root = __VelocityFns.getTargetRoot(model, NewAttachConfig.Bone or "HumanoidRootPart")
            if humanoid and root and humanoid.Health > 0 then
                table.insert(npcs, model)
            end
        end
    end
    return npcs
end

function __VelocityFns.isValidAttachTarget(model)
    if not model or model == LocalPlayer.Character or not model:IsA("Model") then
        return false
    end
    local humanoid = __VelocityFns.getHumanoid(model)
    local root = __VelocityFns.getTargetRoot(model, NewAttachConfig.Bone or "HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then
        return false
    end

    local player = Players:GetPlayerFromCharacter(model)
    if player and NewAttachConfig.IgnoreTeammates and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    return player ~= nil or NewAttachConfig.NPC
end

function __VelocityFns.getAttachTarget()
    local mouseTarget = Mouse and Mouse.Target
    if mouseTarget and mouseTarget.Parent then
        local model = mouseTarget:FindFirstAncestorOfClass("Model")
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetRoot = model and __VelocityFns.getTargetRoot(model, NewAttachConfig.Bone or "HumanoidRootPart")
        if myRoot and __VelocityFns.isValidAttachTarget(model)
            and (myRoot.Position - targetRoot.Position).Magnitude <= (NewAttachConfig.MaxAttachDistance or 9999) then
            return model
        end
    end

    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        return nil
    end

    local best, bestDistance = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and __VelocityFns.isValidAttachTarget(player.Character) then
            local character = player.Character
            local humanoid = __VelocityFns.getHumanoid(character)
            local root = __VelocityFns.getTargetRoot(character, NewAttachConfig.Bone or "HumanoidRootPart")
            if humanoid and root and humanoid.Health > 0 then
                local distance = (myRoot.Position - root.Position).Magnitude
                if distance < bestDistance and distance <= (NewAttachConfig.MaxAttachDistance or 9999) then
                    bestDistance, best = distance, character
                end
            end
        end
    end

    if NewAttachConfig.NPC then
        for _, model in ipairs(__VelocityFns.getAllValidNPCs()) do
            local humanoid = __VelocityFns.getHumanoid(model)
            local root = __VelocityFns.getTargetRoot(model, NewAttachConfig.Bone or "HumanoidRootPart")
            if humanoid and root and humanoid.Health > 0 then
                local distance = (myRoot.Position - root.Position).Magnitude
                if distance < bestDistance and distance <= (NewAttachConfig.MaxAttachDistance or 9999) then
                    bestDistance, best = distance, model
                end
            end
        end
    end

    return best
end

function __VelocityFns.getAttachOffset()
    local offset = NewAttachConfig.Offset
    local behind = NewAttachConfig.V2 and NewAttachConfig.V2.BehindTarget
    return Vector3.new(offset.Side, offset.Height, behind and offset.Back or -offset.Back)
end

function __VelocityFns.attachToBack()
    if AttachConnection then
        safeDisconnect(AttachConnection)
        AttachConnection = nil
    end


    local filteredPosition = nil
    local previousTargetPosition = nil
    local outsideSince = nil
    AttachConnection = RunService.Stepped:Connect(function(_, deltaTime)
        if not NewAttachConfig.Enabled or not Attached then
            __VelocityFns.cleanupAttach()
            return
        end

        local target = AttachTarget
        local targetRoot = target and __VelocityFns.getTargetRoot(target, NewAttachConfig.Bone or "HumanoidRootPart")
        local myCharacter = LocalPlayer.Character
        local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = target and __VelocityFns.getHumanoid(target)
        local myHumanoid = myCharacter and __VelocityFns.getHumanoid(myCharacter)
        if not targetRoot or not myRoot or not myHumanoid or myHumanoid.Health <= 0
            or not targetHumanoid or targetHumanoid.Health <= 0
            or not targetRoot:IsDescendantOf(Workspace) then
            __VelocityFns.cleanupAttach()
            return
        end

        local distance = (myRoot.Position - targetRoot.Position).Magnitude
        local maxDistance = tonumber(NewAttachConfig.MaxAttachDistance) or 7000
        local v2 = NewAttachConfig.V2
        local recoveryDistance = tonumber(v2.MaxRecoveryDistance) or 90
        if distance > math.min(maxDistance, recoveryDistance > 0 and recoveryDistance or maxDistance) then
            outsideSince = outsideSince or os.clock()
            local grace = math.clamp(tonumber(v2.RecoveryGrace) or 0.16, 0, 0.5)
            if os.clock() - outsideSince >= grace then
                __VelocityFns.cleanupAttach()
                return
            end
        else
            outsideSince = nil
        end

        local offset = __VelocityFns.getAttachOffset()
        local poseRoot = target:FindFirstChild("HumanoidRootPart") or targetRoot
        local targetPosition = targetRoot.Position + poseRoot.CFrame:VectorToWorldSpace(offset)
        local desiredPosition = targetPosition
        if v2.Enabled then
            local velocity = targetRoot.AssemblyLinearVelocity
            local prediction = math.clamp(tonumber(v2.Prediction) or 0, 0, 0.15)
            local maxLead = math.clamp(tonumber(v2.MaxLead) or 5, 0, 12)
            local lead = velocity * prediction
            if lead.Magnitude > maxLead then lead = lead.Unit * maxLead end
            desiredPosition = targetPosition + lead

            local response = math.clamp(tonumber(v2.Smoothing) or 0.88, 0.1, 1)
            local targetJump = previousTargetPosition and (targetPosition - previousTargetPosition).Magnitude or 0
            if v2.AdaptiveTracking and targetJump > 2 then
                response = math.max(response, 0.98)
            end
            local catchUp = math.clamp(tonumber(v2.CatchUpDistance) or 4, 1, 20)
            if (myRoot.Position - desiredPosition).Magnitude > catchUp then
                response = math.max(response, 0.995)
            end

            local dt = math.clamp(tonumber(deltaTime) or (1 / 60), 1 / 240, 1 / 15)
            local alpha = 1 - (1 - response) ^ (dt * 60)
            local dashThreshold = math.clamp(tonumber(v2.SnapThreshold) or 8, 3, 40)
            if not filteredPosition or (v2.SnapOnDash and targetJump > dashThreshold)
                or (desiredPosition - filteredPosition).Magnitude > 35 then
                filteredPosition = desiredPosition
            else
                filteredPosition = filteredPosition:Lerp(desiredPosition, alpha)
            end
            desiredPosition = filteredPosition
        end
        previousTargetPosition = targetPosition

        if v2.PhysicsMode == "Constraint" then
            if AttachBodyPosition then safeDestroy(AttachBodyPosition); AttachBodyPosition = nil end
            local attachment = NewAttachConfig.__Attachment
            local align = NewAttachConfig.__AlignPosition
            if not attachment or attachment.Parent ~= myRoot then
                if attachment then safeDestroy(attachment) end
                if align then safeDestroy(align) end
                attachment = Instance.new("Attachment")
                attachment.Name = "VelocityRideAttachment"
                attachment.Parent = myRoot
                align = Instance.new("AlignPosition")
                align.Name = "VelocityRideAlign"
                align.Mode = Enum.PositionAlignmentMode.OneAttachment
                align.Attachment0 = attachment
                align.MaxForce = 100000000
                align.MaxVelocity = math.huge
                align.Responsiveness = 200
                align.RigidityEnabled = false
                align.ApplyAtCenterOfMass = true
                align.Parent = myRoot
                NewAttachConfig.__Attachment = attachment
                NewAttachConfig.__AlignPosition = align
            end
            align.Position = desiredPosition
        else
            if NewAttachConfig.__AlignPosition then
                safeDestroy(NewAttachConfig.__AlignPosition)
                NewAttachConfig.__AlignPosition = nil
            end
            if NewAttachConfig.__Attachment then
                safeDestroy(NewAttachConfig.__Attachment)
                NewAttachConfig.__Attachment = nil
            end
            if not AttachBodyPosition or AttachBodyPosition.Parent ~= myRoot then
                if AttachBodyPosition then safeDestroy(AttachBodyPosition) end
                local bodyPosition = Instance.new("BodyPosition")
                for key, value in pairs(NewAttachConfig.BodyPosition) do
                    if key ~= "Name" then bodyPosition[key] = value end
                end
                bodyPosition.Name = NewAttachConfig.BodyPosition.Name
                bodyPosition.Parent = myRoot
                AttachBodyPosition = bodyPosition
            end
            if (AttachBodyPosition.Position - desiredPosition).Magnitude > 0.015 then
                AttachBodyPosition.Position = desiredPosition
            end
        end

        if not myHumanoid.PlatformStand then myHumanoid.PlatformStand = true end
        local damping = v2.Enabled and math.clamp(tonumber(v2.VelocityDamping) or 0.35, 0, 1) or 0.35
        myRoot.AssemblyLinearVelocity *= damping
        myRoot.AssemblyAngularVelocity *= damping
    end)
end

function __VelocityFns.setupAttachKeyListener()
    if AttachKeyConn then
        safeDisconnect(AttachKeyConn)
        AttachKeyConn = nil
    end

    AttachKeyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode == (NewAttachConfig.AttachKey or Enum.KeyCode.X) then
            if Attached then
                __VelocityFns.cleanupAttach()
            else
                if not NewAttachConfig.Enabled then
                    __VelocityFns.cleanupAttach()
                    return
                end

                local target = __VelocityFns.getAttachTarget()
                if target then
                    AttachTarget = target
                    Attached = true
                    __VelocityFns.attachToBack()
                else
                    __VelocityFns.cleanupAttach()
                end
            end
        end
    end)
end

function __VelocityFns.attachToBackLoad()
    __VelocityFns.setupAttachKeyListener()
    if AttachCharacterConn then
        safeDisconnect(AttachCharacterConn)
    end
    AttachCharacterConn = LocalPlayer.CharacterAdded:Connect(function()
        __VelocityFns.cleanupAttach()
    end)
end

local Window = Library:CreateWindow({
    Title = "UWU Friend Edition 1.4  |  ABA  •  " .. LocalPlayer.DisplayName,
    Center = true,
    AutoShow = not getgenv().UI.Streamproof,
    TabPadding = 12,
    MenuFadeTime = 0.25
})

local Tabs = {
    Main = Window:AddTab("Combat"),
    Movement = Window:AddTab("Movement"),
    Macro = Window:AddTab("Macros"),
    Misc = Window:AddTab("Visuals"),
    Player = Window:AddTab("Input"),
    ["UI Settings"] = Window:AddTab("Config")
}

local MiscESPSelf = Tabs.Misc:AddLeftGroupbox("Local Player • ESP")
local MiscESPOthers = Tabs.Misc:AddRightGroupbox("Other Players • ESP")
local MiscPrestige = Tabs.Player:AddLeftGroupbox("Character Selection")
local MiscConnections = {}
local ESPObjects = {}
local ESPPlayerConnections = {}
local espUpdateConnection
local ESPAsset = nil

function __VelocityFns.cleanupESPObject(player)
    local entry = ESPObjects[player]
    if not entry then
        return
    end
    if entry.Connection then
        safeDisconnect(entry.Connection)
    end
    if entry.Gui then
        safeDestroy(entry.Gui)
    end
    ESPObjects[player] = nil
end

function __VelocityFns.getESPModeValue(player)
    local candidates = {
        { "SungJinWooBar", Color3.fromRGB(53, 211, 255) },
        { "BrolyBar", nil },
        { "GatesBar", Color3.fromRGB(149, 0, 255) },
        { "PucciPieces", Color3.fromRGB(184, 143, 255) },
        { "AstaBar", Color3.fromRGB(255, 48, 51) },
        { "RagnaBar", Color3.fromRGB(140, 180, 255) },
        { "RoomBar", Color3.fromRGB(116, 211, 255) },
        { "BloodBar", Color3.fromRGB(57, 0, 0) }
    }

    for _, item in ipairs(candidates) do
        local value = player:FindFirstChild(item[1])
        if value then
            return value, item[2]
        end
    end

    if player.Character then
        local value = player.Character:FindFirstChild("IndraArrowBar") or player.Character:FindFirstChild("HamonMeter")
        if value then
            return value
        end
    end

    return player:FindFirstChild("SecondBar")
end

function __VelocityFns.getESPSlot(config)
    for _, child in ipairs(config:GetChildren()) do
        if child.Name:match("Slot") then
            return child.Name:split("Slot")[2]
        elseif child.Name == "M2Skill" then
            return "5"
        end
    end
end

function __VelocityFns.attachVelocityESP(player)
    __VelocityFns.cleanupESPObject(player)
    if not ESPAsset then
        local ok, objects = pcall(function()
            return game:GetObjects("rbxassetid://99131262255411")
        end)
        ESPAsset = ok and objects and objects[1] or nil
    end
    if not ESPAsset then return end
    local gui = ESPAsset:Clone()
    gui.Parent = game.CoreGui

    local frame = gui:FindFirstChild("Target")
    if not frame then
        gui:Destroy()
        return
    end

    local health = frame.Health
    local mode = frame.Mode
    local info = frame.Info
    local moves = frame.Moves
    local boxStrokes = {}
    local moveFrames = {}

    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("UIStroke") then
            table.insert(boxStrokes, child)
        end
    end

    for _, child in ipairs(moves:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(moveFrames, child)
        end
    end

    local function createESPLabel(name, position, size)
        local label = Instance.new("TextLabel")
        label.Name = name
        label.BackgroundTransparency = 1
        label.Position = position
        label.Size = size
        label.Font = Enum.Font.SourceSansBold
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 13
        label.TextStrokeTransparency = 0.35
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.Visible = false
        label.ZIndex = 10
        label.Parent = frame
        return label
    end

    local nameLabel = createESPLabel("ESPName", UDim2.new(-0.5, 0, -0.8, 0), UDim2.new(2, 0, 0.55, 0))
    local distanceLabel = createESPLabel("ESPDistance", UDim2.new(-0.5, 0, 1, 0), UDim2.new(2, 0, 0.5, 0))
    local healthLabel = createESPLabel("ESPHealth", UDim2.new(1, 3, 0, 0), UDim2.new(1.25, 0, 0.5, 0))
    healthLabel.TextXAlignment = Enum.TextXAlignment.Left

    local status = {
        Maka = info.Maka,
        BlackFlash = info.BlackFlash,
        Mahoraga = info.Mahoraga,
        Crow = info.Crow,
        Boa = info.Boa,
        Iframe = info.Iframe,
        Nanami = info.Nanami
    }

    local function write(instance, property, value)
        if instance[property] ~= value then instance[property] = value end
    end

    local function updateESP(heavy)
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and __VelocityFns.getCharacterRoot(character)
        if not humanoid or not root then
            write(gui, "Enabled", false)
            return
        end

        local esp = getgenv().Esp
        local config = player == LocalPlayer and esp.Self or esp.Others
        write(gui, "Enabled", config.Enabled)
        if not gui.Enabled then
            return
        end
        if __VelocityFns.isStreamproof() then
            write(gui, "Enabled", false)
            return
        end

        if config.Team_Check and player ~= LocalPlayer and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            write(frame, "Visible", false)
            return
        end

        local distance = (Camera.CFrame.Position - character:GetPivot().Position).Magnitude
        local maxDist = tonumber(config.MaxDistance) or 0
        if maxDist > 0 and distance > maxDist then
            write(frame, "Visible", false)
            return
        end

        write(frame, "Visible", true)
        write(gui, "Adornee", root)

        local size = config.Scaling and clamp((distance / 2) * config.Scale_Size, 20, 60) or 20
        write(gui, "Size", UDim2.fromScale(size, size))

        write(health, "Visible", config.Healthbar)
        write(nameLabel, "Visible", config.Names)
        if config.Names then
            write(nameLabel, "Text", player.DisplayName or player.Name)
        end

        write(distanceLabel, "Visible", config.Distance)
        if config.Distance then
            write(distanceLabel, "Text", string.format("%d studs", math.floor(distance + 0.5)))
        end

        write(healthLabel, "Visible", config.Health)
        if config.Health then
            write(healthLabel, "Text", string.format("%d/%d", math.floor(humanoid.Health + 0.5), math.floor(humanoid.MaxHealth + 0.5)))
        end

        write(mode, "Visible", config.Ultimatives)
        write(info, "Visible", config.Info)
        write(moves, "Visible", config.Moves)

        for _, stroke in ipairs(boxStrokes) do
            write(stroke, "Enabled", config.Box)
        end

        if config.Info and heavy then
            local maka = player:FindFirstChild("KishinEgg")
            write(status.Maka, "Visible", maka ~= nil)
            if maka then
                write(status.Maka.AmountText, "Text", tostring(maka.Value))
            end

            local ratio = character:GetAttribute("RatioCounter")
            write(status.Nanami, "Visible", ratio and ratio > 0 or false)
            if ratio and ratio > 0 then
                write(status.Nanami.AmountText, "Text", tostring(ratio))
            end

            write(status.Iframe, "Visible", character:FindFirstChild("i") ~= nil or character:FindFirstChild("ip") ~= nil)
            write(status.Crow, "Visible", character:FindFirstChild("CrowClone") ~= nil)

            local charmedAt = character:GetAttribute("CharmedAt")
            write(status.Boa, "Visible", charmedAt ~= nil)
            if charmedAt then
                write(status.Boa.AmountText, "Text", string.format("%.1f", tick() - charmedAt))
            end

            local spins = character:FindFirstChild("WheelSpins")
            write(status.Mahoraga, "Visible", spins ~= nil)
            if spins then
                write(status.Mahoraga.AmountText, "Text", tostring(spins.Value))
            end

            local blackFlash = character:FindFirstChild("BlackFlashRequirement")
            write(status.BlackFlash, "Visible", blackFlash ~= nil)
            if blackFlash then
                write(status.BlackFlash.AmountText, "Text", tostring(math.floor((blackFlash.Value / math.max(blackFlash.MaxValue, 1)) * 100)) .. "%")
            end
        end

        if config.Moves and heavy then
            for _, moveFrame in ipairs(moveFrames) do
                write(moveFrame, "Visible", false)
            end

            local backpack = player:FindFirstChildOfClass("Backpack")
            if backpack then
                local hasM2Skill = backpack:FindFirstChild("M2Skill", true) ~= nil
                for index, move in ipairs(backpack:GetChildren()) do
                    if move:IsA("Configuration") then
                        local configObject = move:FindFirstChild(".Config")
                        local slot = configObject and __VelocityFns.getESPSlot(configObject)
                        local slotIndex = slot or tostring(index - 4)
                        local moveFrame = moves:FindFirstChild(slotIndex)
                        if moveFrame then
                            write(moveFrame, "Visible", true)

                            local hunterData = {}
                            local isGuardbreak = move:HasTag("Guardbreaks")
                            if move.Name == "Skill Hunter" then
                                local skillHunter = character:FindFirstChild("SkillHunter")
                                if skillHunter then
                                    hunterData.Name = skillHunter:GetAttribute("Move")
                                    hunterData.GuardBreaks = skillHunter:GetAttribute("Selected") == "Guardbreak"
                                end
                            end

                            local infoTag = moveFrame:FindFirstChild("InfoTag")
                            if infoTag then
                                isGuardbreak = isGuardbreak or hunterData.GuardBreaks == true
                                write(infoTag, "Text", "Guardbreaks")
                                write(infoTag, "Visible", isGuardbreak)
                            end

                            local moveColor = Color3.fromRGB(223, 43, 43)
                            if player.Team then
                                moveColor = player.TeamColor.Color
                            end

                            local usingSkill = character:FindFirstChild("UsingSkill")
                            if usingSkill and move.Name == usingSkill.Value then
                                moveColor = Color3.fromRGB(255, 255, 255)
                            end

                            local moveName = move.Name
                            local newName = move:FindFirstChild("NewName", true)
                            if newName then
                                moveName = newName.Value
                            end

                            local cooldown = tonumber(move:GetAttribute("COOLDOWN")) or 20
                            local coverSize = clamp(1 - cooldown / 20, 0, 1)

                            write(moveFrame.ImageLabel, "ImageColor3", moveColor)
                            write(moveFrame.TextLabel, "Text", hunterData.Name or moveName)
                            write(moveFrame.DisableCover, "Visible", true)
                            write(moveFrame.DisableCover, "Size", UDim2.fromScale(1, coverSize))
                        end
                    end
                end

                local fifthMove = moves:FindFirstChild("5")
                if fifthMove and not hasM2Skill then
                    write(fifthMove, "Visible", false)
                end
            end
        end

        if config.Ultimatives then
            local secondMode, secondColor = __VelocityFns.getESPModeValue(player)
            local ultimate2 = mode.Ultimate2
            write(ultimate2, "Visible", secondMode ~= nil)
            if secondMode then
                write(ultimate2.Bar, "Size", UDim2.fromScale(secondMode.Value / math.max(secondMode.MaxValue, 1), 0.78))
                write(ultimate2.Bar, "BackgroundColor3", secondColor or Color3.fromRGB(149, 0, 255))
            end

            local charge = player:FindFirstChild("Charge")
            local ultimate = mode.Ultimate
            write(ultimate.Bar, "Size", UDim2.fromScale(charge and charge.Value / math.max(charge.MaxValue, 1) or 0, 0.912))
            write(ultimate.Bar, "BackgroundColor3", character:FindFirstChild("IfDied") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 0, 0))
        end

        if config.Healthbar then
            write(health.Bar, "Size", UDim2.fromScale(clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1), 1))
        end
    end

    local now = os.clock()
    ESPObjects[player] = { Gui = gui, Update = updateESP, NextUpdate = now, NextHeavy = now }
end

function __VelocityFns.refreshVelocityESP()
    for _, connection in pairs(ESPPlayerConnections) do
        safeDisconnect(connection)
    end
    table.clear(ESPPlayerConnections)
    if espUpdateConnection then
        safeDisconnect(espUpdateConnection)
        espUpdateConnection = nil
    end
    for player in pairs(ESPObjects) do
        __VelocityFns.cleanupESPObject(player)
    end

    local esp = getgenv().Esp
    if not esp.Self.Enabled and not esp.Others.Enabled then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if (player == LocalPlayer and esp.Self.Enabled)
            or (player ~= LocalPlayer and esp.Others.Enabled) then
            __VelocityFns.attachVelocityESP(player)
        end
    end

    ESPPlayerConnections.Added = Players.PlayerAdded:Connect(function(player)
        if getgenv().Esp.Others.Enabled then
            __VelocityFns.attachVelocityESP(player)
        end
    end)
    ESPPlayerConnections.Removed = Players.PlayerRemoving:Connect(__VelocityFns.cleanupESPObject)

    espUpdateConnection = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        local config = getgenv().Performance
        local base = math.max(config.StabilityMode and 0.3 or 0.16, tonumber(config.EspUpdateInterval) or 0.25)
        local budget = config.StabilityMode and 3 or 6
        for _, entry in pairs(ESPObjects) do
            if budget <= 0 then break end
            if now >= entry.NextUpdate then
                entry.NextUpdate = now + base
                local heavy = now >= entry.NextHeavy
                if heavy then entry.NextHeavy = now + math.max(0.75, base * 3) end
                entry.Update(heavy)
                budget -= 1
            end
        end
    end)
end

function __VelocityFns.addESPControls(group, config, prefix)
    group:AddToggle(prefix .. "Enabled", {
        Text = "Enabled",
        Default = config.Enabled,
        Tooltip = "Turns this ESP overlay on or off.",
        Callback = function(value)
            config.Enabled = value
            __VelocityFns.refreshVelocityESP()
        end
    })

    group:AddToggle(prefix .. "Healthbar", { Text = "Health Bar", Default = config.Healthbar, Tooltip = "Shows the character's health as a bar.", Callback = function(value) config.Healthbar = value end })
    group:AddToggle(prefix .. "Health", { Text = "HP Text", Default = config.Health, Tooltip = "Shows current and maximum health as text.", Callback = function(value) config.Health = value end })
    group:AddToggle(prefix .. "Names", { Text = "Nametags", Default = config.Names, Tooltip = "Shows the character's display name.", Callback = function(value) config.Names = value end })
    group:AddToggle(prefix .. "Distance", { Text = "Range Display", Default = config.Distance, Tooltip = "Shows the character's distance from you.", Callback = function(value) config.Distance = value end })
    group:AddToggle(prefix .. "Ultimates", { Text = "Ultimate Meters", Default = config.Ultimatives, Tooltip = "Shows ultimate and secondary charge meters when available.", Callback = function(value) config.Ultimatives = value end })
    group:AddToggle(prefix .. "Moves", { Text = "Skill Slots", Default = config.Moves, Tooltip = "Shows equipped skills and their cooldown state.", Callback = function(value) config.Moves = value end })
    group:AddToggle(prefix .. "Info", { Text = "Status Icons", Default = config.Info, Tooltip = "Shows detected character status indicators.", Callback = function(value) config.Info = value end })
    group:AddToggle(prefix .. "TeamCheck", { Text = "Ignore Teammates", Default = config.Team_Check, Tooltip = "When used on Others ESP, hides teammate overlays.", Callback = function(value) config.Team_Check = value end })
    group:AddToggle(prefix .. "Scaling", { Text = "Distance Scale", Default = config.Scaling, Tooltip = "Scales the overlay according to character distance.", Callback = function(value) config.Scaling = value end })
    group:AddToggle(prefix .. "Box", { Text = "Bounding Box", Default = config.Box, Tooltip = "Draws the ESP outline around the character.", Callback = function(value) config.Box = value end })

    group:AddSlider(prefix .. "ScaleSize", {
        Text = "Scale Factor",
        Default = config.Scale_Size,
        Min = 1,
        Max = 5,
        Rounding = 1,
        Tooltip = "Adjusts the distance-based ESP size multiplier.",
        Callback = function(value)
            config.Scale_Size = value
        end
    })

    group:AddSlider(prefix .. "MaxDistance", {
        Text = "Max Distance",
        Default = config.MaxDistance or 0,
        Min = 0,
        Max = 2000,
        Rounding = 0,
        Suffix = " studs",
        Tooltip = "0 = unlimited. Hides this ESP beyond this range.",
        Callback = function(value)
            config.MaxDistance = value
        end
    })
end

__VelocityFns.addESPControls(MiscESPSelf, getgenv().Esp.Self, "VelocityESPSelf")
__VelocityFns.addESPControls(MiscESPOthers, getgenv().Esp.Others, "VelocityESPOthers")

local selectedPrestige = "Tokita Ohma"
MiscPrestige:AddDropdown("VelocityPrestigeSelect", {
    Values = { "Tokita Ohma", "Zenitsu", "Shisui", "Tobi", "Satsuki Kiryuin", "Achilles", "Zamasu [Fused]", "Super Dummy", "Hercule Satan", "Shadow DIO", "Mr President" },
    Default = 1,
    Multi = false,
    Text = "Character",
    Tooltip = "Choose which prestige character to apply.",
    Callback = function(value)
        selectedPrestige = value
    end
})

local ApplyPrestigeButton = MiscPrestige:AddButton("Apply Prestige", function()
    for _, value in getgc() do
        if typeof(value) == "function" then
            local info = debug.getinfo(value)
            if info.currentline == 8 and info.source:match("PrestigePick") then
                debug.setupvalue(value, 1, LocalPlayer:FindFirstChild(selectedPrestige, true))
            end
        end
    end
end)
ApplyPrestigeButton:AddTooltip("Applies the selected prestige character to the game.")

-- Real controller detection only, no platform overrides.
function __VelocityFns.isPhysicalControllerConnected()
    return #UserInputService:GetConnectedGamepads() > 0
end

local AimbotSelectionBox
function __VelocityFns.clearAimbotSelectionBox()
    if AimbotSelectionBox then
        safeDestroy(AimbotSelectionBox)
        AimbotSelectionBox = nil
    end
end

function __VelocityFns.addKeyPickerTooltip(control, text)
    local textLabel = control and control.TextLabel
    local keyPickerFrame = textLabel and textLabel:FindFirstChildOfClass("Frame")
    if keyPickerFrame then
        Library:AddToolTip(text, keyPickerFrame)
    end
end

local LeftGroup1 = Tabs.Main:AddLeftGroupbox("Camera Lock-On")

LeftGroup1:AddToggle("AimbotEnabled", {
    Text = "Enabled",
    Default = false,
    Tooltip = "Tracks a selected target using the selected RMB input mode.",
    Callback = function(value)
        getgenv().AimbotSettings.Enabled = value
    end
})

LeftGroup1:AddDropdown("AimbotInputMode", {
    Values = { "Hold", "Toggle" },
    Default = getgenv().AimbotSettings.InputMode == "Toggle" and 2 or 1,
    Multi = false,
    Text = "Right Click Mode",
    Tooltip = "Hold RMB to track, or click RMB to toggle tracking.",
    Callback = function(value)
        getgenv().AimbotSettings.InputMode = value
    end
})

LeftGroup1:AddLabel("Camera Response: Instant Only")

LeftGroup1:AddToggle("AimbotNpc", {
    Text = "Target NPCs",
    Default = false,
    Tooltip = "Allows the aimbot to acquire NPCs as targets.",
    Callback = function(value)
        getgenv().AimbotSettings.Npc = value
    end
})

LeftGroup1:AddToggle("AimbotTeamCheck", {
    Text = "Ignore Teammates",
    Default = getgenv().AimbotSettings.Team_Check,
    Tooltip = "Prevents the aimbot from selecting players on your team.",
    Callback = function(value)
        getgenv().AimbotSettings.Team_Check = value
    end
})

LeftGroup1:AddDropdown("AimbotBone", {
    Values = { "Head", "HumanoidRootPart" },
    Default = 2,
    Multi = false,
    Text = "Aim Point",
    Tooltip = "Choose whether the aimbot aims at the head or lower torso.",
    Callback = function(value)
        getgenv().AimbotSettings.Bone = value
    end
})

LeftGroup1:AddSlider("AimbotOffsetY", {
    Text = "Aim Offset Y",
    Default = getgenv().AimbotSettings.AimOffsetY,
    Min = -4,
    Max = 4,
    Rounding = 2,
    Suffix = " studs",
    Tooltip = "Adjusts the vertical aim point. Small positive values on the character root target the lower torso.",
    Callback = function(value)
        getgenv().AimbotSettings.AimOffsetY = value
    end
})

LeftGroup1:AddSlider("AimbotFOV", {
    Text = "Acquisition FOV",
    Default = getgenv().AimbotSettings.FOV,
    Min = 5,
    Max = 600,
    Rounding = 0,
    Suffix = " px",
    Tooltip = "Sets the screen radius used to acquire targets.",
    Callback = function(value)
        getgenv().AimbotSettings.FOV = value
    end
})

LeftGroup1:AddToggle("AimbotAlignCharacterYaw", {
    Text = "Perfect Facing Auto-Alignment",
    Default = getgenv().AimbotSettings.AlignCharacterYaw,
    Tooltip = "Faces your character toward the target while aiming; pauses while either Shift key is held",
    Callback = function(value)
        getgenv().AimbotSettings.AlignCharacterYaw = value
    end
})

LeftGroup1:AddToggle("AimbotShowFov", {
    Text = "Visualize FOV",
    Default = false,
    Tooltip = "Displays the target acquisition radius around the cursor.",
    Callback = function(value)
        getgenv().AimbotSettings.ShowFov = value
    end
})

LeftGroup1:AddToggle("AimbotSelectionBox", {
    Text = "Highlight Lock",
    Default = true,
    Tooltip = "Shows a selection outline around the current target.",
    Callback = function(value)
        if not value then
            __VelocityFns.clearAimbotSelectionBox()
        end
    end
})

local LeftGroup2 = Tabs.Main:AddRightGroupbox("Auto Parry & Reactions")

local indGui
local indLbl

-- Diagnostic overlay: shows input/trigger state without modifying game networking.
local parryDiagnostics = {
    Last = "Waiting for HP loss (fully blocked hits don't trigger)",
    HpEvents = 0,
    TriggerEvents = 0,
    M1Requests = 0,
    SuppressedReactions = 0,
}
local parryDebugGui = Instance.new("ScreenGui")
parryDebugGui.Name = "UWUAutoParryDiagnostics"
parryDebugGui.ResetOnSpawn = false
parryDebugGui.DisplayOrder = 80
parryDebugGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
local parryDebugLabel = Instance.new("TextLabel")
parryDebugLabel.Name = "Status"
parryDebugLabel.Size = UDim2.fromOffset(430, 164)
parryDebugLabel.Position = UDim2.new(1, -445, 0, 65)
parryDebugLabel.BackgroundColor3 = Color3.fromRGB(23, 17, 40)
parryDebugLabel.BackgroundTransparency = 0.12
parryDebugLabel.BorderSizePixel = 0
parryDebugLabel.TextColor3 = Color3.new(1, 1, 1)
parryDebugLabel.Font = Enum.Font.Code
parryDebugLabel.TextSize = 14
parryDebugLabel.TextXAlignment = Enum.TextXAlignment.Left
parryDebugLabel.TextYAlignment = Enum.TextYAlignment.Top
parryDebugLabel.TextWrapped = true
parryDebugLabel.Parent = parryDebugGui
parryDebugGui.Enabled = false
table.insert(Runtime.cleanup, function() safeDestroy(parryDebugGui) end)

function __VelocityFns.updateParryDiagnostics()
    local cfg = getgenv().AutoParry
    if not cfg or not cfg.DebugEnabled then
        parryDebugGui.Enabled = false
        return
    end
    parryDebugGui.Enabled = true
    local connected = UserInputService:GetConnectedGamepads()
    local guard = __VelocityFns.isAutoParryGuardHeld and __VelocityFns.isAutoParryGuardHeld() or false
    local remote = __VelocityFns.refreshInputRemote and __VelocityFns.refreshInputRemote() or false
    parryDebugLabel.Text = string.format(
        "AUTO PARRY DIAGNOSTICS\nEnabled: %s   Controllers: %d\nGuard held: %s (%s)   Input remote: %s\nHP loss events: %d   Passed filters: %d   M1 requests: %d\nBurst repeats skipped: %d\nLast: %s",
        tostring(cfg.Enabled == true), #connected, tostring(guard),
        tostring(cfg.ControllerGuardButton or "n/a"), remote and "Found" or "MISSING",
        parryDiagnostics.HpEvents, parryDiagnostics.TriggerEvents,
        parryDiagnostics.M1Requests, parryDiagnostics.SuppressedReactions, parryDiagnostics.Last
    )
end

function __VelocityFns.noteParryDiagnostic(message)
    parryDiagnostics.Last = tostring(message)
    __VelocityFns.updateParryDiagnostics()
end

registerConnection(UserInputService.InputBegan:Connect(function()
    __VelocityFns.updateParryDiagnostics()
end))
registerConnection(UserInputService.InputEnded:Connect(function()
    __VelocityFns.updateParryDiagnostics()
end))
registerConnection(UserInputService.GamepadConnected:Connect(function()
    __VelocityFns.updateParryDiagnostics()
end))
registerConnection(UserInputService.GamepadDisconnected:Connect(function()
    __VelocityFns.updateParryDiagnostics()
end))


function __VelocityFns.setAutoParryEnabled(value)
    getgenv().AutoParry.Enabled = value == true
end

function __VelocityFns.refreshIndicator()
    if __VelocityFns.isStreamproof() then
        if indLbl then
            indLbl.Text = ""
            indLbl.Visible = false
        end
        if indGui then
            indGui.Enabled = false
        end
        return
    end
    if indGui then
        indGui.Enabled = true
    end
    local config = getgenv().AutoParry
    local label = getgenv().__AutoParryIndicatorLbl
    if not label then
        return
    end
    local active = config
        and config.Enabled == true
        and config.Indicator
        and config.Indicator.Visible == true
    label.Text = active and "A" or ""
    label.Visible = active == true
end

-- Roblox normalizes supported Xbox and PlayStation buttons to the same KeyCode values.
local AUTO_PARRY_GAMEPAD_BUTTONS = {
    ["X / Square"] = Enum.KeyCode.ButtonX,
    ["A / Cross"] = Enum.KeyCode.ButtonA,
    ["B / Circle"] = Enum.KeyCode.ButtonB,
    ["Y / Triangle"] = Enum.KeyCode.ButtonY,
    ["LB / L1"] = Enum.KeyCode.ButtonL1,
    ["LT / L2"] = Enum.KeyCode.ButtonL2,
    ["RB / R1"] = Enum.KeyCode.ButtonR1,
    ["RT / R2"] = Enum.KeyCode.ButtonR2,
    ["L3"] = Enum.KeyCode.ButtonL3,
    ["R3"] = Enum.KeyCode.ButtonR3,
    ["D-Pad Up"] = Enum.KeyCode.DPadUp,
    ["D-Pad Down"] = Enum.KeyCode.DPadDown,
    ["D-Pad Left"] = Enum.KeyCode.DPadLeft,
    ["D-Pad Right"] = Enum.KeyCode.DPadRight,
}
local AUTO_PARRY_GAMEPAD_CHOICES = {
    "X / Square", "A / Cross", "B / Circle", "Y / Triangle",
    "LB / L1", "LT / L2", "RB / R1", "RT / R2",
    "L3", "R3", "D-Pad Up", "D-Pad Down", "D-Pad Left", "D-Pad Right"
}

function __VelocityFns.isPhysicalGamepadButtonHeld(settingName)
    local selected = getgenv().AutoParry[settingName]
    local keyCode = AUTO_PARRY_GAMEPAD_BUTTONS[selected]
    if not keyCode then return false end
    -- Only sample buttons from actually connected controllers.
    for _, gamepad in ipairs(UserInputService:GetConnectedGamepads()) do
        local ok, held = pcall(function()
            return UserInputService:IsGamepadButtonDown(gamepad, keyCode)
        end)
        if ok and held then return true end
    end
    return false
end

function __VelocityFns.isAutoParryGuardHeld()
    -- Report configuration honestly; the ABA screenshot maps B to Punch and X to Block.
    return UserInputService:IsKeyDown(Enum.KeyCode.F)
        or __VelocityFns.isPhysicalGamepadButtonHeld("ControllerGuardButton")
end

function __VelocityFns.isAutoParryJumpHeld()
    return UserInputService:IsKeyDown(Enum.KeyCode.Space)
        or __VelocityFns.isPhysicalGamepadButtonHeld("ControllerJumpButton")
end

local AutoParryToggle = LeftGroup2:AddToggle("AutoParryEnabled", {
    Text = "Enabled",
    Default = getgenv().AutoParry.Enabled,
    Tooltip = "Automatically parries eligible damage while Block is held, within the configured range and damage limits. Use the key picker to set its toggle key.",
    Callback = function(value)
        __VelocityFns.setAutoParryEnabled(value)
        __VelocityFns.refreshIndicator()
        __VelocityFns.noteParryDiagnostic(value and "Auto Parry enabled" or "Auto Parry disabled")
    end
})

AutoParryToggle:AddKeyPicker("AutoParryKeybind", {
    Default = "LeftControl",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Keybind",
    NoUI = false,
    Callback = function(value)
        __VelocityFns.setAutoParryEnabled(value)
        __VelocityFns.refreshIndicator()
    end,
})
__VelocityFns.addKeyPickerTooltip(AutoParryToggle, "Choose the key that toggles Auto Parry.")

LeftGroup2:AddToggle("AutoParryUseControllerSupport", {
    Text = "Use Controller Support",
    Default = getgenv().AutoParry.UseControllerSupport == true,
    Tooltip = "Keeps physical gamepad guard/jump controls enabled. Follow-up uses the game M1 action because virtual B/Circle taps are unreliable.",
    Callback = function(value)
        getgenv().AutoParry.UseControllerSupport = value
    end,
})

LeftGroup2:AddToggle("AutoParryControllerOnePunch", {
    Text = "Controller: One Punch Per Hit Burst",
    Default = getgenv().AutoParry.ControllerOnePunchPerBurst ~= false,
    Tooltip = "When a real controller is connected and Use Controller Support is on, allow only one M1 follow-up for consecutive HP-loss events.",
    Callback = function(value)
        getgenv().AutoParry.ControllerOnePunchPerBurst = value
    end,
})
LeftGroup2:AddSlider("AutoParryControllerBurstGap", {
    Text = "Controller Burst Gap",
    Default = math.clamp(tonumber(getgenv().AutoParry.ControllerBurstGap) or 0.85, 0.3, 2),
    Min = 0.3, Max = 2, Rounding = 2, Suffix = " s",
    Tooltip = "Seconds without another qualifying HP-loss event before a new counterattack may trigger. Default 0.85s.",
    Callback = function(value)
        getgenv().AutoParry.ControllerBurstGap = value
    end,
})

LeftGroup2:AddToggle("AutoParryDebugEnabled", {
    Text = "Auto Parry Diagnostics",
    Default = getgenv().AutoParry.DebugEnabled == true,
    Tooltip = "Shows live controller, guard, Input remote, and HP-loss trigger status. For private testing.",
    Callback = function(value)
        getgenv().AutoParry.DebugEnabled = value
        __VelocityFns.updateParryDiagnostics()
    end,
})

LeftGroup2:AddDropdown("AutoParryControllerGuard", {
    Text = "Controller Guard Button",
    Values = AUTO_PARRY_GAMEPAD_CHOICES,
    Default = getgenv().AutoParry.ControllerGuardButton,
    Multi = false,
    Tooltip = "Physical Xbox / PS4 / PS5 button for hold-to-guard detection.",
    Callback = function(value) getgenv().AutoParry.ControllerGuardButton = value end,
})
LeftGroup2:AddDropdown("AutoParryControllerJump", {
    Text = "Controller Jump Button",
    Values = AUTO_PARRY_GAMEPAD_CHOICES,
    Default = getgenv().AutoParry.ControllerJumpButton,
    Multi = false,
    Tooltip = "Physical controller jump button for Auto Parry recovery.",
    Callback = function(value) getgenv().AutoParry.ControllerJumpButton = value end,
})
LeftGroup2:AddToggle("AutoParryControllerToggleEnabled", {
    Text = "Controller Toggle Enabled",
    Default = getgenv().AutoParry.ControllerToggleEnabled,
    Tooltip = "Allow a physical controller button to toggle Auto Parry.",
    Callback = function(value) getgenv().AutoParry.ControllerToggleEnabled = value end,
})
LeftGroup2:AddDropdown("AutoParryControllerToggleButton", {
    Text = "Controller Toggle Button",
    Values = AUTO_PARRY_GAMEPAD_CHOICES,
    Default = getgenv().AutoParry.ControllerToggleButton,
    Multi = false,
    Tooltip = "Button used to switch Auto Parry on or off, default D-Pad Down.",
    Callback = function(value) getgenv().AutoParry.ControllerToggleButton = value end,
})

registerConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not input.UserInputType.Name:match("^Gamepad") then return end
    local config = getgenv().AutoParry
    if not config.ControllerToggleEnabled then return end
    local toggleButton = AUTO_PARRY_GAMEPAD_BUTTONS[config.ControllerToggleButton]
    if not toggleButton or input.KeyCode ~= toggleButton then return end
    local nextValue = not config.Enabled
    -- Keep Linoria's visual toggle, config saving, and callbacks synchronized.
    if Toggles and Toggles.AutoParryEnabled then
        Toggles.AutoParryEnabled:SetValue(nextValue)
    else
        __VelocityFns.setAutoParryEnabled(nextValue)
        __VelocityFns.refreshIndicator()
    end
end))

LeftGroup2:AddToggle("AutoParryIndicator", {
    Text = "Status Indicator",
    Default = getgenv().AutoParry.Indicator.Visible,
    Tooltip = "Shows or hides the on-screen Auto Parry status indicator.",
    Callback = function(value)
        getgenv().AutoParry.Indicator.Visible = value
        __VelocityFns.refreshIndicator()
    end
})

LeftGroup2:AddSlider("AutoParryRange", {
    Text = "Detection Range",
    Default = getgenv().AutoParry.Range,
    Min = 0,
    Max = 50,
    Rounding = 1,
    Suffix = " studs",
    Tooltip = "Sets the maximum distance for Auto Parry target detection.",
    Callback = function(value)
        getgenv().AutoParry.Range = value
    end
})

LeftGroup2:AddSlider("AutoParryMinDMG", {
    Text = "Min Trigger Damage",
    Default = getgenv().AutoParry.MinDMG,
    Min = 0,
    Max = 5,
    Rounding = 10,
    Tooltip = "Damage below this amount will not trigger Auto Parry.",
    Callback = function(value)
        getgenv().AutoParry.MinDMG = value
    end
})

LeftGroup2:AddSlider("AutoParryMaxDMG", {
    Text = "Max Trigger Damage",
    Default = getgenv().AutoParry.MaxDMG,
    Min = 0,
    Max = 30,
    Rounding = 10,
    Tooltip = "Damage above this amount will not trigger Auto Parry.",
    Callback = function(value)
        getgenv().AutoParry.MaxDMG = value
    end
})


LeftGroup2:AddLabel("Activation & Filtering")

LeftGroup2:AddToggle("AutoParryRequireBlock", {
    Text = "Manual Guard Requirement",
    Default = getgenv().AutoParry.RequireBlockHeld,
    Tooltip = "Only react while the block key is held.",
    Callback = function(value) getgenv().AutoParry.RequireBlockHeld = value end
})

LeftGroup2:AddToggle("AutoParryRequireTarget", {
    Text = "Proximity Verification",
    Default = getgenv().AutoParry.RequireNearbyTarget,
    Tooltip = "Skip reactions when no eligible target is inside detection range.",
    Callback = function(value) getgenv().AutoParry.RequireNearbyTarget = value end
})

LeftGroup2:AddToggle("AutoParryIgnoreTeam", {
    Text = "Ignore Teammates",
    Default = getgenv().AutoParry.IgnoreTeammates,
    Tooltip = "Do not select teammates as nearby targets.",
    Callback = function(value) getgenv().AutoParry.IgnoreTeammates = value end
})

LeftGroup2:AddToggle("AutoParryGroundOnly", {
    Text = "Grounded Activation Only",
    Default = getgenv().AutoParry.GroundOnly,
    Tooltip = "Do not trigger while jumping or falling.",
    Callback = function(value) getgenv().AutoParry.GroundOnly = value end
})

LeftGroup2:AddDropdown("AutoParryTargetType", {
    Values = { "Both", "Players", "NPCs" },
    Default = getgenv().AutoParry.TargetType,
    Multi = false,
    Text = "Eligible Targets",
    Tooltip = "Choose which characters count as nearby targets.",
    Callback = function(value) getgenv().AutoParry.TargetType = value end
})

LeftGroup2:AddLabel("Reaction Timing")

LeftGroup2:AddSlider("AutoParryCooldown", {
    Text = "Reaction Cooldown",
    Default = getgenv().AutoParry.TriggerCooldown,
    Min = 0.05,
    Max = 1.5,
    Rounding = 2,
    Suffix = " sec",
    Tooltip = "Prevents repeated parry sequences from rapidly triggering.",
    Callback = function(value) getgenv().AutoParry.TriggerCooldown = value end
})
LeftGroup2:AddDropdown("VelocityParryFollowUp", {
    Values = { "M1", "Grounded M1", "Guard Only" },
    Default = getgenv().AutoParry.FollowUp == "Guard Only" and 3
        or getgenv().AutoParry.FollowUp == "Grounded M1" and 2 or 1,
    Multi = false,
    Text = "Reaction Follow-Up",
    Tooltip = "Grounded M1 skips the automatic follow-up while jumping, falling, or holding Space.",
    Callback = function(value) getgenv().AutoParry.FollowUp = value end
})
LeftGroup2:AddDropdown("VelocityParrySpacePolicy", {
    Values = { "Physical", "Downslam" },
    Default = getgenv().AutoParry.SpacePolicy == "Downslam" and 2 or 1,
    Multi = false,
    Text = "Aerial Input Policy",
    Tooltip = "Physical mirrors held Space. Downslam temporarily releases Space for the parry M1; experimental.",
    Callback = function(value) getgenv().AutoParry.SpacePolicy = value end
})
LeftGroup2:AddSlider("VelocityParryReleaseDelay", {
    Text = "Release Timing", Default = getgenv().AutoParry.ReleaseDelay,
    Min = 0.01, Max = 0.1, Rounding = 3, Suffix = "s",
    Callback = function(value) getgenv().AutoParry.ReleaseDelay = value end
})
LeftGroup2:AddSlider("VelocityParryRecoveryDelay", {
    Text = "Recovery Timing", Default = getgenv().AutoParry.RecoveryDelay,
    Min = 0.01, Max = 0.2, Rounding = 3, Suffix = "s",
    Callback = function(value) getgenv().AutoParry.RecoveryDelay = value end
})

local LeftGroup3 = Tabs.Movement:AddLeftGroupbox("Jump & Movement")

local ForceJumpToggle = LeftGroup3:AddToggle("ForceJumpEnabled", {
    Text = "Enabled",
    Default = getgenv().Force_Jump.Enabled,
    Tooltip = "Enables repeated jump pulses for the configured burst after the assigned key is pressed.",
    Callback = function(value)
        getgenv().Force_Jump.Enabled = value
    end
})

ForceJumpToggle:AddKeyPicker("ForceJumpKey", {
    Default = getgenv().Force_Jump.Key,
    SyncToggleState = true,
    Mode = "Hold",
    Text = "Keybind",
    NoUI = false,
    ChangedCallback = function(newKey)
        if typeof(newKey) == "EnumItem" then
            getgenv().Force_Jump.Key = newKey
        end
    end
})
__VelocityFns.addKeyPickerTooltip(ForceJumpToggle, "Choose the key to hold for the Force Jump burst.")

LeftGroup3:AddSlider("ForceJumpUpward", {
    Text = "Lift Force",
    Default = getgenv().Force_Jump.Upward,
    Min = 30,
    Max = 35,
    Rounding = 10,
    Tooltip = "Sets the upward velocity applied during each jump pulse.",
    Callback = function(value)
        getgenv().Force_Jump.Upward = value
    end
})

LeftGroup3:AddSlider("ForceJumpInterval", {
    Text = "Pulse Rate",
    Default = getgenv().Force_Jump.Interval,
    Min = 0.001,
    Max = 0.01,
    Rounding = 4,
    Tooltip = "Sets the delay between jump pulses.",
    Callback = function(value)
        getgenv().Force_Jump.Interval = value
    end
})

LeftGroup3:AddSlider("ForceJumpDuration", {
    Text = "Burst Length",
    Default = getgenv().Force_Jump.Duration,
    Min = 0.05,
    Max = 0.3,
    Rounding = 3,
    Tooltip = "Sets how long the jump pulses continue after pressing the key.",
    Callback = function(value)
        getgenv().Force_Jump.Duration = value
    end
})

local RightGroup1 = Tabs.Movement:AddRightGroupbox("Target Positioning")

RightGroup1:AddToggle("AttachToBackEnabled", {
    Text = "Enabled",
    Default = NewAttachConfig.Enabled,
    Tooltip = "Enables the attach-to-back feature; use the latch key to attach or release.",
    Callback = function(value)
        NewAttachConfig.Enabled = value
        if not value then __VelocityFns.cleanupAttach() end
    end
})

local HeadrideKeyLabel = RightGroup1:AddLabel("Latch / Release Key (Toggle)")
HeadrideKeyLabel:AddKeyPicker("HeadrideLatchKey", {
    Default = typeof(NewAttachConfig.AttachKey) == "EnumItem" and NewAttachConfig.AttachKey.Name or "X",
    Text = "Latch / Release", Mode = "Toggle", NoUI = true, SyncToggleState = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then NewAttachConfig.AttachKey = key end
    end
})

RightGroup1:AddToggle("AttachNPC", {
    Text = "Include NPCs",
    Default = NewAttachConfig.NPC,
    Tooltip = "Allows the latch key to select NPCs as targets.",
    Callback = function(value)
        NewAttachConfig.NPC = value
    end
})

RightGroup1:AddToggle("AttachIgnoreTeammates", {
    Text = "Ignore Teammates",
    Default = NewAttachConfig.IgnoreTeammates == true,
    Tooltip = "Excludes teammates when selecting a player target.",
    Callback = function(value)
        NewAttachConfig.IgnoreTeammates = value
    end
})

RightGroup1:AddDropdown("AttachBone", {
    Values = { "HumanoidRootPart", "Head" },
    Default = NewAttachConfig.Bone == "Head" and 2 or 1,
    Multi = false,
    Text = "Latch Point",
    Tooltip = "Choose the target body part used to position the attachment.",
    Callback = function(value)
        NewAttachConfig.Bone = value
    end
})

RightGroup1:AddSlider("AttachMaxDist", {
    Text = "Latch Range",
    Default = NewAttachConfig.MaxAttachDistance,
    Min = 5,
    Max = 10000,
    Rounding = 0,
    Suffix = " studs",
    Tooltip = "Sets the maximum distance at which a target can be latched.",
    Callback = function(value)
        NewAttachConfig.MaxAttachDistance = value
    end
})

RightGroup1:AddSlider("AttachHeight", {
    Text = "Vertical Offset",
    Default = NewAttachConfig.Offset.Height,
    Min = 3,
    Max = 6,
    Rounding = 2,
    Tooltip = "Adjusts how high above the target the attachment places you.",
    Callback = function(value)
        NewAttachConfig.Offset.Height = value
    end
})

RightGroup1:AddSlider("AttachSide", {
    Text = "Lateral Offset",
    Default = NewAttachConfig.Offset.Side,
    Min = -2,
    Max = 2,
    Rounding = 2,
    Tooltip = "Moves the attachment left or right relative to the target.",
    Callback = function(value)
        NewAttachConfig.Offset.Side = value
    end
})

RightGroup1:AddSlider("AttachBack", {
    Text = "Depth Offset",
    Default = NewAttachConfig.Offset.Back,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Tooltip = "Adjusts the distance behind the target where you are positioned.",
    Callback = function(value)
        NewAttachConfig.Offset.Back = value
    end
})

RightGroup1:AddLabel("Press the Latch Key once to attach, again to detach. No hold.", true)


local HeadrideV2Group = Tabs.Movement:AddLeftGroupbox("Headride • Response")
HeadrideV2Group:AddToggle("HeadrideV2Enabled", {
    Text = "Enhanced Tracking", Default = NewAttachConfig.V2.Enabled,
    Tooltip = "Velocity prediction and adaptive smoothing. Disable for original behavior.",
    Callback = function(value) NewAttachConfig.V2.Enabled = value end
})
HeadrideV2Group:AddToggle("HeadrideV2Adaptive", {
    Text = "Adaptive Aerial Response", Default = NewAttachConfig.V2.AdaptiveTracking,
    Tooltip = "Respond faster when the target suddenly moves vertically or is launched.",
    Callback = function(value) NewAttachConfig.V2.AdaptiveTracking = value end
})
HeadrideV2Group:AddSlider("HeadrideV2Lead", {
    Text = "Movement Prediction", Default = NewAttachConfig.V2.Prediction,
    Min = 0, Max = 0.15, Rounding = 3, Suffix = " s",
    Tooltip = "Short velocity lead; zero disables prediction.",
    Callback = function(value) NewAttachConfig.V2.Prediction = value end
})
HeadrideV2Group:AddSlider("HeadrideV2Response", {
    Text = "Tracking Response", Default = NewAttachConfig.V2.Smoothing,
    Min = 0.1, Max = 1, Rounding = 2,
    Tooltip = "Higher means faster tracking; 1 is immediate.",
    Callback = function(value) NewAttachConfig.V2.Smoothing = value end
})
HeadrideV2Group:AddSlider("HeadrideV2Damping", {
    Text = "Momentum Retention", Default = NewAttachConfig.V2.VelocityDamping,
    Min = 0, Max = 1, Rounding = 2,
    Tooltip = "Higher retains more momentum; original setting is 0.35.",
    Callback = function(value) NewAttachConfig.V2.VelocityDamping = value end
})
HeadrideV2Group:AddSlider("HeadrideV2Recovery", {
    Text = "Auto Detach Distance", Default = NewAttachConfig.V2.MaxRecoveryDistance,
    Min = 10, Max = 250, Rounding = 0, Suffix = " studs",
    Tooltip = "Detach when the target exceeds this distance beyond the grace period.",
    Callback = function(value) NewAttachConfig.V2.MaxRecoveryDistance = value end
})
HeadrideV2Group:AddSlider("VelocityRideRecoveryGrace", {
    Text = "Launch Recovery Grace", Default = NewAttachConfig.V2.RecoveryGrace,
    Min = 0, Max = 0.5, Rounding = 2, Suffix = " s",
    Tooltip = "Wait briefly before detaching after a sudden launch.",
    Callback = function(value) NewAttachConfig.V2.RecoveryGrace = value end
})
HeadrideV2Group:AddDropdown("VelocityRidePhysics", {
    Values = { "Classic", "Constraint" },
    Default = NewAttachConfig.V2.PhysicsMode == "Constraint" and 2 or 1, Multi = false,
    Text = "Positioning Physics",
    Tooltip = "Classic preserves existing movement. Constraint is an experimental AlignPosition alternative.",
    Callback = function(value) NewAttachConfig.V2.PhysicsMode = value end
})
HeadrideV2Group:AddToggle("VelocityRideBehind", {
    Text = "Position Behind Target", Default = NewAttachConfig.V2.BehindTarget,
    Tooltip = "Use the target's back-facing direction for the depth offset.",
    Callback = function(value) NewAttachConfig.V2.BehindTarget = value end
})
HeadrideV2Group:AddToggle("UWUHeadrideSnapDash", {
    Text = "Re-anchor After Target Dash", Default = NewAttachConfig.V2.SnapOnDash,
    Tooltip = "Reacquires the target position after a sharp dash, using the existing active latch update; no added loop.",
    Callback = function(value) NewAttachConfig.V2.SnapOnDash = value end
})
HeadrideV2Group:AddSlider("UWUHeadrideSnapThreshold", {
    Text = "Dash Re-anchor Distance", Default = NewAttachConfig.V2.SnapThreshold,
    Min = 3, Max = 40, Rounding = 0, Suffix = " studs",
    Callback = function(value) NewAttachConfig.V2.SnapThreshold = value end
})
HeadrideV2Group:AddSlider("UWUHeadrideCatchUp", {
    Text = "Catch-up Distance", Default = NewAttachConfig.V2.CatchUpDistance,
    Min = 1, Max = 20, Rounding = 1, Suffix = " studs",
    Callback = function(value) NewAttachConfig.V2.CatchUpDistance = value end
})
HeadrideV2Group:AddSlider("UWUHeadrideLeadCap", {
    Text = "Max Prediction Lead", Default = NewAttachConfig.V2.MaxLead,
    Min = 0, Max = 12, Rounding = 1, Suffix = " studs",
    Callback = function(value) NewAttachConfig.V2.MaxLead = value end
})


local NanamiMacroGroup = Tabs.Macro:AddRightGroupbox("Nanami • Black Flash")
NanamiMacroGroup:AddToggle("BlackFlashNanami", {
    Text = "Nanami Black Flash",
    Default = getgenv().BlackFlash.Nanami,
    Tooltip = "Automatically clicks when Nanami's timing marker reaches the target zone.",
    Callback = function(value)
        getgenv().BlackFlash.Nanami = value
    end
})

NanamiMacroGroup:AddSlider("BlackFlashNamamiChance", {
    Text = "Nanami Success Rate",
    Default = getgenv().BlackFlash.Nanami_Hitchance,
    Min = 1,
    Max = 100,
    Rounding = 10,
    Suffix = "%",
    Tooltip = "Sets the chance that a detected Nanami timing window is acted on.",
    Callback = function(value)
        getgenv().BlackFlash.Nanami_Hitchance = value
    end
})

NanamiMacroGroup:AddLabel("Yuji, Todo, Geto Patched")


do
    local cfg = getgenv().Macro.Gojo
    if cfg.Mode == "Frame-Sync Infinity Blues" then cfg.Mode = "Frame-Sync Triple Blue" end
    cfg.Mode = cfg.Mode or "Triple Blue"
    cfg.BlueDelayMs = cfg.BlueDelayMs or 60
    cfg.FifthM1DelayMs = cfg.FifthM1DelayMs or 0
    cfg.QToBlueMs = cfg.QToBlueMs or 35
    cfg.OverlapMs = cfg.OverlapMs or 25
    cfg.InputHoldMs = cfg.InputHoldMs or 30
    cfg.DashRepeats = cfg.DashRepeats or 3
    cfg.FrameSyncFrames = math.clamp(tonumber(cfg.FrameSyncFrames) or 0, 0, 8)
    cfg.CancelRequested = false
    if cfg.HotkeyEnabled == nil then cfg.HotkeyEnabled = true end
    cfg.Busy = false
    local group = Tabs.Macro:AddLeftGroupbox("Gojo | Blue Techniques")
    local enabled = group:AddToggle("GojoTripleBlue", {
        Text = "Enable Gojo Techniques", Default = cfg.TripleBlue,
        Callback = function(v) cfg.TripleBlue = v end
    })
    enabled:AddKeyPicker("GojoTripleBlueKey", {
        Default = cfg.Key.Name, Mode = "Hold", Text = "Technique Hotkey",
        NoUI = false, SyncToggleState = false,
        ChangedCallback = function(k) if typeof(k) == "EnumItem" then cfg.Key = k end end
    })
    group:AddDropdown("GojoBlueMode", {
        Text = "Technique", Values = {"Triple Blue", "Blue Dash", "Triple Blue + Fifth M1", "Frame-Sync Triple Blue"},
        Default = table.find({"Triple Blue", "Blue Dash", "Triple Blue + Fifth M1", "Frame-Sync Triple Blue"}, cfg.Mode) or 1,
        Callback = function(v) cfg.Mode = v end
    })
    group:AddSlider("GojoBlueDelay", {
        Text = "3-to-Q Delay", Default = cfg.BlueDelayMs, Min = 50, Max = 100,
        Rounding = 0, Suffix = " ms", Callback = function(v) cfg.BlueDelayMs = v end
    })
    group:AddSlider("GojoFifthDelay", {
        Text = "M1-to-Blue Offset", Default = cfg.FifthM1DelayMs,
        Min = 0, Max = 80, Rounding = 0, Suffix = " ms",
        Callback = function(v) cfg.FifthM1DelayMs = v end
    })
    group:AddSlider("GojoQToBlue", {
        Text = "Q-to-Second-Blue", Default = cfg.QToBlueMs,
        Min = 0, Max = 120, Rounding = 0, Suffix = " ms",
        Callback = function(v) cfg.QToBlueMs = v end
    })
    group:AddSlider("GojoInputHold", {
        Text = "Input Hold", Default = cfg.InputHoldMs,
        Min = 10, Max = 80, Rounding = 0, Suffix = " ms",
        Callback = function(v) cfg.InputHoldMs = v end
    })
    group:AddSlider("GojoOverlap", {
        Text = "M1 + Blue Overlap", Default = cfg.OverlapMs,
        Min = 0, Max = 80, Rounding = 0, Suffix = " ms",
        Callback = function(v) cfg.OverlapMs = v end
    })
    group:AddSlider("GojoDashRepeats", {
        Text = "Blue Dash Repeats", Default = cfg.DashRepeats,
        Min = 1, Max = 6, Rounding = 0,
        Callback = function(v) cfg.DashRepeats = v end
    })
    group:AddSlider("GojoFrameSyncFrames", {
        Text = "Q -> Blue Frame Offset", Default = cfg.FrameSyncFrames,
        Min = 0, Max = 8, Rounding = 0, Suffix = " frames",
        Tooltip = "0 sends Q and 3 in the same client frame; 1+ waits that many rendered frames. This cannot guarantee a server frame.",
        Callback = function(v) cfg.FrameSyncFrames = v end
    })
    group:AddLabel("Frame-Sync Triple: 3 > Q+3 > Q+3. Infinity Blue has its own independent controls.", true)
    group:AddLabel("After 4 manual M1s, the legacy fifth-M1 mode overlaps that hit with Blue; its timing is game-dependent.", true)
end

do
    local cfg = getgenv().Macro.InfinityBlue
    local group = Tabs.Macro:AddRightGroupbox("Gojo | Infinity Blue Dash Assist")
    local toggle = group:AddToggle("InfinityBlueEnabled", {
        Text = "Enable Infinity Blue", Default = cfg.Enabled,
        Callback = function(v) cfg.Enabled = v end
    })
    toggle:AddKeyPicker("InfinityBlueHotkey", {
        Default = cfg.Key.Name, Mode = "Hold", Text = "Infinity Hotkey",
        NoUI = false, SyncToggleState = false,
        ChangedCallback = function(k) if typeof(k) == "EnumItem" then cfg.Key = k end end
    })
    group:AddSlider("InfinityBluePreQDelay", {
        Text = "Before Q Delay", Default = cfg.PreQDelayMs, Min = 0, Max = 150,
        Rounding = 0, Suffix = " ms", Callback = function(v) cfg.PreQDelayMs = v end
    })
    group:AddSlider("InfinityBlueFrameOffset", {
        Text = "Q -> 3 Frame Offset", Default = cfg.QToBlueFrames, Min = 0, Max = 8,
        Rounding = 0, Suffix = " frames", Callback = function(v) cfg.QToBlueFrames = v end
    })
    group:AddSlider("InfinityBlueQHold", {
        Text = "Q Hold", Default = cfg.QHoldMs, Min = 10, Max = 100,
        Rounding = 0, Suffix = " ms", Callback = function(v) cfg.QHoldMs = v end
    })
    group:AddSlider("InfinityBlue3Hold", {
        Text = "Second 3 Hold", Default = cfg.BlueHoldMs, Min = 10, Max = 100,
        Rounding = 0, Suffix = " ms", Callback = function(v) cfg.BlueHoldMs = v end
    })
    group:AddLabel("Press 3 yourself for Blue overlay, then Infinity hotkey: Q -> 3 -> STOP. No initial 3, no repeat.", true)
end

local MobGroup = Tabs.Macro:AddLeftGroupbox("Mob • Combos")
local MobToggle = MobGroup:AddToggle("MobBarrage", {
    Text = "Barrage",
    Default = getgenv().Macro.Mob.Barrage,
    Tooltip = "Enables the Mob barrage sequence while its assigned key is pressed.",
    Callback = function(value)
        getgenv().Macro.Mob.Barrage = value
    end
})
MobToggle:AddKeyPicker("MobBarrageKey", {
    Default = getgenv().Macro.Mob.Key1.Name,
    SyncToggleState = false,
    Mode = "Hold",
    Text = "Macro Key",
    NoUI = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then
            getgenv().Macro.Mob.Key1 = key
        end
    end
})
__VelocityFns.addKeyPickerTooltip(MobToggle, "Choose the key that triggers the Mob barrage.")

local MobWeakRepelToggle = MobGroup:AddToggle("MobWeakRepel", {
    Text = "Weak Repel",
    Default = getgenv().Macro.Mob.WeakRepel,
    Tooltip = "Same as Barrage but uses move 1 (Weak Repel) instead of move 2.",
    Callback = function(value)
        getgenv().Macro.Mob.WeakRepel = value
    end
})
MobWeakRepelToggle:AddKeyPicker("MobWeakRepelKey", {
    Default = (getgenv().Macro.Mob.KeyWeakRepel and getgenv().Macro.Mob.KeyWeakRepel.Name) or "N",
    SyncToggleState = false,
    Mode = "Hold",
    Text = "Macro Key",
    NoUI = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then
            getgenv().Macro.Mob.KeyWeakRepel = key
        end
    end
})
__VelocityFns.addKeyPickerTooltip(MobWeakRepelToggle, "Choose the key that triggers Mob Weak Repel.")

local VegetaGroup = Tabs.Macro:AddLeftGroupbox("Vegeta • Combos")
local VegetaToggle = VegetaGroup:AddToggle("VegetaEvasive", {
    Text = "Evasive",
    Default = getgenv().Macro.Vegeta.Evasive,
    Tooltip = "Enables the Vegeta evasive sequence while its assigned key is pressed.",
    Callback = function(value)
        getgenv().Macro.Vegeta.Evasive = value
    end
})
VegetaToggle:AddKeyPicker("VegetaEvasiveKey", {
    Default = getgenv().Macro.Vegeta.Key.Name,
    SyncToggleState = false,
    Mode = "Hold",
    Text = "Macro Key",
    NoUI = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then
            getgenv().Macro.Vegeta.Key = key
        end
    end
})
__VelocityFns.addKeyPickerTooltip(VegetaToggle, "Choose the key that triggers the Vegeta evasive sequence.")

local ZabuzaGroup = Tabs.Macro:AddRightGroupbox("Zabuza • Combos")
local ZabuzaToggle = ZabuzaGroup:AddToggle("ZabuzaClone", {
    Text = "Clone Head Ride",
    Default = getgenv().Macro.Zabuza.Clone,
    Tooltip = "Enables the Zabuza clone head-ride sequence on its assigned key.",
    Callback = function(value)
        getgenv().Macro.Zabuza.Clone = value
    end
})
ZabuzaToggle:AddKeyPicker("ZabuzaCloneKey", {
    Default = getgenv().Macro.Zabuza.Key.Name,
    SyncToggleState = false,
    Mode = "Hold",
    Text = "Macro Key",
    NoUI = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then
            getgenv().Macro.Zabuza.Key = key
        end
    end
})
__VelocityFns.addKeyPickerTooltip(ZabuzaToggle, "Choose the key that triggers the Zabuza clone sequence.")
ZabuzaGroup:AddDropdown("ZabuzaCloneMode", {
    Values = { "Legit", "Blatant" },
    Default = getgenv().Macro.Zabuza.Mode or "Legit",
    Text = "Clone Mode",
    Tooltip = "Legit = jump and clone input. Blatant = ride on the clone head.",
    Callback = function(value)
        getgenv().Macro.Zabuza.Mode = value
    end
})
ZabuzaGroup:AddToggle("ZabuzaCloneJump", {
    Text = "Auto Perform Jump",
    Default = getgenv().Macro.Zabuza.Auto_Perform_Jump,
    Tooltip = "Performs the jump setup automatically before the Zabuza sequence.",
    Callback = function(value)
        getgenv().Macro.Zabuza.Auto_Perform_Jump = value
    end
})

local RikkaGroup = Tabs.Macro:AddRightGroupbox("Rikka • Combos")
local RikkaToggle = RikkaGroup:AddToggle("RikkaUptilt", {
    Text = "Uptilt",
    Default = getgenv().Macro.Rikka.Uptilt,
    Tooltip = "Enables the Rikka uptilt sequence on its assigned key.",
    Callback = function(value)
        getgenv().Macro.Rikka.Uptilt = value
    end
})
RikkaToggle:AddKeyPicker("RikkaUptiltKey", {
    Default = getgenv().Macro.Rikka.Key.Name,
    SyncToggleState = false,
    Mode = "Hold",
    Text = "Macro Key",
    NoUI = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then
            getgenv().Macro.Rikka.Key = key
        end
    end
})
__VelocityFns.addKeyPickerTooltip(RikkaToggle, "Choose the key that triggers Rikka's uptilt.")

local StarkGroup = Tabs.Macro:AddRightGroupbox("Stark • Combos")
local StarkToggle = StarkGroup:AddToggle("StarkUptilt", {
    Text = "Sonido Strike Uptilt",
    Default = getgenv().Macro.Stark.Uptilt,
    Tooltip = "Enables the Stark Sonido Strike and uptilt sequence on its assigned key.",
    Callback = function(value)
        getgenv().Macro.Stark.Uptilt = value
    end
})
StarkToggle:AddKeyPicker("StarkUptiltKey", {
    Default = getgenv().Macro.Stark.Key.Name,
    SyncToggleState = false,
    Mode = "Hold",
    Text = "Macro Key",
    NoUI = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then
            getgenv().Macro.Stark.Key = key
        end
    end
})
__VelocityFns.addKeyPickerTooltip(StarkToggle, "Choose the key that triggers Stark's sequence.")

local KiriGroup = Tabs.Macro:AddRightGroupbox("Kiritsugu • Combos")
local KiriToggle = KiriGroup:AddToggle("KiriKnife", {
    Text = "Combat Knife",
    Default = getgenv().Macro.Kiri.Knife,
    Tooltip = "Enables the Kiritsugu Combat Knife sequence on its assigned key.",
    Callback = function(value)
        getgenv().Macro.Kiri.Knife = value
    end
})
KiriToggle:AddKeyPicker("KiriKnifeKey", {
    Default = getgenv().Macro.Kiri.Key.Name,
    SyncToggleState = false,
    Mode = "Hold",
    Text = "Macro Key",
    NoUI = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then
            getgenv().Macro.Kiri.Key = key
        end
    end
})
__VelocityFns.addKeyPickerTooltip(KiriToggle, "Choose the key that triggers the Combat Knife sequence.")

local DioGroup = Tabs.Macro:AddRightGroupbox("DIO • Combos")
local DioToggle = DioGroup:AddToggle("DIOUptilt", {
    Text = "Time Shift Uptilt",
    Default = getgenv().Macro.Dio.Uptilt,
    Tooltip = "Enables the DIO Time Shift uptilt sequence on its assigned key.",
    Callback = function(value)
        getgenv().Macro.Dio.Uptilt = value
    end
})
DioToggle:AddKeyPicker("DIOUptiltKey", {
    Default = getgenv().Macro.Dio.Key.Name,
    SyncToggleState = false,
    Mode = "Hold",
    Text = "Macro Key",
    NoUI = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then
            getgenv().Macro.Dio.Key = key
        end
    end
})
__VelocityFns.addKeyPickerTooltip(DioToggle, "Choose the key that triggers DIO's Time Shift sequence.")

local RyokoGroup = Tabs.Macro:AddLeftGroupbox("Ryoko • Combos")
local RyokoToggle = RyokoGroup:AddToggle("RyokoEnabled", {
    Text = "Clone Launch",
    Default = getgenv().Macro.Ryoko.Enabled,
    Tooltip = "Enables the Ryoko clone-launch sequence on its assigned key.",
    Callback = function(value)
        getgenv().Macro.Ryoko.Enabled = value
    end
})
RyokoToggle:AddKeyPicker("RyokoKey", {
    Default = getgenv().Macro.Ryoko.Key.Name,
    SyncToggleState = false,
    Mode = "Hold",
    Text = "Macro Key",
    NoUI = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then
            getgenv().Macro.Ryoko.Key = key
        end
    end
})
__VelocityFns.addKeyPickerTooltip(RyokoToggle, "Choose the key that triggers the Ryoko clone-launch sequence.")
RyokoGroup:AddLabel("Requires a perfect setup; launch timing is RNG and can be inconsistent.")

local ForceUptiltGroup = Tabs.Macro:AddLeftGroupbox("Universal • Uptilt")
local ForceUptiltToggle = ForceUptiltGroup:AddToggle("ForceUptiltEnabled", {
    Text = "Enabled",
    Default = getgenv().Macro.ForceUptilt.Enabled,
    Tooltip = "Runs the Rikka-style M1 uptilt sequence without using a character move.",
    Callback = function(value)
        getgenv().Macro.ForceUptilt.Enabled = value
    end
})
ForceUptiltToggle:AddKeyPicker("ForceUptiltKey", {
    Default = getgenv().Macro.ForceUptilt.Key.Name,
    SyncToggleState = false,
    Mode = "Toggle",
    Text = "Macro Key",
    NoUI = false,
    ChangedCallback = function(key)
        if typeof(key) == "EnumItem" then
            getgenv().Macro.ForceUptilt.Key = key
        end
    end
})
__VelocityFns.addKeyPickerTooltip(ForceUptiltToggle, "Choose the key that triggers Force Uptilt.")
ForceUptiltGroup:AddToggle("ForceUptiltJump", {
    Text = "Add Jump",
    Default = getgenv().Macro.ForceUptilt.Jump,
    Tooltip = "Applies a jump impulse when the Force Uptilt macro is triggered.",
    Callback = function(value)
        getgenv().Macro.ForceUptilt.Jump = value
    end
})

local FovCircle = Drawing and Drawing.new("Circle")
if FovCircle then
    FovCircle.Visible = false
    FovCircle.Transparency = 1
    FovCircle.Thickness = 2
    FovCircle.Color = Color3.fromRGB(86, 114, 214)
    FovCircle.Filled = false
end

function __VelocityFns.updateFovCircle()
    Camera = Workspace.CurrentCamera
    if not FovCircle or not Camera then
        return
    end
    if __VelocityFns.isStreamproof() then
        FovCircle.Visible = false
        return
    end
    if getgenv().AimbotSettings.ShowFov then
        local last = UserInputService:GetLastInputType()
        local gamepad = last.Name:match("^Gamepad") ~= nil and __VelocityFns.isPhysicalControllerConnected()
        local mousePos = gamepad and Camera.ViewportSize / 2 or UserInputService:GetMouseLocation()
        FovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        FovCircle.Radius = getgenv().AimbotSettings.FOV
        FovCircle.Visible = true
    else
        FovCircle.Visible = false
    end
end

function __VelocityFns.getDistanceFromCursorToWorldPos(worldPos)
    Camera = Workspace.CurrentCamera
    if not Camera then
        return math.huge
    end
    local vector, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then
        return math.huge
    end
    local last = UserInputService:GetLastInputType()
    local useCenter = last.Name:match("^Gamepad") ~= nil and __VelocityFns.isPhysicalControllerConnected()
    local mousePos = useCenter and Camera.ViewportSize / 2 or UserInputService:GetMouseLocation()
    local dx, dy = vector.X - mousePos.X, vector.Y - mousePos.Y
    return dx * dx + dy * dy
end

function __VelocityFns.isValidTarget(character)
    if not character or not character:IsA("Model") then
        return false
    end
    local humanoid = __VelocityFns.getHumanoid(character)
    local bone = __VelocityFns.getTargetPart(character)
    if not (humanoid and bone and humanoid.Health > 0) then
        return false
    end
    if character:FindFirstChild("NoTarg") or character:FindFirstChild("ForceUnlock") then
        return false
    end
    local torso = character:FindFirstChild("Torso")
    if torso and torso:IsA("BasePart") and torso.Transparency > 0.991 then
        return false
    end

    local owner = Players:GetPlayerFromCharacter(character)
    if owner and owner == LocalPlayer then
        return false
    end

    if owner then
        if getgenv().AimbotSettings.Team_Check and owner.Team and LocalPlayer.Team and owner.Team == LocalPlayer.Team then
            return false
        end
        return true
    end

    if getgenv().AimbotSettings.Npc then
        return true
    end

    return false
end

function __VelocityFns.getClosestAimbotTarget(excluded)
    local minDist = math.huge
    local bestCharacter = nil
    local fov = math.max(tonumber(getgenv().AimbotSettings.FOV) or 120, 0)
    local fovSquared = fov * fov

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character ~= excluded
            and player.Character and __VelocityFns.isValidTarget(player.Character) then
            local aimPosition = __VelocityFns.getAimbotAimPosition(player.Character)
            if aimPosition then
                local dist = __VelocityFns.getDistanceFromCursorToWorldPos(aimPosition)
                if dist <= fovSquared and dist < minDist then
                    minDist = dist
                    bestCharacter = player.Character
                end
            end
        end
    end

    if getgenv().AimbotSettings.Npc then
        local live = Workspace:FindFirstChild("Live")
        if live then
            for _, npc in ipairs(live:GetChildren()) do
                if npc ~= excluded and not Players:GetPlayerFromCharacter(npc)
                    and __VelocityFns.isValidTarget(npc) then
                    local aimPosition = __VelocityFns.getAimbotAimPosition(npc)
                    if aimPosition then
                        local dist = __VelocityFns.getDistanceFromCursorToWorldPos(aimPosition)
                        if dist <= fovSquared and dist < minDist then
                            minDist = dist
                            bestCharacter = npc
                        end
                    end
                end
            end
        end
    end

    return bestCharacter
end

function __VelocityFns.getDirectionalAimbotTarget(currentTarget, side)
    local camera = Workspace.CurrentCamera
    if not camera or not currentTarget then return nil end
    local currentPart = __VelocityFns.getTargetPart(currentTarget)
    if not currentPart then return nil end
    local currentScreen, visible = camera:WorldToViewportPoint(currentPart.Position)
    if not visible then return nil end
    local best, bestScore
    local maxRadius = math.max(tonumber(getgenv().AimbotSettings.FOV) or 120, 0)
    local function consider(character)
        if character == currentTarget or not __VelocityFns.isValidTarget(character) then return end
        local position = __VelocityFns.getAimbotAimPosition(character)
        if not position then return end
        local point, onScreen = camera:WorldToViewportPoint(position)
        if not onScreen then return end
        local dx = point.X - currentScreen.X
        if dx * side <= 8 then return end
        local cursorDist = __VelocityFns.getDistanceFromCursorToWorldPos(position)
        if cursorDist > maxRadius * maxRadius then return end
        local score = math.abs(dx) + math.abs(point.Y - currentScreen.Y) * 0.5
        if not bestScore or score < bestScore then
            best, bestScore = character, score
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then consider(player.Character) end
    end
    if getgenv().AimbotSettings.Npc then
        local live = Workspace:FindFirstChild("Live")
        if live then
            for _, npc in ipairs(live:GetChildren()) do
                if not Players:GetPlayerFromCharacter(npc) then consider(npc) end
            end
        end
    end
    return best
end

local AimbotRenderStepName = "VelocityAimbotCamera"
local AimbotRenderStepBound = false
local FovDrawConnection = nil
local LockedAimbotTarget = nil
local AimRotationHumanoid
local AimRotationOriginalAutoRotate
local AimbotSelectionBoxTarget
local AimbotSelectionBoxPart

function __VelocityFns.clearAimbotSelectionBoxSafely()
    if AimbotSelectionBox then
        AimbotSelectionBox:Destroy()
        AimbotSelectionBox = nil
    end
    AimbotSelectionBoxTarget = nil
    AimbotSelectionBoxPart = nil
end

function __VelocityFns.updateAimbotSelectionBox(target, targetPart)
    if not Toggles.AimbotSelectionBox.Value or not target then
        __VelocityFns.clearAimbotSelectionBoxSafely()
        return
    end

    if not AimbotSelectionBox then
        local template = game.StarterGui:FindFirstChild("SelectionBox", true)
        if not template then
            return
        end
        AimbotSelectionBox = template:Clone()
    end

    targetPart = targetPart or target
    if AimbotSelectionBoxTarget ~= target
        or AimbotSelectionBoxPart ~= targetPart
        or AimbotSelectionBox.Parent ~= target
        or AimbotSelectionBox.Adornee ~= targetPart
        or not AimbotSelectionBox.Enabled then
        AimbotSelectionBox.Parent = target
        AimbotSelectionBox.Adornee = targetPart
        AimbotSelectionBox.Enabled = true
        AimbotSelectionBoxTarget = target
        AimbotSelectionBoxPart = targetPart
    end
end

function __VelocityFns.restoreAimbotCharacterRotation()
    if AimRotationHumanoid and AimRotationHumanoid.Parent and AimRotationOriginalAutoRotate ~= nil then
        AimRotationHumanoid.AutoRotate = AimRotationOriginalAutoRotate
    end
    AimRotationHumanoid = nil
    AimRotationOriginalAutoRotate = nil
end

function __VelocityFns.alignAimbotCharacter(root, humanoid, targetPosition)
    if not getgenv().AimbotSettings.AlignCharacterYaw then
        __VelocityFns.restoreAimbotCharacterRotation()
        return
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        __VelocityFns.restoreAimbotCharacterRotation()
        return
    end
    if AimRotationHumanoid ~= humanoid then
        __VelocityFns.restoreAimbotCharacterRotation()
        AimRotationHumanoid = humanoid
        AimRotationOriginalAutoRotate = humanoid.AutoRotate
    end
    humanoid.AutoRotate = false
    local flat = Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z)
    if (flat - root.Position).Magnitude > 0.001 then
        root.CFrame = CFrame.lookAt(root.Position, flat)
    end
end

function __VelocityFns.startAimbot()
    if AimbotRenderStepBound then
        RunService:UnbindFromRenderStep(AimbotRenderStepName)
        AimbotRenderStepBound = false
    end
    if FovDrawConnection then
        safeDisconnect(FovDrawConnection)
        FovDrawConnection = nil
    end
    for _, key in ipairs({"__AimbotMouseConn", "__AimbotMouseConn2", "__VelocityAimFocusConn", "__VelocityAimRespawnConn"}) do
        if _G[key] then
            safeDisconnect(_G[key])
            _G[key] = nil
        end
    end
    __VelocityFns.restoreAimbotCharacterRotation()
    __VelocityFns.clearAimbotSelectionBoxSafely()
    LockedAimbotTarget = nil
    if not getgenv().AimbotSettings.Enabled then
        if FovCircle then FovCircle.Visible = false end
        return
    end

    local toggleAimActive = false
    local controllerAimActive = false
    local acquireElapsed = 0
    local missingFrames = 0
    local function aimingNow()
        local settings = getgenv().AimbotSettings
        return controllerAimActive
            or (settings.InputMode == "Toggle" and toggleAimActive)
            or (settings.InputMode ~= "Toggle"
                and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    end
    local function clearAim()
        toggleAimActive = false
        controllerAimActive = false
        LockedAimbotTarget = nil
        acquireElapsed = 0
        missingFrames = 0
        __VelocityFns.clearAimbotSelectionBoxSafely()
        __VelocityFns.restoreAimbotCharacterRotation()
    end
    local function acquireTarget()
        LockedAimbotTarget = __VelocityFns.getClosestAimbotTarget()
        missingFrames = 0
        acquireElapsed = 0
    end

    local fovElapsed = 0
    FovDrawConnection = RunService.Heartbeat:Connect(function(dt)
        if not getgenv().AimbotSettings.ShowFov then return end
        fovElapsed += dt
        if fovElapsed >= 0.05 then
            fovElapsed = 0
            __VelocityFns.updateFovCircle()
        end
    end)
    __VelocityFns.updateFovCircle()

    _G.__AimbotMouseConn = UserInputService.InputBegan:Connect(function(input, processed)
        local settings = getgenv().AimbotSettings
        if input.KeyCode == Enum.KeyCode.ButtonR3 and settings.ControllerR3Lock then
            if processed and UserInputService:GetFocusedTextBox() then return end
            controllerAimActive = not controllerAimActive
            if controllerAimActive then acquireTarget()
            elseif not aimingNow() then clearAim() end
            return
        end
        if processed or UserInputService:GetFocusedTextBox() then return end
        local side = input.KeyCode == Enum.KeyCode.Y and -1
            or (input.KeyCode == Enum.KeyCode.U and 1 or nil)
        if side and settings.DirectionalSwitch and aimingNow() and LockedAimbotTarget then
            local nextTarget = __VelocityFns.getDirectionalAimbotTarget(LockedAimbotTarget, side)
            if nextTarget then LockedAimbotTarget = nextTarget; missingFrames = 0 end
            return
        end
        if input.KeyCode == Enum.KeyCode.T and settings.CycleTarget
            and aimingNow() and LockedAimbotTarget then
            local nextTarget = __VelocityFns.getClosestAimbotTarget(LockedAimbotTarget)
            if nextTarget then LockedAimbotTarget = nextTarget; missingFrames = 0 end
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
        if settings.InputMode == "Toggle" then
            toggleAimActive = not toggleAimActive
            if not toggleAimActive and not controllerAimActive then
                clearAim()
            elseif toggleAimActive then
                acquireTarget()
            end
        else
            acquireTarget()
        end
    end)
    _G.__AimbotMouseConn2 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2
            and getgenv().AimbotSettings.InputMode ~= "Toggle"
            and not controllerAimActive then
            clearAim()
        end
    end)
    _G.__VelocityAimFocusConn = UserInputService.WindowFocusReleased:Connect(clearAim)
    _G.__VelocityAimRespawnConn = LocalPlayer.CharacterAdded:Connect(clearAim)

    RunService:BindToRenderStep(AimbotRenderStepName, Enum.RenderPriority.Camera.Value + 8, function(dt)
        if not getgenv().AimbotSettings.Enabled then return end
        if not aimingNow() then
            __VelocityFns.clearAimbotSelectionBoxSafely()
            __VelocityFns.restoreAimbotCharacterRotation()
            return
        end
        Camera = Workspace.CurrentCamera
        if not Camera or Camera.CameraType == Enum.CameraType.Scriptable then return end
        if not __VelocityFns.isValidTarget(LockedAimbotTarget) then
            missingFrames += 1
            __VelocityFns.clearAimbotSelectionBoxSafely()
            if missingFrames >= 4 then LockedAimbotTarget = nil end
        else
            missingFrames = 0
        end
        if not LockedAimbotTarget then
            acquireElapsed += dt
            if acquireElapsed < 0.1 then return end
            acquireElapsed = 0
            acquireTarget()
        end
        local target = LockedAimbotTarget
        if not target then return end
        local point = __VelocityFns.getAimbotAimPosition(target)
        if not point then return end
        local cameraPosition = Camera.CFrame.Position
        local direction = point - cameraPosition
        if direction.Magnitude < 0.01 then return end

        -- Instant response: no Lerp, temporal smoothing, or camera translation.
        local horizontal = Vector3.new(direction.X, 0, direction.Z)
        local flatDistance = horizontal.Magnitude
        local flatForward = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
        if flatForward.Magnitude < 0.001 then flatForward = Vector3.new(0, 0, -1) end
        local stableHeading = flatDistance > 0.08 and horizontal.Unit or flatForward.Unit
        local pitch = math.atan2(direction.Y, math.max(flatDistance, 0.5))
        if getgenv().AimbotSettings.ViewStyle == "Overhead" then
            pitch -= math.rad(clamp(tonumber(getgenv().AimbotSettings.OverheadPitch) or 10, 0, 20))
        end
        pitch = clamp(pitch, math.rad(-82), math.rad(82))
        local look = stableHeading * math.cos(pitch) + Vector3.yAxis * math.sin(pitch)
        Camera.CFrame = CFrame.lookAt(cameraPosition, cameraPosition + look)
        __VelocityFns.updateAimbotSelectionBox(target, __VelocityFns.getTargetPart(target))
        local myCharacter = LocalPlayer.Character
        local root = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        local humanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health > 0 then
            __VelocityFns.alignAimbotCharacter(root, humanoid, point)
        end
    end)
    AimbotRenderStepBound = true
end

local parryRunning = false
local parryPending = false
local healthConnection = nil
local inputRemote = nil
local inputChildConnection = nil
local inputRemovedConnection = nil
local backpackChildConnection = nil
local backpackRemovedConnection = nil
local autoParryCharacterConnection = nil

function __VelocityFns.refreshInputRemote()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    local remote = (backpack and backpack:FindFirstChild("Input")) or (character and character:FindFirstChild("Input"))
    if remote and remote:IsA("RemoteEvent") then
        inputRemote = remote
    else
        inputRemote = nil
    end
    return inputRemote ~= nil
end

function __VelocityFns.watchInputRemote(character)
    if inputChildConnection then
        safeDisconnect(inputChildConnection)
        inputChildConnection = nil
    end
    if inputRemovedConnection then
        safeDisconnect(inputRemovedConnection)
        inputRemovedConnection = nil
    end
    if backpackChildConnection then
        safeDisconnect(backpackChildConnection)
        backpackChildConnection = nil
    end
    if backpackRemovedConnection then
        safeDisconnect(backpackRemovedConnection)
        backpackRemovedConnection = nil
    end

    if character then
        inputChildConnection = character.ChildAdded:Connect(function(child)
            if child.Name == "Input" then
                __VelocityFns.refreshInputRemote()
            end
        end)
        inputRemovedConnection = character.ChildRemoved:Connect(function(child)
            if child == inputRemote then
                __VelocityFns.refreshInputRemote()
            end
        end)
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        backpackChildConnection = backpack.ChildAdded:Connect(function(child)
            if child.Name == "Input" then
                __VelocityFns.refreshInputRemote()
            end
        end)
        backpackRemovedConnection = backpack.ChildRemoved:Connect(function(child)
            if child == inputRemote then
                __VelocityFns.refreshInputRemote()
            end
        end)
    end

    __VelocityFns.refreshInputRemote()
end

function __VelocityFns.getParryTarget()
    local character = LocalPlayer.Character
    local config = getgenv().AutoParry
    local range = math.max(tonumber(config and config.Range) or 25, 0)
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closest, minDistSq = nil, range * range
    local myPos = hrp.Position
    local seen = {}
    local targetType = config.TargetType or "Both"

    local function consider(model)
        if not model or model == character or not model:IsA("Model") or seen[model] then return end
        seen[model] = true
        local player = Players:GetPlayerFromCharacter(model)
        if targetType == "Players" and not player then return end
        if targetType == "NPCs" and player then return end
        if config.IgnoreTeammates and player and player.Team and LocalPlayer.Team
            and player.Team == LocalPlayer.Team then return end

        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return end
        local delta = root.Position - myPos
        local distSq = delta:Dot(delta)
        if distSq <= minDistSq then
            minDistSq, closest = distSq, root
        end
    end

    if targetType ~= "NPCs" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then consider(player.Character) end
        end
    end

    if targetType ~= "Players" then
        local live = Workspace:FindFirstChild("Live")
        if live then
            for _, model in ipairs(live:GetChildren()) do consider(model) end
        end
    elseif Workspace:FindFirstChild("Live") then

        for _, model in ipairs(LiveFolder:GetChildren()) do
            if Players:GetPlayerFromCharacter(model) then consider(model) end
        end
    end
    return closest
end

function __VelocityFns.canAutoParry()
    local config = getgenv().AutoParry
    return config and config.Enabled
end

function __VelocityFns.fireInput(...)
    if not inputRemote or not inputRemote.Parent then
        __VelocityFns.refreshInputRemote()
    end
    if not inputRemote then
        return false
    end

    local args = { ... }
    local remote = inputRemote
    local success = pcall(function()
        remote:FireServer(table.unpack(args))
    end)
    if not success then
        __VelocityFns.refreshInputRemote()
        remote = inputRemote
        if remote then
            success = pcall(function()
                remote:FireServer(table.unpack(args))
            end)
        end
    end
    return success
end

-- VirtualInputManager does not reliably simulate gamepad input in normal Roblox play.
-- Keep controller recognition for guarding, but use the existing M1 game action.
-- This confirms only request submission, never that the server accepted the action.

function __VelocityFns.parrySequence(forceTarget)
    if parryRunning then return end
    parryRunning = true
    local character = LocalPlayer.Character
    local ok = pcall(function()
        local config = getgenv().AutoParry
        if not config.Enabled or not character or not __VelocityFns.refreshInputRemote() then
            __VelocityFns.noteParryDiagnostic("Reaction blocked: disabled, no character, or missing Input remote")
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        if config.RequireBlockHeld and not __VelocityFns.isAutoParryGuardHeld() then return end

        __VelocityFns.fireInput("BlockOff")
        task.wait(math.clamp(tonumber(config.ReleaseDelay) or 0.025, 0.01, 0.1))
        if character ~= LocalPlayer.Character or humanoid.Health <= 0 then return end

        local state = humanoid:GetState()
        local airborne = state == Enum.HumanoidStateType.Jumping
            or state == Enum.HumanoidStateType.Freefall
            or state == Enum.HumanoidStateType.FallingDown
        local heldSpace = __VelocityFns.isAutoParryJumpHeld()
        local airAttack = airborne and heldSpace and config.SpacePolicy ~= "Downslam"
        __VelocityFns.fireInput(airAttack and "SpaceOn" or "SpaceOff")

        local followUp = config.FollowUp or "M1"
        local useM1 = followUp == "M1"
            or followUp == "Grounded M1" and not airborne and not heldSpace
        if useM1 then
            local target = forceTarget
            if not target or not target:IsDescendantOf(Workspace) then
                target = __VelocityFns.getParryTarget()
            end
            local root = character:FindFirstChild("HumanoidRootPart")
            local hitCFrame = target and target.CFrame or root and root.CFrame or CFrame.new()
            -- A controller's B/Circle is the game's physical punch binding, but
            -- injecting a virtual press does not reliably invoke the game's action.
            -- Submit the same game M1 request used for keyboard players.
            local requestOk = __VelocityFns.fireInput("M1", {
                air = airAttack,
                skeyreal = false,
                skeydown = true,
                mousehit = hitCFrame,
                md = Vector3.zero
            })
            parryDiagnostics.M1Requests += 1
            __VelocityFns.noteParryDiagnostic(requestOk
                and "M1 FireServer call returned (server acceptance unknown)"
                or "M1 request failed: Input remote unavailable")
        end
        task.wait(math.clamp(tonumber(config.RecoveryDelay) or 0.055, 0.01, 0.2))
    end)

    if character and character == LocalPlayer.Character then
        __VelocityFns.fireInput(__VelocityFns.isAutoParryJumpHeld() and "SpaceOn" or "SpaceOff")
        __VelocityFns.fireInput(__VelocityFns.isAutoParryGuardHeld() and "BlockOn" or "BlockOff")
    end
    parryRunning = false
    if not ok then __VelocityFns.refreshInputRemote() end
end

local lastParryTrigger = -math.huge
local lastControllerDamageAt = -math.huge

-- Requires both the opted-in option and an actually connected physical pad.
-- An inactive/disconnected pad cannot change mouse/keyboard reaction timing.
local function isControllerOnePunchMode()
    local cfg = getgenv().AutoParry
    return cfg and cfg.UseControllerSupport == true
        and cfg.ControllerOnePunchPerBurst ~= false
        and #UserInputService:GetConnectedGamepads() > 0
end


function __VelocityFns.setupAutoParryCharacter(character)
    if healthConnection then
        safeDisconnect(healthConnection)
        healthConnection = nil
    end

    if character ~= LocalPlayer.Character then
        return
    end

    local humanoid = character:WaitForChild("Humanoid", 4)
    if not humanoid then
        return
    end

    if character ~= LocalPlayer.Character then
        return
    end

    parryPending = false
    lastParryTrigger = -math.huge
    lastControllerDamageAt = -math.huge
    local lastHealth = humanoid.Health
    healthConnection = humanoid.HealthChanged:Connect(function(newHealth)
        if character ~= LocalPlayer.Character then
            return
        end
        local damage = lastHealth - newHealth
        lastHealth = newHealth

        if damage <= 0 or newHealth <= 0 or humanoid.Health <= 0 then
            return
        end
        parryDiagnostics.HpEvents += 1
        if not __VelocityFns.canAutoParry() then
            __VelocityFns.noteParryDiagnostic("HP fell but Auto Parry is disabled")
            return
        end
        local config = getgenv().AutoParry
        if config.RequireBlockHeld and not __VelocityFns.isAutoParryGuardHeld() then
            __VelocityFns.noteParryDiagnostic("HP fell; guard not detected. Block is X/Square, NOT B/Circle.")
            return
        end
        if config.GroundOnly then
            local state = humanoid:GetState()
            if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
                return
            end
        end

        local minD = tonumber(config.MinDMG) or 0
        local maxD = tonumber(config.MaxDMG) or math.huge
        if minD > maxD or damage < minD or damage > maxD then
            __VelocityFns.noteParryDiagnostic(string.format("HP loss %.2f outside trigger damage range", damage))
            return
        end

        -- Controller one-punch mode: classify a burst of successive HP drops
        -- as one reaction. Each eligible HP event extends the burst window.
        -- PC/keyboard input retains the original 0.2s default cooldown.
        if isControllerOnePunchMode() then
            local now = os.clock()
            local gap = math.clamp(tonumber(config.ControllerBurstGap) or 0.85, 0.3, 2)
            local repeatHit = now - lastControllerDamageAt < gap
            lastControllerDamageAt = now
            if repeatHit then
                parryDiagnostics.SuppressedReactions += 1
                __VelocityFns.noteParryDiagnostic("Controller burst: repeat reaction suppressed (one M1)")
                return
            end
        end
        if parryRunning or parryPending then return end
        local now = os.clock()
        local cooldown = math.max(tonumber(config.TriggerCooldown) or 0.2, 0.05)
        if now - lastParryTrigger < cooldown then return end
        local target
        if config.RequireNearbyTarget then
            target = __VelocityFns.getParryTarget()
            if not target then
                __VelocityFns.noteParryDiagnostic("HP fell; no target found in detection range")
                return
            end
        end
        parryDiagnostics.TriggerEvents += 1
        __VelocityFns.noteParryDiagnostic("HP decrease passed filters; starting reaction")
        lastParryTrigger = now
        parryPending = true
        task.spawn(function()
            parryPending = false
            __VelocityFns.parrySequence(target)
        end)
    end)
end

function __VelocityFns.setupAutoParry(character)
    character = character or LocalPlayer.Character
    __VelocityFns.watchInputRemote(character)
    if character then
        __VelocityFns.setupAutoParryCharacter(character)
    end
end

autoParryCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
    __VelocityFns.setupAutoParry(character)
    task.defer(function()
        if LocalPlayer.Character == character then
            __VelocityFns.refreshInputRemote()
        end
    end)
end)

if LocalPlayer.Character then
    __VelocityFns.setupAutoParry()
end

local cg = game:GetService("CoreGui")
indGui = cg:FindFirstChild("AutoParryIndicator") or Instance.new("ScreenGui")
indGui.Name = "AutoParryIndicator"
indGui.ResetOnSpawn = false
indGui.Parent = cg

indLbl = indGui:FindFirstChild("A_Indicator") or Instance.new("TextLabel")
indLbl.Name = "A_Indicator"
indLbl.Size = UDim2.new(0, 36, 0, 36)
indLbl.Position = UDim2.new(0, 15, 0.5, -18)
indLbl.BackgroundTransparency = 1
indLbl.TextColor3 = Color3.fromRGB(100, 255, 140)
indLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
indLbl.TextStrokeTransparency = 0
indLbl.TextScaled = true
indLbl.Font = Enum.Font.GothamBold
indLbl.Text = ""
indLbl.Visible = false
indLbl.Parent = indGui

getgenv().__AutoParryIndicatorLbl = indLbl

__VelocityFns.refreshIndicator()

function __VelocityFns.applyStreamproofVisuals()
    local hide = __VelocityFns.isStreamproof()

    if FovCircle and hide then
        FovCircle.Visible = false
    end

    if indGui then
        indGui.Enabled = not hide
    end
    if indLbl and hide then
        indLbl.Visible = false
        indLbl.Text = ""
    elseif not hide then
        __VelocityFns.refreshIndicator()
    end

    for _, entry in pairs(ESPObjects) do
        if entry and entry.Gui and hide then
            entry.Gui.Enabled = false
        end
    end

    pcall(function()
        if hide and typeof(syn) == "table" and typeof(syn.protect_gui) == "function" and indGui then
            syn.protect_gui(indGui)
        end
    end)

    pcall(function()
        if typeof(setwindowdisplayaffinity) == "function" then
            setwindowdisplayaffinity(hide and 0x11 or 0)
        end
    end)
end

__VelocityFns.applyStreamproofVisuals()

local forceJumpBeganConn
local forceJumpEndedConn
local forceJumpCharacterConn
local forceJumpHeld = false
local forceJumpToken = 0

function __VelocityFns.forceJumpOnce(config)
    if not config or not config.Enabled then
        return
    end

    local character = LocalPlayer.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return
    end

    local upward = tonumber(config.Upward)
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    humanoid.Jump = true
    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, upward, root.AssemblyLinearVelocity.Z)
end

function __VelocityFns.setupForceJump()
    forceJumpHeld = false
    forceJumpToken += 1

    if forceJumpBeganConn then
        safeDisconnect(forceJumpBeganConn)
        forceJumpBeganConn = nil
    end
    if forceJumpEndedConn then
        safeDisconnect(forceJumpEndedConn)
        forceJumpEndedConn = nil
    end

    local config = getgenv().Force_Jump
    if not config then
        return
    end

    forceJumpBeganConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if not config.Enabled then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

        local jumpKey = __VelocityFns.getForceJumpKey(config)
        if input.KeyCode ~= jumpKey then return end

        forceJumpHeld = true
        forceJumpToken += 1
        local myToken = forceJumpToken
        local startedAt = tick()
        local interval = clamp(tonumber(config.Interval), 0.008, 0.10)
        local duration = clamp(tonumber(config.Duration), 0.08, 0.50)

        task.spawn(function()
            while forceJumpHeld and config.Enabled and myToken == forceJumpToken and tick() - startedAt < duration do
                __VelocityFns.forceJumpOnce(config)
                task.wait(interval)
            end
        end)
    end)

    forceJumpEndedConn = UserInputService.InputEnded:Connect(function(input)
        local configNow = getgenv().Force_Jump
        if not configNow then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == __VelocityFns.getForceJumpKey(configNow) then
            forceJumpHeld = false
            forceJumpToken += 1
        end
    end)
end

__VelocityFns.setupForceJump()
if typeof(LocalPlayer.CharacterAdded) == "RBXScriptSignal" then
    forceJumpCharacterConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.15)
        __VelocityFns.setupForceJump()
    end)
end

function __VelocityFns.getClosestTarget()
    local target = nil
    local smallestDist = math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)

    for _, model in ipairs(LiveFolder:GetChildren()) do
        local human = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if model ~= LocalPlayer.Character and human and human.Health > 0 and root then
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < smallestDist then
                    smallestDist = dist
                    target = model
                end
            end
        end
    end

    return target
end

function __VelocityFns.macroInfinityBlue()
    local cfg = getgenv().Macro.InfinityBlue
    if not cfg.Enabled or cfg.Busy then return end
    cfg.Busy = true
    local vim = game:GetService("VirtualInputManager")
    local qDown, blueDown = false, false
    local ok, err = pcall(function()
        local preDelay = math.clamp(tonumber(cfg.PreQDelayMs) or 0, 0, 150) / 1000
        local frames = math.clamp(math.floor(tonumber(cfg.QToBlueFrames) or 1), 0, 8)
        local qHold = math.clamp(tonumber(cfg.QHoldMs) or 35, 10, 100) / 1000
        local blueHold = math.clamp(tonumber(cfg.BlueHoldMs) or 30, 10, 100) / 1000
        if preDelay > 0 then task.wait(preDelay) end
        if not cfg.Enabled then return end
        vim:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
        qDown = true
        for _ = 1, frames do
            if not cfg.Enabled then return end
            RunService.RenderStepped:Wait()
        end
        if not cfg.Enabled then return end
        vim:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
        blueDown = true
        task.wait(blueHold)
        vim:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
        blueDown = false
        if qHold > blueHold then task.wait(qHold - blueHold) end
    end)
    if blueDown then pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Three, false, game) end) end
    if qDown then pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.Q, false, game) end) end
    cfg.Busy = false
    if not ok then warn("[Infinity Blue]", err) end
end

function __VelocityFns.macroGojoTripleBlue()
    local cfg = getgenv().Macro.Gojo
    if cfg.Busy then
        if cfg.Mode == "Frame-Sync Triple Blue" then
            cfg.CancelRequested = true
        end
        return
    end
    cfg.Busy = true
    cfg.CancelRequested = false

    local pressed = {}
    local vim = game:GetService("VirtualInputManager")
    local function keyDown(key)
        vim:SendKeyEvent(true, key, false, game)
        pressed[key] = true
    end
    local function keyUp(key)
        if pressed[key] then
            vim:SendKeyEvent(false, key, false, game)
            pressed[key] = nil
        end
    end
    local function tap(key, seconds)
        keyDown(key)
        task.wait(seconds)
        keyUp(key)
    end
    local function stopped()
        return cfg.CancelRequested or not cfg.TripleBlue
    end
    local ok, err = pcall(function()
        local hold = math.clamp(tonumber(cfg.InputHoldMs) or 30, 10, 80) / 1000
        local qDelay = math.clamp(tonumber(cfg.BlueDelayMs) or 60, 50, 100) / 1000
        local secondDelay = math.clamp(tonumber(cfg.QToBlueMs) or 35, 0, 120) / 1000
        local function legacyTriple(firstAlreadyPressed)
            if not firstAlreadyPressed then tap(Enum.KeyCode.Three, hold) end
            task.wait(math.max(0, qDelay - hold))
            tap(Enum.KeyCode.Q, hold)
            task.wait(secondDelay)
            tap(Enum.KeyCode.Three, hold)
        end
        local function frameSyncChain(count)
            local frames = math.clamp(math.floor(tonumber(cfg.FrameSyncFrames) or 0), 0, 8)
            count = math.clamp(math.floor(count), 2, 3)
            tap(Enum.KeyCode.Three, hold)
            for _ = 2, count do
                if stopped() then break end
                task.wait(math.max(0, qDelay - hold))
                if stopped() then break end
                keyDown(Enum.KeyCode.Q)
                for _ = 1, frames do
                    if stopped() then break end
                    RunService.RenderStepped:Wait()
                end
                if stopped() then
                    keyUp(Enum.KeyCode.Q)
                    break
                end
                keyDown(Enum.KeyCode.Three)
                task.wait(hold)
                keyUp(Enum.KeyCode.Three)
                keyUp(Enum.KeyCode.Q)
            end
        end

        if cfg.Mode == "Frame-Sync Triple Blue" then
            frameSyncChain(3)
        elseif cfg.Mode == "Blue Dash" then
            local count = math.clamp(math.floor(tonumber(cfg.DashRepeats) or 3), 1, 6)
            for iteration = 1, count do
                if stopped() then break end
                keyDown(Enum.KeyCode.Three)
                keyDown(Enum.KeyCode.Q)
                task.wait(hold)
                keyUp(Enum.KeyCode.Q)
                keyUp(Enum.KeyCode.Three)
                if iteration < count and not stopped() then
                    task.wait(math.clamp(tonumber(cfg.BlueDelayMs) or 60, 50, 100) / 1000)
                end
            end
        elseif cfg.Mode == "Triple Blue + Fifth M1" then
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(math.clamp(tonumber(cfg.FifthM1DelayMs) or 0, 0, 80) / 1000)
            keyDown(Enum.KeyCode.Three)
            task.wait(math.clamp(tonumber(cfg.OverlapMs) or 25, 0, 80) / 1000)
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            task.wait(math.max(0, hold - math.clamp(tonumber(cfg.OverlapMs) or 25, 0, 80) / 1000))
            keyUp(Enum.KeyCode.Three)
            legacyTriple(true)
        else
            legacyTriple(false)
        end
    end)
    for key in pairs(pressed) do
        pcall(function() vim:SendKeyEvent(false, key, false, game) end)
        pressed[key] = nil
    end
    cfg.Busy = false
    cfg.CancelRequested = false
    if not ok then warn("[Velocity Gojo]", err) end
end

function __VelocityFns.macroMobBarrage()
    local VIM = game:GetService("VirtualInputManager")
    for _ = 1, 6 do
        VIM:SendKeyEvent(true, Enum.KeyCode.G, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.G, false, game)
        task.wait(0.03)
        VIM:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
        task.wait(0.03)
    end
end

function __VelocityFns.macroMobWeakRepel()
    local VIM = game:GetService("VirtualInputManager")
    for _ = 1, 6 do
        VIM:SendKeyEvent(true, Enum.KeyCode.G, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.G, false, game)
        task.wait(0.03)
        VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        task.wait(0.03)
    end
end

function __VelocityFns.macroVegetaEvasive()
    local VIM = game:GetService("VirtualInputManager")
    for _ = 1, 6 do
        VIM:SendKeyEvent(true, Enum.KeyCode.G, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.G, false, game)
        task.wait(0.025)
        VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        task.wait(0.025)
    end
end

function __VelocityFns.macroRikkaUptilt()
    local target = __VelocityFns.getClosestTarget()
    if not target then return end
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root or not root.CFrame then return end

    local input = __VelocityFns.getInputRemote()
    if not input then return end

    task.spawn(function()
        input:FireServer("SprintOff")
        input:FireServer("SprintOn")
        input:FireServer("SpaceOn")
        for _ = 1, 6 do
            input:FireServer("M1", {
                air = false,
                skeyreal = false,
                skeydown = true,
                running = false,
                mousehit = Mouse.Hit,
                md = Vector3.zero
            })
            task.wait(0.013)
        end
        task.wait(0.0589)
        input:FireServer("SpaceOff")
    end)

    task.wait(0.01)
    local args = {
        "UseMove",
        {
            air = true,
            neutral = true,
            campos = Camera.CFrame.Position,
            range = "2",
            ToolName = "Chuuni-charge",
            running = true,
            camdir = Camera.CFrame.LookVector,
            targ = target,
            teamtarg = target,
            mousehit = root.CFrame
        }
    }
    input:FireServer(unpack(args))
end

function __VelocityFns.macroForceUptilt()
    local input = __VelocityFns.getInputRemote()
    if not input then return end

    task.spawn(function()
        if getgenv().Macro.ForceUptilt.Jump then
            local forceJumpConfig = getgenv().Force_Jump
            __VelocityFns.forceJumpOnce({
                Enabled = true,
                Upward = forceJumpConfig and forceJumpConfig.Upward or 35
            })
            task.wait(0.01)
        end

        input:FireServer("SprintOff")
        input:FireServer("SprintOn")
        input:FireServer("SpaceOn")
        for _ = 1, 7 do
            input:FireServer("M1", {
                air = false,
                skeyreal = false,
                skeydown = true,
                running = false,
                mousehit = Mouse.Hit,
                md = Vector3.zero
            })
            task.wait(0.0135)
        end
        task.wait(0.0588)
        input:FireServer("SpaceOff")
    end)
end

function __VelocityFns.macroKiriKnife()
    if not getgenv().Macro.Kiri.Knife then
        return
    end

    local originalCFrame = Camera.CFrame
    local target = __VelocityFns.getClosestTarget()
    if not target then return end

    local root = target:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local args = {
        "UseMove",
        {
            air = true,
            neutral = true,
            campos = Camera.CFrame.Position,
            range = "2",
            ToolName = "Combat Knife",
            running = true,
            camdir = Camera.CFrame.LookVector,
            targ = target,
            teamtarg = target,
            mousehit = root.CFrame
        }
    }

    local inputRemote = __VelocityFns.getInputRemote()
    if inputRemote then
        inputRemote:FireServer(unpack(args))
    end

    task.wait(1.8)
    Camera.CFrame *= CFrame.Angles(0, math.rad(180), 0)
    task.wait(0.18)
    Camera.CFrame = originalCFrame
end

function __VelocityFns.macroZabuzaCloneHeadride()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end

    local mode = getgenv().Macro.Zabuza.Mode or "Legit"
    local inputRemote = __VelocityFns.getInputRemote()
    if not inputRemote then return end
    local target = __VelocityFns.getClosestTarget()
    if not target then return end
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    local VIM = game:GetService("VirtualInputManager")

    local function fireClone()
        inputRemote:FireServer("UseMove", {
            air = true,
            neutral = true,
            campos = Camera.CFrame.Position,
            range = "2",
            ToolName = "Water Clone",
            running = true,
            camdir = Camera.CFrame.LookVector,
            targ = target,
            teamtarg = target,
            mousehit = targetRoot and targetRoot.CFrame or (Mouse and Mouse.Hit) or CFrame.new()
        })
    end

    local function findNewClone(entitiesBefore, exclude)
        local deadline = tick() + 0.55
        while tick() < deadline do
            for _, model in ipairs(LiveFolder:GetChildren()) do
                if model:IsA("Model")
                    and model ~= character
                    and model ~= exclude
                    and not entitiesBefore[model] then
                    local human = model:FindFirstChildOfClass("Humanoid")
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if human and human.Health > 0 and hrp then
                        return model
                    end
                end
            end
            task.wait(0.025)
        end
        return nil
    end

    if mode == "Legit" then
        VIM:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        pcall(function()
            inputRemote:FireServer("SprintOn")
        end)
        task.wait(0.02)

        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        root.AssemblyLinearVelocity = Vector3.new(
            root.AssemblyLinearVelocity.X,
            math.max(root.AssemblyLinearVelocity.Y, 28),
            root.AssemblyLinearVelocity.Z
        )
        task.wait(0.031)
        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)

        task.wait(0.055)

        fireClone()
        VIM:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.021)
        VIM:SendKeyEvent(false, Enum.KeyCode.One, false, game)

        task.wait(0.2)
        VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        pcall(function()
            inputRemote:FireServer("SprintOff")
        end)
        return
    end

    local entitiesBefore = {}
    for _, model in ipairs(LiveFolder:GetChildren()) do
        if model:IsA("Model") and model ~= character then
            entitiesBefore[model] = true
        end
    end

    if getgenv().Macro.Zabuza.Auto_Perform_Jump then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 30, root.AssemblyLinearVelocity.Z)
        task.wait(0.05)
    end

    fireClone()
    local newClone = findNewClone(entitiesBefore, target)
    if not newClone then return end

    local ridePart = newClone:FindFirstChild("Head") or newClone:FindFirstChild("HumanoidRootPart")
    if not ridePart then return end

    local rideUntil = tick() + 1.0
    local rideConn
    rideConn = RunService.Heartbeat:Connect(function()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot or not ridePart.Parent or tick() > rideUntil then
            if rideConn then
                rideConn:Disconnect()
                rideConn = nil
            end
            return
        end

        local yOffset = (ridePart.Size.Y * 0.5) + (myRoot.Size.Y * 0.5) + 0.12
        local pos = ridePart.Position + Vector3.new(0, yOffset, 0)
        local look = ridePart.CFrame.LookVector
        myRoot.CFrame = CFrame.new(pos, pos + Vector3.new(look.X, 0, look.Z))
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
    end)
end

function __VelocityFns.macroStarkUptilt()
    local target = __VelocityFns.getClosestTarget()
    if not target then return end
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root or not root.CFrame then return end

    local input = __VelocityFns.getInputRemote()
    if not input then return end

    local args = {
        "UseMove",
        {
            air = true,
            neutral = true,
            campos = Camera.CFrame.Position,
            range = "2",
            ToolName = "Sonido Strike",
            running = true,
            camdir = Camera.CFrame.LookVector,
            targ = target,
            teamtarg = target,
            mousehit = root.CFrame
        }
    }
    input:FireServer(unpack(args))
    task.wait(1.89)
    task.spawn(function()
        input:FireServer("SprintOff")
        input:FireServer("SprintOn")
        input:FireServer("SpaceOn")
        for _ = 1, 6 do
            input:FireServer("M1", {
                air = false,
                skeyreal = false,
                skeydown = true,
                running = false,
                mousehit = Mouse.Hit,
                md = Vector3.zero
            })
            task.wait(0.013)
        end
        task.wait(0.0589)
        input:FireServer("SpaceOff")
    end)
end

function __VelocityFns.macroDioUptilt()
    local target = __VelocityFns.getClosestTarget()
    if not target then return end
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root or not root.CFrame then return end

    local input = __VelocityFns.getInputRemote()
    if not input then return end

    input:FireServer("SprintOff")
    input:FireServer("SprintOn")
    input:FireServer("SpaceOff")
    input:FireServer("M1", {
        air = false,
        skeyreal = false,
        skeydown = true,
        running = false,
        mousehit = Mouse.Hit,
        md = Vector3.zero
    })
    task.wait(0.3)
    input:FireServer("SprintOff")
    input:FireServer("SprintOn")
    input:FireServer("SpaceOn")
    for _ = 1, 7 do
        input:FireServer("M1", {
            air = false,
            skeyreal = false,
            skeydown = true,
            running = false,
            mousehit = Mouse.Hit,
            md = Vector3.zero
        })
        task.wait(0.013)
    end
    task.wait(0.0589)

    local args = {
        "UseMove",
        {
            air = true,
            neutral = true,
            campos = Camera.CFrame.Position,
            range = "2",
            ToolName = "Time Shift",
            running = true,
            camdir = Camera.CFrame.LookVector,
            targ = target,
            teamtarg = target,
            mousehit = root.CFrame
        }
    }
    input:FireServer(unpack(args))
end

local MacroInputConnection = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    local infinity = getgenv().Macro.InfinityBlue
    if infinity.Enabled and input.KeyCode == infinity.Key then
        task.spawn(__VelocityFns.macroInfinityBlue)
    end
    if getgenv().Macro.Gojo.TripleBlue and input.KeyCode == getgenv().Macro.Gojo.Key
        and not (infinity.Enabled and input.KeyCode == infinity.Key) then
        task.spawn(__VelocityFns.macroGojoTripleBlue)
    end

    if getgenv().Macro.Ryoko.Enabled and input.KeyCode == getgenv().Macro.Ryoko.Key then
        local VIM = game:GetService("VirtualInputManager")
        task.wait(0.0015)
        VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.0075)
        VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        task.wait(0.0075)
        VIM:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
        task.wait(0.005)
        VIM:SendKeyEvent(true, Enum.KeyCode.Four, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
    end

    if getgenv().Macro.Mob.Barrage and input.KeyCode == getgenv().Macro.Mob.Key1 then
        __VelocityFns.macroMobBarrage()
    end

    if getgenv().Macro.Mob.WeakRepel and input.KeyCode == getgenv().Macro.Mob.KeyWeakRepel then
        __VelocityFns.macroMobWeakRepel()
    end

    if getgenv().Macro.Vegeta.Evasive and input.KeyCode == getgenv().Macro.Vegeta.Key then
        __VelocityFns.macroVegetaEvasive()
    end

    if getgenv().Macro.Rikka.Uptilt and input.KeyCode == getgenv().Macro.Rikka.Key then
        __VelocityFns.macroRikkaUptilt()
    end

    if getgenv().Macro.ForceUptilt.Enabled and input.KeyCode == getgenv().Macro.ForceUptilt.Key then
        __VelocityFns.macroForceUptilt()
    end

    if getgenv().Macro.Stark.Uptilt and input.KeyCode == getgenv().Macro.Stark.Key then
        __VelocityFns.macroStarkUptilt()
    end

    if getgenv().Macro.Dio.Uptilt and input.KeyCode == getgenv().Macro.Dio.Key then
        __VelocityFns.macroDioUptilt()
    end

    if getgenv().Macro.Kiri.Knife and input.KeyCode == getgenv().Macro.Kiri.Key then
        __VelocityFns.macroKiriKnife()
    end

    if getgenv().Macro.Zabuza.Clone and input.KeyCode == getgenv().Macro.Zabuza.Key then
        __VelocityFns.macroZabuzaCloneHeadride()
    end
end)

local Allconns = Runtime.connections
local currentConnection = nil

function __VelocityFns.disconnectCurrentConnection()
    if currentConnection then
        safeDisconnect(currentConnection)
        currentConnection = nil
    end
end

function __VelocityFns.mouse1Click()
    local VIM = nil
    pcall(function()
        VIM = game:GetService("VirtualInputManager")
    end)
    local cam = Workspace.CurrentCamera
    if not VIM or not cam then
        return
    end

    local viewport = cam.ViewportSize
    VIM:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, true, game, 0)
    task.wait()
    VIM:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, false, game, 0)
end

function __VelocityFns.setupCutter()
    __VelocityFns.disconnectCurrentConnection()
    local clicked = false
    local lastClick = 0
    local cooldown = 0.25
    currentConnection = RunService.PreRender:Connect(function()
        local config = getgenv().BlackFlash
        if not config or not config.Nanami then return end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local cutGui = root and root:FindFirstChild("NanamiCutGUI")
        local mainBar = cutGui and cutGui:FindFirstChild("MainBar")
        local cutter = mainBar and mainBar:FindFirstChild("Cutter")
        local goal = mainBar and mainBar:FindFirstChild("Goal")
        if not cutter or not goal then
            clicked = false
            return
        end
        if math.abs(cutter.Position.X.Scale - goal.Position.X.Scale) > 0.005 then
            clicked = false
            return
        end
        local now = os.clock()
        if clicked or now - lastClick < cooldown then return end
        clicked = true
        lastClick = now
        if math.random(100) <= (tonumber(config.Nanami_Hitchance) or 100) then
            task.spawn(__VelocityFns.mouse1Click)
        end
    end)
end

function __VelocityFns.updateCutterState()
    local config = getgenv().BlackFlash
    if config and config.Nanami then
        if not currentConnection then
            __VelocityFns.setupCutter()
        end
    else
        __VelocityFns.disconnectCurrentConnection()
    end
end

if LocalPlayer and LocalPlayer.Character then
    __VelocityFns.updateCutterState()
    if getgenv().BlackFlash and not getmetatable(getgenv().BlackFlash) then
        setmetatable(getgenv().BlackFlash, {
            __newindex = function(t, k, v)
                rawset(t, k, v)
                if k == "Nanami" then
                    __VelocityFns.updateCutterState()
                end
            end,
        })
    end
end

if typeof(LocalPlayer.CharacterAdded) == "RBXScriptSignal" then
    registerConnection(LocalPlayer.CharacterAdded:Connect(function()
        __VelocityFns.updateCutterState()
    end))
end


local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Interface & Privacy")
MenuGroup:AddToggle("Streamproof", {
    Text = "Streamproof (hide UI + overlays)",
    Default = getgenv().UI.Streamproof,
    Tooltip = "Hides menu on load and hides Drawing/ESP/indicator overlays so they are less likely to show on stream. Does not hide the Roblox game itself from game capture.",
    Callback = function(value)
        getgenv().UI.Streamproof = value
        if value then
            pcall(function()
                if Library.Toggled or (Window.Holder and Window.Holder.Visible) then
                    Library:Toggle()
                end
            end)
        end
        __VelocityFns.applyStreamproofVisuals()
        if not value then
            __VelocityFns.updateFovCircle()
            if type(__VelocityFns.refreshIndicator) == "function" then
                __VelocityFns.refreshIndicator()
            end
        end
    end
})

local PerfGroup = Tabs["UI Settings"]:AddRightGroupbox("Graphics & Frame Rate")
getgenv().Performance = getgenv().Performance or {
    NoRender = false,
    Quality = 0,
    FpsCap = 0,
}

local function applyQualityLevel(value)
    local quality = math.floor(clamp(tonumber(value) or 0, 0, 10))
    local qualityName = quality == 10 and "Level10" or string.format("Level%02d", math.max(quality, 1))
    pcall(function()
        local rendering = settings().Rendering
        if quality <= 0 then
            rendering.QualityLevel = Enum.QualityLevel.Automatic
        else
            rendering.QualityLevel = Enum.QualityLevel[qualityName] or Enum.QualityLevel.Level01
        end
    end)
end

PerfGroup:AddToggle("NoRender", {
    Text = "Low detail (quality floor)",
    Default = getgenv().Performance.NoRender,
    Tooltip = "Forces lowest rendering quality via Roblox client settings.",
    Callback = function(value)
        getgenv().Performance.NoRender = value
        if value then
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
        else
            applyQualityLevel(getgenv().Performance.Quality)
        end
    end
})

PerfGroup:AddSlider("GraphicsQuality", {
    Text = "Quality Level",
    Default = getgenv().Performance.Quality,
    Min = 0,
    Max = 10,
    Rounding = 0,
    Tooltip = "0 = Automatic. 1-10 maps to QualityLevel when NoRender is off.",
    Callback = function(value)
        getgenv().Performance.Quality = value
        if not getgenv().Performance.NoRender then
            applyQualityLevel(value)
        end
    end
})

PerfGroup:AddToggle("VelocityStabilityMode", {
    Text = "Stability Mode (recommended)",
    Default = getgenv().Performance.StabilityMode,
    Tooltip = "Coalesces controller HUD image updates and reduces unused UI work. Does not change camera tracking or mouse tilt.",
    Callback = function(value)
        getgenv().Performance.StabilityMode = value
    end
})

PerfGroup:AddSlider("VelocityEspUpdateInterval", {
    Text = "ESP Refresh Interval",
    Default = getgenv().Performance.EspUpdateInterval,
    Min = 0.12,
    Max = 0.5,
    Rounding = 2,
    Suffix = " s",
    Tooltip = "When Stability Mode is on, higher values reduce ESP CPU cost but refresh overlays less often. 0.25 is recommended.",
    Callback = function(value)
        getgenv().Performance.EspUpdateInterval = value
    end
})

PerfGroup:AddSlider("FpsCap", {
    Text = "FPS Cap",
    Default = getgenv().Performance.FpsCap,
    Min = 0,
    Max = 240,
    Rounding = 0,
    Tooltip = "0 = no cap. Uses executor setfpscap when available.",
    Callback = function(value)
        getgenv().Performance.FpsCap = value
        pcall(function()
            if typeof(setfpscap) == "function" then
                setfpscap(value <= 0 and 999 or value)
            end
        end)
    end
})


;(function()
    local modeHud = (function()
        local modeGroup = Tabs.Player:AddRightGroupbox("Xbox • Awakening HUD")
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local enabled = false
        local listening = false
        local lastRefresh = 0
        local records = {}
        local addedConnection
        local heartbeatConnection
        local overlay = Instance.new("ScreenGui")
        overlay.Name = "VelocityModeDPadOverlay"
        overlay.ResetOnSpawn = false
        overlay.IgnoreGuiInset = false
        overlay.DisplayOrder = 50
        overlay.Enabled = false
        local previous = playerGui:FindFirstChild(overlay.Name)
        if previous then safeDestroy(previous) end
        overlay.Parent = playerGui

        local function visibleThroughAncestors(label)
            if not label or not label.Parent or not label.Visible then return false end
            local ancestor = label.Parent
            while ancestor and ancestor ~= playerGui do
                if ancestor:IsA("GuiObject") and not ancestor.Visible then return false end
                if ancestor:IsA("ScreenGui") and not ancestor.Enabled then return false end
                ancestor = ancestor.Parent
            end
            return ancestor == playerGui
        end

        local function findBar(label)
            local viewport = Camera and Camera.ViewportSize
            local xLimit = viewport and math.min(90, viewport.X * 0.08) or 90
            local position, size = label.AbsolutePosition, label.AbsoluteSize
            local rotation = (label.Rotation or 0) % 180
            local nearSide = position.X <= xLimit and (size.Y >= 90 or math.abs(rotation - 90) < 12)
            local node = label.Parent
            local horizontal, hScore = nil, math.huge
            local vertical, vScore = nil, math.huge
            for depth = 1, 10 do
                if not node or node == playerGui then break end
                if node:IsA("GuiObject") then
                    local p, s = node.AbsolutePosition, node.AbsoluteSize
                    if p.X >= -18 and p.X <= xLimit and s.X >= 18 and s.X <= 95
                        and s.Y >= 140 and s.Y >= s.X * 3 then
                        local score = math.abs(s.X - 36) + depth
                        if score < vScore then vertical, vScore = node, score end
                    end
                    if s.X >= 180 and s.Y >= 12 and s.Y <= 95 then
                        local score = math.abs(s.Y - 34) + depth * 2
                        if score < hScore then horizontal, hScore = node, score end
                    end
                end
                node = node.Parent
            end
            local side = nearSide or (vertical ~= nil and position.X < vertical.AbsolutePosition.X + vertical.AbsoluteSize.X + 38)
            return side, side and (vertical or label) or (horizontal or label)
        end

        local function rewritePrompt(label, rec, side)
            if rec.Writing or not label.Parent then return end
            local current = label.Text
            if current:find("PRESS G", 1, true) then
                rec.Original = current
            elseif rec.Applied and current ~= rec.Applied then
                rec.Original = current
                rec.Applied = nil
            end
            local replacement = side and "PRESS UP" or "D-PAD UP"
            local newText = current
            if current:find("PRESS G", 1, true) then
                newText = current:gsub("PRESS G", replacement)
            elseif current:find("D-PAD UP", 1, true) and side then
                newText = current:gsub("D-PAD UP", replacement)
            elseif current:find("PRESS UP", 1, true) and not side then
                newText = current:gsub("PRESS UP", replacement)
            end
            if newText ~= current then
                rec.Writing = true
                label.Text = newText
                rec.Writing = false
                rec.Applied = newText
            end
            rec.Side = side
        end

        local function removePrompt(label, rec, restore)
            if rec.Connection then safeDisconnect(rec.Connection); rec.Connection = nil end
            if restore and label.Parent and rec.Applied and label.Text == rec.Applied then
                rec.Writing = true
                label.Text = rec.Original
                rec.Writing = false
            end
            if rec.Icon then safeDestroy(rec.Icon); rec.Icon = nil end
            records[label] = nil
        end

        local function watchPrompt(label)
            if not listening or not label or not label.Parent then return end
            if not (label:IsA("TextLabel") or label:IsA("TextButton")) or records[label] then return end
            local content = label.Text
            if not (content:find("PRESS G", 1, true)
                or content:find("PRESS UP", 1, true)
                or content:find("D-PAD UP", 1, true)) then return end
            local rec = { Original = content, Writing = false, Side = nil }
            records[label] = rec
            rec.Connection = label:GetPropertyChangedSignal("Text"):Connect(function()
                if not listening or rec.Writing then return end
                local newContent = label.Text
                if newContent:find("PRESS G", 1, true)
                    or newContent:find("PRESS UP", 1, true)
                    or newContent:find("D-PAD UP", 1, true) then
                    local side = findBar(label)
                    rewritePrompt(label, rec, side)
                else
                    rec.Original = newContent
                    rec.Applied = nil
                    if rec.Icon then rec.Icon.Visible = false end
                end
            end)
            local side = findBar(label)
            rewritePrompt(label, rec, side)
        end

        local function startTracking()
            if listening then return end
            listening = true
            for _, item in ipairs(playerGui:GetDescendants()) do
                watchPrompt(item)
            end
            addedConnection = playerGui.DescendantAdded:Connect(function(item)
                if not listening then return end
                if item:IsA("TextLabel") or item:IsA("TextButton") then
                    watchPrompt(item)
                end
            end)
        end

        local function stopTracking()
            if addedConnection then safeDisconnect(addedConnection); addedConnection = nil end
            listening = false
            for label, rec in pairs(records) do
                removePrompt(label, rec, true)
            end
            if overlay.Enabled then overlay.Enabled = false end
        end

        local function refresh()
            local active = enabled and __VelocityFns.isPhysicalControllerConnected()
            if not active then
                if listening then stopTracking() end
                return
            end
            if not listening then startTracking() end
            local now = os.clock()
            if now - lastRefresh < 0.35 then return end
            lastRefresh = now
            if overlay.Parent ~= playerGui then overlay.Parent = playerGui end
            local visibleCount = 0
            for label, rec in pairs(records) do
                if not label:IsDescendantOf(playerGui) then
                    removePrompt(label, rec, false)
                else
                    local show = visibleThroughAncestors(label)
                        and (label.Text:find("PRESS UP", 1, true)
                            or label.Text:find("D-PAD UP", 1, true))
                    if show then
                        local side, bar = findBar(label)
                        if side ~= rec.Side then rewritePrompt(label, rec, side) end
                        if not rec.Icon then
                            local icon = Instance.new("ImageLabel")
                            icon.Name = "DPadUpForMode"
                            icon.BackgroundTransparency = 1
                            icon.Image = "rbxasset://textures/ui/Controls/XboxController/DPadUp@3x.png"
                            icon.ScaleType = Enum.ScaleType.Fit
                            icon.ImageColor3 = Color3.fromRGB(216, 219, 226)
                            icon.ImageTransparency = 0.06
                            icon.ZIndex = 20
                            icon.Parent = overlay
                            rec.Icon = icon
                        end
                        local icon = rec.Icon
                        local p, s = bar.AbsolutePosition, bar.AbsoluteSize
                        local size = side and UDim2.fromOffset(44, 44) or UDim2.fromOffset(56, 56)
                        local position
                        if side then
                            position = UDim2.fromOffset(math.floor(math.max(0, p.X + s.X) + 16),
                                math.floor(p.Y + s.Y / 2 - 22))
                        else
                            position = UDim2.fromOffset(math.floor(p.X + s.X / 2 - 28),
                                math.floor(p.Y + s.Y + 14))
                        end
                        if icon.Size ~= size then icon.Size = size end
                        if icon.Position ~= position then icon.Position = position end
                        if not icon.Visible then icon.Visible = true end
                        visibleCount += 1
                    elseif rec.Icon and rec.Icon.Visible then
                        rec.Icon.Visible = false
                    end
                end
            end
            local shouldShow = visibleCount > 0
            if overlay.Enabled ~= shouldShow then overlay.Enabled = shouldShow end
        end

        modeGroup:AddToggle("ReforgedConsoleModePrompt", {
            Text = "Xbox D-Pad Up Mode Prompt", Default = false,
            Tooltip = "Shows the Xbox Mode prompt beside the mode bar. Scans the HUD once on enable; does no scanning when off.",
            Callback = function(value)
                enabled = value == true
                if enabled then
                    lastRefresh = -math.huge
                    if not heartbeatConnection then
                        local elapsed = 0
                        heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
                            elapsed += dt
                            if elapsed < 0.40 then return end
                            elapsed = 0
                            refresh()
                        end)
                    end
                elseif heartbeatConnection then
                    safeDisconnect(heartbeatConnection)
                    heartbeatConnection = nil
                end
                refresh()
            end
        })
        return {
            Refresh = refresh,
            Destroy = function()
                if heartbeatConnection then
                    safeDisconnect(heartbeatConnection)
                    heartbeatConnection = nil
                end
                stopTracking()
                safeDestroy(overlay)
            end
        }
    end)()
    __VelocityFns.refreshModePrompt = modeHud.Refresh
    table.insert(Runtime.cleanup, modeHud.Destroy)
end)()

;(function()
    local unloadButton = MenuGroup:AddButton("Unload", function()
        Library:Unload()
    end)
    unloadButton:AddTooltip("Stops the script and runs its cleanup handler.")
    local menuBindLabel = MenuGroup:AddLabel("Menu bind")
    menuBindLabel:AddKeyPicker("MenuKeybind", { Default = "LeftAlt", NoUI = true, Text = "Menu keybind" })
    __VelocityFns.addKeyPickerTooltip(menuBindLabel, "Choose the key used to open or close the menu.")
end)()

Library.ToggleKeybind = Options and Options.MenuKeybind or nil

Library:OnUnload(function()
    for _, fn in ipairs(Runtime.cleanup) do pcall(fn) end
    __VelocityFns.cleanupAttach()
    if AimbotRenderStepBound then
        RunService:UnbindFromRenderStep(AimbotRenderStepName)
        AimbotRenderStepBound = false
    end
    if FovDrawConnection then
        safeDisconnect(FovDrawConnection)
        FovDrawConnection = nil
    end
    LockedAimbotTarget = nil
    if FovCircle then
        pcall(function() FovCircle:Remove() end)
        FovCircle = nil
    end
    safeDestroy(indGui)
    getgenv().__AutoParryIndicatorLbl = nil
    if AttachKeyConn then
        safeDisconnect(AttachKeyConn)
        AttachKeyConn = nil
    end
    if AttachCharacterConn then
        safeDisconnect(AttachCharacterConn)
        AttachCharacterConn = nil
    end
    if healthConnection then
        safeDisconnect(healthConnection)
        healthConnection = nil
    end
    if inputChildConnection then
        safeDisconnect(inputChildConnection)
        inputChildConnection = nil
    end
    if inputRemovedConnection then
        safeDisconnect(inputRemovedConnection)
        inputRemovedConnection = nil
    end
    if backpackChildConnection then
        safeDisconnect(backpackChildConnection)
        backpackChildConnection = nil
    end
    if backpackRemovedConnection then
        safeDisconnect(backpackRemovedConnection)
        backpackRemovedConnection = nil
    end
    if autoParryCharacterConnection then
        safeDisconnect(autoParryCharacterConnection)
        autoParryCharacterConnection = nil
    end
    if forceJumpBeganConn then
        safeDisconnect(forceJumpBeganConn)
        forceJumpBeganConn = nil
    end
    if forceJumpEndedConn then
        safeDisconnect(forceJumpEndedConn)
        forceJumpEndedConn = nil
    end
    if forceJumpCharacterConn then
        safeDisconnect(forceJumpCharacterConn)
        forceJumpCharacterConn = nil
    end
    if MacroInputConnection then
        safeDisconnect(MacroInputConnection)
        MacroInputConnection = nil
    end
    for _, connection in ipairs(Allconns) do
        safeDisconnect(connection)
    end
    __VelocityFns.disconnectCurrentConnection()
    for _, connection in pairs(ESPPlayerConnections) do
        safeDisconnect(connection)
    end
    if espUpdateConnection then
        safeDisconnect(espUpdateConnection)
        espUpdateConnection = nil
    end
    for _, entry in pairs(ESPObjects) do
        if entry.Connection then
            safeDisconnect(entry.Connection)
        end
        if entry.Gui then
            safeDestroy(entry.Gui)
        end
    end
    for _, connection in ipairs(MiscConnections) do
        safeDisconnect(connection)
    end
    for _, connection in ipairs(Runtime.connections) do safeDisconnect(connection) end

    if _G.__AimbotMouseConn then
        safeDisconnect(_G.__AimbotMouseConn)
    end
    if _G.__AimbotMouseConn2 then
        safeDisconnect(_G.__AimbotMouseConn2)
    end
    if _G.__VelocityAimFocusConn then
        safeDisconnect(_G.__VelocityAimFocusConn)
        _G.__VelocityAimFocusConn = nil
    end
    if _G.__VelocityAimRespawnConn then
        safeDisconnect(_G.__VelocityAimRespawnConn)
        _G.__VelocityAimRespawnConn = nil
    end
    __VelocityFns.restoreAimbotCharacterRotation()
    __VelocityFns.clearAimbotSelectionBoxSafely()
    table.clear(ESPPlayerConnections)
    table.clear(ESPObjects)
    table.clear(MiscConnections)
    table.clear(Allconns)
    getgenv().__UWUFriendEditionLoaded = nil
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("uwu_friend")
SaveManager:SetFolder("uwu_friend/ABA")

pcall(function()
    if isfolder and makefolder and not isfolder("uwu_friend/ABA/Macros") then
        makefolder("uwu_friend/ABA/Macros")
    end
end)

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])


Toggles.AimbotEnabled:OnChanged(function()
    __VelocityFns.startAimbot()
end)
Options.AimbotInputMode:OnChanged(function()
    __VelocityFns.startAimbot()
end)
Options.AimbotFOV:OnChanged(function()
    __VelocityFns.updateFovCircle()
end)
Toggles.AimbotShowFov:OnChanged(function()
    __VelocityFns.updateFovCircle()
end)

Toggles.AttachToBackEnabled:OnChanged(function(value)
    NewAttachConfig.Enabled = value
end)
Toggles.AttachNPC:OnChanged(function(value)
    NewAttachConfig.NPC = value
end)
Toggles.AttachIgnoreTeammates:OnChanged(function(value)
    NewAttachConfig.IgnoreTeammates = value
end)
Options.AttachBone:OnChanged(function(value)
    NewAttachConfig.Bone = value
end)
Options.AttachMaxDist:OnChanged(function(value)
    NewAttachConfig.MaxAttachDistance = value
end)

Toggles.AutoParryEnabled:OnChanged(function(value)
    __VelocityFns.setAutoParryEnabled(value)
    __VelocityFns.refreshIndicator()
end)
Toggles.AutoParryIndicator:OnChanged(function(value)
    getgenv().AutoParry.Indicator.Visible = value
    __VelocityFns.refreshIndicator()
end)

if getgenv().AimbotSettings.Enabled then
    __VelocityFns.startAimbot()
end

__VelocityFns.attachToBackLoad()


;(function()
    local cfg = ensureGlobalTable("DownslamAssist", {
        Enabled = false,
        FinisherHit = 5,
        ResetSeconds = 1.35,
    })
    local group = Tabs.Main:AddLeftGroupbox("M1 • Air Finisher")
    local label = group:AddLabel("Air finisher: Space-release assist ready")
    local hits, lastClick, previousCharacter = 0, 0, nil
    local alive = true

    local function isAirborne()
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end
        local state = humanoid:GetState()
        return state == Enum.HumanoidStateType.Jumping
            or state == Enum.HumanoidStateType.Freefall
            or state == Enum.HumanoidStateType.FallingDown
            or humanoid.FloorMaterial == Enum.Material.Air
    end

    local function resetCounts()
        hits, lastClick = 0, 0
        previousCharacter = LocalPlayer.Character
    end

    local function updateStatus(message)
        if alive and label then label:SetText(message) end
    end

    local function releaseForFinisher()
        __VelocityFns.fireInput("SpaceOff")
        task.delay(0.11, function()
            if alive and LocalPlayer.Character and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                __VelocityFns.fireInput("SpaceOn")
            end
        end)
    end

    group:AddToggle("VelocityAutoDownslam", {
        Text = "Air Downslam / Ground Kickaway",
        Default = cfg.Enabled == true,
        Tooltip = "Sends SpaceOff before the last airborne M1, without adding a second attack. Ground combos stay unchanged.",
        Callback = function(value)
            cfg.Enabled = value
            resetCounts()
            updateStatus(value and "Air finisher: Space-release assist on" or "Air finisher: off")
        end
    })
    group:AddDropdown("VelocityDownslamHit", {
        Text = "Finisher M1 Number",
        Values = { "5", "4" },
        Default = cfg.FinisherHit == 4 and 2 or 1,
        Multi = false,
        Tooltip = "Choose which M1 is the aerial finisher; five is the usual full combo, four supports shorter strings.",
        Callback = function(value)
            cfg.FinisherHit = tonumber(value) or 5
            resetCounts()
        end
    })
    local inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if not alive or not cfg.Enabled or processed
            or input.UserInputType ~= Enum.UserInputType.MouseButton1
            or UserInputService:GetFocusedTextBox() then return end
        local now = os.clock()
        local character = LocalPlayer.Character
        if character ~= previousCharacter or now - lastClick > math.clamp(tonumber(cfg.ResetSeconds) or 1.35, 0.6, 2.5) then
            hits = 0
        end
        previousCharacter = character
        lastClick = now
        hits = (hits % 5) + 1
        if isAirborne() then
            if hits == cfg.FinisherHit - 1 then
                task.defer(function()
                    if alive and cfg.Enabled and isAirborne() then
                        __VelocityFns.fireInput("SpaceOff")
                    end
                end)
            elseif hits == cfg.FinisherHit then
                releaseForFinisher()
                updateStatus("Air finisher: Space released")
            end
        elseif hits == cfg.FinisherHit then
            updateStatus("Ground finisher: unchanged kickaway")
        end
    end)
    local characterConnection = LocalPlayer.CharacterAdded:Connect(resetCounts)
    table.insert(Runtime.cleanup, function()
        alive = false
        safeDisconnect(inputConnection)
        safeDisconnect(characterConnection)
    end)
end)()

local autoloadOk, autoloadErr = pcall(function() SaveManager:LoadAutoloadConfig() end)
if not autoloadOk then warn("[UWU] Config autoload error:", autoloadErr) end
getgenv().__UWUFriendEditionLoaded = true
