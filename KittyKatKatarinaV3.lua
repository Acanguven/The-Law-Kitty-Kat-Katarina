--[[


	Script Manager


]]


class 'KittyKat'
function KittyKat:__init()
	self.version = "4"
	self.updateUrl = "https://raw.githubusercontent.com/thelaw44/The-Law-Kitty-Kat-Katarina/master/Kitty-Kat-Katarina.lua"
	self.downloadHost = "raw.github.com"
	self.remoteVersion = "/thelaw44/The-Law-Kitty-Kat-Katarina/master/version" .. "?random=" .. math.random(100000)
	self.scriptValid = false
	self.scriptFile = SCRIPT_PATH.."updateTest.lua"
	self.statsHost = ""
	self.statsUrl = ""
	self.requredLibsDownloaded = false
	return self
end

function KittyKat:getVersion()
	return self.version
end

function KittyKat:getcUpdateUrl()
	return self.updateUrl
end

function KittyKat:checkHeroValid()
	return myHero.charName == "Katarina"
end

function KittyKat:checkValidate()
	if self:checkHeroValid() and self:checkSameGameDeveloper() and self:checkVersionValid() then 
		if self.requredLibsDownloaded then
			self.scriptValid = true
		end
		return true
	else
		self.scriptValid = false
		return false
	end
end

function KittyKat:OnTick()

end

function KittyKat:checkVersionValid()
	drawing:print("Cheking for new version","orange")
	if self:GetRemoteVersion() ~= self.version then
		drawing:print("Version mismatch error, updating...","red")
		self:DownloadNewFile()
		return false
	end
	drawing:print("Loading version: " .. self.version,"green")
	return true
end

function KittyKat:checkSameGameDeveloper()
	for i, enemy in ipairs(GetEnemyHeroes()) do
	    if enemy.name == "ACG" or enemy.name == "zigagang44" then
	        drawing:print("You can't play against the creator of this script :(","red") 
	        return false
	    end
	end
	return true
end

function KittyKat:GetRemoteVersion()
  	local webResult = GetWebResult(self.downloadHost, self.remoteVersion)
  	local remoteVersion = string.gsub(webResult,"\n", "")
  	return remoteVersion
end

function KittyKat:DownloadNewFile()
    DelayAction(function () DownloadFile(self.updateUrl, self.scriptFile, function() drawing:print("Script updated, please reload!","orange") end) end, 2)
end

function KittyKat:PingKill()
	GetAsyncWebResult(self.statsHost,self.statsUrl.."?a=1")
end

function KittyKat:requireLibs()

end


--[[


	Katarina Controller


]]


class 'Katarina'
function Katarina:__init()
	self.qMarkeds = {}
	self.items = {}
	self.targetQueue = {}
	self.canMove = true
	self.skills = {		
		SkillQ =	{range = 675, name = "Bouncing Blades",	ready = false,	delay = 400,	projSpeed = 1400,	timeToHit = 0,	markDelay = 4000,	color = ARGB(255,178, 0 , 0 )	},
		SkillW =	{range = 375, name = "Sinister Steel",	ready = false,																			color = ARGB(255, 32,178,170)	},
		SkillE =	{range = 700, name = "Shunpo",			ready = false,																			color = ARGB(255,128, 0 ,128)	},
		SkillR =	{range = 550, name = "Death Lotus",		ready = false,					castingUlt = false,																		},
		SkillWard = {range = 600, lastJump = 0,				itemSlot = nil																											}
	}
	self.summonerSpells = {
		ignite = {},
		flash = {},
		heal = {},
		barrier = {}
	}
	self.igniteFound = false
	self.attackMode = ""
	self.Qtarget = nil
	self.waitQ = false
	self.lastQ = os.clock()
	self.lastWard = os.clock()
	self.lastE = os.clock()
	self.targetOnly = nil
	self.jumpBack = false

	_G.myHero.SaveMove = _G.myHero.MoveTo
	_G.myHero.SaveAttack = _G.myHero.Attack
	_G.myHero.MoveTo = function(...) if not self.skills.SkillR.castingUlt then _G.myHero.SaveMove(...) end end
	_G.myHero.Attack = function(...) if not self.skills.SkillR.castingUlt then _G.myHero.SaveAttack(...) end end

	AddDrawCallback(function() 
		self:OnDraw()
	end)
	self.jumpWardMinion = nil
	self.wardJumpProgress = 0

	AddCreateObjCallback(function(obj) self:ObjCreate(obj) end)
	self.lastWardObj = nil

	return self
end

function Katarina:disableMove()
	self.canMove = false
end

function Katarina:enableMove()
	self.canMove = true
end

function Katarina:OnTick()
	self:checks()
	self:QueueUpdate()

	if self.skills.SkillR.castingUlt then
		--SxOrb:DisableAttacks()
		--SxOrb:DisableMove() 
	else
		--SxOrb:EnableAttacks()
		--SxOrb:EnableMove() 		
	end

	if settings.combosettings.comboactive or (settings.misc.hitrun.hitandrun and self.targetOnly ~= nil) then
		self:Combo()
		moveToCursor()
	end

	if settings.farm.lastHit then
		self:lastHit()
		moveToCursor()
	end

	if settings.farm.clearKey then
		self:clearLane()
		moveToCursor()
	end

	if settings.harass.harassKey then
		self:harass()
		moveToCursor()
	end
end

function Katarina:checks()

	if self.targetOnly ~= nil then
		if settings.combosettings.targetOnlyDead and self.targetOnly.dead then
			if settings.misc.hitrun.moreTarget and settings.misc.hitrun.hitandrun then
				target = self:GetTarget(700)
				if target ~= nil then
					calc = self:GetKillTime(target)
					if calc.hardness < 4 then
						self.targetOnly = target
					end
				end
			end		
			if self.targetOnly.dead then
				self.targetOnly = nil
				if settings.misc.hitrun.hitandrun then
					self.jumpBack = true
				end
			end
		end
	end

	if self.jumpBack then
		local wardTo = myHero + (Vector(mousePos) - myHero):normalized()*500
		self:putWard(wardTo.x,wardTo.z)
	end

	self.skills.SkillQ.ready = (myHero:CanUseSpell(_Q) == READY)
	self.skills.SkillW.ready = (myHero:CanUseSpell(_W) == READY)
	self.skills.SkillE.ready = (myHero:CanUseSpell(_E) == READY)

	if myHero:CanUseSpell(_R) == READY  then
		self.skills.SkillR.ready = true
	else
		self.skills.SkillR.ready = false
	end

	if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then
		self.igniteFound = true
		self.summonerSpells.ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then
		self.igniteFound = true
		self.summonerSpells.ignite = SUMMONER_2
	end

	if myHero:GetSpellData(SUMMONER_1).name:find("summonerflash") then
		self.summonerSpells.flash = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerflash") then
		self.summonerSpells.flash = SUMMONER_2
	end


	self.items = {
		["BLACKFIRE"]	= { id = 3188, range = 750 },
		["BRK"]			= { id = 3153, range = 500 },
		["BWC"]			= { id = 3144, range = 450 },
		["DFG"]			= { id = 3128, range = 750 },
		["HXG"]			= { id = 3146, range = 700 },
		["ODYNVEIL"]	= { id = 3180, range = 525 },
		["DVN"]			= { id = 3131, range = 200 },
		["ENT"]			= { id = 3184, range = 350 },
		["HYDRA"]		= { id = 3074, range = 350 },
		["TIAMAT"]		= { id = 3077, range = 350 },
		["YGB"]			= { id = 3142, range = 350 }
	}

	if self.waitQ then
		if (os.clock() - self.lastQ) > 0.5 then
			self.waitQ = false
		end
	end

	if (os.clock() - self.lastWard) < 0.5 and self.skills.SkillE.ready then
		if self.lastWardObj ~= nil then	
			self:Cast("E", self.lastWardObj)
		end
	else
		self.lastWardObj = nil
	end

end

function Katarina:getCounter()
	return self.counter
end

function Katarina:GetKillTime(enemy)
	if enemy == nil then return -1 end
	dfgDmg, hxgDmg, bwcDmg, iDmg, bftDmg, liandrysDmg = 0, 0, 0, 0, 0, 0
	pDmg = ((self.skills.SkillQ.ready and getDmg("Q", enemy, myHero, 2)) or 0)
	qDmg = ((self.skills.SkillQ.ready and getDmg("Q",enemy, myHero)) or 0)
	wDmg = ((self.skills.SkillW.ready and getDmg("W",enemy, myHero)) or 0)
	eDmg = ((self.skills.SkillE.ready and getDmg("E",enemy, myHero)) or 0)
	rDmg = ((self.skills.SkillR.ready and getDmg("R",enemy, myHero)) or 0)
	dfgDmg = ((self.items.dfgReady and getDmg("DFG", enemy, myHero)) or 0)
	hxgDmg = ((self.items.hxgReady and getDmg("HXG", enemy, myHero)) or 0)
	bwcDmg = ((self.items.bwcReady and getDmg("BWC", enemy, myHero)) or 0)
	bftdmg = ((self.items.bftReady and getDmg("BLACKFIRE", enemy, myHero)) or 0)
	liandrysDmg = ((self.items.liandrysReady and getDmg("LIANDRYS", enemy, myHero)) or 0)
	iDmg = (getDmg("IGNITE", enemy, myHero) or 0)
	onspellDmg = liandrysDmg + bftDmg
	itemsDmg = dfgDmg + hxgDmg + bwcDmg + iDmg + onspellDmg
	--Calculation of time
	if enemy.health < eDmg and self.skills.SkillE.ready then
		return {time="E",attack="E",hardness = 1}
	end

	if enemy.health < wDmg and self.skills.SkillW.ready and GetDistance(myHero,enemy) < self.skills.SkillW.range then
		return {text="W",attack="W",hardness = 2}
	end

	if enemy.health < qDmg and self.skills.SkillQ.ready then
		return {text="Q",attack="Q",hardness = 3}
	end

	if enemy.health < qDmg and self.skills.SkillQ.ready and settings.combosettings.useignite and myHero:CanUseSpell(self.summonerSpells.ignite) == READY then
		return {text="Q + Ignite",attack="QI",hardness = 3}
	end

	if enemy.health < eDmg + wDmg and self.skills.SkillE.ready and self.skills.SkillW.ready then
		return {text="EW",attack="EW",hardness = 4}
	end

	if enemy.health < eDmg + wDmg + iDmg and self.skills.SkillE.ready and self.skills.SkillW.ready and self.igniteFound and settings.combosettings.useignite and myHero:CanUseSpell(self.summonerSpells.ignite) == READY then
		return {text="EW + Ignite",attack="EWI",hardness = 5}
	end

	if enemy.health < qDmg + pDmg + wDmg and self.skills.SkillQ.ready and self.skills.SkillW.ready and GetDistance(myHero,enemy) < self.skills.SkillW.range  then
		return {text="QW",attack="QW",hardness = 6}
	end

	if enemy.health < eDmg + wDmg + qDmg and self.skills.SkillE.ready and self.skills.SkillW.ready and  self.skills.SkillQ.ready then
		return {text="EQW",attack="EQW",hardness = 7}
	end

	if enemy.health < eDmg + wDmg + qDmg and self.skills.SkillE.ready and self.skills.SkillW.ready and  self.skills.SkillQ.ready and self.igniteFound and settings.combosettings.useignite and myHero:CanUseSpell(self.summonerSpells.ignite) == READY then
		return {text="EQW + Ignite",attack="EQWI",hardness = 8}
	end

	if enemy.health < qDmg + eDmg + wDmg + pDmg and self.skills.SkillE.ready and self.skills.SkillW.ready and  self.skills.SkillQ.ready then
		return {text="QWE",attack="QEW",hardness = 9}
	end

	if enemy.health < qDmg + eDmg + wDmg + rDmg + pDmg and self.skills.SkillE.ready and self.skills.SkillW.ready and  self.skills.SkillQ.ready and self.skills.SkillR.ready then
		return {text="QWER",attack="QEWR",hardness = 10}
	end

	if enemy.health < qDmg + eDmg + wDmg + rDmg + iDmg + pDmg and self.skills.SkillE.ready and self.skills.SkillW.ready and  self.skills.SkillQ.ready and self.skills.SkillR.ready and self.igniteFound and settings.combosettings.useignite and myHero:CanUseSpell(self.summonerSpells.ignite) == READY then
		return {text="QWER + Ignite",attack="QEWRI",hardness = 11}
	end

	if enemy.health < itemsDmg + qDmg + eDmg + wDmg + rDmg + iDmg + pDmg and self.skills.SkillE.ready and self.skills.SkillW.ready and  self.skills.SkillQ.ready and self.skills.SkillR.ready and self.igniteFound and settings.combosettings.useignite and myHero:CanUseSpell(self.summonerSpells.ignite) == READY then
		return {text="QWER + Ignite + Items",attack="DQEWRI",hardness = 12}
	end

	return {text="Harass Him",attack="DQEWRI",hardness=13}

end

function Katarina:QueueUpdate()
	queue = enemies:GetEnemyList(100000)
	if queue[1] ~= nil then
		table.sort(queue, compareByHardness)
	end
	self.targetQueue = queue
end

function Katarina:GetTarget(range,minRange)

	if self.targetOnly ~= nil and not self.targetOnly.dead then
		return self.targetOnly
	end

	if not minRange then 
		minRange = 0
	end
	for _, enemy in pairs(self.targetQueue) do
		if enemy.visible and not enemy.dead then
			if GetDistance(myHero,enemy) <= range and GetDistance(enemy) > minRange then
				return enemy
			end
		end
	end
	return nil
end

function Katarina:Combo()

	if settings.combosettings.flashjumpcombo and self.skills.SkillE.ready and not self.skills.SkillR.castingUlt and false then
		target = self:GetTarget(1200,750)
		if target ~= nil then 
			calc = self:GetKillTime(target)
			if calc and calc.hardness <= 9  then
				jumpPos = myHero + (Vector(target) - myHero):normalized()*400
				CastSpell(self.summonerSpells.flash,jumpPos.x,jumpPos.z)
			end
		end
	end

	if settings.combosettings.wardjumpcombo and self.skills.SkillQ.ready and not self.skills.SkillR.castingUlt then
		target = self:GetTarget(1200,750)
		if target ~= nil then 
			calc = self:GetKillTime(target)
			if calc and calc.hardness < 5 then
				jumpPos = myHero + (Vector(target) - myHero):normalized()*500
				self:putWard(jumpPos.x,jumpPos.z)
			end
	 	end
	end

	target = self:GetTarget(800)
	if target == nil then return end
	calc = self:GetKillTime(target)
	if self:canBreakUlt() then
		self.skills.SkillR.castingUlt = false
	end

	self:doCombo(calc,target)
end


function Katarina:doCombo(calc,target)
	if not self.skills.SkillR.castingUlt then
		self:UseItems(target)
		if self.skills.SkillE.ready then
			self:Cast("E",target) 
		end

		if self.skills.SkillQ.ready then
			self:Cast("Q",target) 
		end

		if self.skills.SkillW.ready and self.waitQ == false then
			self:Cast("W",target) 
		end

		if self.skills.SkillR.ready and not self.skills.SkillQ.ready and not self.skills.SkillW.ready and not self.skills.SkillE.ready then
			self:Cast("R",target) 
		end
	end
	if (getDmg("IGNITE", target, myHero) or 0) > target.health and self.igniteFound and settings.combosettings.useignite and myHero:CanUseSpell(self.summonerSpells.ignite) == READY then
		CastSpell(self.summonerSpells.ignite, target)
	end
end

function Katarina:UseItems(target)
	for i, Item in pairs(self.items) do
		local Item = self.items[i]
		if GetInventoryItemIsCastable(Item.id) and GetDistanceSqr(target) <= Item.range*Item.range then
			CastItem(Item.id, target)
		end
	end
end

function Katarina:harass()
	target = self:GetTarget(800)
	if target == nil then return end
	if self.skills.SkillE.ready and settings.harass.harasse then
		self:Cast("E",target) 
		return
	end

	if self.skills.SkillQ.ready then
		self:Cast("Q",target) 
		return
	end

	if self.skills.SkillW.ready and self.waitQ == false then
		self:Cast("W",target) 
		return
	end
end

function Katarina:lastHit()
  	for _, minion in pairs(minions.enemyMinions.objects) do

	    local qMinionDmg = getDmg("Q", minion, myHero)
	    local wMinionDmg = getDmg("W", minion, myHero)
	    local eMinionDmg = getDmg("E", minion, myHero)

  		if ValidTarget(minion) and minion ~= nil and self.skills.SkillW.ready and settings.farm.farmw then
  			if GetDistanceSqr(minion) <= self.skills.SkillW.range*self.skills.SkillW.range then
  				if minion.health <= (wMinionDmg) then
              		self:Cast("W",minion) 
	                break
	            end
            end
        end

        if ValidTarget(minion) and minion ~= nil and self.skills.SkillQ.ready and settings.farm.farmq then
  			if GetDistanceSqr(minion) <= self.skills.SkillQ.range*self.skills.SkillQ.range then
  				if minion.health <= (qMinionDmg) then
              		self:Cast("Q",minion) 
	                break
	            end
            end
        end

        if ValidTarget(minion) and minion ~= nil and self.skills.SkillE.ready and settings.farm.farme then
  			if GetDistanceSqr(minion) <= self.skills.SkillE.range*self.skills.SkillE.range then
  				if minion.health <= (eMinionDmg) then
              		self:Cast("E",minion) 
	                break
	            end
            end
        end
  	end
end

function Katarina:clearLane()
  	for _, minion in pairs(minions.enemyMinions.objects) do
  		if ValidTarget(minion) and minion ~= nil and self.skills.SkillQ.ready and settings.farm.farmq then
  			if GetDistanceSqr(minion) <= self.skills.SkillQ.range*self.skills.SkillQ.range then
          		self:Cast("Q",minion) 
            end
        end

        if ValidTarget(minion) and minion ~= nil and self.skills.SkillE.ready and settings.farm.farme then
  			if GetDistanceSqr(minion) <= self.skills.SkillE.range*self.skills.SkillE.range then
          		self:Cast("E",minion) 
            end
        end

        if ValidTarget(minion) and minion ~= nil and self.skills.SkillW.ready and settings.farm.farmw then
  			if GetDistanceSqr(minion) <= self.skills.SkillW.range*self.skills.SkillW.range then
          		self:Cast("W",minion) 
            end
        end
  	end

  	for _, minion in pairs(minions.jungleMinions.objects) do
  		if ValidTarget(minion) and minion ~= nil and self.skills.SkillQ.ready and settings.farm.farmq then
  			if GetDistanceSqr(minion) <= self.skills.SkillQ.range*self.skills.SkillQ.range then
          		self:Cast("Q",minion) 
            end
        end

        if ValidTarget(minion) and minion ~= nil and self.skills.SkillE.ready and settings.farm.farme then
  			if GetDistanceSqr(minion) <= self.skills.SkillE.range*self.skills.SkillE.range then
          		self:Cast("E",minion) 
            end
        end

        if ValidTarget(minion) and minion ~= nil and self.skills.SkillW.ready and settings.farm.farmw then
  			if GetDistanceSqr(minion) <= self.skills.SkillW.range*self.skills.SkillW.range then
          		self:Cast("W",minion) 
            end
        end
  	end
end

function Katarina:canBreakUlt()
	if self.skills.SkillR.castingUlt and settings.combosettings.breakult then
		local lowHpTargets = 0
		local nearTargest
		for _, enemy in pairs(self.targetQueue) do
			if enemy.visible and not enemy.dead then
				if GetDistance(myHero,enemy) <= self.skills.SkillQ.range then
					calc = self:GetKillTime(enemy)
					if calc.hardness <= 9 then
						lowHpTargets = lowHpTargets + 1
					end
				end
			end
		end
		if enemies:GetNearestEnemy(self.skills.SkillR.range) == nil and settings.combosettings.breakultnoEne then
			return true
		end
		if lowHpTargets >= 2 and self.skills.SkillQ.ready and self.skills.SkillW.ready and self.skills.SkillE.ready then
			return true			
		end
		return false    
	end   
end

function Katarina:putWard(x,y)
	if (os.clock() - self.lastWard) > 0.5 then
		local Slot = nil
		if string.find(GetSpellData(ITEM_7).name,"Trinket") and myHero:CanUseSpell(ITEM_7) == READY then
			Slot = ITEM_7
		end
		if not Slot then
			for itemPos = ITEM_1, ITEM_7 do
				if (string.find(myHero:GetSpellData(itemPos).name,"ItemGhostWard") or string.find(myHero:GetSpellData(itemPos).name,"sightward") or string.find(myHero:GetSpellData(itemPos).name,"VisionWard")) and myHero:CanUseSpell(itemPos) == READY then
					Slot = itemPos
				end
			end
		end
		if Slot ~= nil then
			self.lastWard = os.clock()
			CastSpell(Slot, x, y)
		end
	end
end

function Katarina:Cast(_type,enemy)
	if _type == "Q" and enemy ~= nil and self.skills.SkillQ.ready then
		if VIP_USER and settings.misc.packets then
			self.cassQTime = GetTickCount()
			Packet("S_CAST", {spellId = _Q, targetNetworkId = enemy.networkID}):send()
		else
			self.cassQTime = GetTickCount()
			CastSpell(_Q, enemy)
		end
	end
	if _type == "E" and enemy ~= nil and self.skills.SkillE.ready then
		if (os.clock() - self.lastE) > settings.combosettings.hdelay then
			if VIP_USER and settings.misc.packets then
				Packet("S_CAST", {spellId = _E, targetNetworkId = enemy.networkID}):send()
			else
				CastSpell(_E, enemy)
			end
		end
	end
	if _type == "W" and enemy ~= nil and self.skills.SkillW.ready then
		if VIP_USER and settings.misc.packets then
			if GetDistance(myHero,enemy) < self.skills.SkillW.range then
				CastSpell(_W)
			end
		else
			if GetDistance(myHero,enemy) < self.skills.SkillW.range then
				CastSpell(_W)
			end
		end
	end
	if _type == "R" and enemy ~= nil and self.skills.SkillR.ready and GetDistance(myHero,enemy) <= self.skills.SkillR.range then
		if VIP_USER and settings.misc.packets then
			CastSpell(_R)
		else
			CastSpell(_R)
		end
	end
end

function Katarina:markQ(unit, source,  buff)
	if unit == myHero and buff.name == 'katarinaqmark' then
		self.waitQ = false
	end
end

function Katarina:unBuff(unit, buff)
	if unit.isMe and buff.name == "katarinarsound" then
		self.skills.SkillR.castingUlt = false
	end
end

function Katarina:onSpell(unit,spell,endPos,target)
	if unit == myHero then
		if spell.name == 'KatarinaQ' then
			self.waitQ = true
			self.lastQ = os.clock()
		end
	end
end

function Katarina:ObjCreate(obj)
	if (os.clock() - self.lastWard) < 0.5 then
		if obj.valid and (string.find(obj.name, "Ward") ~= nil or string.find(obj.name, "Wriggle") ~= nil or string.find(obj.name, "Trinket")) then
			self.lastWardObj = obj
			self.jumpBack = false
		end
	end
end

function Katarina:OnDraw()

	if settings.misc.kjump.wardJump then
		
		local p1 = WorldToScreen(myHero.pos)
	    local p2 = WorldToScreen(mousePos) 
	    --Calculation for Ward
	    if GetDistance(mousePos) > 600 then
		    ward = myHero + (Vector(mousePos) - myHero):normalized()*600
		else
			ward = myHero + (Vector(mousePos) - myHero)
		end

		if self.skills.SkillE.ready then
		    minionFound = false
		    minionDist = 9999

		    for _, minion in pairs(minions.allyMinions.objects) do
		  		if GetDistance(minion,ward) < 200 and not minion.dead then
		  			if minionDist > GetDistance(mousePos,minion) then
		  				minionDist = GetDistance(mousePos,minion)
			  			minionFound = minion
			  		end
		        end
		  	end

		  	for _, minion in pairs(minions.enemyMinions.objects) do
		  		if GetDistance(minion,ward) < 200 and not minion.dead then
		  			if minionDist > GetDistance(mousePos,minion) then
		  				minionDist = GetDistance(mousePos,minion)
			  			minionFound = minion
			  		end
		        end
		  	end

		  	for _, minion in pairs(minions.jungleMinions.objects) do
		  		if GetDistance(minion,ward) < 200 and not minion.dead then
		  			if minionDist > GetDistance(mousePos,minion) then
		  				minionDist = GetDistance(mousePos,minion)
			  			minionFound = minion
			  		end
		        end
		  	end

		  	if minionFound then
		  		ward = minionFound
		  	end

  		    drawing:DrawCircle(ward.x, ward.y, ward.z, 50, ARGB(255,0,255,0))
			localLinePos = WorldToScreen(D3DXVECTOR3(ward.x,ward.y,ward.z))
    		DrawLine(p1.x, p1.y, localLinePos.x, localLinePos.y, 2, ARGB(255,0,255,0))

    		if not minionFound then
		    	DrawText("Ward Jump Here",14,localLinePos.x-20,localLinePos.y-20,ARGB(255,0,255,0))
		    else
	    		DrawText("Minion Jump Here",14,localLinePos.x-20,localLinePos.y-20,ARGB(255,0,255,0))
		    end

		    if GetDistance(mousePos) < 600 then
		    	if minionFound then
			    	self:Cast("E",minionFound) 
			    else
			    	self:putWard(ward.x,ward.z)
			    end
		    end

		    --Calculation for error rate
		    if GetDistance(mousePos) > 600 then
		    	if GetDistance(mousePos) < 600 + settings.misc.kjump.secureLength then
				    errorRate = ward + (Vector(mousePos) - ward)
				    errorLinePos = WorldToScreen(D3DXVECTOR3(errorRate.x,errorRate.y,errorRate.z))
				    DrawLine(localLinePos.x, localLinePos.y, errorLinePos.x, errorLinePos.y, 2, ARGB(255,255,0,0))
				    DrawText("Secure Length",14,errorLinePos.x-20,errorLinePos.y-20,ARGB(255,255,0,0))
				    --Jump case 1,1
				    if minionFound then
				    	self:Cast("E",minionFound) 
				    else
				    	self:putWard(ward.x,ward.z)
				    end
				else
					errorRate = ward + (Vector(mousePos) - ward):normalized()*settings.misc.kjump.secureLength
				    errorLinePos = WorldToScreen(D3DXVECTOR3(errorRate.x,errorRate.y,errorRate.z))
				    DrawLine(localLinePos.x, localLinePos.y, errorLinePos.x, errorLinePos.y, 2, ARGB(255,255,0,0))
				end

			end
			
			--Calculation for Flash
			if GetDistance(mousePos) > 600 + settings.misc.kjump.secureLength then
				if GetDistance(mousePos) < 1200 then
					flashPos = errorRate + (Vector(mousePos) - errorRate)
				    drawing:DrawCircle(flashPos.x, flashPos.y, flashPos.z, 50, ARGB(255,255,255,0))
				    flashLinePos = WorldToScreen(D3DXVECTOR3(flashPos.x,flashPos.y,flashPos.z))
				    DrawLine(errorLinePos.x, errorLinePos.y, flashLinePos.x, flashLinePos.y, 2, ARGB(255,255,255,0))
				else
					flashPos = errorRate + (Vector(mousePos) - errorRate):normalized()*(1200-settings.misc.kjump.secureLength-600)
				    drawing:DrawCircle(flashPos.x, flashPos.y, flashPos.z, 50, ARGB(255,255,255,0))
				    flashLinePos = WorldToScreen(D3DXVECTOR3(flashPos.x,flashPos.y,flashPos.z))
				    DrawLine(errorLinePos.x, errorLinePos.y, flashLinePos.x, flashLinePos.y, 2, ARGB(255,255,255,0))
				end
				DrawText("Flash Here",14,flashLinePos.x-20,flashLinePos.y-20,ARGB(255,255,255,0))
				--Jump case 1,2
				if minionFound then
			    	self:Cast("E",minionFound) 
			    else
			    	self:putWard(ward.x,ward.z)
			    end
			end
		else
			if GetDistance(mousePos) < settings.misc.kjump.secureLength then
			    DrawLine(p1.x, p1.y, p2.x, p2.y, 2, ARGB(255,255,0,0))
			    DrawText("Secure Length",14,p2.x-20,p2.y-20,ARGB(255,255,0,0))
			else
				errorRate = myHero + (Vector(mousePos) - myHero):normalized()*settings.misc.kjump.secureLength
			    errorLinePos = WorldToScreen(D3DXVECTOR3(errorRate.x,errorRate.y,errorRate.z))
			    DrawLine(p1.x, p1.y, errorLinePos.x, errorLinePos.y, 2, ARGB(255,255,0,0))
			end
			if GetDistance(mousePos) > settings.misc.kjump.secureLength and settings.misc.kjump.kjumpflash then
				if GetDistance(mousePos) < 500 then	
				    flashPos = errorRate + (Vector(mousePos) - errorRate)
				    drawing:DrawCircle(flashPos.x, flashPos.y, flashPos.z, 50, ARGB(255,255,255,0))
				    flashLinePos = WorldToScreen(D3DXVECTOR3(flashPos.x,flashPos.y,flashPos.z))
				    DrawLine(errorLinePos.x, errorLinePos.y, flashLinePos.x, flashLinePos.y, 2, ARGB(255,255,255,0))
				else
					flashPos = errorRate + (Vector(mousePos) - errorRate):normalized()*(500-settings.misc.kjump.secureLength)
				    drawing:DrawCircle(flashPos.x, flashPos.y, flashPos.z, 50, ARGB(255,255,255,0))
				    flashLinePos = WorldToScreen(D3DXVECTOR3(flashPos.x,flashPos.y,flashPos.z))
				    DrawLine(errorLinePos.x, errorLinePos.y, flashLinePos.x, flashLinePos.y, 2, ARGB(255,255,255,0))
				end
				--Jump case 2,1
				flashTo = myHero + (Vector(mousePos) - myHero):normalized()*400
				CastSpell(self.summonerSpells.flash,flashTo.x,flashTo.z)
				--myHero:MoveTo(flashPos.x,flashPos.z)
			end
	  	end   
	  	moveToCursor()
	end

	if self.targetOnly ~= nil then
	    
	    if settings.misc.hitrun.hitandrun then
	    	local enemyVec = WorldToScreen(self.targetOnly.pos)
	    	local mouseVec = WorldToScreen(mousePos) 
	    	DrawLine(enemyVec.x, enemyVec.y, mouseVec.x, mouseVec.y, 3, ARGB(255,50,0,255))
	    	DrawText("Trying Hit & Run on " .. self.targetOnly.charName, 30, 100, 150, ARGB(255,50,0,255))
	    else
	    	DrawText("Targeting only " .. self.targetOnly.charName, 30, 100, 150, 0xFF88FF00)
	    end
	end
end

--[[


	Drawing Controller


]]

class 'VisualManager'
function VisualManager:__init()
	self.textColor = ARGB(255, 32,178,170)
	return self
end

function VisualManager:print(txt,color)
	if color == "red" then
		print("<font color='#FF0000'>[Kitty Kat Katarina] " .. txt .. "</font>") 
	end
	if color == "green" then
		print("<font color='#00FF00'>[Kitty Kat Katarina] " .. txt .. "</font>") 
	end
	if color == "blue" then
		print("<font color='#0000FF'>[Kitty Kat Katarina] " .. txt .. "</font>") 
	end
	if color == "orange" then
		print("<font color='#FF9900'>[Kitty Kat Katarina] " .. txt .. "</font>") 
	end
end

function VisualManager:pchat(txt)
	PrintChat("[Kitty Kat Katarina] " .. txt)
end

function VisualManager:OnDraw()
	

	local targetsConnected = {}
	for _, enemy in pairs(GetEnemyHeroes()) do
		if not enemy.dead and enemy.visible then
			calc = kat:GetKillTime(enemy)
			local barPos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z)) 
			local PosX = barPos.x - 35
			local PosY = barPos.y - 10
			DrawText(calc.text, 18, PosX, PosY, ARGB(255,255,204,0))
			

			target = kat:GetTarget(1000)
			if target ~= nil then
				self:DrawCircle(target.x, target.y, target.z, 100, ARGB(255,255,0,0))
			end
			if enemy ~= target then
				self:DrawCircle(enemy.x, enemy.y, enemy.z, 100, ARGB(255,255,255,255))
			end
		end
		if target ~= nil and ValidTarget(target,1000) and target.visible and not myHero.dead then
			drawLineshit(myHero,target, 0xFF0000, 1)
		end
		for _, enem in pairs(kat.targetQueue) do
			--DrawText(_..":"..enem.charName .. " Health:"..enem.health, 30, 100, 150+(_*20), 0xFF88FF00)
			if  (kat.targetQueue[(_+1)] ~= nil and not kat.targetQueue[(_+1)].dead and not enem.dead and enem.visible) and GetDistance(enem,kat.targetQueue[(_+1)]) <= 700 then
				drawLineshit(enem,kat.targetQueue[(_+1)], 0xFFFF0000, 1)
			end
		end
	end
	self:DrawCircle(myHero.x, myHero.y, myHero.z, 700, ARGB(255,255,0,0))
end

function VisualManager:DrawCircle(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
	
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
		self:DrawCircleNextLvl(x, y, z, radius, 1, color, 300) 
	end
end

function VisualManager:DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8, self:Round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
	quality = 2 * math.pi / quality
	radius = radius * .92
	local points = {}
	
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)
end
function VisualManager:Round(number)
	if number >= 0 then 
		return math.floor(number+.5) 
	else 
		return math.ceil(number-.5) 
	end
end

function VisualManager:OnTick()

end


--[[


	Enemies Controller


]]

class 'Enemies'
function Enemies:__init()
	self.enemyList = GetEnemyHeroes()
	return self
end

function Enemies:getLowestHp(range)
	range = range or 675
	returnEnemy = nil
	for _, enemy in pairs(self.enemyList) do
        if (ValidTarget(enemy, range) and not enemy.dead) or (returnEnemy == nil and not returnEnemy.dead) then
            if returnEnemy == nil then
            	returnEnemy = enemy
            else
            	if returnEnemy.health > enemy.health then
            		returnEnemy = enemy
            	end
            end
        end
    end
    return returnEnemy
end

function Enemies:GetNearestEnemy(range)
	range = range or 675
	returnEnemy = nil
	for _, enemy in pairs(self.enemyList) do
        if ValidTarget(enemy, range) and not enemy.dead then
            if returnEnemy == nil or GetDistance(myHero,enemy) <= 675 then
            	returnEnemy = enemy
            end
        end
    end
    return returnEnemy
end

function Enemies:GetEnemyList(range)
	range = range or 675
	local list = {}
	for _, enemy in pairs(self.enemyList) do
        if ValidTarget(enemy, range) and not enemy.dead and enemy.visible then
			if  GetDistance(myHero,enemy) <= range then
            	table.insert(list, enemy)
            end
        end
    end
    return list
end



--[[


	Minions Controller


]]


class 'Minions'
function Minions:__init()
	self.enemyMinions = minionManager(MINION_ENEMY, 675, player, MINION_SORT_HEALTH_ASC)
	self.allyMinions = minionManager(MINION_ALLY, 675, player, MINION_SORT_HEALTH_ASC)
	self.jungleMinions = minionManager(MINION_JUNGLE,  675, myHero, MINION_SORT_HEALTH_ASC)
	return self
end

function Minions:update()
	self.enemyMinions:update()
	self.jungleMinions:update()
	self.allyMinions:update()
end

function Minions:OnTick()
	self:update()
end






--[[


	Init


]]



drawing = VisualManager()
drawing:print("Loading...","orange")
scriptController = KittyKat()
scriptController:requireLibs()
enemies = Enemies()
minions = Minions()
kat = Katarina()
--vPred = VPrediction()


if scriptController:checkValidate() then
	drawing:print("Script validated and ready to run, good luck have fun!","green")
else
	drawing:print("Script not loaded","red")
end

AddApplyBuffCallback(function(unit, source, buff) 
	kat:markQ(unit, source, buff) 
end)

AddRemoveBuffCallback(function(unit, buff) 
	kat:unBuff(unit, buff) 
end)

AddTickCallback(function() 
	minions:OnTick() 
	kat:OnTick()
end)

AddDrawCallback(function() 
	drawing:OnDraw()
end)

AddCreateObjCallback(function(obj) 
	--kat:ObjCreate(obj) 
end)

AddDeleteObjCallback(function(obj) 
	--kat:ObjDelete(obj) 
end)

AddProcessSpellCallback(function(unit,spell) 
	kat:onSpell(unit,spell) 
end)


function OnLoad()
	settings = scriptConfig("Kitty Kat Katarina", "kittykat")
	--settings:addSubMenu("Stats","stats")
	--settings.stats:addParam("killcounter", "Kills of Kitty Kat Katarina:", SCRIPT_PARAM_INFO, "1853789")
	--settings.stats:addParam("gamecounter", "Games with Kitty Kat Katarina:", SCRIPT_PARAM_INFO, "5234")
	settings:addSubMenu("Combo", "combosettings")
	settings.combosettings:addParam("comboactive", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	settings.combosettings:addParam("useignite", "Use ignite in combo", SCRIPT_PARAM_ONOFF, true)
	settings.combosettings:addParam("breakult", "Break ult for fast reactions", SCRIPT_PARAM_ONOFF, true)
	settings.combosettings:addParam('wardjumpcombo',  'Use ward jump in combo',SCRIPT_PARAM_ONOFF, true)
	settings.combosettings:addParam('flashjumpcombo',  'Use flash jump in combo',SCRIPT_PARAM_ONOFF, true)
	settings.combosettings:addParam('targetOnly',  'Left click to lock target',SCRIPT_PARAM_ONOFF, true)
	settings.combosettings:addParam('targetOnlyDead',  'Release locked target when enemy dead',SCRIPT_PARAM_ONOFF, true)
	settings.combosettings:addParam("breakultnoEne", "Break when no enemy", SCRIPT_PARAM_ONOFF, true)
	settings.combosettings:addParam('hdelay',  'Humanizer Delay',     SCRIPT_PARAM_SLICE, 1, 0, 500, 1)
	settings.combosettings:permaShow("comboactive")
	settings:addSubMenu("Misc","misc")
	settings.misc:addSubMenu("Katarina Jump","kjump")
	settings.misc:addSubMenu("Hit & Run","hitrun")
	settings.misc.hitrun:addParam("hitandrun", "Hit & Run Key (select target before)", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('T'))
	settings.misc.hitrun:permaShow("hitandrun")
	settings.misc.hitrun:addParam("moreTarget", "Jump if other targets also killable", SCRIPT_PARAM_ONOFF, true)
	settings.misc.kjump:addParam("wardJump", "Jump Kata Key", SCRIPT_PARAM_ONKEYDOWN, false, 17)
	settings.misc.kjump:permaShow("wardJump")
	settings.misc.kjump:addParam("kjumpflash", "Flash if needed", SCRIPT_PARAM_ONOFF, false)
	settings.misc.kjump:addParam('secureLength',  'Secure Length for Flash',     SCRIPT_PARAM_SLICE, 1, 0, 450, 1)
	settings:addSubMenu("Farm","farm")
	settings:addSubMenu("Harass","harass")
	settings.harass:addParam("harassKey", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('C'))
	settings.harass:addParam("harasse", "Use E in harass", SCRIPT_PARAM_ONOFF, true)
	settings.harass:permaShow("harassKey")
	settings.farm:addParam("lastHit", "Last Hit", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('X'))
	settings.farm:addParam("clearKey", "Clear Lane", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('V'))
	settings.farm:addParam("farmq", "Use Q in farming", SCRIPT_PARAM_ONOFF, true)
	settings.farm:addParam("farmw", "Use W in farming", SCRIPT_PARAM_ONOFF, true)
	settings.farm:addParam("farme", "Use E in farming", SCRIPT_PARAM_ONOFF, true)
	settings.farm:permaShow("lastHit")
	settings.farm:permaShow("clearKey")
	settings.farm.lastHit = false
	settings.farm.clearKey = false
	settings.combosettings:permaShow("comboactive")
	if VIP_USER then settings.misc:addParam("packets", "Use Packets", SCRIPT_PARAM_ONOFF, true) end
	settings:addSubMenu('Orbwalker', 'orbwalk')
	--SxOrb:LoadToMenu(settings.orbwalk, true)
	--SxOrb:RegisterHotKey('fight',     settings.combosettings, 'comboactive')
	--SxOrb:RegisterHotKey('fight',     settings.misc.hitrun, 'hitandrun')
	--SxOrb:RegisterHotKey('harass',    settings.harass, 'harassKey')
	--SxOrb:RegisterHotKey('laneclear', settings.farm, 'clearKey')
	--SxOrb:RegisterHotKey('lasthit',   settings.farm, 'lastHit')
	settings.misc.packets = false
end

function OnCreateObj(object)
	if object.name:find("katarina_daggered") then 
		kat:markedQ()
	end
	if (object.name:find("katarina_deathLotus_mis.troy") or object.name:find("katarina_deathLotus_tar.troy")) then
		if GetDistanceSqr(object, myHero) <= 70*70 then
			kat.skills.SkillR.castingUlt = false
		end
	end
end

function OnGainBuff(unit, buff)
	if unit.isMe and buff.name == "katarinarsound" then
		kat.skills.SkillR.castingUlt = true
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name == "katarinarsound" then
		kat.skills.SkillR.castingUlt = false
	end
end

function OnCastSpell(iSpell,startPos,endPos,targetUnit)
	if iSpell == 3 then
		kat.skills.SkillR.castingUlt = true
	end
	if iSpell == 2 then
		kat.lastE = os.clock()
	end
end



--[[

Mechanics

]]

function compareByHealth(a,b)
  return a.health < b.health
end

function compareByHardness(a,b)
  	if kat:GetKillTime(a).hardness ~= kat:GetKillTime(b).hardness then
  		return kat:GetKillTime(a).hardness < kat:GetKillTime(b).hardness
  	else
  		return a.health < b.health
	end
end

function drawLineshit(point1, point2, color, width)
    local p1 = WorldToScreen(point1.pos)
    local p2 = WorldToScreen(point2.pos) 
    DrawLine(p1.x, p1.y, p2.x, p2.y, 3, ARGB(0xFF,0xFF,0xFF,0xFF))
end 

function moveToCursor()
	if GetDistance(mousePos) then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
		--_G.NebelwolfisOrbWalker:ForcePoint(moveToPos.x, moveToPos.z)
	end		
end

function OnWndMsg(msg,key)
	if msg == WM_LBUTTONDOWN then
	    local dist = 1000000
	    local tempTarget = nil
	    
	    for i, enemy in ipairs(enemies.enemyList) do
	      if enemy~= nil and not enemy.dead then
	        if GetDistance(enemy, mousePos) <= dist then
	          dist = GetDistance(enemy, mousePos)
	          tempTarget = enemy
	        end
	      end
	    end
	    
	    if tempTarget ~= nil then
	      if dist < 250 then
	        kat.targetOnly = tempTarget
	        return
	      end
	    end
	    kat.targetOnly = nil
  	end
end
