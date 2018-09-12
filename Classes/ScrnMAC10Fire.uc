//=============================================================================
// MAC Fire
//=============================================================================
class ScrnMAC10Fire extends MAC10Fire;

//close bolt if attempted to fire when empty
simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).MagAmmoRemaining == 0 && !KFWeapon(Weapon).bIsReloading )
	{
    	if( Level.TimeSeconds - LastClickTime>FireRate )
            ScrnMAC10MP(Weapon).MoveBoltForward(); //close bolt on empty chamber
	}
	return Super.AllowFire();
}

// Overwritten to switch damage types for the firebug
function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
    local Actor Other;
    local KFWeaponAttachment WeapAttach;
    local array<int> HitPoints;
    local KFPawn HitPawn;
    local KFMonster KFMonsterVictim;

    MaxRange();

    Weapon.GetViewAxes(X, Y, Z);

    DamageType = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.static.GetMAC10DamageType(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo));

    if ( Weapon.WeaponCentered() )
    {
        ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
    }
    else
    {
        ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X + Weapon.Hand * Weapon.EffectOffset.Y * Y +
        Weapon.EffectOffset.Z * Z);
    }

    X = Vector(Dir);
    End = Start + TraceRange * X;
    Other = Instigator.HitPointTrace(HitLocation, HitNormal, End, HitPoints, Start,, 1);

    if ( Other != None && Other != Instigator && Other.Base != Instigator )
    {
        WeapAttach = KFWeaponAttachment(Weapon.ThirdPersonActor);

        if ( !Other.bWorldGeometry )
        {
            // Update hit effect except for pawns
            if ( !Other.IsA('Pawn') && !Other.IsA('HitScanBlockingVolume') &&
                 !Other.IsA('ExtendedZCollision') )
            {
                if( WeapAttach!=None )
                {
                    WeapAttach.UpdateHit(Other, HitLocation, HitNormal);
                }
            }

            HitPawn = KFPawn(Other);

            if ( HitPawn != none )
            {
                if ( !HitPawn.bDeleteMe )
                {
                    HitPawn.ProcessLocationalDamage(DamageMax, Instigator, HitLocation, Momentum * X, DamageType, HitPoints);
                }
            }
            else
            {
                if ( ExtendedZCollision(Other) != none)
                    Other = Other.Owner; // ExtendedZCollision is attached to and owned by a KFMonster
                KFMonsterVictim = KFMonster(Other);
                if ( KFMonsterVictim != none && KFMonsterVictim.Health > 0
                        && ClassIsChildOf(DamageType, class'DamTypeMAC10MPInc')
                        && class'ScrnBalance'.default.Mut.BurnMech != none)
                {
                    class'ScrnBalance'.default.Mut.BurnMech.MakeBurnDamage(
                        KFMonsterVictim, DamageMax, Instigator, HitLocation, Momentum * X, DamageType);
                }
                else {
                    Other.TakeDamage(DamageMax, Instigator, HitLocation, Momentum * X, DamageType);
                }
            }
        }
        else
        {
            HitLocation = HitLocation + 2.0 * HitNormal;

            if ( WeapAttach != None )
            {
                WeapAttach.UpdateHit(Other,HitLocation,HitNormal);
            }
        }
    }
    else
    {
        HitLocation = End;
        HitNormal = Normal(Start - End);
    }
}


defaultproperties
{
    FireAnim=Fire_Iron
    FireEndAnim=Fire_Iron_End
    //FireAnimRate=5.00 //used for single fire only, this fixes aiming after single hipfire
    //FireUnaimedEndAnimRate=5.00 //fix for aiming after auto hipfire
}
