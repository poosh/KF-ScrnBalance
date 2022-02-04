class SocRules extends ScrnGameRulesMod;

var transient float NextMsgTime;
var localized string strInfectedItems;

function bool TestInfectedItem(ScrnPlayerInfo SPI, PlayerController OwnerPC) {
    local ScrnPlayerInfo OwnerSPI;
    local VirusInfo OwnerVirus;

    if (SPI.PlayerOwner == OwnerPC)
        return false;  // can pickup own items

    OwnerSPI = SPI.GameRules.GetPlayerInfo(OwnerPC);
    if ( OwnerSPI == none )
        return false;
    OwnerVirus = VirusInfo(OwnerSPI.CustomInfo(class'VirusInfo'));
    if (OwnerVirus == none || !OwnerVirus.HasSymptoms())
        return false;

    if ( Level.TimeSeconds > NextMsgTime ) {
        SPI.PlayerOwner.ClientMessage(class'ScrnUtility'.static.ColorString(strInfectedItems,192,128,1));
        NextMsgTime = Level.TimeSeconds + 1;
    }
    return true;
}

function bool AllowWeaponPickup(ScrnPlayerInfo SPI, KFWeaponPickup WP)
{
    if ( !super.AllowWeaponPickup(SPI, WP) )
        return false;

    return !TestInfectedItem(SPI, WP.DroppedBy);
}

// function bool AllowCashPickup(ScrnPlayerInfo SPI, CashPickup Cash)
// {
//     if ( !super.AllowCashPickup(SPI, Cash) )
//         return false;
//
//     return !TestInfectedItem(SPI, PlayerController(Cash.DroppedBy));
// }


defaultproperties
{
    strInfectedItems="Cannot pick up infected items"
}
