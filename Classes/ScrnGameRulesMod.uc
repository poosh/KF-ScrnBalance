class ScrnGameRulesMod extends ScrnGameRulesExt
    dependsOn(ScrnGameRules)
    abstract;

var ScrnGameRulesMod Next;

function ApplyGameRules()
{
    GameRules.AddMod(self);
}

function AddMod(ScrnGameRulesMod Mod)
{
    if ( Next != None )
        Next.AddMod(Mod);
    else
        Next = Mod;
}

function int ModifyMonsterDamage(out ScrnGameRules.MonsterInfo MI, ScrnPlayerController instigatedBy,
        int OriginalDamage, int Damage, vector HitLocation, out vector Momentum, class<KFWeaponDamageType> KFDamType)
{
    if ( Next != None )
        Damage = Next.ModifyMonsterDamage(MI, instigatedBy, OriginalDamage, Damage, HitLocation, Momentum, KFDamType);

    return Damage;
}

/**
 * Allows overriding weapon purchase at the Trader, or/and blame the player for buying the weapon.
 * This function controls only weapons purchased from the Trader. If the player dropped a weapon and picked up again,
 * or picked a weapon from a dead teammate's body, the function does NOT get called.
 *
 * @param PC player controller which wants to buy a weapon
 * @param WP weapon pickup class to buy
 * @param [out] BuyRules (default = BUY_ALLOW) - Buy rule flags.
 *          Set BuyRules=BUY_REJECT to prevent weapon purchase.
 *          Add BUY_BLAME flag to blame the player for buying the weapon.
 *          Add BUY_SLIGHTLY_OP, BUY_OP, or BUY_MEGA_OP if the weapon is considered overpowered. Leads to lowering HL.
 * @return  true  - the mod overrode the weapon purchase. Default rules will not be applied.
 *          false - the mod has no interest in controlling the given weapon. Proceed with the default rules.
 */
function bool OverrideWeaponBuy(ScrnPlayerController PC, class<KFWeaponPickup> WP, out byte BuyRules)
{
    if ( Next != None && Next.OverrideWeaponBuy(PC, WP, BuyRules) )
        return true;

    return false;
}

/**
 * Allows prohibiting a player from picking up a weapon
 *
 * @param SPI player info which wants to pick up a weapon
 * @param WP weapon pickup to pick up
 * @return  true  - the mod allows or does not care about (by default) the pickup
 *          false - the mod prohibits the pick up
 */
function bool AllowWeaponPickup(ScrnPlayerInfo SPI, KFWeaponPickup WP)
{
    if ( Next != None && !Next.AllowWeaponPickup(SPI, WP) )
        return false;

    return true;
}

/**
 * Allows prohibiting a player from picking up a cash
 *
 * @param SPI player info which wants to pick up a weapon
 * @param WP weapon pickup class to pickup
 * @return  true  - the mod allows or does not care about (by default) the pickup
 *          false - the mod prohibits the pickup
 */
function bool AllowCashPickup(ScrnPlayerInfo SPI, CashPickup Cash)
{
    if ( Next != None && !Next.AllowCashPickup(SPI, Cash) )
        return false;

    return true;
}
