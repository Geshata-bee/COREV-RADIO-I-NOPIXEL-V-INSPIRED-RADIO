# corev-radio

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
