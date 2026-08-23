--!strict
const ContentProvider = game:GetService("ContentProvider")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const SoundService = game:GetService("SoundService")

const Packets = require(ReplicatedStorage.Shared.Combat.Packets)
const SoundManifest = require(ReplicatedStorage.Shared.Combat.Data.SoundManifest)

const PITCH_VARIANCE = 0.05
const REPEAT_WINDOW = 0.05
const CLEANUP_PADDING = 1

const templates: { [SoundManifest.SoundKind]: Sound } = {}
const lastPlayed: { [Model]: { [SoundManifest.SoundKind]: number } } = {}

const SoundController = {}

function SoundController:Init()
    const sfxFolder = SoundService:FindFirstChild("SFX")
    if not sfxFolder then
        warn("Cannot find SoundService.SFX")
        return
    end

    for _, soundKind in SoundManifest.ByteMap do
        const template = sfxFolder:FindFirstChild(soundKind)
        if not template then
            warn(`No sound asset for kind: { soundKind }`)
            continue
        end
        if not template:IsA("Sound") then
            warn(`Sound asset is not a Sound: { soundKind }`)
            continue
        end

        templates[soundKind] = template
    end

    task.spawn(function()
        const assets: { Instance } = {}
        for _, template in templates do
            table.insert(assets, template)
        end

        if #assets == 0 then return end
        ContentProvider:PreloadAsync(assets)
    end)
end

function SoundController:Start()
    Packets.Sound.listen(function(data: Packets.SoundPayload)
        if not data.Character then return end
        if not data.Character:IsA("Model") then return end
        if not data.Kind then return end

        const soundKind: SoundManifest.SoundKind = SoundManifest.ByteMap[data.Kind]
        if not soundKind then return end

        self:_Play(data.Character, soundKind)
    end)
end

function SoundController:_Play(character: Model, soundKind: SoundManifest.SoundKind)
    const template = templates[soundKind]
    if not template then return end

    const root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not root:IsA("BasePart") then return end

    if self:_IsRepeat(character, soundKind) then return end

    const sound = template:Clone()
    sound.PlaybackSpeed = template.PlaybackSpeed * (1 + (math.random() - 0.5) * 2 * PITCH_VARIANCE)
    sound.Parent = root
    sound:Play()

    sound.Ended:Once(function()
        sound:Destroy()
    end)

    -- TimeLength is zero until the asset loads, so the backup cleanup needs a floor
    const lifetime = math.max(sound.TimeLength, 1) + CLEANUP_PADDING
    task.delay(lifetime, function()
        if not sound.Parent then return end
        sound:Destroy()
    end)
end

function SoundController:_IsRepeat(character: Model, soundKind: SoundManifest.SoundKind): boolean
    const now = os.clock()
    local played = lastPlayed[character]

    if not played then
        played = {}
        lastPlayed[character] = played

        character.Destroying:Once(function()
            lastPlayed[character] = nil
        end)
    end
    assert(played, "unreachable")

    const previous = played[soundKind]
    if previous and now - previous < REPEAT_WINDOW then
        return true
    end

    played[soundKind] = now
    return false
end

return SoundController
