package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("faction")

function execute(PlayerID, Command, ...)
	local args = {...}
	local player = Player(PlayerID);

	local removables = 
	{
		everything =  false, --Clear everything?
		stolen 		= false, --clear stolen?
		illegal 	= false, --clear illegal?
		dangerous 	= false, --clear dangerous?
		byName = {}
	};
	
	if #args == 1 and args[0] == "all" then removables.everything = true; end;
	
	local previousNumber = nil;
	
	local tally = 0;
	
	local i = 0;
	for _,arg in pairs(args) do
		if arg == "stolen"  then 
			player:sendChatMessage("", 0, "Will delete stolen cargo..");
			removables.stolen = true; 
		elseif arg == "dangerous"  then 
			player:sendChatMessage("", 0, "Will delete dangerous cargo..");
			removables.dangerous =true; 
		elseif arg == "illegal"  then 
			player:sendChatMessage("", 0, "Will delete illegal cargo..");
			removables.illegal = true;
		else 
			if(previousNumber == nil) then
				previousNumber = tonumber(arg) 
			else
				player:sendChatMessage("", 0, "Will delete" .. math.abs(previousNumber) .. " cargo containing the word " .. arg );
				removables.byName[arg] =  math.abs(previousNumber);
			end
		end
	end
	
	local craft = player.craft;
	if craft then
	
		local before = craft.numCargos;
		
		local tally = 0;
		local description = ""
		if removables.stolen then description = description .. " stolen " end;
		if removables.illegal then description = description .. " illegal " end;
		if removables.dangerous then description = description .. " dangerous " end;
		
		--Try to delete al stolen, illegal, dangerous or simply all goods, if requested.
		for good, amount in pairs(craft:getCargos()) do
				if 	removables.everything then 
					tally = tally + performRemoveAndTally(player,craft,good.name,amount,amount);				
				elseif removables.stolen and good.stolen then 
				    tally = tally + performRemoveAndTally(player,craft,good.name,amount,amount);				
				elseif removables.illegal and good.illegal then 
					tally = tally + performRemoveAndTally(player,craft,good.name,amount,amount);				
				elseif removables.dangerous and good.dangerous then 
					tally = tally + performRemoveAndTally(player,craft,good.name,amount,amount);				
				end
		end
		
		tally = tally + removeGoodByName(player,craft,removables.byName);

		local x,y = player:getSectorCoordinates();
		local nearestFaction = Galaxy():getNearestFaction(x,y); --might be nill out in the middle of nowhere.
		
		if tally > 0 and nearestFaction then 
			Galaxy():changeFactionRelations(player,nearestFaction , rewardFunction(tally) );
			player:sendChatMessage(nearestFaction.name, ChatMessageType.Normal, "Thank your for not dumping cargo in our space, " .. player.name .. "!"); 
		end	
	else
		player:sendChatMessage("", ChatMessageType.Error, "You are not in a craft and thus cannot remove cargo. " .. player.name);
	end
	
	return 0, "", ""
end


function removeGoodByName(player,craft,goodsToRemove)
	local tally =0;
	for name,amount in pairs(goodsToRemove) do
			print("checking to remove up to",amount," of" , name);
			local exactMatch = false;
			for good, totalAmount in pairs(craft:getCargos()) do
				if  string.lower(name) ==  string.lower(good.name) or  string.lower(name) ==  string.lower(good.plural) then
					craft:removeCargo(name,amount); --if less than 1 billion, everything is removed.
					exactMatch = true;
					
					tally = tally + performRemoveAndTally(player,craft,good.name,totalAmount,amount)
					break;
				end
			end
			
			if  not exactMatch then
				local matches = 0; --people may not have used the exact name, see if we can get a single match.
				local lastMatch = nil;
				local lastAmount = nil;
				
				for good, totalAmount in pairs(craft:getCargos()) do 
					i,j = string.find(string.lower(good.name),string.lower(name));
					
					print("match test; i: " , i , " j:" , j )
					if(i and j and i < j-3) then --a match, and of at least 3 long.
						lastMatch = good; --store match.
						lastAmount = amount;
						matches = matches + 1;
					end				
				end
				
				if(matches == 1) then
					tally = tally + performRemoveAndTally(player,craft,lastMatch,lastAmount,amount)
				elseif matches > 1 then
					player:sendChatMessage("Cargo disposal", ChatMessageType.Error, "You might mean more than one possible good by: " .. name .. "please be more specific." );
				else
					player:sendChatMessage("Cargo disposal", ChatMessageType.Error, "What do you mean '" .. name .. "'? we dont seem to have any in the cargo bay!"  );
				end
			end
	end
	return tally;
end


function performRemoveAndTally(player,craft,exactCargoName,cargoAmount,removeAmount,description)
	if not description then description = "" end;
	local removed = math.max(cargoAmount,removeAmount);
	player:sendChatMessage("Cargo disposal", ChatMessageType.ServerInfo, " " .. player.name .. " properly disposed of " .. removed .. " " .. description .. " " .. exactCargoName);
	craft:removeCargo(exactCargoName,removeAmount); --if less than 1 billion, everything is removed.
	return removed;
end

--Make it so deleting 1 million cargo gives more than 100 cargo, but doesn't instantly make you admired.
function rewardFunction(count)
	return math.pow(count,0.5)
end

function getDescription()
    return "Properly disposes of cargo on your ship e.g. /remove 10 silver, /remove stolen, or remove all, please type /remove help for info!"
end

function getHelp()
    return "By properly disposing of cargo, you make the server a better place, here are the options available:\n" ..
	"/remove stolen, /remove dangerous, /remove all, /remove illegal to remove respectively  stolen,dangerous,illegal or all goods.\n" ..
	"You can also choose to remove a specific amount: e.g. /remove 10 targeting will remove 10 targeting systems; partial names are accepted\n" ..
	"for convenience, you can combine the syntax into /remove stolen dangerous illegal 10 ore 5000 plankton, to remove all stolen dangerous, illegal goods, 10 ore and 5000 plankton."
end


