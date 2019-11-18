# I18n package of Onset

Add translations in your Onset package

This package is an integration of the i18n libray made by kikito (https://github.com/kikito/i18n.lua)

# Install

Add package in `onset/packages/i18n`, enable it in `server_config.json` and restart your Onset server.

# Functions

```
AddFunctionExport( 'trans', i18n.translate )
AddFunctionExport( 'getLocale', i18n.getLocale )
AddFunctionExport( 'setLocale', i18n.setLocale )
AddFunctionExport( 'getFallbackLocale', i18n.getFallbackLocale )
AddFunctionExport( 'setFallbackLocale', i18n.setFallbackLocale )
AddFunctionExport( 'load', i18n.load )
AddFunctionExport( 'loadFile', i18n.loadFile )
AddFunctionExport( 'reset', i18n.reset )
AddFunctionExport( 'set', i18n.set )
```

# Usage

```
local i18n = ImportPackage( 'i18n' ) or error('i18n package is missing (https://github.com/sdieunidou/onset-i18n)!')

i18n.load({
  en = {
	  welcome = 'You are not allowed to join this server!',
	  invalid_config = 'Your %{path} has an invalid JSON format. Check it!',
	  connected = 'Welcome %{name}!',
  },
  fr = {
    welcome = 'Vous n\'êtes pas autorisé à rejoindre ce serveur!',
	  invalid_config = 'Votre fichier %{path} ne respecte pas le format JSON. Corrigez la configuration!',
	  connected = 'Bienvenue %{name}!',
  }
})

i18n.setLocale( "en" )

print(i18n.translate('welcome'));
print(i18n.translate('welcome', { locale = 'en' ));
print(i18n.translate('welcome', { locale = 'fr' ));

print(i18n.translate('invalid_config'));
print(i18n.translate('invalid_config', { path = 'config.json' ));
print(i18n.translate('invalid_config', { path = 'config.json' ));

function OnPlayerJoin( player )
    AddPlayerChat( player, i18n.trans( 'connected', { name = GetPlayerName(player),locale = GetPlayerLocale(player) } ) )
end
AddEvent( 'OnPlayerSteamAuth', OnPlayerSteamAuth )
```

#  Credits

* Onset Server Hosting: https://mtxserv.com/host-server/onset
* Thanks to GCA: https://g-ca.fr/
