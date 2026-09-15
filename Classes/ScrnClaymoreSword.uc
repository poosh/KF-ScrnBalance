class ScrnClaymoreSword extends ClaymoreSword;

defaultproperties
{
    Weight=8
    MinReloadPct=0.70  // When Fire + SwitchWeapon, increase DownDelay to wait for the FireMode.Timer()
    bIsTier2Weapon=False
    bIsTier3Weapon=True
    FireModeClass(0)=class'ScrnClaymoreSwordFire'
    FireModeClass(1)=class'ScrnClaymoreSwordFireB'
    Priority=105
    GroupOffset=4
    PickupClass=class'ScrnClaymoreSwordPickup'
    ItemName="Claymore Sword SE"
}
