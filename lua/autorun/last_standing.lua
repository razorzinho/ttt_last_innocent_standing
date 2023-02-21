-- Create options for the addon functionality
local cvar_enable = CreateConVar("ttt_announce_last_innocent_alive", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_PROTECTED}, "Enable notifications to warn the last Innocent alive that they are by theirselves? 1 or 0", 0, 1)
local cvar_if_one_t = CreateConVar("ttt_announce_if_one_traitor", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_PROTECTED}, "Enable notifications if there is only one Traitor left? 1 or 0, 0 by default", 0, 1)
local cvar_warn_detective = CreateConVar("ttt_announce_if_detective", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_PROTECTED}, "Enable notifications if the last one is a Detective? 1 or 0, 0 by default", 0, 1)

-- Turn cvars into boolean values to make our work easier down the way
cvar_enable = cvar_enable:GetBool()
cvar_if_one_t = cvar_if_one_t:GetBool()
cvar_warn_detective = cvar_warn_detective:GetBool()

-- Define either the player was already warned or not, so we don't get multiple warns when there are more than one Traitor
local broadcasted = broadcasted or false

-- Define some colours we will need down the way
local yellow_color = table.ToString(Color(200, 160, 0))
local red_color = table.ToString(Color(230, 0, 0))

-- Function for counting the ammount of players and their in-game roles so we can work with them
local CountActiveRolePlayers = function()

	-- Create players object to keep track of each players' roles
	local players = {}

    players.innocents = {}
	
	players.traitors = {}
	
	players.detectives = {}
    
	for _, ply in ipairs( player.GetAll() ) do
		
		if (IsValid(ply) and ply:IsActive() and ply:GetRole() == ROLE_INNOCENT) then

			table.insert(players.innocents, ply)

		elseif (IsValid(ply) and ply:IsActive() and ply:GetRole() == ROLE_TRAITOR) then

			table.insert(players.traitors, ply)

		elseif (IsValid(ply) and ply:IsActive() and ply:GetRole() == ROLE_DETECTIVE) then

			table.insert(players.detectives, ply)

		end
	
	end
    
	return players

end

local GetLastInnocentStanding = function()
	for _, ply in ipairs( player.GetAll() ) do
		if (!ply:IsSpec() and ply:IsActive() and !ply:IsTraitor() and !ply:IsActiveTraitor() and ply:IsTerror()) then
			return ply:Name()
		end
	end
end

-- Prepare some stuff and execute the initial count of players
hook.Add("TTTBeginRound", "InitTTTLastInnocentAlive", function()
	if SERVER then
		print("Avisar último Inocente? " .. (cvar_enable and "Sim" or "Não"))
		print("Avisar somente quando houver mais de um Traidor? " .. (!cvar_if_one_t and "Sim" or "Não"))
		print("Avisar Detetive? " .. (cvar_warn_detective and "Sim" or "Não"))
		
		if !cvar_enable then broadcasted = true return end
		if cvar_if_one_t then return end
		broadcasted = false
		local players = CountActiveRolePlayers()
	end
end)

if SERVER then
	hook.Add("PostPlayerDeath", "CheckIfLastInnocentAliveAfterDeath", function(ply)
		if (GetRoundState() != ROUND_ACTIVE) then return end
       	if !cvar_enable then broadcasted = true return end
		if broadcasted then return end
		if ply:IsGhost() then return end
		local players = CountActiveRolePlayers()
		
		if ((#players.innocents == 1 or #players.detectives == 1) and #players.traitors > 0) then
			
			-- Don't do anything if "warn only if there is more than 1 traitor" cvar is enabled
			if (!cvar_if_one_t and #players.traitors == 1) then broadcasted = false return end
			
			-- Same as above, but if the "warn detectives" is disabled
			if (!cvar_warn_detective and #players.detectives > 0) then broadcasted = false return end

			print(GetLastInnocentStanding() .. " é o último Inocente vivo!")

			-- Quick and easy (but not the best) way of propagating the message to all players in the server
			BroadcastLua("chat.AddText(" .. red_color .. ", '" .. GetLastInnocentStanding() .. "', " .. yellow_color .. ", ' é o '," .. red_color .. ", 'último Inocente'," .. yellow_color .. ", ' vivo! '," .. red_color .. ", 'MATE TODOS!!!')")
			
			-- Avoid repeated warnings after first one
			broadcasted = true
		
		end
	
	end)

	hook.Add("PlayerDisconnected", "CheckIfLastInnocentAliveAfterDisconnect", function(ply)
		if (GetRoundState() != ROUND_ACTIVE) then return end
		if !cvar_enable then return end
        if broadcasted then return end
		local players = CountActiveRolePlayers()
		
		if ((#players.innocents == 1 or #players.detectives == 1) and #players.traitors > 0) then
			
			-- Don't do anything if "warn only if there is more than 1 traitor" cvar is enabled
			if (!cvar_if_one_t and #players.traitors == 1) then broadcasted = false return end
			
			-- Same as above, but if the "warn detectives" is disabled
			if (!cvar_warn_detective and #players.detectives > 0) then broadcasted = false return end

			print(GetLastInnocentStanding() .. " é o último Inocente vivo!")

			-- Quick and easy (but not the best) way of propagating the message to all players in the server
			BroadcastLua("chat.AddText(" .. red_color .. "'" .. GetLastInnocentStanding() .. "'" .. yellow_color .. ", ' é o '," .. red_color .. ", 'último Inocente'," .. yellow_color .. ", ' vivo! '," .. red_color .. ", 'MATE TODOS!!!')")

			-- Avoid repeated warnings after first one
			broadcasted = true
		
		end
	end)

end