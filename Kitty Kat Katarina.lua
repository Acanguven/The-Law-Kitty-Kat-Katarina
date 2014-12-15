local version = "1"

-- Encryption starts from here
--
--
--
--
--
--
--
print("<font color='#FF9900'>[Kitty Kat Katarina] Starting Kitty Kat Katarina with version : ".. version .."</font>")
print("<font color='#FF9900'>[Kitty Kat Katarina] Checking for any update...</font>")
--
--
--
-------------
--
--
--
--
--   Update
--
--
--
-------------
local SELF = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local URL = "https://raw.githubusercontent.com/zikenzie/Kitty-Kat-Katarina/master/Kitty%20Kat%20Katarina.lua?token=AA8QJkIF-6Jj2_1VGIpwAim1LXNQQ4P6ks5Ul8DRwA%3D%3D"
local UPDATE_TMP_FILE = LIB_PATH .."kittytempupdater.txt" .. math.random(100000)

function Update()
  local url = URL .. "&random=" .. math.random(100000)
  DownloadFile(url, UPDATE_TMP_FILE, UpdateCallback)

end


function UpdateCallback()
  file = io.open(UPDATE_TMP_FILE, "rb")
  if file ~= nil then
    content = file:read("*all")
    file:close()
    os.remove(UPDATE_TMP_FILE)
    if content then
      tmp, sstart = string.find(content, "local version = \"")
      if sstart then
        send, tmp = string.find(content, "\"", sstart+1)
      end
      if send then
        Version = tonumber(string.sub(content, sstart+1, send-1))
      end
      if (Version ~= nil)  and  (Version > tonumber(version)) then
        file = io.open(SELF, "w")
        if file then
          file:write(content)
          file:flush()
          file:close()
          print("<font color='#00FF00'>[Kitty Kat Katarina] Kitty Kat Katarina updated to version: "..Version) 
          print("<font color='#FF0000'>[Kitty Kat Katarina] Please press F9 twice to reload.</font>")
        else
          print("<font color='#FF0000'>[Kitty Kat Katarina] Error updating the script, some features will not work.</font>") 
        end
      else         
        print("<font color='#FF9900'>[Kitty Kat Katarina] is up to date.</font>")
      end
    end
  end
end

Update()

if myHero.charName ~= "Katarina" then 
  print("<font color='#FF0000'>[Kitty Kat Katarina] You must play with Katarina to use my godly skills.</font>") 
  return 
end


local actionRange = 730
local SPACE = 32
local KeyC = 67
local KeyV = 86
local KeyX = 88
local KeyZ = 90
local qRange = 675
local wRange = 375
local eRange = 700
local rRange = 550
local wardRange = 600
local ID = {DFG = 3128, HXG = 3146, BWC = 3144, Sheen = 3057, Trinity = 3078, LB = 3100, IG = 3025, LT = 3151, BT = 3188, STI = 3092, RO = 3143, BRK = 3153}
local Slot = {Q = _Q, W = _W, E = _E, R = _R, I = nil, DFG = nil, HXG = nil, BWC = nil, Sheen = nil, Trinity = nil, LB = nil, IG = nil, LT = nil, BT = nil, STI = nil, RO = nil, BRK = nil}
local RDY = {Q = false, W = false, E = false, R = false, I = false, DFG = false, HXG = false, BWC = false, STI = false, RO = false, BRK = false}
local usableWards = {TrinketWard = false,RubySightStone=false,SightStone=false,SightWard=false,VisionWard=false}
local lastAttack = 0
local lastAttackCD = 0
local lastWindUpTime = 0
local attacked = false
local distancetarget
local Wards = {}
local timeq = 0
local spinnig = false
local lastqmark = 0
local ultActive = false
local timeult = 0
local ts
local allyHeroes
local enemyHeroes
local willJump = true
local disableScript = false
local haveflash = false
local flashShot = nil
local targetOnly = nil

if myHero:GetSpellData(SUMMONER_1).name:lower():find("summonerdot") then 
  Slot.I = SUMMONER_1 
elseif myHero:GetSpellData(SUMMONER_2).name:lower():find("summonerdot") then 
  Slot.I = SUMMONER_2 
end
if myHero:GetSpellData(SUMMONER_1).name:find("summonerflash") then 
    haveflash = true
    flashSlot = SUMMONER_1
elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerflash") then 
    flashSlot = SUMMONER_2
    haveflash = true
end

local waittxt = {}
local calculationenemy = 1
local floattext = {"Dont even try","Maybe","Kill","FREE KILL!"}
local killable = {}
local tick = nil
--------------------
-- Builtin speeldmg calculator
--
--
if getDmg == nil then
  function getDmg(spellname,target,owner,stagedmg,spelllvl)
        local name = owner.charName
        local lvl = owner.level
        local ap = owner.ap
        local ad = owner.totalDamage
        local bad = owner.addDamage
        local ar = owner.armor
        local mmana = owner.maxMana
        local mana = owner.mana
        local mhp = owner.maxHealth
        local tap = target.ap
        local thp = target.health
        local tmhp = target.maxHealth
        local Qlvl = spelllvl and spelllvl or owner:GetSpellData(_Q).level
        local Wlvl = spelllvl and spelllvl or owner:GetSpellData(_W).level
        local Elvl = spelllvl and spelllvl or owner:GetSpellData(_E).level
        local Rlvl = spelllvl and spelllvl or owner:GetSpellData(_R).level
        local stagedmg1,stagedmg2,stagedmg3 = 1,0,0
        if stagedmg == 2 then stagedmg1,stagedmg2,stagedmg3 = 0,1,0
        elseif stagedmg == 3 then stagedmg1,stagedmg2,stagedmg3 = 0,0,1 end
        local TrueDmg = 0
        local TypeDmg = 1 --1 ability/normal--2 bonus to attack
        if ((spellname == "Q" or spellname == "QM") and Qlvl == 0) or ((spellname == "W" or spellname == "WM") and Wlvl == 0) or ((spellname == "E" or spellname == "EM") and Elvl == 0) or (spellname == "R" and Rlvl == 0) then
                TrueDmg = 0
        elseif spellname == "Q" or spellname == "W" or spellname == "E" or spellname == "R" or spellname == "P" or spellname == "QM" or spellname == "WM" or spellname == "EM" then
                local DmgM = 0
                local DmgP = 0
                local DmgT = 0
                
                if name == "Katarina" then
                    if spellname == "Q" then DmgM = math.max((25*Qlvl+35+.45*ap)*stagedmg1,(15*Qlvl+.15*ap)*stagedmg2,(40*Qlvl+35+.6*ap)*stagedmg3) --stage1:Dagger, Each subsequent hit deals 10% less damage. stage2:On-hit. stage3: Max damage
                    elseif spellname == "W" then DmgM = 40*Wlvl+.25*ap+.5*bad
                    elseif spellname == "E" then DmgM = 25*Elvl+35+.5*ap
                    elseif spellname == "R" then DmgM = math.max(10*Rlvl+30+.175*ap+.3*bad,(10*Rlvl+30+.175*ap+.3*bad)*10*stagedmg3) --xdagger (champion can be hit by a maximum of 10 daggers (2 sec)). stage3: Max damage
                    end
                end
                
                if DmgM > 0 then DmgM = owner:CalcMagicDamage(target,DmgM) end
                if DmgP > 0 then DmgP = owner:CalcDamage(target,DmgP) end
                TrueDmg = DmgM+DmgP+DmgT
        elseif (spellname == "AD") then
                TrueDmg = owner:CalcDamage(target,ad)
        elseif (spellname == "IGNITE") then
                TrueDmg = 50+20*lvl
        elseif (spellname == "SMITESS") then
                TrueDmg = 54+6*lvl --60-162 over 3 seconds
        elseif (spellname == "SMITESB") then
                TrueDmg = 20+8*lvl --28-164
        elseif (spellname == "DFG") then
                TrueDmg = owner:CalcMagicDamage(target,.15*tmhp)
        elseif (spellname == "HXG") then
                TrueDmg = owner:CalcMagicDamage(target,150+.4*ap)
        elseif (spellname == "BWC") then
                TrueDmg = owner:CalcMagicDamage(target,100)
        elseif (spellname == "KITAES") then
                TrueDmg = owner:CalcMagicDamage(target,.025*tmhp)
        elseif (spellname == "NTOOTH") then
                TrueDmg = owner:CalcMagicDamage(target,15+.15*ap)
        elseif (spellname == "WITSEND") then
                TrueDmg = owner:CalcMagicDamage(target,42)
        elseif (spellname == "SHEEN") then
                TrueDmg = owner:CalcDamage(target,ad-bad) --(bonus)
        elseif (spellname == "TRINITY") then
                TrueDmg = owner:CalcDamage(target,2*(ad-bad)) --(bonus)
        elseif (spellname == "LICHBANE") then
                TrueDmg = owner:CalcMagicDamage(target,.75*(ad-bad)+.5*ap) --(bonus)
        elseif (spellname == "LIANDRYS") then
                TrueDmg = owner:CalcMagicDamage(target,.06*thp) --over 3 sec, If their movement is impaired, they take double damage from this effect
        elseif (spellname == "BLACKFIRE") then
                TrueDmg = owner:CalcMagicDamage(target,.035*tmhp) --over 2 sec
        elseif (spellname == "STATIKK") then
                TrueDmg = owner:CalcMagicDamage(target,100)
        elseif (spellname == "ICEBORN") then
                TrueDmg = owner:CalcDamage(target,1.25*(ad-bad)) --(bonus)
        elseif (spellname == "TIAMAT") then
                TrueDmg = owner:CalcDamage(target,.6*ad) --decaying down to 33.33% near the edge (20% of ad)
        elseif (spellname == "HYDRA") then
                TrueDmg = owner:CalcDamage(target,.6*ad) --decaying down to 33.33% near the edge (20% of ad)
        elseif (spellname == "RUINEDKING") then
                TrueDmg = math.max(owner:CalcDamage(target,.08*thp)*(stagedmg1+stagedmg3),owner:CalcDamage(target,math.max(.1*tmhp,100))*stagedmg2) --stage1-3:Passive. stage2:Active.
        elseif (spellname == "MURAMANA") then
                TrueDmg = owner:CalcDamage(target,.06*mana)
        elseif (spellname == "HURRICANE") then
                TrueDmg = owner:CalcDamage(target,10+.5*ad) --apply on-hit effects
        elseif (spellname == "SUNFIRE") then
                TrueDmg = owner:CalcMagicDamage(target,25+lvl) --x sec
        elseif (spellname == "LIGHTBRINGER") then
                TrueDmg = owner:CalcMagicDamage(target,100) -- 20% chance
        elseif (spellname == "MOUNTAIN") then
                TrueDmg = owner:CalcMagicDamage(target,.3*ap+ad)
        elseif (spellname == "SPIRITLIZARD" or spellname == "ISPARK" or spellname == "MADREDS" or spellname == "ECALLING" or spellname == "EXECUTIONERS" or spellname == "MALADY") then
                TrueDmg = 0
        else
                PrintChat("Error spellDmg "..name.." "..spellname)
                TrueDmg = 0
        end
        return TrueDmg, TypeDmg
  end
end
-------------------
--
--
function OnLoad()
  ComboSettings = scriptConfig("Kitty Kat Katarina Combo", "katarinacombo")
  ComboSettings:addParam("activateCombo", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, SPACE)
  ComboSettings:addParam("comboToggle", "Combo Toogle", SCRIPT_PARAM_ONKEYTOGGLE, false, KeyV)
  ComboSettings:addParam("igniteEnabled", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
  ComboSettings:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
  ComboSettings:addParam("useult", "Use Ulti", SCRIPT_PARAM_ONOFF, true)
  ComboSettings:addParam("noobMode", "Noob Mode", SCRIPT_PARAM_ONOFF, false)
  ComboSettings:addParam("noobModeinf", "Noob Mode-Anti Cheat Detection: It wont break ulti and jump.", SCRIPT_PARAM_INFO, "")
  ComboSettings:addParam("noobModeRate", "Noob Rate (Higher is noober)", SCRIPT_PARAM_SLICE, 300, 0, 1000, 0)
  ComboSettings:addParam("noobModeinf2", "Noob Rate will be calculated if you activated Noob Mode", SCRIPT_PARAM_INFO, "")
  ComboSettings:addParam("noobModeinf3", "Noob Mode is not working due to current status of BoL", SCRIPT_PARAM_INFO, "")
  
  HarassSettings = scriptConfig("Kitty Kat Katarina Harass", "katarinaharas")
  HarassSettings:addParam("activateHarass", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, KeyC)
  HarassSettings:addParam("harassToggle", "Harass Toggle", SCRIPT_PARAM_ONKEYTOGGLE, false, KeyX)
  HarassSettings:addParam("igniteEnabled", "Use Ignite when killable", SCRIPT_PARAM_ONOFF, true)
  HarassSettings:addParam("waitW", "Wait for mark before W", SCRIPT_PARAM_ONOFF, true)
  HarassSettings:addParam("mouseMove", "Move to Mouse", SCRIPT_PARAM_ONOFF, true)
  HarassSettings:addParam("mode", "Harass Type", SCRIPT_PARAM_SLICE, 0, 1, 2, 0)
  HarassSettings:addParam("m1", "Harass Type 1 = Q - W", SCRIPT_PARAM_INFO, "")
  HarassSettings:addParam("m2", "Harass Type 2 = E - Q - W", SCRIPT_PARAM_INFO, "")
  
  FarmSettings = scriptConfig("Kitty Kat Katarina Farm", "katarinafarm")
  FarmSettings:addParam("activateFarm", "Farm Key", SCRIPT_PARAM_ONKEYDOWN, false, KeyZ)
  FarmSettings:addParam("mouseMove", "Move to Mouse", SCRIPT_PARAM_ONOFF, true)
  FarmSettings:addParam("farmQ", "Farm With Q", SCRIPT_PARAM_ONOFF, true)
  FarmSettings:addParam("farmW", "Farm With W", SCRIPT_PARAM_ONOFF, true)
  FarmSettings:addParam("farmE", "Farm With E", SCRIPT_PARAM_ONOFF, false)
  
  MiscSettings = scriptConfig("Kitty Kat Katarina Misc", "katarinaMisc")
  MiscSettings:addParam("wardJump", "Jump Kata Key", SCRIPT_PARAM_ONKEYDOWN, false, 18)
  MiscSettings:addParam("fastReturn", "Set Fast Return", SCRIPT_PARAM_ONKEYDOWN, false, 84)
  --if VIP_USER then MiscSettings:addParam("packetUse", "Use Packets", SCRIPT_PARAM_ONOFF, true) end
  MiscSettings:addParam("packetinf", "Packets are disabled due to current status of BoL", SCRIPT_PARAM_INFO, "")
  MiscSettings:addParam("wardlessRange", "Wardless Jump Range from cursor", SCRIPT_PARAM_SLICE, 200, 0, 500, 0)
  
  EvadeSettings = scriptConfig("Kitty Kat Katarina Escape", "katarinaEvade")
  EvadeSettings:addSubMenu("Evading","evade")
  EvadeSettings:addSubMenu("Panic Mode","panic")
  EvadeSettings.panic:addParam("panicon", "Panic Mode", SCRIPT_PARAM_ONOFF, true)
  EvadeSettings.panic:addParam("panicHealth", "Panic mode starts below health", SCRIPT_PARAM_SLICE, 50, 0, 1500, 0)
  EvadeSettings.panic:addParam("dangerZone", "Panic mode danger zone", SCRIPT_PARAM_SLICE, 500, 0, 2000, 0)
  EvadeSettings.evade:addParam("evade", "Try to evade skills with E", SCRIPT_PARAM_ONOFF, true)
  EvadeSettings.evade:addParam("evade", "Try to evade skills with Flash", SCRIPT_PARAM_ONOFF, true)
  EvadeSettings.evade:addParam("evade", "Try to evade skills with Ward or Minion Jump", SCRIPT_PARAM_ONOFF, true)
  EvadeSettings.evade:addParam("evadeinf", "These features are disabled due to current status of BoL", SCRIPT_PARAM_INFO, "")
  
  DrawSettings = scriptConfig("Kitty Kat Katarina Draw", "katarinadraw")
  DrawSettings:addParam("drawRange", "Draw Action Range", SCRIPT_PARAM_ONOFF, true)
  DrawSettings:addParam("drawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
  DrawSettings:addParam("drawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
  DrawSettings:addParam("drawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
  DrawSettings:addParam("wardJump", "Draw Ward Jump Range", SCRIPT_PARAM_ONOFF, true)
  
  
  

  
  
  ts = TargetSelector(TARGET_LESS_CAST_PRIORITY,actionRange,DAMAGE_MAGIC)
  ts.name = "Katarina"
  ComboSettings:addTS(ts)
  allyHeroes = GetAllyHeroes()
  enemyHeroes = GetEnemyHeroes()
  
  for i, enemy in ipairs(enemyHeroes) do
   if enemy.name == "ACG" or enemy.name == "zigagang44" then
     print("<font color='#FF0000'>[Kitty Kat Katarina] You can't play against the creator of this script :(</font>") 
     disableScript = true
     return
   end
  end
  
  for i, ally in ipairs(allyHeroes) do
   if ally.name == "ACG" or ally.name == "zigagang44" then
     print("<font color='#FF0000'>[Kitty Kat Katarina] Thank to creator of this script, he is in the same team with you :)</font>") 
   end
  end
  
  if VIP_USER then
    LoadVIPScript('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TXuQDxBMMvRwSwR+TnnXjlRM7rV0SUM+DXkXTlNMsjR3S4S+SXlLzlBOdXQ0S8S+SXmXTlNMMjt3Sxj+TXvQDhBM8jR3S0SxSHkXgVVMrrR0SYM+DXlXgVBMcvt0S8SxTXmLzlBONXs0SwSxWHnXgUVM8vthS1jxTXsQARBMsrt0S4TxTXlXwFBMbrt0ScMxDXmXAXFMMnpVSwQwbHnLwVBO9Xs0S0SwVnkXgEtMsvpvS5jxTXtQABBMcnptS8QwVHmXAElMLrp0SQMwDXnXAFJM8np2S0QzT3kLwFBOtXo0S4QwUXlXA0xMcnloS9jwTXuQABBMMjl3SwRzTnnXQ1NM7jp0SWG5TXleSVDMO/MViE25Db1eiZCILDP0S895TXlSRVBMM1AbJyoLPjovKjwpMzdwS0V5Hz4USVNMMzN0S0UZDXpWSVBMMzN0S0Z5TXlWSTAtczB0S0V5TdkyCVNMMzN0S0U8DXpWSVBMM3MSC0Z5TXlWSVANczB0S0V5Tfk9CVNMMzN0S0VNDXpWSVBMMzM6C0Z5TXlWSbAjczB0S0V5TbkOCVNMMzN0S4UoDXpWSVBMM/MrC0Z5TXlWSVAYczB0S0V5Tdk/CVNMMzN0S0UuDXpWSVBMMzMaC0Z5TXlWSXAhczB0S0V5Tbk0CVNMMzN0S8UnDXpWSVBMM3MbC0Z5TXlWSdAQczB0S0V5TXkyCVNMMzN0SwUoDXpWSVBMM7MVC0Z5TXlWSbAmczB0S0V5TXkxCVNMMzN0S4UZDXpWSVBMMzNSC0Z5TXlWSRAnczB0S0V5TXkWCVNMMzN0S4UUDXpWSVBMMzMZC0Z5TXlWSRApczB0S0V5TdkxCVNMMzN0S6UfDXpWSVBMM/MuC0Z5TXlWSZAgczB0S0V5TTk1CVNMMzN0S0UwDXpWSVBMM3MhC0Z5TXlWSdALczB0S0V5Tbk3CVNMMzN0S8U4DXpWSVBMMzMrC0Z5TXlWSdAjczB0S0V5TdkzCVNMMzN0S0UgDXpWSVBMMzMWC0Z5TXlWSVAvczB0S0V5TRk5CVNMMzN0S6UYDXpWSVBMM7MTC0Z5TXlWSVALczB0S0V5TbkDCVNMMzN0S8UgDXpWSVBMM1MSC0Z5TXlWSRAQczB0S0V5TbkFCVNMMzN0S0UVDXpWSVBMM/MdC0Z5TXlWSXAmczB0S0V5TXkGCVNMMzN0S0UTDXpWSVBMMzMmC0Z5TXlWSdAlczB0S0V5TZkzCVNMMzN0S8UTDXpWSVBMMzMSC0Z5TXlWSZAbczB0S0V5Tbk1CVNMMzN0S8UoDXpWSVBMM3MUC0Z5TXlWSdAqczB0S0V5Tdk0CVNMMzN0S+UUDXpWSVBMM9MTC0Z5TXlWSVByczB0S0V5TXk9CVNMMzN0S6UZDXpWSVBMM1MZC0Z5TXlWSVB1czB0S0V5TXkKCVNMMzN0SwUpDXpWSVBMM3MuC0Z5TXlWSXAgczB0S0V5TTk3CVNMMzN0S8U8DXpWSVBMM3MYC0Z5TXlWSZAeczB0S0V5TfkYCVNMMzN0S8UjDXpWSVBMM7MiC0Z5TXlWSZASczB0S0V5TXkMCVNMMzN0SyUbDXpWSVBMM1MfC0Z5TXlWSdAuczB0S0V5TRk8CVNMMzN0S2UaDXpWSVBMM3MTC0Z5TXlWSfAnczB0S0V5Tbk8CVNMMzN0S6URDXpWSVBMMzNBC0Z5TXlWSfAsczB0S0V5TbkwCVNMMzN0S2URDXpWSVBMMzMcC0Z5TXlWSTAlczB0S0V5Tdk4CVNMMzN0S8UVDXpWSVBMM7McC0Z5TXlWSZAnczB0S0V5TXk5CVNMMzN0SwUTDXpWSVBMMzNHC0Z5TXlWSdAYczB0S0V5TfkQCVNMMzN0S8U2DXpWSVBMM7MaC0Z5TXlWSdAoczB0S0V5TXkOCVNMMzN0S+UfDXpWSVBMMxMTC0Z5TXlWSfAjczB0S0V5TZk7CVNMMzN0S+UTDXpWSVBMM/MpC0Z5TXlWSVAtczB0S0V5TVkzCVRfMzN0KCoVIgslCikvX1Y3PjcLKBciSVNMMzN0S0WJcn1dSVBMVlUSLiYNGRA1IlBIOTN0SzcYIx0VJjwjQTN0S0V5THlWSVBMMzN0S0V5TXlWSVBMMzN0S2h5TXliSVBMMzN2XkV5TX8WCVBRs7N0Q0V5zX/WCVBL83N0TEU4TWIWSVBb8zP0TQU4TT8WCFAL8/J0QQV5zn/WCVBL83N0TEU4TWJWSVBbszP0TQU4TT9WC1BGczP3VEX5TXBWSVBINjN0SzEQLhJWTV1MMzMzLjEtJBo9Cj85XUd0T0B5TXkbLD45MzdxS0V5ABg/J1BIOzN0SwkYKj8kLDVMNzB0S0UmCnlSQlBMM3cGKjI6JAs1JTVMNz10S0UWIR0SOzE7cFoGKCkc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')
  end
  

  for i=1, heroManager.iCount do waittxt[i] = i*3 end
  minionInit()
  print("<font color='#00FF00'>[Kitty Kat Katarina] Script loaded.</font>")
end

function OnTick()
  if disableScript then
   return
  end
  checks()
  
  if MiscSettings.wardJump then
    wardJump(mousePos.x,mousePos.z)
  end
  
  if ultActive and ts.target ~= nil then
    if KCDmgCalculation2(ts.target) > ts.target.health then
      ultActive = false
      timeult = 0
    end
  end 
  
  if ComboSettings.activateCombo or(MiscSettings.fastReturn and targetOnly ~= nil) then
    combo()
  end
  
  if not ComboSettings.activateCombo and FarmSettings.activateFarm then
    farm()
  end
  
  if not ComboSettings.activateCombo and HarassSettings.activateHarass then
    harass()
  end
end

function OnDraw()
  if disableScript then
   return
  end
  if DrawSettings.drawRange then
    DrawCircle(myHero.x, myHero.y, myHero.z, actionRange, 0x19A712)
  end
  if DrawSettings.drawQ then
    if RDY.Q then
      DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0xCCCCCC)
    else
      DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x300000)
    end
  end
  if targetOnly ~= nil then
    DrawText("Targeting only " .. targetOnly.charName, 30, 100, 150, 0xFF88FF00)
  end
  if EvadeSettings.panic.panicon and myHero.health < EvadeSettings.panic.panicHealth and not myHero.dead then
    DrawText("Panic mode activated", 30, 100, 185, 0xFF990000)
    DrawCircle(myHero.x, myHero.y, myHero.z, EvadeSettings.panic.dangerZone, 0xff0000)
  end
  if DrawSettings.drawW then
    if RDY.W then
      DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0xCCCCCC)
    else
      DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0x300000)
    end
  end
  if DrawSettings.drawE then
    if RDY.E then
      DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0xCCCCCC)
    else
      DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0x300000)
    end
  end
  
  for i=1, heroManager.iCount do
    local enemydraw = heroManager:GetHero(i)
    if targetOnly == nil or enemydraw == targetOnly then 
      if ValidTarget(enemydraw) then
        if killable[i] == 1 then
          DrawCircle3D(enemydraw.x, enemydraw.y, enemydraw.z, 30, 6, ARGB(155,0,0,255), 16)
        elseif killable[i] == 2 then
          DrawCircle3D(enemydraw.x, enemydraw.y, enemydraw.z, 10, 6, ARGB(155,255,0,0), 16)
        elseif killable[i] == 3 then
          DrawCircle3D(enemydraw.x, enemydraw.y, enemydraw.z, 10, 6, ARGB(155,255,0,0), 16)
          DrawCircle3D(enemydraw.x, enemydraw.y, enemydraw.z, 30, 6, ARGB(155,255,0,0), 16)
        elseif killable[i] == 4 then
          DrawCircle3D(enemydraw.x, enemydraw.y, enemydraw.z, 10, 6, ARGB(155,255,0,0), 16)
          DrawCircle3D(enemydraw.x, enemydraw.y, enemydraw.z, 30, 6, ARGB(155,255,0,0), 16)
          DrawCircle3D(enemydraw.x, enemydraw.y, enemydraw.z, 50, 6, ARGB(155,255,0,0), 16)
        end
        if floattext[killable[i]] ~= 0 then 
          PrintFloatText(enemydraw,0,floattext[killable[i]])
        end
      end
      if waittxt[i] == 1 then waittxt[i] = 30
      else waittxt[i] = waittxt[i]-1 end
    end
  end
  if MiscSettings.wardJump and DrawSettings.wardJump then
    DrawCircle(myHero.x, myHero.y, myHero.z, 600, 0xFF9900)
  end 
  
  if MiscSettings.fastReturn and targetOnly ~= nil and targetOnly.visible then
   drawLineshit(targetOnly,mousePos, 0xFFFF0000, 2)
   DrawCircle(mousePos.x,mousePos.y,mousePos.z,100,0xFF9900)
   DrawCircle(targetOnly.x,targetOnly.y,targetOnly.z,400,0xffff00)
   DrawCircle(targetOnly.x,targetOnly.y,targetOnly.z,1000,0xFF9900)
  end
end

function drawLineshit(point1, point2, color, width)
    local p1 = WorldToScreen(point1.pos)
    local p2 = WorldToScreen(point2) 
    DrawLine(p1.x, p1.y, p2.x, p2.y, 3, ARGB(0xFF,0xFF,0xFF,0xFF))
end   
 
function OnCreateObj(object)
  if object ~= nil then
    if object.name:find("katarina_daggered") then 
      lastqmark = GetTickCount() 
    end
    
    if object.valid and (string.find(object.name, "Ward") ~= nil or string.find(object.name, "Wriggle") ~= nil or string.find(object.name, "Trinket")) then 
      Wards[#Wards+1] = object
    end
  end
end

function OnAnimation(unit,animationName)
  if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end

function OnProcessSpell(object,spell)
  
  if object == myHero then
    if spell.name == "KatarinaQ" then timeq = GetTickCount() end
    --if spell.name:lower():find("katarinar") then
    --  SkillR.castingUlt = true
    --end

    if spell.name:lower():find("attack") then
      lastAttack = GetTickCount() - GetLatency()/2
      lastWindUpTime = spell.windUpTime*1000
      lastAttackCD = spell.animationTime*1000   
    end
  end
end

function minionInit()
  enemyMinions = minionManager(MINION_ENEMY, actionRange, player, MINION_SORT_HEALTH_ASC)
  allyMinions = minionManager(MINION_ALLY, actionRange, player, MINION_SORT_HEALTH_ASC)
end

function FlashTo(x, y)
    CastSpell(flashSlot, x, y)
end

function checks()

  

  if tick == nil or GetTickCount()-tick >= 100 then
    tick = GetTickCount()
    KCDmgCalculation()
  end
  
  if MiscSettings.fastReturn and targetOnly ~= nil and targetOnly.dead then
   moveToCursor()
   if haveflash and myHero:CanUseSpell(flashSlot) == READY then
     local castPos = myHero + (Vector(mousePos) - myHero):normalized()*400
     FlashTo(castPos.x,castPos.z)
     local castPos2 = myHero + (Vector(mousePos) - myHero):normalized()*600
     wardJump(castPos2.x,castPos2.z,false)
   else
     local castPos = myHero + (Vector(mousePos) - myHero):normalized()*600
     wardJump(castPos.x,castPos.z,false)
   end
  end
  
  wardJumpPart2()
  ts:update()
  ultActive = GetTickCount() <= timeult+GetLatency()+50 or lastAnimation == "Spell4"
  for name,number in pairs(ID) do Slot[name] = GetInventorySlotItem(number) end
  for name,state in pairs(RDY) do RDY[name] = (Slot[name] ~= nil and myHero:CanUseSpell(Slot[name]) == READY) end
  if EvadeSettings.panic.panicon and myHero.health < EvadeSettings.panic.panicHealth and not myHero.dead and not ultActive then
    DangerCheck()
  end
  enemyMinions:update()
  allyMinions:update()
  usableWards.TrinketWard   = (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3340) or (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3350) or (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3361) or (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3362)
  usableWards.RubySightStone   = (rstSlot ~= nil and myHero:CanUseSpell(rstSlot) == READY)
  usableWards.SightStone     = (ssSlot ~= nil and myHero:CanUseSpell(ssSlot) == READY)
  usableWards.SightWard   = (swSlot ~= nil and myHero:CanUseSpell(swSlot) == READY)
  usableWards.VisionWard     = (vwSlot ~= nil and myHero:CanUseSpell(vwSlot) == READY)
  rstSlot, ssSlot, swSlot, vwSlot = GetInventorySlotItem(2045),GetInventorySlotItem(2049),GetInventorySlotItem(2044),GetInventorySlotItem(2043)
  dfgSlot, hxgSlot, bwcSlot, brkSlot = GetInventorySlotItem(3128),GetInventorySlotItem(3146),GetInventorySlotItem(3144),GetInventorySlotItem(3153)
  hpSlot, fskSlot = GetInventorySlotItem(2003),GetInventorySlotItem(2041)
  znaSlot, wgtSlot, bftSlot, liandrysSlot = GetInventorySlotItem(3157),GetInventorySlotItem(3090),GetInventorySlotItem(3188),GetInventorySlotItem(3151)
end

function combo()
  if targetOnly ~= nil then
    distancetarget = GetDistance(targetOnly)
    
    if (ComboSettings.activateCombo or MiscSettings.fastReturn) and targetOnly ~= nil and not ultActive then
        if targetOnly ~= nil and targetOnly.visible and not targetOnly.dead then myHero:MoveTo(targetOnly.x,targetOnly.z) end
        if RDY.DFG then CastSpell(Slot.DFG, targetOnly) end
        if RDY.E then CastE(targetOnly) end
        if RDY.Q then CastQ(targetOnly) end
        if Slot.I and myHero:CanUseSpell(Slot.I) == READY then
          CastSpell(Slot.I, targetOnly)
        end
        if RDY.W and distancetarget< wRange and (((GetTickCount()-timeq>650 or GetTickCount()-lastqmark<650) and not RDY.Q) or not HarassSettings.waitW or (RDY.R)) then CastW(targetOnly) end
        if RDY.HXG then 
          CastSpell(Slot.HXG, targetOnly) 
        end
        if RDY.BWC then 
          CastSpell(Slot.BWC, targetOnly) 
        end
        if RDY.BRK then 
          CastSpell(Slot.BRK, targetOnly) 
        end
        if RDY.STI and distancetarget<=wRange then 
          CastSpell(Slot.STI, myHero) 
        end
        if RDY.RO and distancetarget<=500 then 
          CastSpell(Slot.RO) 
        end
        if RDY.R and ComboSettings.useult and not RDY.Q and not RDY.W and not RDY.E and not RDY.DFG and not RDY.HXG and not RDY.BWC and not RDY.BRK and not RDY.STI and not RDY.RO and distancetarget<275 then
          timeult = GetTickCount()
          CastSpell(_R)
        end
      else
        if Slot.I and myHero:CanUseSpell(Slot.I) == READY then
          CastSpell(Slot.I, targetOnly)
        end
      end
  else
    ts:update()
    if ts.target ~= nil then 
      distancetarget = GetDistance(ts.target)
  
      if ComboSettings.activateCombo and ts.target ~= nil and not ultActive then
        if RDY.DFG then CastSpell(Slot.DFG, ts.target) end
        if RDY.E then CastE(ts.target) end
        if RDY.Q then CastQ(ts.target) end
        if Slot.I and myHero:CanUseSpell(Slot.I) == READY then
          CastSpell(Slot.I, ts.target)
        end
        if RDY.W and distancetarget< wRange and (((GetTickCount()-timeq>650 or GetTickCount()-lastqmark<650) and not RDY.Q) or not HarassSettings.waitW or (RDY.R)) then CastW(ts.target) end
        if RDY.HXG then 
          CastSpell(Slot.HXG, ts.target) 
        end
        if RDY.BWC then 
          CastSpell(Slot.BWC, ts.target) 
        end
        if RDY.BRK then 
          CastSpell(Slot.BRK, ts.target) 
        end
        if RDY.STI and distancetarget<=wRange then 
          CastSpell(Slot.STI, myHero) 
        end
        if RDY.RO and distancetarget<=500 then 
          CastSpell(Slot.RO) 
        end
        if RDY.R and ComboSettings.useult and not RDY.Q and not RDY.W and not RDY.E and not RDY.DFG and not RDY.HXG and not RDY.BWC and not RDY.BRK and not RDY.STI and not RDY.RO and distancetarget<275 then
          timeult = GetTickCount()
          CastSpell(_R)
        end
      else
        if Slot.I and myHero:CanUseSpell(Slot.I) == READY then
          CastSpell(Slot.I, ts.target)
        end
      end
    end
  end
end

function harass()
  if HarassSettings.mouseMove then
    moveToCursor()
  end
  
  if targetOnly ~= nil then
    distancetarget = GetDistance(targetOnly)
    
    if HarassSettings.mode == 2 and RDY.E then 
      CastE(targetOnly) 
    end
    if RDY.Q then CastQ(targetOnly) end
    if HarassSettings.mode >= 1 then
      CastW(targetOnly) 
    end
    return
  end
  
  if ts.target ~= nil then
    distancetarget = GetDistance(ts.target)
    
    if HarassSettings.mode == 2 and RDY.E then 
      CastE(ts.target) 
    end
    if RDY.Q then CastQ(ts.target) end
    if HarassSettings.mode >= 1 then
      CastW(ts.target) 
    end
  end
  
end


function farm()
  
  
  
  for _, minion in pairs(enemyMinions.objects) do
    local qMinionDmg = getDmg("Q", minion, myHero)
    local wMinionDmg = getDmg("W", minion, myHero)
    local eMinionDmg = getDmg("E", minion, myHero)
    local aDmg = getDmg("AD", minion, myHero)
    
    if ValidTarget(minion) and minion ~= nil then
      
      if GetDistanceSqr(minion) <= wRange*wRange then
        if FarmSettings.farmW then
          if RDY.W then
            if minion.health <= (wMinionDmg) then
              CastW(minion)
              break
            end
          end
        end
        
      end
      
      if GetDistanceSqr(minion) <= qRange*qRange then
        if FarmSettings.farmQ then
          if RDY.Q then
            if minion.health <= (qMinionDmg) then
              CastQ(minion)
              break
            end
          end
        end
      end
      
      if GetDistanceSqr(minion) <= eRange*qRange then
        if FarmSettings.farmE then
          if RDY.E then
            if minion.health <= (eMinionDmg) then
              CastE(minion)
              break
            end
          end
        end
      end
      
    end
    break
  end
  
  if FarmSettings.mouseMove then
     moveToCursor()
  end
end

function CastQ(enemy)
    if not RDY.Q or (GetDistanceSqr(enemy) > qRange*qRange) then
      return false
    end
    if ValidTarget(enemy) and enemy ~= nil then 
      if VIP_USER and MiscSettings.packetUse then
        if enemy~= nil then
          Packet("S_CAST", {spellId = _Q, targetNetworkId = enemy.networkID}):send()
        end
        return true
      else
        CastSpell(_Q, enemy)
        return true
      end
    end
    return false

end

function CastE(enemy)
    if not RDY.E or (GetDistanceSqr(enemy) > eRange*eRange) then
      return false
    end
    if ValidTarget(enemy) and enemy ~= nil then 
      if VIP_USER and MiscSettings.packetUse then
       
        Packet("S_CAST", {spellId = _E, targetNetworkId = enemy.networkID}):send()
        return true
      else
        CastSpell(_E, enemy)
        return true
      end
    end
    return false

end

function CastW(enemy)
    if not RDY.W or (GetDistanceSqr(enemy) > wRange*wRange) then
      return false
    end
    if ValidTarget(enemy) and enemy ~= nil then
      
        CastSpell(_W)

    end
    return false
end

function OnWndMsg(msg,key)
  if key == ULTK and msg == KEY_DOWN then timeult = GetTickCount() end
  if msg == KEY_DOWN then
    --prt(key)
  end
  
  if msg == WM_LBUTTONDOWN then
    local dist = 1000000
    local tempTarget = nil
    
    for i, enemy in ipairs(enemyHeroes) do
      if enemy~= nil and not enemy.dead then
        if GetDistance(enemy, mousePos) <= dist then
          dist = GetDistance(enemy, mousePos)
          tempTarget = enemy
        end
      end
    end
    
    if tempTarget ~= nil then
      if dist < 250 then
        targetOnly = tempTarget
        return
      end
    end
    targetOnly = nil
  end
  
  
end

function prt(msg)
  print("<font color='#0000ff'>[Kitty Kat Katarina] " .. msg .. "</font>")
end

function moveToCursor()
  if GetDistance(mousePos) then
    if not VIP_USER or not MiscSettings.packetUse  then
      myHero:MoveTo(mousePos.x, mousePos.z)
    else
      Packet('S_MOVE', {x = mousePos.x, z = mousePos.z}):send()
    end
  end   
end

function isInDanger(hero)
  nEnemiesClose, nEnemiesFar = 0, 0
  hpPercent = hero.health / hero.maxHealth
  for _, enemy in pairs(enemyHeroes) do
      if not enemy.dead and hero:GetDistance(enemy) <= EvadeSettings.panic.dangerZone then
          nEnemiesClose = nEnemiesClose + 1
          if hpPercent < enemy.health / enemy.maxHealth then 
            return true 
          end
      elseif not enemy.dead and hero:GetDistance(enemy) <= 1000 then
          nEnemiesFar = nEnemiesFar + 1
      end
  end
   
  if nEnemiesClose > 1 then return true end
  if nEnemiesClose == 1 and nEnemiesFar > 1 then return true end
  return false
end

function DangerCheck()
  if isInDanger(myHero) then
    for _, ally in pairs(allyHeroes) do
      if ally ~= nil and not ally.dead and GetDistance(ally,myHero) < 700 then
          CastSpell(_E, ally) 
          return
      end
    end
  end
end

function wardJump(x,z,minionMode)
  if x ~= nil and z~= nil then
    if RDY.E then
      if minionMode ~= nil and minionMode then
        for _, ally in pairs(allyHeroes) do
          if ValidTarget(ally, eRange, false) and ally ~= nil then
            if GetDistanceSqr(ally, mousePos) <= MiscSettings.wardlessRange*MiscSettings.wardlessRange then
              CastSpell(_E, ally)
              return
            end
          end
        end
        for _, minion in pairs(allyMinions.objects) do
          if ValidTarget(minion, eRange, false) and minion ~= nil then
            if GetDistanceSqr(minion, mousePos) <= MiscSettings.wardlessRange*MiscSettings.wardlessRange then
              CastSpell(_E, minion)
              return
            end
          end
        end
        for _, minion in pairs(enemyMinions.objects) do
          if ValidTarget(minion, eRange, false) and minion ~= nil then
            if GetDistanceSqr(minion, mousePos) <= MiscSettings.wardlessRange*MiscSettings.wardlessRange then
              CastSpell(_E, minion)
              return
            end
          end
        end
      end
    
      local cward
      if usableWards.TrinketWard then
        cward = ITEM_7
      elseif usableWards.RubySightStone then
        cward = rstSlot
      elseif usableWards.SightStone then 
        cward = ssSlot
      elseif usableWards.SightWard then
        cward = swSlot
      elseif usableWards.VisionWard then
        cward = vwSlot
      end
      
      if cward ~= nil then
        CastSpell(cward, x, z)
        willJump = true
      end
    end
  end
end

function wardJumpPart2()
  if willJump then
    if next(Wards) ~= nil then
      for i, obj in pairs(Wards) do
        if obj.valid then
          if GetDistanceSqr(obj, MousePos) <= 600*600 then
            CastSpell(_E, obj)
            willJump = false
           end
        end
      end
    end
  end
end

function panic()

end



function KCDmgCalculation()
  local enemy = heroManager:GetHero(calculationenemy)
  if ValidTarget(enemy) then
    local qdamage = getDmg("Q",enemy,myHero)
    local qdamage2 = getDmg("Q",enemy,myHero,2)
    local wdamage = getDmg("W",enemy,myHero)
    local edamage = getDmg("E",enemy,myHero)
    local rdamage = getDmg("R",enemy,myHero) --xdagger (champion can be hit by a maximum of 10 daggers (2 sec))
    local hitdamage = getDmg("AD",enemy,myHero)
    local dfgdamage = (Slot.DFG and getDmg("DFG",enemy,myHero) or 0)--amplifies all magic damage they take by 20%
    local hxgdamage = (Slot.HXG and getDmg("HXG",enemy,myHero) or 0)
    local bwcdamage = (Slot.BWC and getDmg("BWC",enemy,myHero) or 0)
    local brkdamage = (Slot.BRK and getDmg("RUINEDKING",enemy,myHero,2) or 0)
    local ignitedamage = (Slot.I and getDmg("IGNITE",enemy,myHero) or 0)
    local onhitdmg = (Slot.Sheen and getDmg("SHEEN",enemy,myHero) or 0)+(Slot.Trinity and getDmg("TRINITY",enemy,myHero) or 0)+(Slot.LB and getDmg("LICHBANE",enemy,myHero) or 0)+(Slot.IG and getDmg("ICEBORN",enemy,myHero) or 0)
    local onspelldamage = (Slot.LT and getDmg("LIANDRYS",enemy,myHero) or 0)+(Slot.BT and getDmg("BLACKFIRE",enemy,myHero) or 0)
    local onspelldamage2 = 0
    local combo1 = hitdamage + (qdamage*2 + qdamage2*2 + wdamage*2 + edamage*2 + rdamage*10)*(RDY.DFG and 1.2 or 1) + onhitdmg + onspelldamage*4 --0 cd
    local combo2 = hitdamage + onhitdmg
    local combo3 = hitdamage + onhitdmg
    local combo4 = 0
    if RDY.Q then
      combo2 = combo2 + (qdamage + qdamage2)*(RDY.DFG and 2.2 or 2)
      combo3 = combo3 + (qdamage + qdamage2)*(RDY.DFG and 1.2 or 1)
      combo4 = combo4 + qdamage + (RDY.E and qdamage2 or 0)
      onspelldamage2 = onspelldamage2+1
    end
    if RDY.W then
      combo2 = combo2 + wdamage*(RDY.DFG and 2.2 or 2)
      combo3 = combo3 + wdamage*(RDY.DFG and 1.2 or 1)
      combo4 = combo4 + (RDY.E and wdamage or 0)
      onspelldamage2 = onspelldamage2+1
    end
    if RDY.E then
      combo2 = combo2 + edamage*(RDY.DFG and 2.2 or 2)
      combo3 = combo3 + edamage*(RDY.DFG and 1.2 or 1)
      combo4 = combo4 + edamage
      onspelldamage2 = onspelldamage2+1
    end
    if myHero:CanUseSpell(_R) ~= COOLDOWN and not myHero.dead then
      combo2 = combo2 + rdamage*10*(RDY.DFG and 1.2 or 1)
      combo3 = combo3 + rdamage*7*(RDY.DFG and 1.2 or 1)
      combo4 = combo4 + (RDY.E and rdamage*3 or 0)
      onspelldamage2 = onspelldamage2+1
    end
    if RDY.DFG then
      combo1 = combo1 + dfgdamage
      combo2 = combo2 + dfgdamage
      combo3 = combo3 + dfgdamage
      combo4 = combo4 + dfgdamage
    end
    if RDY.HXG then               
      combo1 = combo1 + hxgdamage*(RDY.DFG and 1.2 or 1)
      combo2 = combo2 + hxgdamage*(RDY.DFG and 1.2 or 1)
      combo3 = combo3 + hxgdamage*(RDY.DFG and 1.2 or 1)
      combo4 = combo4 + hxgdamage
    end
    if RDY.BWC then
      combo1 = combo1 + bwcdamage*(RDY.DFG and 1.2 or 1)
      combo2 = combo2 + bwcdamage*(RDY.DFG and 1.2 or 1)
      combo3 = combo3 + bwcdamage*(RDY.DFG and 1.2 or 1)
      combo4 = combo4 + bwcdamage
    end
    if RDY.BRK then
      combo1 = combo1 + brkdamage
      combo2 = combo2 + brkdamage
      combo3 = combo3 + brkdamage
      combo4 = combo4 + brkdamage
    end
    if RDY.I then
      combo1 = combo1 + ignitedamage 
      combo2 = combo2 + ignitedamage
      combo3 = combo3 + ignitedamage
    end
    combo2 = combo2 + onspelldamage*onspelldamage2
    combo3 = combo3 + onspelldamage/2 + onspelldamage*onspelldamage2/2
    combo4 = combo4 + onspelldamage
    if combo4 >= enemy.health then killable[calculationenemy] = 4
    elseif combo3 >= enemy.health then killable[calculationenemy] = 3
    elseif combo2 >= enemy.health then killable[calculationenemy] = 2
    elseif combo1 >= enemy.health then killable[calculationenemy] = 1
    else killable[calculationenemy] = 0 end   
  end
  if calculationenemy == 1 then calculationenemy = heroManager.iCount
  else calculationenemy = calculationenemy-1 end
end

function KCDmgCalculation2(enemy)
  local distanceenemy = GetDistance(enemy)
  local qdamage = getDmg("Q",enemy,myHero)
  local qdamage2 = getDmg("Q",enemy,myHero,2)
  local wdamage = getDmg("W",enemy,myHero)
  local edamage = getDmg("E",enemy,myHero)
  local combo5 = 0
  if RDY.Q then
    combo5 = combo5 + qdamage
    if RDY.E or (distanceenemy<400 and RDY.W) then
      combo5 = combo5 + qdamage2
    end
  end
  if RDY.W and (RDY.E or distanceenemy<400) then
    combo5 = combo5 + wdamage
  end
  if RDY.E then
    combo5 = combo5 + edamage
  end
  return combo5
end


--Lib implement

