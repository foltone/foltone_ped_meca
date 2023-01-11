fx_version 'cerulean'

author 'Foltone#6290'

games { 'gta5' };

lua54 'yes'

ui_page 'client/nui/index.html'

files {
    'client/nui/index.html',
    'client/nui/script.js',
    'client/nui/styles.css',
    'client/nui/reset.css',
    'client/nui/img/*.png'
}

client_scripts {
    'client/cl_trad.lua',
    'Config.lua',
    'locales/*.lua',
    'client/cl_main.lua'
}

server_script {
    'server/sv_main.lua'
}
