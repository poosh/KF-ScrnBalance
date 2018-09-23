class ScrnM4203AssaultRifle extends M4203AssaultRifle
    config(user);

var transient bool bTriggerReleased;           // indicates that fire button is released, but need to end the burst
var transient float PrevFireTime;

var         name             ReloadShortAnim;
var         float             ReloadShortRate;

var transient bool  bShortReload;
var vector ZoomedViewOffset;


//copypaste to add additional offset
simulated event RenderOverlays( Canvas Canvas )
{
    local int m;
    local vector DrawOffset;
    if (Instigator == None)
        return;

    if ( Instigator.Controller != None )
        Hand = Instigator.Controller.Handedness;

    if ((Hand < -1.0) || (Hand > 1.0))
        return;

    // draw muzzleflashes/smoke for all fire modes so idle state won't
    // cause emitters to just disappear
    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m] != None)
        {
            FireMode[m].DrawMuzzleFlash(Canvas);
        }
    }
    DrawOffset = (90/DisplayFOV * ZoomedViewOffset) >> Instigator.GetViewRotation(); //calculate additional offset
    SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) + DrawOffset); //add additional offset
    SetRotation( Instigator.GetViewRotation() + ZoomRotInterp);

    //PreDrawFPWeapon();    // Laurent -- Hook to override things before render (like rotation if using a staticmesh)

    bDrawingFirstPerson = true;
    Canvas.DrawActor(self, false, false, DisplayFOV);
    bDrawingFirstPerson = false;
}

    
simulated function bool StartFire(int Mode)
{
    if ( Mode > 0 ) {
        if ( FireMode[0].IsInState('WaitingForFireButtonRelease') )
            FireMode[0].GotoState(''); 
        if ( AmmoAmount(1) > 1 ) {
            KFShotgunFire(FireMode[1]).FireAimedAnim='Fire_Iron_Secondary';
            FireMode[1].FireAnim='Fire_Secondary';
            FireMode[1].default.FireRate=1.99;
        }
        else {
            KFShotgunFire(FireMode[1]).FireAimedAnim='FireLast_Iron_Secondary';
            FireMode[1].FireAnim='FireLast_Secondary';
            FireMode[1].default.FireRate=0.5;
        }
        return super.StartFire(Mode);
    }

    if (FireMode[0].IsInState('WaitingForFireButtonRelease') || FireMode[0].IsInState('FireBurst'))
        return false;

    if( !super(KFWeapon).StartFire(0) )  // returns false when mag is empty
       return false;

    //AnimStopLooping();
                                                                         //prevent fire button spam-clicking
    if( !FireMode[0].IsInState('FireBurst') && (AmmoAmount(0) > 0) && Level.TimeSeconds > PrevFireTime + 0.2 )
    {   
        PrevFireTime = Level.TimeSeconds;
        bTriggerReleased = false;
        FireMode[0].GotoState('FireBurst');
        return true;
    }

    return false;
}

simulated function ReallyStopFire(int Mode) 
{
    super.StopFire(Mode);
}

simulated function StopFire(int Mode)
{
    //log("StopFire("$Mode$")", 'ScrnBalance');
    if ( Mode > 0 ) {
        if ( FireMode[0].IsInState('WaitingForFireButtonRelease') ) //this shouldn't happed, but just to be sure
            FireMode[0].GotoState('');    
            
        super.StopFire(Mode);
        return;
    }
    // Dear Server and Mighty Cthulhu, who's living inside KFMod code and makes stuff glitching all the time,
    // By setting the flag below I want to acknowledge you my wish of stopping bring death to this holy place
    // as soon as my weapon stops firing (burst ends).
    // So please allow me to reload my gun this time!
    // kind regards,
    // Client.
    bTriggerReleased = true;

    // Always shoots full burt
    // if ( FireMode[0].IsInState('WaitingForFireButtonRelease') )
        // FireMode[0].GotoState('');
    // else if ( !FireMode[0].IsInState('FireBurst') )
        // super.StopFire(0);
        
    // Allows stopping fire 
    super.StopFire(Mode);
    if (FireMode[Mode].IsInState('WaitingForFireButtonRelease'))
        FireMode[Mode].GotoState('');
}


exec function ReloadMeNow()
{
    local float ReloadMulti;
    
    // tbs burst fire won't screw reload
    if ( FireMode[0].IsInState('FireBurst') || FireMode[0].IsInState('WaitingForFireButtonRelease') )
        FireMode[0].GotoState('');
        
    if(!AllowReload())
        return;
    if ( bHasAimingMode && bAimingRifle )
    {
        FireMode[1].bIsFiring = False;

        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }
    
    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
        ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), self);
    else
        ReloadMulti = 1.0;
        
    bIsReloading = true;
    ReloadTimer = Level.TimeSeconds;
    bShortReload = MagAmmoRemaining > 0;
    if ( bShortReload )
        ReloadRate = Default.ReloadShortRate / ReloadMulti;
    else
        ReloadRate = Default.ReloadRate / ReloadMulti;
        
    if( bHoldToReload )
    {
        NumLoadedThisReload = 0;
    }
    ClientReload();
    Instigator.SetAnimAction(WeaponReloadAnim);
    if ( Level.Game.NumPlayers > 1 && KFGameType(Level.Game).bWaveInProgress && KFPlayerController(Instigator.Controller) != none &&
        Level.TimeSeconds - KFPlayerController(Instigator.Controller).LastReloadMessageTime > KFPlayerController(Instigator.Controller).ReloadMessageDelay )
    {
        KFPlayerController(Instigator.Controller).Speech('AUTO', 2, "");
        KFPlayerController(Instigator.Controller).LastReloadMessageTime = Level.TimeSeconds;
    }
}

simulated function ClientReload()
{
    local float ReloadMulti;
    if ( bHasAimingMode && bAimingRifle )
    {
        FireMode[1].bIsFiring = False;

        ZoomOut(false);
        if( Role < ROLE_Authority)
            ServerZoomOut(false);
    }
    
    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
        ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), self);
    else
        ReloadMulti = 1.0;
        
    bIsReloading = true;
    if (MagAmmoRemaining <= 0)
    {
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
    }
    else if (MagAmmoRemaining >= 1)
    {
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.1);
    }
}

function AddReloadedAmmo()
{
    local int a;
    
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    a = MagCapacity;
    if ( bShortReload )
        a++; // 1 bullet already bolted
    
    if ( AmmoAmount(0) >= a )
        MagAmmoRemaining = a;
    else
        MagAmmoRemaining = AmmoAmount(0);

    // this seems redudant -- PooSH
    // if( !bHoldToReload )
    // {
        // ClientForceKFAmmoUpdate(MagAmmoRemaining,AmmoAmount(0));
    // }

    if ( PlayerController(Instigator.Controller) != none && KFSteamStatsAndAchievements(PlayerController(Instigator.Controller).SteamStatsAndAchievements) != none )
    {
        KFSteamStatsAndAchievements(PlayerController(Instigator.Controller).SteamStatsAndAchievements).OnWeaponReloaded();
    }
}

defaultproperties
{
    IdleAnimRate=0.33 //fix because animation package has idle at 30fps
    ReloadShortAnim="Reload"
    ReloadShortRate=1.9
    ReloadRate=2.794846
    ReloadAnimRate=1.300000
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnM4203BulletFire'
    FireModeClass(1)=Class'ScrnBalanceSrv.ScrnM203Fire'
    Description="An assault rifle with an attached grenade launcher. Shoots in 3-bullet fixed-burst mode."
    InventoryGroup=3
    PickupClass=Class'ScrnBalanceSrv.ScrnM4203Pickup'
    ItemName="M4 203 SE"
    //PrePivot=(Z=-0.35) //rotational fix for ironsight alignment
    ZoomedViewOffset=(X=0.000000,Y=0.000000,Z=-0.250000) //new sight alignment fix
    PlayerViewPivot=(Pitch=25,Roll=0,Yaw=5) //sight fix
}
