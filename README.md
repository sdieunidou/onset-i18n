# I18n package of Onset

Add translations in your Onset package

This package is an integration of the i18n libray made by kikito (https://github.com/kikito/i18n.lua)

# Install

Add package in `onset/packages/simplei18n`, enable it in `server_config.json` and restart your Onset server.

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
local i18n = ImportPackage( 'simplei18n' ) or error('simplei18n package is missing (https://github.com/sdieunidou/onset-i18n)!')

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


-- i18n.loadFile( 'packages/yourpackage/i18n/en.lua' ) -- load English language file
-- i18n.loadFile( 'packages/yourpackage/i18n/de.lua' ) -- load German language file
-- i18n.loadFile( 'packages/yourpackage/i18n/fr.lua' ) -- load French language file

i18n.setFallbackLocale( "en" )
i18n.setLocale( "en" )

print( i18n.trans( 'welcome') );
print( i18n.trans( 'welcome', { locale = 'en' ) );
print( i18n.trans( 'welcome', { locale = 'fr' ) );

print( i18n.trans( 'invalid_config' ));
print( i18n.trans( 'invalid_config', { path = 'config.json' ) );
print( i18n.trans( 'invalid_config', { path = 'config.json' ) );

function OnPlayerJoin( player )
    AddPlayerChat( player, i18n.trans( 'connected', { name = GetPlayerName( player ), locale = GetPlayerLocale( player ) } ) )
end
AddEvent( 'OnPlayerJoin', OnPlayerJoin )
```


Interpolation
=============

You can interpolate variables in 3 different ways:

``` lua
-- the most usual one
i18n.set('variables', 'Interpolating variables: %{name} %{age}')
i18n('variables', {name='john', 'age'=10}) -- Interpolating variables: john 10

i18n.set('lua', 'Traditional Lua way: %d %s')
i18n('lua', {1, 'message'}) -- Traditional Lua way: 1 message

i18n.set('combined', 'Combined: %<name>.q %<age>.d %<age>.o')
i18n('combined', {name='john', 'age'=10}) -- Combined: john 10 12k
```



Pluralization
=============

This lib implements the [unicode.org plural rules](http://cldr.unicode.org/index/cldr-spec/plural-rules). Just set the locale you want to use and it will deduce the appropiate pluralization rules:

``` lua
i18n = require 'simplei18n'

i18n.load({
  en = {
    msg = {
      one   = "one message",
      other = "%{count} messages"
    }
  },
  ru = {
    msg = {
      one   = "1 сообщение",
      few   = "%{count} сообщения",
      many  = "%{count} сообщений",
      other = "%{count} сообщения"
    }
  }
})

i18n('msg', {count = 1}) -- one message
i18n.setLocale('ru')
i18n('msg', {count = 5}) -- 5 сообщений
```

The appropiate rule is chosen by finding the 'root' of the locale used: for example if the current locale is 'fr-CA', the 'fr' rules will be applied.

If the provided functions are not enough (i.e. invented languages) it's possible to specify a custom pluralization function in the second parameter of setLocale. This function must return 'one', 'few', 'other', etc given a number.


Fallbacks
=========

When a value is not found, the lib has several fallback mechanisms:

* First, it will look in the current locale's parents. For example, if the locale was set to 'en-US' and the key 'msg' was not found there, it will be looked over in 'en'.
* Second, if the value is not found in the locale ancestry, a 'fallback locale' (by default: 'en') can be used. If the fallback locale has any parents, they will be looked over too.
* Third, if all the locales have failed, but there is a param called 'default' on the provided data, it will be used.
* Otherwise the translation will return nil.

The parents of a locale are found by splitting the locale by its hyphens. Other separation characters (spaces, underscores, etc) are not supported.

Using language files
====================

It might be a good idea to store each translation in a different file. This is supported via the 'i18n.loadFile' directive:

``` lua
…
i18n.loadFile('packages/yourpackage/i18n/de.lua') -- German translation
i18n.loadFile('packages/yourpackage/i18n/en.lua') -- English translation
i18n.loadFile('packages/yourpackage/i18n/fr.lua') -- French translation
…
```

The German language file 'de.lua' should read:

``` lua
return {
  de = {
    good_bye = "Auf Wiedersehen!",
    age_msg = "Ihr Alter beträgt %{age}.",
    phone_msg = {
      one = "Sie haben eine neue Nachricht.",
      other = "Sie haben %{count} neue Nachrichten."
    }
  }
}
```

If desired, you can also store all translations in one single file (eg. 'translations.lua'):

``` lua
return {
  de = {
    good_bye = "Auf Wiedersehen!",
    age_msg = "Ihr Alter beträgt %{age}.",
    phone_msg = {
      one = "Sie haben eine neue Nachricht.",
      other = "Sie haben %{count} neue Nachrichten."
    }
  },
  fr = {
    good_bye = "Au revoir !",
    age_msg = "Vous avez %{age} ans.",
    phone_msg = {
      one = "Vous avez une noveau message.",
      other = "Vous avez %{count} noveaux messages."
    }
  },
  …
}
```

#  Credits

* Thanks to kikito: https://github.com/kikito/i18n.lua
* Onset Server Hosting: https://mtxserv.com/host-server/onset
* Thanks to GCA: https://g-ca.fr/
