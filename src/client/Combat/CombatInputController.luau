--!strict

const ContextActionService = game:GetService("ContextActionService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const UserInputService = game:GetService("UserInputService")

const Dash = require(ReplicatedStorage.Shared.Combat.Data.Dash)
const DoubleJump = require(ReplicatedStorage.Shared.Combat.Data.DoubleJump)
const Packets = require(ReplicatedStorage.Shared.Combat.Packets)

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

    const function GetDashKind(): Dash.DashKind
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then return "Forward" end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then return "Back" end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then return "Left" end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then return "Right" end

        return "Forward"
    end

    const function DashAction(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject): Enum.ContextActionResult?
        if inputState ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Pass
        end

        Packets.DashRequest.send(Dash.ReverseMap[GetDashKind()])
        return Enum.ContextActionResult.Sink
    end

    ContextActionService:BindAction("M1", Attack, true, Enum.UserInputType.MouseButton1)
    ContextActionService:BindAction("Block", Block, true, Enum.KeyCode.F)
    ContextActionService:BindAction("Grab", Grab, true, Enum.KeyCode.G)
    -- ContextActionService:BindAction("Dodge", Dodge, true, Enum.KeyCode.E)
    const function GetDoubleJumpKind(): DoubleJump.DoubleJumpKind
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then return "Forward" end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then return "Back" end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then return "Left" end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then return "Right" end

        return "Neutral"
    end

    UserInputService.JumpRequest:Connect(function()
        Packets.DoubleJumpRequest.send(DoubleJump.ReverseMap[GetDoubleJumpKind()])
    end)

    ContextActionService:BindAction("Dash", DashAction, true, Enum.KeyCode.Q)
end

return CombatInputController