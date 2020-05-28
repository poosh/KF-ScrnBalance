class ToiletPaperAmmo extends KFAmmunition;


function bool AddAmmo(int AmmoToAdd)
{
    local int OldAmmo;
    local ScrnHumanPawn ScrnPawn;

    OldAmmo = AmmoAmount;
    if ( !super.AddAmmo(AmmoToAdd) )
        return false;

    if ( AmmoAmount > OldAmmo ) {
        ScrnPawn = ScrnHumanPawn(Instigator);
        if ( ScrnPawn != none && ScrnPawn.bServerShopping ) {
            class'ScrnAchCtrl'.static.ProgressAchievementByID(
                class'ScrnAchCtrl'.static.PlayerLink(PlayerController(ScrnPawn.Controller))
                , 'CovidiotG', AmmoAmount - OldAmmo);
        }
    }
    return true;
}


defaultproperties
{
    AmmoPickupAmount=0
    MaxAmmo=200
    InitialAmount=1
    PickupClass=Class'ScrnBalanceSrv.ToiletPaperAmmoPickup'
    IconMaterial=Texture'KillingFloorHUD.Generic.HUD'
    IconCoords=(X1=458,Y1=82,X2=491,Y2=133)
    ItemName="A Toilet Paper Roll"
}
