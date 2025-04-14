local MarketPlaceService = game:GetService("MarketplaceService")   

local function GenerateIDList(): {any}
	local ids = {}
	local tasks = {}

	for _, obj in ipairs(game:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
			-- Check for AnimationIds within the script's code

			local scriptCode = obj.Source

			for id in scriptCode:gmatch("%d+") do
				local ibx = #tasks+1

				tasks[ibx] = true

                task.spawn(function()
                    if #id > 10 then
                        local _, Info = pcall(function()
                            return MarketPlaceService:GetProductInfo(tonumber(id), Enum.InfoType.Asset)
                        end)    
                        Info = Info or {}   
                        if Info.AssetTypeId == 24 then
                            table.insert(ids, {Info.Name, id})
                        end  
                    end    
    
                    tasks[ibx] = nil
                end)    
			end
		end
	end

	while #tasks > 0 do
		task.wait()
	end    
    print(ids)
	return ids
end	


local ToSpoofID = GenerateIDList()

local function SendPOST(ids: {any})
  game:GetService("HttpService"):PostAsync("http://127.0.0.1:6969/", game:GetService("HttpService"):JSONEncode({['type'] = 'Animation', ["ids"]=ids}))
end

local function PollForResponse(): {any}
	local response
	while not response and wait(4) do
		response = game:GetService("HttpService"):JSONDecode(game:GetService("HttpService"):GetAsync("http://127.0.0.1:6969/"))
	end
	return response
end

SendPOST(ToSpoofID)
local newIDList = PollForResponse()

for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
        local scriptCode = obj.Source
        local updatedCode = scriptCode

        -- Replace animation IDs in the script's source code
        for oldId, newId in pairs(newIDList) do
            updatedCode = updatedCode:gsub("rbxassetid://" .. tonumber(oldId), "rbxassetid://" .. tonumber(newId))
            updatedCode = updatedCode:gsub(tonumber(oldId), tonumber(newId))
        end

        if updatedCode ~= scriptCode then
            obj.Source = updatedCode
            print("Updated script:", obj:GetFullName())
        end
    end
end