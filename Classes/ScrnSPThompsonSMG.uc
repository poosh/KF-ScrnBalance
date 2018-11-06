class ScrnSPThompsonSMG extends SPThompsonSMG
    config(user);

var         name            ReloadShortAnim;
var         float           ReloadShortRate;

var transient bool  bShortReload;
var transient bool bTweeningBolt;
var transient bool bBoltClosed;
var float TweenEndTime;
var vector ChargingHandleOffset; //for tactical reload
    
replication
{
    reliable if(Role < ROLE_Authority)
        ServerCloseBolt;
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    Super.BringUp(PrevWeapon);
    if (bBoltClosed)
        MoveBoltForward();
}
    
simulated function AltFire(float F) 
{
    // disable semi-auto mode
}

simulated function ResetBoltPosition()
{
    SetBoneLocation( 'Bolt', ChargingHandleOffset, 0 ); //reset charging handle position
}

simulated function MoveBoltForward()
{
    SetBoneLocation( 'Bolt', -ChargingHandleOffset, 100 ); //move bolt forward
    bBoltClosed = true; //set this bool so weapon bolt will stay closed if dropped
}

simulated function InterpolateBolt(float time)
{
    SetBoneLocation( 'Bolt', ChargingHandleOffset, (time*500) ); //smooth moves
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
        StartTweeningBolt(); //start tweening Bolt back
    bBoltClosed = false; //reset bool
    bIsReloading = false;

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
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
    if (bBoltClosed)
    {
        bShortReload = false;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.001);
        SetBoneLocation( 'Bolt', ChargingHandleOffset, 0 ); //reset bolt so that the animation's Bolt position gets used
    }
    else if (MagAmmoRemaining >= 1 || !bBoltClosed)
    {
        bShortReload = true;
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.001); //reduced tween time to prevent Bolt from sliding
        SetBoneLocation( 'Bolt', ChargingHandleOffset, 100 ); //move the bolt back
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
    //if ( bShortReload || !bBoltClosed)
        //StartTweeningBolt();
    //    a++; // 1 bullet already bolted
    //removed +1 on tactical reload because MKb42(H) is an open bolt weapon

    if ( AmmoAmount(0) >= a )
        MagAmmoRemaining = a;
    else
        MagAmmoRemaining = AmmoAmount(0);

    bBoltClosed = false;
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
     Weight=5
     MagCapacity=40
     ReloadRate=3.304348 //3.8/1.15
     ReloadAnimRate=1.15
     ReloadShortAnim="Reload"
     ReloadShortRate=2.244
     ChargingHandleOffset=(X=-0.059,Y=0,Z=0)
     Priority=123
     GroupOffset=19
     PickupClass=Class'ScrnBalanceSrv.ScrnSPThompsonPickup'
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnSPThompsonFire'
     AttachmentClass=Class'ScrnBalanceSrv.ScrnSPThompsonAttachment'
     ItemName="Dr. T's Lead Delivery System SE"
}
