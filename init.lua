local i18n = {}

local store
local locale
local pluralizeFunction
local defaultLocale = 'en'
local defaultPatternPath = 'packages/%s/i18n'
local fallbackLocale = defaultLocale

local currentFilePath = ( 'packages/%s' ):format( GetPackageName() )

local plural      = require( currentFilePath .. '.plural' )
local interpolate = require( currentFilePath .. '.interpolate' )
local variants    = require( currentFilePath .. '.variants' )
local version     = require( currentFilePath .. '.version' )

i18n.plural, i18n.interpolate, i18n.variants, i18n.version, i18n._VERSION =
	plural, interpolate, variants, version, version

-- private stuff

local function dotSplit( str )
	local fields, length = {}, 0
		str:gsub( '[^%.]+', function( c )
			length = length + 1
			fields[ length ] = c
		end)
	return fields, length
end

local function isTable( t )
	return type( t ) == 'table'
end

local function isPluralTable( t )
	return isTable( t ) and type( t.other ) == 'string'
end

local function isPresent( str )
	return type( str ) == 'string' and #str > 0
end

local function assertPresent( functionName, paramName, value )
	if isPresent( value ) then return end

	local msg = 'i18n.%s requires a non-empty string on its %s. Got %s (a %s value).'
	error( msg:format( functionName, paramName, tostring( value ), type( value ) ) )
end

local function assertPresentOrPlural( functionName, paramName, value )
	if isPresent( value ) or isPluralTable( value ) then return end

	local msg = 'i18n.%s requires a non-empty string or plural-form table on its %s. Got %s (a %s value).'
	error( msg:format( functionName, paramName, tostring( value ), type( value ) ) )
end

local function assertPresentOrTable( functionName, paramName, value )
	if isPresent( value ) or isTable( value ) then return end

	local msg = 'i18n.%s requires a non-empty string or table on its %s. Got %s (a %s value).'
	error( msg:format( functionName, paramName, tostring( value ), type( value ) ) )
end

local function assertFunctionOrNil( functionName, paramName, value )
	if value == nil or type( value ) == 'function' then return end

	local msg = 'i18n.%s requires a function (or nil) on param %s. Got %s (a %s value).'
	error( msg:format( functionName, paramName, tostring( value ), type( value ) ) )
end

local function defaultPluralizeFunction( count )
	return plural.get( variants.root( i18n.getLocale() ), count )
end

local function pluralize( t, data )
	assertPresentOrPlural( 'interpolatePluralTable', 't', t )
	data = data or {}
	local count = data.count or 1
	local plural_form = pluralizeFunction( count )
	return t[ plural_form ]
end

local function treatNode( node, data )
	if type( node ) == 'string' then
		return interpolate( node, data )
	elseif isPluralTable( node ) then
		return interpolate( pluralize( node, data ), data )
	end
	return node
end

local function recursiveLoad( currentContext, data )
	local composedKey
	for k,v in pairs( data ) do
		composedKey = ( currentContext and ( currentContext .. '.' ) or '' ) .. tostring( k )
		assertPresent( 'load', composedKey, k )
		assertPresentOrTable( 'load', composedKey, v)
		if type( v ) == 'string' then
			i18n.set( composedKey, v )
		else
			recursiveLoad( composedKey, v )
		end
	end
end

local function localizedTranslate( key, loc, data )
	local path, length = dotSplit( loc .. '.' .. key )
	local node = store

	for i=1, length do
		node = node[ path[ i ] ]
		if not node then return nil end
	end

	return treatNode( node, data )
end

local function getFileContent( path )
	local file = io.open( path, 'r' )
	if file == nil then return nil end
	file:close()
	local content = ''
	for line in io.lines( path ) do
		content = content .. line
	end
	return content
end

local function folderExist( folder )
	folder = folder .. '/'
	local ok, err, code = os.rename( folder, folder )
	if not ok and  code == 13 then
		return true
	end
	return ok, err
end

local function getFilesInFolder( folder )
	if not folderExist( folder ) then return {} end
	local i, t, popen = 0, {}, io.popen
	for filename in popen( 'dir "' .. folder .. '" /b' ):lines() do
		i = i + 1
		t[ i ] = filename
	end
	return t
end

local function getAllActivePackages()
	local serverConfig = json_decode( getFileContent( 'server_config.json' ) )
	if not isTable( serverConfig ) or not isTable(serverConfig.packages) then return {} end
	return serverConfig.packages
end

-- public interface

function i18n.set( key, value )
	assertPresent( 'set', 'key', key )
	assertPresentOrPlural( 'set', 'value', value )

	local path, length = dotSplit( key )
	local node = store

	for i = 1, length - 1 do
		key = path[ i ]
		node[ key ] = node[ key ] or {}
		node = node[ key ]
	end

	local lastKey = path[ length ]
	node[ lastKey ] = value
end

function i18n.translate( key, data )
	assertPresent( 'translate', 'key', key )

	data = data or {}
	local usedLocale = data.locale or locale

	local fallbacks = variants.fallbacks( usedLocale, fallbackLocale )
	for i = 1, #fallbacks do
		local value = localizedTranslate( key, fallbacks[i], data )
		if value then return value end
	end

	return data.default
end

function i18n.setLocale( newLocale, newPluralizeFunction )
	assertPresent( 'setLocale', 'newLocale', newLocale )
	assertFunctionOrNil( 'setLocale', 'newPluralizeFunction', newPluralizeFunction )
	locale = newLocale
	pluralizeFunction = newPluralizeFunction or defaultPluralizeFunction
end

function i18n.setFallbackLocale( newFallbackLocale )
	assertPresent( 'setFallbackLocale', 'newFallbackLocale', newFallbackLocale )
	fallbackLocale = newFallbackLocale
end

function i18n.getFallbackLocale()
	return fallbackLocale
end

function i18n.getLocale()
	return locale
end

function i18n.reset()
	store = {}
	plural.reset()
	i18n.setLocale( defaultLocale )
	i18n.setFallbackLocale( defaultLocale )
end

function i18n.loadAllPackage()
	local activePackages = getAllActivePackages()
	if not isTable( activePackages ) or #activePackages <= 0 then return end

	for i = 1, #activePackages do
		local packageName = activePackages[ i ]
		local defaultPath = defaultPatternPath:format( packageName )
		local files = getFilesInFolder( defaultPath )
		if isTable(files) and #files > 0 then
			for j = 1, #files do
				i18n.loadFile( ( '%s/%s' ):format( defaultPath, files[ j ] ) )
			end
		end
	end
end
AddEvent( 'OnPackageStart', i18n.loadAllPackage )

function i18n.load( data )
	recursiveLoad( nil, data )
end

function i18n.loadFile( path )
	local chunk = assert( loadfile( path ) )
	local data = chunk()
	i18n.load( data )
end

setmetatable( i18n, { __call = function( _, ... ) return i18n.translate( ... ) end } )

i18n.reset()

AddFunctionExport( 'trans', i18n.translate )
AddFunctionExport( 'getLocale', i18n.getLocale )
AddFunctionExport( 'setLocale', i18n.setLocale )
AddFunctionExport( 'getFallbackLocale', i18n.getFallbackLocale )
AddFunctionExport( 'setFallbackLocale', i18n.setFallbackLocale )
AddFunctionExport( 'load', i18n.load )
AddFunctionExport( 'loadFile', i18n.loadFile )
AddFunctionExport( 'reset', i18n.reset )
AddFunctionExport( 'set', i18n.set )

return i18n
