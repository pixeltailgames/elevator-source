--[[
 	Post-Processing Event Handlers

	by PackRat ( packrat (at) plebsquad (dot) com )

	Version 1.0, 19th Feb 2007
	
	Because PostMan is entirely clientside, 
	the server does not have direct access 
	to the postman library. Post Events 
	allow preset post-processing effects
	to be created and triggered by the 
	server, similar to util.Effect.
]]--



postEvents = {}


-- Add a post event to the client
function AddPostEvent( name, func )

	if ( !name || name == "" ) then return end
	postEvents[name] = func
    
end


-- Remove a post event from the client
function RemovePostEvent( name )

	postEvents[name] = nil

end


-- Let the client trigger post events
-- if they really want to.
function PostEvent( name, mul, time )

	if ( !name || !postEvents[name] ) then return end
	postEvents[name]( mul, time )
	
end


-- Catch post events from the server
local function postEventHook( msg )

	local name = msg:ReadString()
	local mul = msg:ReadFloat() or 0
	local time  = msg:ReadFloat() or 1

	if ( !name || !postEvents[name] ) then return end

	postEvents[name]( mul, time )

end
usermessage.Hook( "postevent", postEventHook )

