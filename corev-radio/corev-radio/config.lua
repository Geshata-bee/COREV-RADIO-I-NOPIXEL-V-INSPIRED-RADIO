Config = {}

-- Opening the radio
Config.Command       = 'radio'   -- /radio toggles the radio UI ('' to disable the command)
Config.OpenKey       = 'F6'      -- default key (players can rebind it in Settings > Key Bindings > FiveM)
Config.EnableKeybind = true

-- Channels
Config.MinChannel    = 1
Config.MaxChannel    = 1000
Config.AllowDecimals = true      -- allow channels like 12.5 (rounded to 2 decimals)

-- Behaviour
Config.StartPowered     = true   -- radio is ON the first time a player opens it
Config.RejoinOnPowerOn  = true   -- turning the radio back ON rejoins the last channel
Config.DefaultVolume    = 50     -- radio volume (0-100) used when un-muting
Config.UseAnimation     = true   -- hold-radio animation + prop while the UI is open

-- Talk sound: the Corev radio beep played when somebody transmits on your channel
Config.TalkSound           = true   -- master switch for the beep
Config.TalkSoundVolume     = 0.6    -- 0.0 - 1.0
Config.TalkSoundOnStart    = true   -- beep when the transmission starts (you press the push-to-talk key)
Config.TalkSoundOnEnd      = false  -- beep again when the transmission ends (key released)
Config.TalkSoundOthers     = true   -- also beep when OTHER players on your channel start talking
Config.DisableVoiceMicClicks = true -- turn off pma-voice's own mic clicks so you don't hear two beeps

-- Animation while the UI is open: looking at the radio in your hand (NOT talking into it).
Config.Animation = { dict = 'cellphone@', name = 'cellphone_text_read_base', flag = 50 }

-- Radio prop in hand. Tweak pos/rot if it does not sit right in the hand.
Config.Prop = {
    model = 'prop_cs_hand_radio',
    bone  = 28422,                  -- right hand
    pos   = vec3(0.0, 0.0, 0.0),
    rot   = vec3(0.0, 0.0, 0.0),
}

-- Restricted channels (checked on the server through ACE permissions, so no framework is needed).
-- Anyone WITHOUT the ace cannot join a channel inside [min, max].
-- Give access in server.cfg, e.g.:
--     add_ace group.police corev.radio.police allow
--     add_principal identifier.license:xxxxxxxx group.police
Config.RestrictedChannels = {
    -- { min = 1, max = 10, ace = 'corev.radio.police', label = 'Police' },
    -- { min = 11, max = 20, ace = 'corev.radio.ems',    label = 'EMS' },
}

Config.Text = {
    open_failed   = 'You cannot use the radio right now.',
    no_voice      = 'Voice system (pma-voice) is not running.',
    powered_off   = 'The radio is turned off.',
    power_on      = 'Radio turned on.',
    power_off     = 'Radio turned off.',
    invalid       = 'Invalid channel.',
    joined        = 'Connected to channel %s MHz.',
    left          = 'Disconnected from the radio.',
    already       = 'You are already on this channel.',
    restricted    = 'This channel is encrypted (%s).',
    muted         = 'Radio muted.',
    unmuted       = 'Radio unmuted.',
    loud_on       = 'Loudspeaker on.',
    loud_off      = 'Loudspeaker off.',
}
