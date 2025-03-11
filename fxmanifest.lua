fx_version "cerulean"
game "gta5"
author "Pickle Mods"
description "The best system for in-game monetization using Tebex."
version "v1.1.3"

ui_page "nui/index.html"

files {
	"nui/index.html",
	"nui/images/*.*",
	"nui/sounds/*.*",
	"nui/assets/**/*.*",
	"nui/debug.js",
	"components/**/*.*",
}

shared_scripts {
	"@ox_lib/init.lua",
	"config.lua",
	"locales/locale.lua",
    "locales/translations/*.lua",
	"modules/**/shared.lua",
    "core/shared.lua"
}

client_scripts {
	"bridge/**/**/client.lua",
	"modules/**/client.lua",
    "core/client.lua"
}

server_scripts {
	"@mysql-async/lib/MySQL.lua",
	"bridge/**/**/server.lua",
	"modules/**/server.lua",
    "core/server.lua",
	"config_sv.lua",
}

lua54 'yes'

escrow_ignore {
	"config.lua",
	"config_sv.lua",
	"__INSTALL/**/*.*",
	"core/*.*",
	"bridge/**/**/*.*",
	"bridge/**/*.*",
    "locales/locale.lua",
    "locales/translations/*.lua",
}