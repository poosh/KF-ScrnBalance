class ScrnCrossbowArrow extends CrossbowArrow;

simulated state OnWall
{
    function ProcessTouch (Actor Other, vector HitLocation)
    {
        local Pawn PawnOther;
        local Inventory inv;
        local Crossbow bow;

        PawnOther = Pawn(Other);
        if( PawnOther != none ) {
            for( inv=PawnOther.Inventory; inv != none; inv = inv.Inventory ) {
                bow = Crossbow(inv); 
                if( bow != none ) {
                    if ( bow.AmmoAmount(0) < bow.MaxAmmo(0) ) {
                        bow.AddAmmo(1,0) ;
                        PlaySound(Sound'KF_InventorySnd.Ammo_GenericPickup', SLOT_Pain,2*TransientSoundVolume,,400);
                        if( PlayerController(PawnOther.Controller)!=none )
                        {
                            PlayerController(PawnOther.Controller).ReceiveLocalizedMessage(class'KFmod.ProjectilePickupMessage',0);
                        }
                        Destroy();
                    }
                    return;
                }
            }
        }
    }
}    

defaultproperties
{
    LifeSpan=60
}