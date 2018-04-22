class ScrnCrossbuzzsawBlade extends CrossbuzzsawBlade;

var Actor ImpactActorFixed; // original ImpactActor isn't replicated corectly

var float ShutMeUpTime;

replication
{
    reliable if ( Role==ROLE_Authority )
        ImpactActorFixed; 
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    
    ShutMeUpTime += Level.TimeSeconds;
}

simulated function PostNetReceive()
{
    if ( Role < ROLE_Authority ){
        if ( bHidden )
            Destroy();
        else if( ImpactActorFixed!=None && Base != ImpactActorFixed )
            GoToState('OnWall');
    }          
}

// destroy an actor and make sure it will be destroyed on clients too
simulated function ReplicatedDestroy()
{    
    if ( Level.NetMode == NM_Client || Level.NetMode == NM_StandAlone ) {
        Destroy();
    }
    else {
        bHidden = true;
        SetCollision(false, false);
        SetPhysics(PHYS_None);
        Velocity = vect(0,0,0);
        Speed = 0;
        NetUpdateTime = Level.TimeSeconds - 1;
        SetTimer(1.0, false);
    }
}

function Timer()
{
    Destroy();
}

simulated function Tick( float Delta )
{
    super.Tick(Delta);
    
    if ( AmbientSound != None && ShutMeUpTime > Level.TimeSeconds )
        AmbientSound = None; // make sure I'll shutup        
}

// overrided to change calss to ReplicatedDestroy()
simulated state OnWall
{
    Ignores HitWall;

    simulated function BeginState()
    {
        bCollideWorld = False;
        AmbientSound = None;
        if( Trail!=None )
            Trail.mRegen = False;

        if( Corona != none )
        {
            Corona.Kill();
        }
        SetCollisionSize(75,50);

        UV2Texture=FadeColor'PatchTex.Common.PickupOverlay';
        
        NetUpdateFrequency = 2.0;
    }

    function ProcessTouch (Actor Other, vector HitLocation)
    {
        local Inventory inv;

        if( !bHidden && Pawn(Other)!=None && Pawn(Other).Inventory!=None )
        {
            for( inv=Pawn(Other).Inventory; inv!=None; inv=inv.Inventory )
            {
                if( Crossbuzzsaw(Inv)!=None && Weapon(inv).AmmoAmount(0)<Weapon(inv).MaxAmmo(0) )
                {
                    KFweapon(Inv).AddAmmo(1,0) ;
                    PlaySound(Sound'KF_InventorySnd.Ammo_GenericPickup', SLOT_Pain,2*TransientSoundVolume,,400);
                    if( PlayerController(Instigator.Controller)!=none )
                    {
                        PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'KFmod.ProjectilePickupMessage',1);
                    }
                    ReplicatedDestroy();
                }
            }
        }
    }

    simulated function Tick( float Delta )
    {
        if( Base==None )
            ReplicatedDestroy();
    }
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    local vector X;
    local Vector TempHitLocation, HitNormal;
    local array<int>    HitPoints;
    local KFPawn HitPawn;
    local bool    bHitWhipAttachment;
    local Pawn P;

    if ( bHidden || Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces || Other==IgnoreImpactPawn ||
        (IgnoreImpactPawn != none && Other.Base == IgnoreImpactPawn) )
        return;

    X =  Vector(Rotation);

     if( ROBulletWhipAttachment(Other) != none )
    {
        bHitWhipAttachment=true;

        if(!Other.Base.bDeleteMe)
        {
            Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (65535 * X), HitPoints, HitLocation,, 1);

            if( Other == none || HitPoints.Length == 0 )
                return;

            HitPawn = KFPawn(Other);

            if (Role == ROLE_Authority)
            {
                if ( HitPawn != none )
                {
                     // Hit detection debugging
                    /*log("Bullet hit "$HitPawn.PlayerReplicationInfo.PlayerName);
                    HitPawn.HitStart = HitLocation;
                    HitPawn.HitEnd = HitLocation + (65535 * X);*/

                    if( !HitPawn.bDeleteMe )
                        HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, MomentumTransfer * X, MyDamageType,HitPoints);

                    Damage *= 0.80;
                    Velocity *= 0.85;

                    IgnoreImpactPawn = HitPawn;

                    if( Level.NetMode!=NM_Client )
                        PlayhitNoise(Pawn(Other)!=none && Pawn(Other).ShieldStrength>0);
                }
            }
        }
        return;
    }

    if ( Pawn(Other)!=None && Vehicle(Other)==None )
        P = Pawn(Other);
    else if ( ExtendedZCollision(Other)!=None && Pawn(Other.Owner)!=None )
        P = Pawn(Other.Owner);
    
    if( Level.NetMode!=NM_Client )
        PlayhitNoise(P != none && P.ShieldStrength>0 );

    if( P != none ) {
        IgnoreImpactPawn = P;
        if( P.IsHeadShot(HitLocation, X, 1.0) )
            P.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, DamageTypeHeadShot);
        else
            P.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
            
        // If blade kills pawn, decatipates it or it was already decapitated, 
        // then apply lower damage and speed reduction
        // -- PooSH
        if ( Physics==PHYS_Projectile && (P == none || P.Health <= 0 || (KFMonster(P) != none && KFMonster(P).bDecapitated)) ) {
            Damage *= 0.85; // vanilla = 0.8
            Velocity *= 0.9; // vanilla = 0.85
        }
        else {
            Damage *= 0.60; // vanilla = 0.8
            Velocity *= 0.75; // vanilla = 0.85
            if ( Damage < default.Damage * 0.50 ) {
                if ( Bounces > 0 )
                    Bounces--; // lower amount of bounces, if blade hit many zeds already
                if ( Role == ROLE_Authority && Bounces == 0 && Damage < default.Damage * 0.20 )
                    ReplicatedDestroy();
            }
        }
    }
    else {
        Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType); 
    }
}

simulated function Stick(actor HitActor, vector HitLocation)
{
    super.Stick(HitActor, HitLocation);
    ImpactActorFixed = ImpactActor; // replicate properly
    NetUpdateTime = Level.TimeSeconds - 1;
}



defaultproperties
{
    HeadShotDamageMult=2.500000
    Damage=400.000000
    MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeCrossbuzzsaw'
    DamageRadius=0
    LifeSpan=60.0
    ShutMeUpTime=10.0 // be sure that ambient sound stops after this time
}
