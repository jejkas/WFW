WFW = {};
WFW.LastOnUpdateEvent = 0;
WFW.TimeBetweenLastOnUpdateEvent = 0.01;
WFW.LastMainHandAttack = 99999;
WFW.LastWeaponSwitch = 0;
WFW.merchantstatus = false
WFW.isActive = false;

SLASH_Wfw1 = "/wfw";


SlashCmdList["Wfw"] = function(args)
	if (WFW.isActive)
	then
		ChatFrame1:AddMessage('WFW: Off');
		WFW.isActive = false;
	else
		ChatFrame1:AddMessage('WFW: On');
		WFW.isActive = true;
	end
end;



function WFW.OnUpdateEvent()
	if (WFW.LastOnUpdateEvent + WFW.TimeBetweenLastOnUpdateEvent) <= GetTime()
	then
		-- We don't want to do this when the merch is open because that will sell the weapons.
		if WFW.merchantstatus then WFW.printDebug("WFW.merchantstatus true"); return end;
		local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo();
		-- Change them from NIL to 0 so we can run less then check on them.
		if not mainHandExpiration then mainHandExpiration = 0; end
		if not offHandExpiration then offHandExpiration = 0; end
		
		local mainSpeed, offSpeed = UnitAttackSpeed("Player");
		--WFW.printDebug("++++++++++++++++++++++++++");
		--WFW.printDebug(GetTime() - WFW.LastMainHandAttack);
		--WFW.printDebug(GetTime() - WFW.LastWeaponSwitch);
		if ((GetTime() - WFW.LastMainHandAttack < 1 or (GetTime() - WFW.LastMainHandAttack) > 5) and WFW.LastWeaponSwitch + 5 <= GetTime())
		then
			--WFW.printDebug("-----------------------");
			--WFW.printDebug(hasMainHandEnchant);
			--WFW.printDebug(offHandExpiration < mainHandExpiration);
			-- Only switch weapon if we have a main hand enchant and offhand enchant time is shorter then main hand.
			if hasMainHandEnchant and offHandExpiration < mainHandExpiration
			then
				-- Only want to do this in combat.
				-- (Might change this, so that we can pre-buff WF on both weapons, but then we need to have a out of combat weapon switch senario that doesn't check attacks etc.)
				if not UnitAffectingCombat("player") or not offSpeed -- No offhand equiped.
				then
					return;
				end
				PickupInventoryItem(16);
				PickupInventoryItem(17);
				
				-- If there has been more then 10 second since we did our last switch, we have to reset our last switch time.
				-- If it is between 5 and 10 then we just add 5 second on time of the old timer, this way the timer does not get delayed by the swing time - Always switch every 5 sec!
				if(GetTime() - WFW.LastWeaponSwitch >= 10)
				then
					WFW.LastWeaponSwitch = GetTime();
				else
					WFW.LastWeaponSwitch = WFW.LastWeaponSwitch + 5;
				end
			end
		end
		WFW.LastOnUpdateEvent = GetTime();
	end;
end;


function WFW.OnLoad()
	
end;

function WFW.eventHandler()
	if true
	then
		--return
	end
	
	WFW.printDebug(event);
	if event == "ADDON_LOADED"
	then
		if arg1 == "WFW"
		then
			WFW.OnLoad()
		end;
	elseif(event == "MERCHANT_SHOW")
	then
		WFW.merchantstatus = true
	elseif(event == "MERCHANT_CLOSED")
	then
		WFW.merchantstatus = false
	elseif event == "CHAT_MSG_COMBAT_SELF_MISSES"
	then
		WFW.HandleAutoAttack(0, 1);
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE"
	then
		WFW.spellhit(arg1)
	elseif event == "CHAT_MSG_COMBAT_SELF_HITS"
	then
		--WFW.printDebug("CHAT_MSG_COMBAT_SELF_HITS: " .. arg1);
		if string.find(arg1, "suffer")
		then
			return;
		end;
		local start,stop = string.find(arg1, "%d+");
		local damage = tonumber(string.sub(arg1, start, stop));
		local critMod = 1;
		
		if string.find(arg1, "crit")
		then
			critMod = 2;
		end;
		
		WFW.HandleAutoAttack(damage, critMod)
	end;
end

-- Taken from Bearcast attack bars.
function WFW.spellhit(arg1)
	a,b,spell=string.find (arg1, "Your (.+) hits")
	if not spell then 	a,b,spell=string.find (arg1, "Your (.+) crit") end
	if not spell then 	a,b,spell=string.find (arg1, "Your (.+) is") end
	if not spell then	a,b,spell=string.find (arg1, "Your (.+) miss") end
	if not spell then	a,b,spell=string.find (arg1, "Your (.+) was") end
	
	if not spell then return end;
	
	if (spell == "Raptor Strike" or spell == "Heroic Strike" or spell == "Maul" or spell == "Cleave")
	then
		WFW.HandleAutoAttack(0, 1);
	end
end

function WFW.HandleAutoAttack(damage, critMod)
	local lowDmg, hiDmg, offlowDmg, offhiDmg, posBuff, negBuff, percentmod = UnitDamage("Player");
	-- We hit a player.
	local mainSpeed, offSpeed = UnitAttackSpeed("Player");
	
	
	if offSpeed ~= nil
	then
		if damage > 0
		then
			if damage > tonumber(lowDmg)*0.8*critMod
			then
				WFW.LastMainHandAttack = GetTime();
			end;
		else
			-- If we missed the attack (0 damage) and it has been longer then main hand attack speed (with 50ms room for error) we assume it was a main hand miss.
			-- The more hit you have the less chance for error here.
			if GetTime() - WFW.LastMainHandAttack + 0.05 >= mainSpeed
			then
				WFW.LastMainHandAttack = GetTime();
			end
		end;
	else
		WFW.LastMainHandAttack = GetTime();
	end;
end;

-- Event stuff

WFW.MainFrame = CreateFrame("FRAME", "TTMainFrame");
WFW.MainFrame:SetScript("OnUpdate", WFW.OnUpdateEvent);
WFW.MainFrame:SetScript("OnEvent", WFW.eventHandler);
WFW.MainFrame:RegisterEvent("ADDON_LOADED");
WFW.MainFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS");
WFW.MainFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE");
WFW.MainFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES");

WFW.MainFrame:RegisterEvent("MERCHANT_SHOW");
WFW.MainFrame:RegisterEvent("MERCHANT_CLOSED");

-- Debug stuff


function WFW.printDebug(str)
	if true
	then
		--return;
	end;
	
	local c = ChatFrame5
	
	if str == nil
	then
		c:AddMessage('WFW: NIL');
	elseif type(str) == "boolean"
	then
		if str == true
		then
			c:AddMessage('WFW: true');
		else
			c:AddMessage('WFW: false');
		end;
	elseif type(str) == "table"
	then
		c:AddMessage('WFW: array');
		WFW.printArray(str);
	else
		c:AddMessage('WFW: '..str);
	end;
end;


function WFW.printArray(arr, n)
	if n == nil
	then
		 n = "arr";
	end
	for key,value in pairs(arr)
	do
		if type(arr[key]) == "table"
		then
			WFW.printArray(arr[key], n .. "[\"" .. key .. "\"]");
		else
			if type(arr[key]) == "string"
			then
				WFW.printDebug(n .. "[\"" .. key .. "\"] = \"" .. arr[key] .."\"");
			elseif type(arr[key]) == "number" 
			then
				WFW.printDebug(n .. "[\"" .. key .. "\"] = " .. arr[key]);
			elseif type(arr[key]) == "boolean" 
			then
				if arr[key]
				then
					WFW.printDebug(n .. "[\"" .. key .. "\"] = true");
				else
					WFW.printDebug(n .. "[\"" .. key .. "\"] = false");
				end;
			else
				WFW.printDebug(n .. "[\"" .. key .. "\"] = " .. type(arr[key]));
				
			end;
		end;
	end
end;



function WFW.strsplit(sep,str)
	local arr = {}
	local tmp = "";
	
	--WFW.printDebug(string.len(str));
	local chr;
	for i = 1, string.len(str)
	do
		chr = string.sub(str, i, i);
		if chr == sep
		then
			table.insert(arr,tmp);
			tmp = "";
		else
			tmp = tmp..chr;
		end;
	end
	table.insert(arr,tmp);
	
	return arr
end

function WFW.round(val, decimal)
	val = tonumber(val);
	if (decimal)
	then
		return math.floor( (val * 10^decimal) + 0.5) / (10^decimal);
	else
		return math.floor(val+0.5);
	end;
end;
