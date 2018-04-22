class ScrnMP7MFire extends MP7MFire;

// fixes double shot bug -- PooSH
state FireLoop
{
    function BeginState()
    {
        super.BeginState();
        
        NextFireTime = Level.TimeSeconds - 0.000001; //fire now!
    }
}  

//add 1 penetration
function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
    local Actor Other;
    local byte HitCount,HCounter;
    local float HitDamage;
    local array<int>    HitPoints;
    local KFPawn HitPawn;
    local array<Actor>    IgnoreActors;
    local Actor DamageActor;
    local int i;

    MaxRange();

    Weapon.GetViewAxes(X, Y, Z);
    if ( Weapon.WeaponCentered() )
    {
        ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
    }
    else
    {
        ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X +
         Weapon.Hand * Weapon.EffectOffset.Y * Y + Weapon.EffectOffset.Z * Z);
    }

    X = Vector(Dir);
    End = Start + TraceRange * X;
    HitDamage = DamageMax;
    While( (HitCount++)<2 ) // 1 penetration
    {
        DamageActor = none;

        Other = Instigator.HitPointTrace(HitLocation, HitNormal, End, HitPoints, Start,, 1);
        if( Other==None )
        {
            Break;
        }
        else if( Other==Instigator || Other.Base == Instigator )
        {
            IgnoreActors[IgnoreActors.Length] = Other;
            Other.SetCollision(false);
            Start = HitLocation;
            Continue;
        }

        if( ExtendedZCollision(Other)!=None && Other.Owner!=None )
        {
            IgnoreActors[IgnoreActors.Length] = Other;
            IgnoreActors[IgnoreActors.Length] = Other.Owner;
            Other.SetCollision(false);
            Other.Owner.SetCollision(false);
            DamageActor = Pawn(Other.Owner);
        }

        if ( !Other.bWorldGeometry && Other!=Level )
        {
            HitPawn = KFPawn(Other);

            if ( HitPawn != none )
            {
                 // Hit detection debugging
                 /*log("PreLaunchTrace hit "$HitPawn.PlayerReplicationInfo.PlayerName);
                 HitPawn.HitStart = Start;
                 HitPawn.HitEnd = End;*/
                 if(!HitPawn.bDeleteMe)
                     HitPawn.ProcessLocationalDamage(int(HitDamage), Instigator, HitLocation, Momentum*X,DamageType,HitPoints);

                 // Hit detection debugging
                 /*if( Level.NetMode == NM_Standalone)
                       HitPawn.DrawBoneLocation();*/

                IgnoreActors[IgnoreActors.Length] = Other;
                IgnoreActors[IgnoreActors.Length] = HitPawn.AuxCollisionCylinder;
                Other.SetCollision(false);
                HitPawn.AuxCollisionCylinder.SetCollision(false);
                DamageActor = Other;
            }
            else
            {
                if( KFMonster(Other)!=None )
                {
                    IgnoreActors[IgnoreActors.Length] = Other;
                    Other.SetCollision(false);
                    DamageActor = Other;
                }
                else if( DamageActor == none )
                {
                    DamageActor = Other;
                }
                Other.TakeDamage(int(HitDamage), Instigator, HitLocation, Momentum*X, DamageType);
            }
            if( (HCounter++)>=3 || Pawn(DamageActor)==None )
            {
                Break;
            }
            HitDamage*=0.5;
            Start = HitLocation;
        }
        else if ( HitScanBlockingVolume(Other)==None )
        {
            if( KFWeaponAttachment(Weapon.ThirdPersonActor)!=None )
              KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
            Break;
        }
    }

    // Turn the collision back on for any actors we turned it off
    if ( IgnoreActors.Length > 0 )
    {
        for (i=0; i<IgnoreActors.Length; i++)
        {
            if ( IgnoreActors[i] != none )
                IgnoreActors[i].SetCollision(true);
        }
    }}

defaultproperties
{
    AmmoClass=Class'ScrnBalanceSrv.ScrnMP7MAmmo'
    DamageType=Class'ScrnBalanceSrv.ScrnDamTypeMP7M'
}
