# COREV Radio `v1.0.2`

Standalone radio (no ESX / QBCore / ox_lib) with the Corev radio NUI. Uses **pma-voice** for the actual voice.

## Install
1. Put `corev-radio` in your resources folder.
2. server.cfg (after pma-voice):
   ```
   ensure pma-voice
   ensure corev-radio
   ```
3. In game: `/radio` or the key set in `config.lua` (default F6, rebindable in FiveM key bindings).

## Restricted channels (ACE based, no framework)
Edit `Config.RestrictedChannels` in `config.lua`, then give access in server.cfg:
```
add_ace group.police corev.radio.police allow
add_principal identifier.license:xxxxxxxx group.police
```

## Exports (client)
`openRadio()`, `closeRadio()`, `joinChannel(ch)`, `leaveChannel()`, `getChannel()`, `isPowered()`, `isOpen()`

Example (use it from an item): `exports['corev-radio']:openRadio()`

## Events
`corev-radio:loudspeakerChanged (bool)`  - fired when the loudspeaker is toggled.
Statebag: `Player(id).state.corevRadioLoudspeaker`

## Talk sound
The Corev radio beep (`html/sounds/radio_interact.ogg`) plays when somebody transmits on your channel: when you press the push-to-talk key and when other players on your channel start talking.
Everything is configurable in `config.lua` (`Config.TalkSound`, `Config.TalkSoundVolume`, `Config.TalkSoundOnStart`, `Config.TalkSoundOnEnd`, `Config.TalkSoundOthers`).
`Config.DisableVoiceMicClicks` turns off pma-voice's own mic clicks so the beep isn't doubled. If your pma-voice build ignores it, set `setr voice_enableMicClicks 0` in server.cfg instead.

## Changelog
- **1.0.2** - Added the Corev radio beep that plays when you talk on the radio, COREV branding across the whole design, version shown in the UI.
- **1.0.0** - Initial release.
