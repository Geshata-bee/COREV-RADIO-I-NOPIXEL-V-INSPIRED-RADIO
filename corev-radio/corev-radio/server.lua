local Text = Config.Text

-- returns true or false + the restriction that blocked the player
local function hasAccess(src, channel)
    local base = math.floor(channel)
    for _, r in ipairs(Config.RestrictedChannels) do
        if base >= r.min and base <= r.max and not IsPlayerAceAllowed(src, r.ace) then
            return false, r
        end
    end
    return true
end

RegisterNetEvent('corev-radio:server:join', function(channel)
    local src = source
    channel = tonumber(channel)

    local valid = channel
        and channel >= Config.MinChannel
        and channel <= Config.MaxChannel
        and (Config.AllowDecimals or channel == math.floor(channel))

    if not valid then
        TriggerClientEvent('corev-radio:client:joinResult', src, false, channel, Text.invalid)
        return
    end

    local ok, restriction = hasAccess(src, channel)
    if not ok then
        TriggerClientEvent('corev-radio:client:joinResult', src, false, channel,
            (Text.restricted):format(restriction.label or 'restricted'))
        return
    end

    TriggerClientEvent('corev-radio:client:joinResult', src, true, channel)
end)

-- Hard enforcement inside pma-voice itself, so restricted channels can't be joined
-- by calling the voice export directly (integer channels only).
local function registerChannelChecks()
    if GetResourceState('pma-voice') ~= 'started' then return end

    for _, r in ipairs(Config.RestrictedChannels) do
        for channel = math.ceil(r.min), math.floor(r.max) do
            pcall(function()
                exports['pma-voice']:addChannelCheck(channel, function(source)
                    return IsPlayerAceAllowed(source, r.ace)
                end)
            end)
        end
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == 'pma-voice' or resource == GetCurrentResourceName() then
        SetTimeout(500, registerChannelChecks)
    end
end)
