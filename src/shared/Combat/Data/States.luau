--!strict

export type StateAnimation = {
    read Id: string,
    read Looped: boolean,
    read Priority: Enum.AnimationPriority
}

const States: { [string]: StateAnimation } = {
    Block = {
        Id = "rbxassetid://132704584767861",
        Looped = true,
        Priority = Enum.AnimationPriority.Action
    }
}

return table.freeze(States)