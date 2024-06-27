fx_version 'cerulean'
lua54 'yes'
game 'gta5'

shared_scripts {
    '@es_extended/imports.lua',
}

client_scripts {
    'client.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
    "server.lua"
}

ui_page "html/index.html"

files {
    "html/index.html",
    "html/assets/*.css",
    "html/assets/*.js",
    "html/assets/*.svg"
}