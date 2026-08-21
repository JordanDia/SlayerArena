--!strict

const ContextActionService = game:GetService("ContextActionService")
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const UserInputService = game:GetService("UserInputService")

const Dash = require(ReplicatedStorage.Shared.Combat.Data.Dash)
const DoubleJump = require(ReplicatedStorage.Shared.Combat.Data.DoubleJump)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)

const Player = Players.LocalPlayer

--[[
    Which way the player is pushing, in world space, relative to the camera.

    Not Humanoid.MoveDirection: that is zero whenever WalkSpeed is zero, and
    MovementLockSystem zeroes WalkSpeed during attacks, blocks and suspends - exactly
    the moments a dash or air jump matters. Reading the keys directly keeps the answer
    available regardless of whether the character is currently allowed to walk.
]]
local function GetCameraMoveDirection(): Vector3
    const camera = workspace.CurrentCamera
    if not camera then return Vector3.zero end

    const cframe = camera.CFrame
    const forward = Vector3.new(cframe.LookVector.X, 0, cframe.LookVector.Z)
    const right = Vector3.new(cframe.RightVector.X, 0, cframe.RightVector.Z)

    -- Camera pointed straight up or down flattens to nothing.
    if forward.Magnitude < 0.001 or right.Magnitude < 0.001 then return Vector3.zero end

    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        move += forward.Unit
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        move -= forward.Unit
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        move += right.Unit
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        move -= right.Unit
    end

    if move.Magnitude < 0.001 then return Vector3.zero end
    return move.Unit
end

--[[
    The same direction expressed in the character's own space, which is what the server
    resolves the byte against. Nil when there is no input or no character.
]]
local function GetLocalMoveDirection(): Vector3?
    const move = GetCameraMoveDirection()
    if move.Magnitude < 0.001 then return nil end

    const character = Player.Character
    if not character then return nil end

    const root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return nil end

    return root.CFrame:VectorToObjectSpace(move)
end

const CombatInputController = {}

function CombatInputController:Start()

    const function Attack(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject): Enum.ContextActionResult?
        if inputState ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end

        Packets.AttackRequest.send()
        return Enum.ContextActionResult.Sink
    end

    const function Block(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject): Enum.ContextActionResult?
        if inputState == Enum.UserInputState.Begin then
            Packets.BlockRequest.send(true)
        elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
            Packets.BlockRequest.send(false)
        end

        return Enum.ContextActionResult.Sink
    end

    const function Uptilt(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject): Enum.ContextActionResult?
        if inputState == Enum.UserInputState.Begin then
            Packets.UptiltRequest.send(true)
        elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
            Packets.UptiltRequest.send(false)
        end

        return Enum.ContextActionResult.Pass
    end

    const function Grab(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject): Enum.ContextActionResult?
        if inputState ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end

        Packets.GrabRequest.send()
        return Enum.ContextActionResult.Sink
    end

    -- Spot dodge is temporarily disabled. The server systems are untouched;
    -- rebind this action to bring it back.
    -- const function Dodge(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject): Enum.ContextActionResult?
    --     if inputState ~= Enum.UserInputState.Begin then
    --         return Enum.ContextActionResult.Pass
    --     end
    --
    --     Packets.DodgeRequest.send()
    --     return Enum.ContextActionResult.Sink
    -- end

    -- Snap the camera-relative input to whichever of the four character-relative kinds
    -- points most nearly the same way. Quantising here rather than sending a raw vector
    -- keeps the byte protocol, keeps the server authoritative over what a dash may be,
    -- and keeps each kind paired with its own animation.
    const function GetDashKind(): Dash.DashKind
        const localMove = GetLocalMoveDirection()
        if not localMove then return "Forward" end

        local bestKind: Dash.DashKind = "Forward"
        local bestDot = -math.huge

        for kind, direction in Dash.DirectionMap do
            const dot = localMove:Dot(direction)
            if dot > bestDot then
                bestDot = dot
                bestKind = kind
            end
        end

        return bestKind
    end

    const function DashAction(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject): Enum.ContextActionResult?
        if inputState ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end

        Packets.DashRequest.send({
            Kind = Dash.ReverseMap[GetDashKind()],
            Direction = GetCameraMoveDirection(),
        })
        return Enum.ContextActionResult.Sink
    end

    ContextActionService:BindAction("M1", Attack, true, Enum.UserInputType.MouseButton1)
    ContextActionService:BindAction("Block", Block, true, Enum.KeyCode.F)
    ContextActionService:BindAction("Uptitle", Uptilt, true, Enum.KeyCode.Space)
    ContextActionService:BindAction("Grab", Grab, true, Enum.KeyCode.G)
    -- ContextActionService:BindAction("Dodge", Dodge, true, Enum.KeyCode.E)
    const function GetDoubleJumpKind(): DoubleJump.DoubleJumpKind
        const localMove = GetLocalMoveDirection()
        if not localMove then return "Neutral" end

        local bestKind: DoubleJump.DoubleJumpKind = "Neutral"
        local bestDot = -math.huge

        for kind, direction in DoubleJump.DirectionMap do
            -- Neutral is the zero vector; it is the no-input fallback, never a match.
            if direction.Magnitude < 0.001 then continue end

            const dot = localMove:Dot(direction)
            if dot > bestDot then
                bestDot = dot
                bestKind = kind
            end
        end

        return bestKind
    end

    UserInputService.JumpRequest:Connect(function()
        Packets.DoubleJumpRequest.send({
            Kind = DoubleJump.ReverseMap[GetDoubleJumpKind()],
            Direction = GetCameraMoveDirection(),
        })
    end)

    ContextActionService:BindAction("Dash", DashAction, true, Enum.KeyCode.Q)
end

return CombatInputController