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
	local wrongInput;
	local expectNumber = nil;
	local specialDone = false;
	for _,arg in pairs(args) do
		if not specialDone and arg == "all"  then 
			player:sendChatMessage("", 0, "Will delete all cargo..");
			removables.everything = true;
		elseif not specialDone and arg == "stolen"  then 
			player:sendChatMessage("", 0, "Will delete stolen cargo..");
			removables.stolen = true; 
		elseif not specialDone and arg == "dangerous"  then 
			player:sendChatMessage("", 0, "Will delete dangerous cargo..");
			removables.dangerous =true; 
		elseif not specialDone and arg == "illegal"  then 
			player:sendChatMessage("", 0, "Will delete illegal cargo..");
			removables.illegal = true;
		else 
			specialDone = true; --no longer process special cases above.
			if expectNumber == nil then expectNumber = true else expectNumber = not expectNumber; end;
			if(expectNumber) then
				previousNumber = tonumber(arg) 
				if previousNumber == nil then
					player:sendChatMessage("", ChatMessageType.Error, "where '" .. arg .. "' was encountered, a number was instead expected." );
					wrongInput = true;
					previousNumber = 0;
				end
			else
				player:sendChatMessage("", 0, "Will delete" .. math.abs(previousNumber) .. " cargo containing the word " .. arg );
				removables.byName[arg] =  math.abs(previousNumber);
			end
		end
	end
	
	if wrongInput then return end;
	
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
				if 	removables.everything  			
				or( removables.stolen and good.stolen) 			
				or( removables.illegal and good.illegal)
				or( removables.dangerous and good.dangerous) then
					tally = tally + performRemoveAndTally(player,craft,good.name,amount,amount,description);				
				end
		end
		
		tally = tally + removeGoodByName(player,craft,removables.byName);

		local x,y = player:getSectorCoordinates();
		local nearestFaction = Galaxy():getNearestFaction(x,y); --might be nill out in the middle of nowhere.
		
		local playerFaction = Faction(player.index);
		
		print('faction is',playerFaction.name);
		print('date/time is currently',os.date());
		
		if tally > 0 and nearestFaction then 
			Galaxy():changeFactionRelations(nearestFaction,playerFaction,rewardFunction(tally),true,true);
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
				local anyCargoAtAll = false;
				
				for good, totalAmount in pairs(craft:getCargos()) do 
					i,j = string.find(string.lower(good.name),string.lower(name));
					anyCargoAtAll = true;
					print("match test; i: " , i , " j:" , j )
					if(i and j and i < j-1) then --a match, and of at least 3 long.
						lastMatch = good; --store match.
						lastAmount = amount;
						matches = matches + 1;
					end				
				end
				
				if(matches == 1) then
					tally = tally + performRemoveAndTally(player,craft,lastMatch.name,lastAmount,amount)
				elseif matches > 1 then
					player:sendChatMessage("Cargo disposal", ChatMessageType.Error, "You might mean more than one possible good by: " .. name .. "please be more specific." );
				elseif string.len(name) < 3 then
					player:sendChatMessage("Cargo disposal", ChatMessageType.Error, "Please use a longer name, the name '" .. name .. "' is too short."  );
				elseif not anyCargoAtAll then
					player:sendChatMessage("Cargo disposal", ChatMessageType.Error, "We don't have any more cargo, but perhaps we can toss some crewmen overboard instead of '" .. name .. "' ?");
				else
					player:sendChatMessage("Cargo disposal", ChatMessageType.Error, "No cargo seems to match '" .. name .. "'."  );
				end
			end
	end
	return tally;
end


function performRemoveAndTally(player,craft,exactCargoName,cargoAmount,removeAmount,description)
	if not description then description = "" end;
	local removed = math.min(cargoAmount,removeAmount);
	player:sendChatMessage("Cargo disposal", ChatMessageType.ServerInfo, " " .. player.name .. " properly disposed of " .. removed .. " " .. description .. " " .. exactCargoName);
	craft:removeCargo(exactCargoName,removeAmount); --if less than 1 billion, everything is removed.
	print('removed ', removed)
	return removed;
end

--Make it so deleting 1 million cargo gives more than 100 cargo, but doesn't instantly make you admired.
function rewardFunction(count)
	print("standing reward for cargo disposal:",math.pow(count,0.5))
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


