class ScrnMP5MMedicGun extends MP5MMedicGun;

var         name            ReloadShortAnim;
var         float           ReloadShortRate;
var         float           ReloadShortAnimRate;
var float ShortReloadFrameSkip;
var float ShortReloadPostFrameSkip;

var transient bool  bShortReload;
var vector ChargingHandleOffset; //for tactical reload
var rotator ChargingHandleRotation; //mp5 charging handle needs rotation correction too

//added this for a somewhat smoother transition for tactical reload start and end
simulated function Timer()
{
    if (bIsReloading)
        AnimSkipToMagChange(); //skip to mag change frame
    //else
    //PlayIdle();
    Super.Timer();
}

simulated function AnimSkipToMagChange()
{
    SetAnimFrame(ShortReloadFrameSkip, 0 , 1);  
    SetBoneLocation( 'Bolt', ChargingHandleOffset, 100 ); //move the charging handle
    SetBoneRotation( 'Bolt', ChargingHandleRotation, , 100 ); //rotate the charging handle
}

simulated function PlayReloadEndAnim()
{
    SetAnimFrame(ShortReloadPostFrameSkip, 0 , 1);  //do this to avoid mag switch and make tactical reload end look good    
    SetBoneLocation( 'Bolt', ChargingHandleOffset, 0 ); 
    SetBoneRotation( 'Bolt', ChargingHandleRotation, , 0 ); 
}

exec function ReloadMeNow()
{
    local float ReloadMulti;
    
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
        bShortReload = false;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
    }
    else if (MagAmmoRemaining >= 1)
    {
        bShortReload = true;
        PlayAnim(ReloadShortAnim, ReloadShortAnimRate*ReloadMulti, 0.001); //reduced tween time for charginghandle
        SetTimer(0.2/ReloadMulti, false); //for tactical reload, skip reload animation only after 7 frames of anim so it looks good
        //
    }
}

simulated function ClientFinishReloading()
{
	bIsReloading = false;
    if (!bShortReload )
        PlayIdle();
    if (bShortReload )
    {
        PlayReloadEndAnim();
    }

	if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
		Instigator.Controller.ClientSwitchToBestWeapon();
}

function AddReloadedAmmo()
{
    local int a;
    
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);
    
    a = MagCapacity;
    if (bShortReload)
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
    ReloadShortAnim="Reload"
    ReloadShortRate=1.9
    ReloadShortAnimRate=1.2
    ReloadAnim="Reload"
    ReloadRate=2.75
    ReloadAnimRate=1.35
    Magcapacity=30
    HealAmmoCharge=0
    Weight=4.000000
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnMP5MFire'
    FireModeClass(1)=Class'ScrnBalanceSrv.ScrnMP5MAltFire'
    bReduceMagAmmoOnSecondaryFire=False
    InventoryGroup=4
    PickupClass=Class'ScrnBalanceSrv.ScrnMP5MPickup'
    ItemName="MP5M Medic Gun SE"
    PlayerViewPivot=(Pitch=45,Roll=0,Yaw=5) //fix to make sight centered
    ChargingHandleOffset=(X=0.0,Y=-0.031,Z=0)
    ChargingHandleRotation=(Pitch=-70,Yaw=0,Roll=0)
    ShortReloadFrameSkip=31.0;
    ShortReloadPostFrameSkip=109.0;
}
