--!strict
--[[
    ========================================================================
    ECONOMY DATA TYPES (LUAU STRICT TYPING)
    ========================================================================
--]]

export type InventoryItem = {
    Id: string,
    Quantity: number,
    ItemKey: string, -- Unique identifier in inventory
}

export type PlayerEconomyData = {
    Cash: number,
    Bank: number,
    JobId: string,
    JobExperience: number,
    Inventory: { [string]: InventoryItem },
    LastPaydayTimestamp: number,
    TotalEarned: number,
    TotalSpent: number,
    TotalTaxPaid: number,
}

export type TradeOffer = {
    Cash: number,
    Items: { [string]: number }, -- ItemId -> Quantity
    IsLocked: boolean,
    IsConfirmed: boolean,
}

export type TradeSession = {
    SessionId: string,
    Player1: Player,
    Player2: Player,
    Offer1: TradeOffer,
    Offer2: TradeOffer,
    CreatedAt: number,
    LastInteractionAt: number,
    Status: "Pending" | "Trading" | "Locked" | "Confirmed" | "Completed" | "Cancelled",
}

return {}
