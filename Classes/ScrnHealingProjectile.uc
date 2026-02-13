class ScrnHealingProjectile extends HealingProjectile;

var int InstantHealAmount;

simulated function PostNetReceive()
{
    if( bHidden && !bHitHealTarget )
    {
        if( HealLocation != vect(0,0,0) )
        {
            // log("PostNetReceive calling HitHealTarget for location of "$HealLocation);
            HitHealTarget(HealLocation,vector(HealRotation));
        }
        // HealLocation doesn't received from server, so don't call HitHealTarget
        // Actually PostNetReceive() shouldn't be called without HealLocation, but who knows
        // the devil that is living inside KF code? :)
        // (c) PooSH
        /*
        else
        {
            log("PostNetReceive calling HitHealTarget for self location of "$HealLocation);
            HitHealTarget(Location,-vector(Rotation));
        }
        */
    }
}

//copy-pasted to use GiveHealth()
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    local KFHumanPawn Healed;

    if (Other == none || Other == Instigator || Other.Base == Instigator || Other.IsA('ExtendedZCollision'))
        return;

    // KFBulletWhipAttachment is attached to KFPawns
    if ( ROBulletWhipAttachment(Other) != none ) {
        // snap to the player
        Healed = KFHumanPawn(Other.Owner);
        if ( Healed == none || Healed.Health >= Healed.HealthMax )
            return;  // ignore the aux cylinder and continue flying
    }
    else {
        Healed = KFHumanPawn(Other);
    }

    if( Healed != none ) {
        if( Role == ROLE_Authority ) {
            // server side
            HitHealTarget(HitLocation, -vector(Rotation));

            if( Instigator != none && Healed.Health > 0 && Healed.Health <  Healed.HealthMax ) {
                if (ScrnHumanPawn(Healed) != none) {
                    ScrnHumanPawn(Healed).TakeHealingEx(ScrnHumanPawn(Instigator), InstantHealAmount, HealBoostAmount,
                            KFWeapon(Instigator.Weapon), true);
                }
                else {
                    class'ScrnHumanPawn'.static.HealLegacyPawn(Healed, Instigator, InstantHealAmount + HealBoostAmount);
                }
            }
        }
        else {
            // client side
            bHidden = true;
            SetPhysics(PHYS_None);
            SetTimer(2.0, false); //give server some time to tell us we're healed somebody, or destroy
            return;
        }
    }
    Explode(HitLocation,-vector(Rotation));
}

function ClientSuccessfulHeal(String PlayerName)
{
    // Replaced by ScrnHealMessage
    // if( KFMedicGun(Instigator.Weapon) != none )
    //     KFMedicGun(Instigator.Weapon).ClientSuccessfulHeal(PlayerName);
}

simulated function Timer()
{
    if ( Role == ROLE_Authority)
        super.Timer();
    else if ( !bHitHealTarget ) // Didn't receive HealingLocation from the Server - Destoy
        Destroy();
}

// why need to shake nearby players?
function ShakeView()
{
}


defaultproperties
{
    Damage=0
    DamageRadius=0
}
