//=============================================================================
// MAC Fire
//=============================================================================
class ScrnMAC10Fire extends MAC10Fire;

var() Sound BoltCloseSound;
var string BoltCloseSoundRef;
var bool bClientEffectPlayed;

//load additional sound
static function PreloadAssets(LevelInfo LevelInfo, optional KFFire Spawned)
{
    local ScrnMac10Fire ScrnSpawned;
    super.PreloadAssets(LevelInfo, Spawned);
	if ( default.BoltCloseSoundRef != "" )
	{
		default.BoltCloseSound = sound(DynamicLoadObject(default.BoltCloseSoundRef, class'Sound', true));
	}
    ScrnSpawned = ScrnMac10Fire(Spawned);
    if ( ScrnSpawned != none )
    {
        ScrnSpawned.BoltCloseSound = default.BoltCloseSound;
    }
}

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


//sets bCloseBolt and plays sound
function CloseBolt()
{
    if (KFWeap != none)
        ScrnMac10MP(KFWeap).bBoltClosed = true;
    if (BoltCloseSound != none && !bClientEffectPlayed )
    {
        Weapon.PlayOwnedSound(BoltCloseSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,1.00,false);
    }
    bClientEffectPlayed = true;
}

//setting bBoltClosed in a non simulated function test
function ModeDoFire()
{
    if (KFWeap.MagAmmoRemaining <= 0 && !KFWeapon(Weapon).bIsReloading && ( Level.TimeSeconds - LastFireTime>FireRate ) && !ScrnMAC10MP(KFWeap).bBoltClosed )
    {
        LastFireTime = Level.TimeSeconds; //moved to allowfire
        ScrnMAC10MP(KFWeap).MoveBoltForward(); //visual effect only
        CloseBolt(); //plays sound and sets bBoltClosed
        ScrnMAC10MP(KFWeap).bBoltClosed = true; //attempt force setting it here
    }
    else
    {
        bClientEffectPlayed = false; //reset if not empty
    }
    Super.ModeDoFire();
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
    BoltCloseSoundRef="KF_FNFALSnd.FNFAL_Bolt_Forward"
    FireAnim=Fire_Iron //fix annoying hipfire messing up aiming after firing
    FireEndAnim=Fire_Iron_End //fix annoying hipfire messing up aiming after firing
}
