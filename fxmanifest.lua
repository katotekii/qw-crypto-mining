fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

description 'Crypto Mining Simulator'
author 'qw-scripts'
version '0.1.0'

client_scripts {
    'bridge/**/*',
    'client/**/*'
}

server_scripts { 
    'bridge/**/*',
    'server/**/*',
    '@oxmysql/lib/MySQL.lua' 
}

shared_scripts { 'shared/**/*', '@ox_lib/init.lua' }