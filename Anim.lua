local idToInstance = {}

local _getUID = function()
    return game:GetService("HttpService"):GenerateGUID(false)
end

local function SpoofTable(tbl)
    local ids = {}
    for _, v in ipairs(tbl) do
        if typeof(v) == "Instance" and v:IsA("Animation") then
            local animID = v.AnimationId:match("%d+")
            if animID then
                idToInstance[animID] = idToInstance[animID] or {}
                table.insert(idToInstance[animID], v)
				table.insert(ids, {v.Name, animID})
            end
        end
    end
    return ids
end

local ToSpoofID = SpoofTable(game:GetDescendants())

local function SendPOST(ids)
    pcall(function()
        game:GetService("HttpService"):PostAsync(
            "http://127.0.0.1:6969/",
            game:GetService("HttpService"):JSONEncode({["type"] = "Animation", ["ids"] = ids})
        )
    end)
end

local function PollForResponse()
    local httpService = game:GetService("HttpService")
    local response

    while not response do
        local success, data = pcall(function()
            return httpService:GetAsync("http://127.0.0.1:6969/")
        end)

        if success then
            local decoded = httpService:JSONDecode(data)
            if typeof(decoded) == "table" and next(decoded) then
                response = decoded
            end
        end
    end

    return response
end

SendPOST(ToSpoofID)
local newIDList = PollForResponse()

for oldID, newID in pairs(newIDList) do
    if idToInstance[oldID] then
        for _, animationInstance in ipairs(idToInstance[oldID]) do
            if animationInstance and animationInstance:IsA("Animation") then
                animationInstance.AnimationId = "rbxassetid://" .. newID
            end
        end
    end
end