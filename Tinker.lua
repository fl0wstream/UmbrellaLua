-- Tinker.lua for Umbrella
-- fl0wstream wit NBOMe, May 2018
-- Last update: 26/05/2018

-- Utility.lua by Eroica-cpp
local Utility = require("scripts/Eroica/Utility")

local Tinker = {}

-- Menu bools
Tinker.menuToggle = Menu.AddOptionBool({"Hero Specific", "Tinker"}, "Enabled", false)
Tinker.checkForSafeCast = Menu.AddOptionBool({"Hero Specific", "Tinker"}, "Safe Cast Check", true)
Tinker.drawDamage = Menu.AddOptionBool({"Hero Specific", "Tinker"}, "Draw Damage", true)
--Tinker.drawDamageSize = Menu.AddOptionSlider({"Hero Specific", "Tinker"}, "Draw Damage Size", 8, 24, 14)

-- > Enemy Selector Settings
Tinker.enemySelectorMode = Menu.AddOptionCombo({"Hero Specific", "Tinker", "Enemy Selector"}, "Enemy Selector Mode", {"Simple", "Smart"}, 0)
Tinker.enemyMouseRange = Menu.AddOptionSlider({"Hero Specific", "Tinker", "Enemy Selector"}, "Mouse Range of Searching", 100, 2000, 400)
Tinker.selectorAwareBlademail = Menu.AddOptionBool({"Hero Specific", "Tinker", "Enemy Selector"}, "Ignore Enemies with Blade Mail or Lotus", false)

-- Menu keys
Tinker.menuComboKey = Menu.AddKeyOption({"Hero Specific", "Tinker"}, "Key: Combo", Enum.ButtonCode.KEY_G)

-- Menu items
Tinker.menuItems =          {ItemSoulring = "Soul Ring",
                            ItemHex = "Scythe of Vise",
                            ItemDagon = "Dagon",
                            ItemEthereal = "Ethereal Blade",
                            ItemVeil = "Veil of Discord",
                            --ItemBlink = "Blink Dagger",
                            ItemOrchid = "Orchid Malevolence",
                            ItemShiva = "Shiva's Guard"}
                            --ItemEuls = "Euls"}

Tinker.menuItemsHandle =    {ItemSoulring,
                            ItemHex,
                            ItemDagon,
                            ItemEthereal,
                            ItemVeil,
                            --ItemBlink,
                            ItemOrchid,
                            ItemShiva}
                            --ItemEuls}
                            

for k, v in pairs(Tinker.menuItems) do
    Tinker.menuItemsHandle[k] = Menu.AddOptionBool({"Hero Specific", "Tinker", "Items usage"}, Tinker.menuItems[k], true)
end

-- Menu abilities
Tinker.menuAbilities =      {SpellLaser = "Laser",
                            SpellRockets = "Rockets",
                            SpellMarch = "March",
                            SpellRefresh = "Refresh"}

Tinker.menuAbilitiesHandle = {SpellLaser,
                            SpellRockets,
                            SpellMarch,
                            SpellRefresh}

for k, v in pairs(Tinker.menuAbilities) do
    Tinker.menuAbilitiesHandle[k] = Menu.AddOptionBool({"Hero Specific", "Tinker", "Abilities usage"}, Tinker.menuAbilities[k], true)
end

-- Menu linkens poppin'
Tinker.menuLinkensPoppers = {ItemHex = "Scythe of Vise",
                            ItemDagon = "Dagon",
                            ItemEthereal = "Ethereal Blade",
                            ItemOrchid = "Orchid Malevolence",
                            ItemEuls = "Euls",
                            SpellLaser = "Spell: Laser"}

Tinker.menuLinkensHandle = {ItemHex,
                            ItemDagon,
                            ItemEthereal,
                            ItemOrchid,
                            ItemEuls,
                            SpellLaser}

for k, v in pairs(Tinker.menuLinkensPoppers) do
    Tinker.menuLinkensHandle[k] = Menu.AddOptionBool({"Hero Specific", "Tinker", "Linkens poppers"}, Tinker.menuLinkensPoppers[k], false)
end

-- Globals
local CurrentVictim = nil
local MyHero = nil
local MyPlayer = nil

local SpellLaser = nil
local SpellRockets = nil
local SpellMarch = nil
local SpellRefresh = nil

local ItemSoulring = nil
local ItemHex = nil
local ItemDagon = nil
local ItemEthereal = nil
local ItemVeil = nil
local ItemBlink = nil
local ItemOrchid = nil
local ItemShiva = nil
local ItemEuls = nil

local NextNukeTime = 0
local NextRefreshTime = 0

local AbilityChannelTime = {3.0, 1.5, 0.75}

local Font = Renderer.LoadFont("Tahoma", 16, Enum.FontWeight.BOLD)	

-- Functions
-- OnGameStart() - resetting all locals
function Tinker.OnGameStart()
    CurrentVictim = nil

    MyHero = nil
    MyPlayer = nil

    Log.Write("Tinker > OnGameStart() -> reset done")
end

-- OnGameEnd() - same as GameStart
function Tinker.OnGameEnd()
    CurrentVictim = nil

    MyHero = nil
    MyPlayer = nil

    SpellLaser = nil
    SpellRockets = nil
    SpellRefresh = nil
    SpellMarch = nil

    ItemSoulring = nil
    ItemHex = nil
    ItemDagon = nil
    ItemEthereal = nil
    ItemVeil = nil
    ItemBlink = nil
    ItemOrchid = nil
    ItemShiva = nil
    ItemEuls = nil

    Log.Write("Tinker > OnGameEnd() -> reset done")
end

-- OnUpdate() - updating this tinker true shit every tick to work
function Tinker.OnUpdate()
    -- checking are we in fucking katka
    if not Engine.IsInGame() 
        or Heroes.GetLocal() == nil
        or not GameRules.GetGameState() == 5
        or not Menu.IsEnabled(Tinker.menuToggle)
        or GameRules.IsPaused() then
            return
    end

    -- or maybe we dont exist and set our playa' to tha fucking glob@ls
    if MyHero == nil then MyHero = Heroes.GetLocal() end
    if MyPlayer == nil then MyPlayer = Players.GetLocal() end

    -- or maybe we arent tinker xd                    -- or maybe we died
    if NPC.GetUnitName(MyHero) ~= "npc_dota_hero_tinker" or not Entity.IsAlive(MyHero) then return end

    -- fetch our abilities and items, yoo
    Tinker.FetchAbilities()
    Tinker.FetchItems()

    -- why not working?
    --Log.Write(Ability.GetLevelSpecialValueForFloat(SpellRefresh, "AbilityChannelTime"))

    --Log.Write(1 - NPC.GetMagicalArmorDamageMultiplier(MyHero))

    -- Combo part, only while keypressed
    if Menu.IsKeyDown(Tinker.menuComboKey) then
        -- then search some mofos
        Tinker.EnemySelector()

        if CurrentVictim then Tinker.DoCombo() end
    end
end

function Tinker.OnDraw()
    if not Menu.IsEnabled(Tinker.drawDamage) then return end

    if not MyHero then return end
    if NPC.GetUnitName(MyHero) ~= "npc_dota_hero_tinker" then return end

    for i = 1, Heroes.Count() do
        local hero = Heroes.Get(i)
        
        if not Entity.IsSameTeam(MyHero, hero) and not Entity.IsDormant(hero) and not NPC.IsIllusion(hero) and Entity.IsAlive(hero) then
            local pos = Entity.GetAbsOrigin(hero)
            pos:SetY(pos:GetY() + 50)

            local x, y, vis = Renderer.WorldToScreen(pos)

            if not vis then return end
            
            local damage = Tinker.CalculateDamage(hero)

            local delta = Entity.GetHealth(hero) - damage

            if delta < 0 then Renderer.SetDrawColor(0, 255, 0, 255) else Renderer.SetDrawColor(255, 0, 0, 255) end

            Renderer.DrawText(Font, x, y, math.floor(delta))
        end
    end
end

-- CalculateDamage(Hero hero) - calculate damage that u can deal to this enemy using Combo
function Tinker.CalculateDamage(hero)
    local pure_damage = 0.0
    local magic_damage = 0.0

    --                                                  hardcode god lul
    local dmg_multiplier = 1 + Hero.GetIntellectTotal(MyHero) * 0.0008765432

    -- Modifiers
    if NPC.HasModifier(MyHero, "modifier_bloodseeker_bloodrage") then
        dmg_multiplier = dmg_multiplier + Modifier.GetConstantByIndex(NPC.GetModifier(MyHero, "modifier_bloodseeker_bloodrage"), 1) / 100
    end

    if NPC.HasModifier(hero, "modifier_bloodseeker_bloodrage") then
        dmg_multiplier = dmg_multiplier + Modifier.GetConstantByIndex(NPC.GetModifier(hero, "modifier_bloodseeker_bloodrage"), 1) / 100
    end

    if NPC.HasModifier(hero, "modifier_chen_penitence") then
		dmg_multiplier = dmg_multiplier + Modifier.GetConstantByIndex(NPC.GetModifier(hero, "modifier_chen_penitence"), 1) / 100
    end
    
	if NPC.HasModifier(hero, "modifier_shadow_demon_soul_catcher") then
		dmg_multiplier = dmg_multiplier + Modifier.GetConstantByIndex(NPC.GetModifier(hero, "modifier_shadow_demon_soul_catcher"), 0) / 100
	end

	if NPC.HasModifier(hero, "modifier_slardar_sprint") then
		dmg_multiplier = dmg_multiplier + Modifier.GetConstantByIndex(NPC.GetModifier(hero, "modifier_slardar_sprint"), 0) / 100
	end

    -- Orchid logic is strange so it needs to be fucking here
    --if Tinker.CanUseItem(ItemOrchid, Tinker.menuItemsHandle["ItemOrchid"], hero) then
    --    dmg_multiplier = dmg_multiplier + 0.3
    --end

    local magic_damage_multiplier = dmg_multiplier - (1 - NPC.GetMagicalArmorDamageMultiplier(hero))

    -- Multipliers
    if Tinker.CanUseItem(ItemEthereal, Tinker.menuItemsHandle["ItemEthereal"], hero) then
        magic_damage_multiplier = magic_damage_multiplier + 0.4
        magic_damage = magic_damage + (75 + 2 * Hero.GetIntellectTotal(MyHero))
    end

    if Tinker.CanUseItem(ItemVeil, Tinker.menuItemsHandle["ItemVeil"], hero) then
        magic_damage_multiplier = magic_damage_multiplier + 0.25
    end

    -- Magic damage
    if Tinker.CanUseItem(ItemDagon, Tinker.menuItemsHandle["ItemDagon"], hero) then
        local dagon_damage = {400, 500, 600, 700, 800}
        magic_damage = magic_damage + dagon_damage[Ability.GetLevel(ItemDagon)]
    end

    if Tinker.CanUseItem(ItemShiva, Tinker.menuItemsHandle["ItemShiva"], hero) then
        magic_damage = magic_damage + 200
    end

    if Tinker.CanCastAbility(SpellRockets, Tinker.menuAbilitiesHandle["SpellRockets"], hero) then
        local damage = {125, 200, 275, 350}
        magic_damage = magic_damage + damage[Ability.GetLevel(SpellRockets)]
    end

    -- Pure damage
    if Tinker.CanCastAbility(SpellLaser, Tinker.menuAbilitiesHandle["SpellLaser"], hero) then
        local damage = {80, 160, 240, 320}
        pure_damage = pure_damage + damage[Ability.GetLevel(SpellLaser)]
    end

    return (pure_damage * dmg_multiplier) + (magic_damage * magic_damage_multiplier)
end

function Tinker.CanUseItem(item, itemHandle, enemy)
    if not item then return false end

    if not Entity.IsEntity(item) then return false end

    if not Utility.IsSuitableToUseItem(MyHero) or not Menu.IsEnabled(itemHandle) then return false end
    if Menu.IsEnabled(Tinker.checkForSafeCast) and not Utility.IsSafeToCast(MyHero, enemy, Ability.GetDamage(item)) then return false end
    if not Ability.IsReady(item) or not Ability.IsCastable(item, Ability.GetManaCost(item)) then return false end

    return true
end

function Tinker.CanCastAbility(item, itemHandle, enemy)
    if not item then return false end

    if not Entity.IsEntity(item) then return false end

    if not Utility.IsSuitableToCastSpell(MyHero) or not Menu.IsEnabled(itemHandle) then return false end
    if Menu.IsEnabled(Tinker.checkForSafeCast) and not Utility.IsSafeToCast(MyHero, enemy, Ability.GetDamage(item)) then return false end
    if not Ability.IsReady(item) or not Ability.IsCastable(item, Ability.GetManaCost(item)) then return false end

    return true
end

-- DoCombo() - doing combo on CurrentVictim
function Tinker.DoCombo()
    --Log.Write("Tinker.DoCombo() -> Combo is executing")

    local enemy = CurrentVictim

    -- in first, maybe autoattack?)
    if not NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_ATTACK_IMMUNE) then
        Player.AttackTarget(MyPlayer, MyHero, enemy, false)
    end

    -- soul ring, motherfucker
    if Tinker.UseItem(ItemSoulring, Tinker.menuItemsHandle["ItemSoulring"]) then return end

    -- AM shield :(
    if Tinker.IsAntimageShielded(enemy) then
        if Tinker.CastAbility(SpellLaser, Tinker.menuLinkensHandle["SpellLaser"]) then return end
        if Tinker.UseItem(ItemDagon, Tinker.menuLinkensHandle["ItemDagon"]) then return end
        if Tinker.UseItem(ItemEthereal, Tinker.menuLinkensHandle["ItemEthereal"]) then return end
        if Tinker.UseItem(ItemEuls, Tinker.menuLinkensHandle["ItemEuls"]) then return end
    end

    -- poppin' linkens, yoo
    if NPC.IsLinkensProtected(enemy) then
        if Tinker.UseItem(ItemEuls, Tinker.menuLinkensHandle["ItemEuls"]) then return end
        if Tinker.UseItem(ItemOrchid, Tinker.menuLinkensHandle["ItemOrchid"]) then return end
        if Tinker.UseItem(ItemDagon, Tinker.menuLinkensHandle["ItemDagon"]) then return end
        if Tinker.UseItem(ItemEthereal, Tinker.menuLinkensHandle["ItemEthereal"]) then return end
        if Tinker.CastAbility(SpellLaser, Tinker.menuLinkensHandle["SpellLaser"]) then return end
        if Tinker.UseItem(ItemHex, Tinker.menuLinkensHandle["ItemHex"]) then return end
    end

    -- maybe hex?)
    if not NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_HEXED) and not NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_STUNNED) then
        if Tinker.UseItem(ItemHex, Tinker.menuItemsHandle["ItemHex"]) then return end
    end	

    -- ethereal
    if not NPC.HasModifier(enemy, "modifier_item_ethereal_blade_ethereal") then
        if Tinker.UseItem(ItemEthereal, Tinker.menuItemsHandle["ItemEthereal"]) then 
            -- missle speed: 1275
            if NPC.IsEntityInRange(MyHero, enemy, Ability.GetCastRange(ItemEthereal)) then
                local my_pos = Entity.GetAbsOrigin(MyHero)
                local distance = my_pos:Distance(Entity.GetAbsOrigin(enemy))

                distance = distance:Length2D()

                local flight_time = distance / 1275

                NextNukeTime = GameRules.GetGameTime() + flight_time
                return 
            end
        end
    end

    -- veil
    if Tinker.UseItem(ItemVeil, Tinker.menuItemsHandle["ItemVeil"]) then return end

    -- orchid
    if Tinker.UseItem(ItemOrchid, Tinker.menuItemsHandle["ItemOrchid"]) then return end

    -- shiva
    if Tinker.UseItem(ItemShiva, Tinker.menuItemsHandle["ItemShiva"]) then return end

    -- waiting for ethereal appers on target
    if GameRules.GetGameTime() < NextNukeTime and NextNukeTime ~= 0 then return end
    NextNukeTime = 0

    -- dagon
    if Tinker.UseItem(ItemDagon, Tinker.menuItemsHandle["ItemDagon"]) then return end

    -- laser
    if Tinker.CastAbility(SpellLaser, Tinker.menuAbilitiesHandle["SpellLaser"]) then return end

    -- rockets
    if Tinker.CastAbility(SpellRockets, Tinker.menuAbilitiesHandle["SpellRockets"]) then return end

    -- waiting for next refresh
    if GameRules.GetGameTime() < NextRefreshTime and NextRefreshTime ~= 0 then return end
    NextRefreshTime = 0

    -- refresh maybe?
    if not Ability.IsReady(SpellLaser) and 
    not Ability.IsReady(SpellRockets)
    then
        if Tinker.CastAbility(SpellRefresh, Tinker.menuAbilitiesHandle["SpellRefresh"]) then 
            NextRefreshTime = GameRules.GetGameTime() + Ability.GetCastPoint(SpellRefresh) + AbilityChannelTime[Ability.GetLevel(SpellRefresh) - 1]
            return 
        end
    end
end

-- IsAntimageShielded(Hero hero) - return is hero == Antimage and has a ready2use shield 
function Tinker.IsAntimageShielded(hero)
    local shield = NPC.GetAbility(hero, "antimage_spell_shield")
	if shield and Ability.IsReady(shield) and NPC.HasItem(hero, "item_ultimate_scepter", true) then
		return true
	end
end

-- FetchAbilities() - gets abilities from our freaky Tinker
function Tinker.FetchAbilities()
    SpellLaser = NPC.GetAbility(MyHero, "tinker_laser")
    SpellRockets = NPC.GetAbility(MyHero, "tinker_heat_seeking_missile")
    SpellMarch = NPC.GetAbility(MyHero, "tinker_march_of_the_machines")
    SpellRefresh = NPC.GetAbility(MyHero, "tinker_rearm")
end

-- FetchItems() - gets items from our freaky Tinker
function Tinker.FetchItems()
    ItemBlink = NPC.GetItem(MyHero, "item_blink_dagger") 
    ItemDagon = NPC.GetItem(MyHero, "item_dagon")
    if not ItemDagon then
		for i = 2, 5 do
			ItemDagon = NPC.GetItem(MyHero, "item_dagon_" .. i, true)
			if ItemDagon then break end
		end
    end
    ItemEthereal = NPC.GetItem(MyHero, "item_ethereal_blade")
    ItemHex = NPC.GetItem(MyHero, "item_sheepstick")
    ItemOrchid = NPC.GetItem(MyHero, "item_orchid")
    ItemShiva = NPC.GetItem(MyHero, "item_shivas_guard")
    ItemSoulring = NPC.GetItem(MyHero, "item_soul_ring")
    ItemEuls = NPC.GetItem(MyHero, "item_cyclone")
    ItemVeil = NPC.GetItem(MyHero, "item_veil_of_discord")
end

-- UseItem(Item item, MenuHandle handle) - uses item properly (in enemy or in ground nearby him)
function Tinker.UseItem(item, itemHandle)
    local enemy = CurrentVictim

    -- omg nil items are 4 motherfuckers
    if not item then return false end

    if not Entity.IsEntity(item) then return false end

    if not Utility.IsSuitableToUseItem(MyHero) or not Menu.IsEnabled(itemHandle) then return false end
    if Menu.IsEnabled(Tinker.checkForSafeCast) and not Utility.IsSafeToCast(MyHero, enemy, Ability.GetDamage(item)) then return false end
    if not Ability.IsReady(item) or not Ability.IsCastable(item, Ability.GetManaCost(item)) then return false end

    local target_type = Ability.GetTargetType(item)
    --Log.Write(target_type .. " | " .. Ability.GetName(item))

    -- none-target
    if (target_type == 0 and item ~= ItemSoulring and item ~= ItemShiva) then
        Ability.CastPosition(item, Entity.GetAbsOrigin(enemy))
        return true
    end
    -- hero or all
    if (target_type == 3 or
        target_type == 19 or
        target_type == 128) then
        Ability.CastTarget(item, enemy)
        return true
    end
    
    -- other cases
    Ability.CastNoTarget(item)
    return true
end    

-- CastAbility(Ability ability, MenuHandle handle) - uses ability properly (in enemy or in ground nearby him)
function Tinker.CastAbility(ability, abilityHandle)
    local enemy = CurrentVictim

    -- omg nil ability are 4 motherfuckers
    if not ability then return false end

    if not Entity.IsEntity(ability) then return false end

    if not Utility.IsSuitableToCastSpell(MyHero) or not Menu.IsEnabled(abilityHandle) then return false end
    if Menu.IsEnabled(Tinker.checkForSafeCast) and not Utility.IsSafeToCast(MyHero, enemy, Ability.GetDamage(ability)) then return false end
    if not Ability.IsReady(ability) or not Ability.IsCastable(ability, Ability.GetManaCost(ability)) then return false end

    local target_type = Ability.GetTargetType(ability)
    --Log.Write(target_type .. " | " .. Ability.GetName(ability))

    -- none-target
    if (target_type == 0) then
        Ability.CastNoTarget(ability)
        return true
    end
    -- hero or all
    if (target_type == 3 or 
        target_type == 19 or
        target_type == 128) then
        Ability.CastTarget(ability, enemy)
        return true
    end
    
    -- other cases
    Ability.CastPosition(ability, Entity.GetAbsOrigin(enemy))
    return true
end    

-- EnemySelector(), calling it when we need some VICTIMS haha
function Tinker.EnemySelector()
    local selector_mode = Menu.GetValue(Tinker.enemySelectorMode)
    local mouse_range = Menu.GetValue(Tinker.enemyMouseRange)
    local selector_aware_blademail = Menu.IsEnabled(Tinker.selectorAwareBlademail)

    local temp_enemy = nil

    -- Enemy Selector: Mode 0 - Simple (just choose random hero around mouse lol)
    if selector_mode == 0 and temp_enemy == nil then
        temp_enemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(MyHero), Enum.TeamType.TEAM_ENEMY)
        if Utility.CanCastSpellOn(temp_enemy) and temp_enemy ~= nil and NPC.IsPositionInRange(temp_enemy, Input.GetWorldCursorPos(), mouse_range) then
            if selector_aware_blademail then
                if Utility.IsLotusProtected(temp_enemy) or NPC.HasModifier(temp_enemy, "modifier_item_blade_mail_reflect") then
                    temp_enemy = nil
                    return
                end           
            end
            CurrentVictim = temp_enemy
        end
    end

    temp_enemy = nil
end

return Tinker