--[[
 	Overly Complex Post-Processing System

	by PackRat ( packrat (at) plebsquad (dot) com )

	Version 1.0, 19th Feb 2007
]]--



-- Include this file on both the server and client
-- to initialise both PostMan and PostEvents.

if ( SERVER ) then

	include( "postevent.lua" )

	AddCSLuaFile( "init.lua" )
	AddCSLuaFile( "cl_postman.lua" )
	AddCSLuaFile( "cl_postevent.lua" )
	AddCSLuaFile( "events.lua" )
	
end

if ( CLIENT ) then

	include( "cl_postman.lua" )
	include( "cl_postevent.lua" )
	include( "events.lua" )

end
