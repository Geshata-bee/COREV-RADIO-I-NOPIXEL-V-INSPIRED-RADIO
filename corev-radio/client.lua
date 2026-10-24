local Text = Config.Text

local state = {
    open        = false,
    powered     = Config.StartPowered,
    channel     = 0,
    lastChannel = 0,
    muted       = false,
    loudspeaker = false,
}

local radioProp = nil

-- ---------------------------------------------------------------- helpers
local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function voiceRunning()
    return GetResourceState('pma-voice') == 'started'
end

local function sendState()
    SendNUIMessage({
        type        = 'radioState',
        powered     = state.powered,
        onRadio     = state.channel > 0,
        channel     = state.channel,
        muted       = state.muted,
        loudSpeaker = state.loudspeaker,
    })
end

-- 0 = empty/leave, nil = invalid, number = valid channel
local function parseChannel(raw)
    raw = tostring(raw or ''):gsub(',', '.'):gsub('%s', '')
    if raw == '' then return 0 end

    local n = tonumber(raw)
    if not n then return nil end
    if n <= 0 then return 0 end

    if Config.AllowDecimals then
        n = math.floor(n * 100 + 0.5) / 100
    else
        n = math.floor(n)
    end

    if n < Config.MinChannel or n > Config.MaxChannel then return nil end
    return n
end

-- ---------------------------------------------------------------- animation / prop
local function loadAnim(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(10) end
    return HasAnimDictLoaded(dict)
end

local function startAnim()
    if not Config.UseAnimation then return end
    local ped = PlayerPedId()
    local anim, prop = Config.Animation, Config.Prop

    if loadAnim(anim.dict) then
        TaskPlayAnim(ped, anim.dict, anim.name, 3.0, 3.0, -1, anim.flag, 0, false, false, false)
    end

    local model = joaat(prop.model)
    RequestModel(model)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(10) end

    if HasModelLoaded(model) then
        local c = GetEntityCoords(ped)
        radioProp = CreateObject(model, c.x, c.y, c.z + 0.2, true, true, false)
        AttachEntityToEntity(radioProp, ped, GetPedBoneIndex(ped, prop.bone),
            prop.pos.x, prop.pos.y, prop.pos.z, prop.rot.x, prop.rot.y, prop.rot.z,
            true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(model)
    end
end

local function stopAnim()
    local ped = PlayerPedId()
    local anim = Config.Animation
    StopAnimTask(ped, anim.dict, anim.name, 3.0)
    if radioProp and DoesEntityExist(radioProp) then
        DeleteEntity(radioProp)
    end
    radioProp = nil
end

-- ---------------------------------------------------------------- voice (pma-voice)
local function applyMute()
    if not voiceRunning() then return end
    local volume = state.muted and 0 or Config.DefaultVolume

    local ok = pcall(function() exports['pma-voice']:setRadioVolume(volume) end)
    if not ok then
        -- fallback for pma-voice builds without setRadioVolume
        pcall(function() exports['pma-voice']:setVoiceProperty('radioEnabled', not state.muted) end)
    end
end

local function setVoiceChannel(channel)
    if not voiceRunning() then return false end
    exports['pma-voice']:setRadioChannel(channel)
    return true
end

local function joinChannel(channel)
    if not setVoiceChannel(channel) then
        notify(Text.no_voice)
        return
    end
    state.channel     = channel
    state.lastChannel = channel
    applyMute()
    notify((Text.joined):format(channel))
    sendState()
end

local function leaveChannel(silent)
    if state.channel > 0 then
        setVoiceChannel(0)
        state.channel = 0
        if not silent then notify(Text.left) end
    end
    sendState()
end

-- ---------------------------------------------------------------- actions
local function requestJoin(raw)
    if not state.powered then
        notify(Text.powered_off)
        return
    end

    local channel = parseChannel(raw)
    if channel == nil then
        notify(Text.invalid)
        sendState()
        return
    end

    if channel == 0 then
        leaveChannel(false)
        return
    end

    if channel == state.channel then
        notify(Text.already)
        sendState()
        return
    end

    -- the server validates range + ACE permissions and answers with joinResult
    TriggerServerEvent('corev-radio:server:join', channel)
end

local function togglePower(raw)
    if state.powered then
        state.powered = false
        leaveChannel(true)
        notify(Text.power_off)
        sendState()
        return
    end

    state.powered = true
    notify(Text.power_on)
    sendState()

    local channel = parseChannel(raw)
    if channel and channel > 0 then
        requestJoin(channel)
    elseif Config.RejoinOnPowerOn and state.lastChannel > 0 then
        requestJoin(state.lastChannel)
    end
end

local function toggleMute()
    if not state.powered then
        notify(Text.powered_off)
        return
    end
    state.muted = not state.muted
    applyMute()
    notify(state.muted and Text.muted or Text.unmuted)
    sendState()
end

local function toggleLoudspeaker()
    if not state.powered then
        notify(Text.powered_off)
        return
    end
    state.loudspeaker = not state.loudspeaker
    LocalPlayer.state:set('corevRadioLoudspeaker', state.loudspeaker, true)
    TriggerEvent('corev-radio:loudspeakerChanged', state.loudspeaker)
    notify(state.loudspeaker and Text.loud_on or Text.loud_off)
    sendState()
end

-- ---------------------------------------------------------------- open / close
local function closeRadio()
    if not state.open then return end
    state.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
    stopAnim()
end

local function openRadio()
    if state.open then return end

    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedCuffed(ped) or IsPedRagdoll(ped) then
        notify(Text.open_failed)
        return
    end

    state.open = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type        = 'open',
        powered     = state.powered,
        onRadio     = state.channel > 0,
        channel     = state.channel,
        muted       = state.muted,
        loudSpeaker = state.loudspeaker,
    })
    startAnim()

    CreateThread(function()
        while state.open do
            local p = PlayerPedId()
            if IsEntityDead(p) or IsPedCuffed(p) then
                closeRadio()
                break
            end
            Wait(250)
        end
    end)
end

-- ---------------------------------------------------------------- NUI callbacks
RegisterNUICallback('escape', function(_, cb)
    closeRadio()
    cb('ok')
end)

RegisterNUICallback('joinRadio', function(data, cb)
    cb('ok')
    requestJoin(data and data.channel)
end)

RegisterNUICallback('poweredOff', function(data, cb)
    cb('ok')
    togglePower(data and data.channel)
end)

RegisterNUICallback('muteRadio', function(_, cb)
    cb('ok')
    toggleMute()
end)

RegisterNUICallback('toggleLoudspeaker', function(_, cb)
    cb('ok')
    toggleLoudspeaker()
end)

-- ---------------------------------------------------------------- server reply
RegisterNetEvent('corev-radio:client:joinResult', function(ok, channel, reason)
    if ok then
        if state.powered then joinChannel(channel) end
    else
        notify(reason or Text.invalid)
        sendState()
    end
end)

-- ---------------------------------------------------------------- command / key
if Config.Command and Config.Command ~= '' then
    RegisterCommand(Config.Command, function()
        if state.open then closeRadio() else openRadio() end
    end, false)

    if Config.EnableKeybind then
        RegisterKeyMapping(Config.Command, 'Open radio', 'keyboard', Config.OpenKey)
    end
end

-- ---------------------------------------------------------------- exports (for inventories / other scripts)
exports('openRadio',    openRadio)
exports('closeRadio',   closeRadio)
exports('joinChannel',  function(channel) requestJoin(channel) end)
exports('leaveChannel', function() leaveChannel(false) end)
exports('getChannel',   function() return state.channel end)
exports('isPowered',    function() return state.powered end)
exports('isOpen',       function() return state.open end)

-- ---------------------------------------------------------------- cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if state.open then closeRadio() end
    if state.channel > 0 and voiceRunning() then
        pcall(function() exports['pma-voice']:setRadioChannel(0) end)
    end
    stopAnim()
end)
