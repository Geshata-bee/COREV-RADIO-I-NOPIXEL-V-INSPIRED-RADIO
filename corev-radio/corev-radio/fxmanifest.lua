fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'corev-radio'
author 'Corev'
description 'Corev Radio - standalone radio (no framework) with NUI for pma-voice'
version '1.0.2'

dependency 'pma-voice'

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/sounds/*.ogg',
}
