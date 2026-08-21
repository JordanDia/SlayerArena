--!strict

export type ReactionKind = "Light" | "Heavy" | "Launch" | "GuardBreak" | "Grab" | "Parried"

export type ReactionAnimation = {
    read Id: string,
    read Looped: boolean,
}

const Reactions: { [ReactionKind]: ReactionAnimation } = {
    Light = { Id = "rbxassetid://109510042993792", Looped = false },
    Heavy = { Id = "rbxassetid://109510042993792", Looped = false },
    Launch = { Id = "rbxassetid://109510042993792", Looped = false },
    Grab = { Id = "rbxassetid://109510042993792", Looped = false },
    GuardBreak = { Id = "rbxassetid://109510042993792", Looped = false },
    Parried = { Id = "rbxassetid://87767349193816", Looped = true },
}

return table.freeze(Reactions)
