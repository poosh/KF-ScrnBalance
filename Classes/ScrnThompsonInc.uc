class ScrnThompsonInc extends ThompsonSMG
    config(user);

var         name            ReloadShortAnim;
var         float           ReloadShortRate;

var transient bool bShortReload;
var transient bool bTweeningBolt;
var bool bBoltClosed;
var float TweenEndTime;
var vector ChargingHandleOffset; //for tactical reload


replication
{
    reliable if(Role < ROLE_Authority)
        ServerCloseBolt;
}

//allow firemode switch even if empty
simulated function AltFire(float F)
{
    DoToggle();
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    Super.BringUp(PrevWeapon);
    if (bBoltClosed)
        MoveBoltForward();
}

simulated function ResetBoltPosition()
{
    if ( Level.NetMode != NM_DedicatedServer )
        SetBoneLocation( 'ChargingHandle', ChargingHandleOffset, 0 ); //reset charging handle position
}

simulated function MoveBoltForward()
{
    if ( Level.NetMode != NM_DedicatedServer )
        SetBoneLocation( 'ChargingHandle', -ChargingHandleOffset, 100 ); //move bolt forward
}

function ServerCloseBolt()
{
    bBoltClosed = true;
    bShortReload = false;
}

simulated function CloseBolt()
{
    ServerCloseBolt();
    bBoltClosed = true;
    bShortReload = false;
    MoveBoltForward();
}

simulated function InterpolateBolt(float time)
{
    SetBoneLocation( 'ChargingHandle', ChargingHandleOffset, (time*500) ); //smooth moves
}

simulated function WeaponTick(float dt)
{
    if (bTweeningBolt && TweenEndTime > 0)
    {
        if (TweenEndTime - Level.TimeSeconds > 0)
            InterpolateBolt(TweenEndTime - Level.TimeSeconds);
        if (TweenEndTime - Level.TimeSeconds < 0)
        {
            ResetBoltPosition();
            TweenEndTime = 0;
            bTweeningBolt = false;
        }
    }

    Super.WeaponTick(dt);
}

simulated function ClientFinishReloading()
{
    PlayIdle();
    if(bShortReload)
        StartTweeningBolt(); //start tweening Bolt backonly for short reload
    bBoltClosed = false; //this is needed to reset bolt position after reload
    bIsReloading = false;

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
}

exec function ReloadMeNow()
{
    local float ReloadMulti;

    if (NumClicks > 0)
        bBoltClosed = true;

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
    bShortReload = !bBoltClosed; //short reload now depends on if bolt is closed or not
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
    bShortReload = !bBoltClosed; //copypaste from exec function
    if (!bShortReload)
    {
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( 'ChargingHandle', ChargingHandleOffset, 0 ); //reset bolt so that the animation's Bolt position gets used
    }
    else
    {
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.001); //reduced tween time to prevent Bolt from sliding
        SetBoneLocation( 'ChargingHandle', ChargingHandleOffset, 100 ); //move the bolt back
    }
}

simulated function StartTweeningBolt()
{
    bTweeningBolt = true; //start bolt tweening
    TweenEndTime = Level.TimeSeconds + 0.2;
}

function AddReloadedAmmo()
{
    local int a;

    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    a = MagCapacity;

    //    a++; // 1 bullet already bolted
    //removed +1 on tactical reload because Thompson SMG is an open bolt weapon

    if ( AmmoAmount(0) >= a )
        MagAmmoRemaining = a;
    else
        MagAmmoRemaining = AmmoAmount(0);

    bBoltClosed = false; //this is needed to fix reload time after empty reload

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
    PickupClass=Class'ScrnBalanceSrv.ScrnThompsonIncPickup'
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnThompsonIncFire'
    ReloadShortAnim="Reload"
    ReloadShortRate=2.33
    MagCapacity=20
    BobDamping=6.0 //4.0
    ChargingHandleOffset=(X=-0.027,Y=0.0,Z=0)
    ItemName="Incendiary Tommy Gun SE"
    AppID=0
}