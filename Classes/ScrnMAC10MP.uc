//-----------------------------------------------------------
// Mac-10 Inventory class
//-----------------------------------------------------------
class ScrnMAC10MP extends MAC10MP;

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
        SetBoneLocation( 'MAC11_Bolt', ChargingHandleOffset, 0 ); //reset charging handle position
}

simulated function MoveBoltForward()
{
    if ( Level.NetMode != NM_DedicatedServer )
    {
        SetBoneLocation( 'MAC11_Bolt', -ChargingHandleOffset, 100 ); //move bolt forward
        bBoltClosed = true; //set this bool so weapon bolt will stay closed if dropped
    }
}

simulated function InterpolateBolt(float time)
{
    if ( Level.NetMode != NM_DedicatedServer )
        SetBoneLocation( 'MAC11_Bolt', ChargingHandleOffset, (time*500) ); //smooth moves
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
        SetAnimFrame(1, 0, 1); //skip frame 0 because it has the bolt back for some reason
        
        SetBoneLocation( 'MAC11_Bolt', ChargingHandleOffset, 0 ); //reset bolt so that the animation's Bolt position gets used
    }
    else if (MagAmmoRemaining >= 1 || !bBoltClosed)
    {
        bShortReload = true;
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.001); //reduced tween time to prevent Bolt from sliding
        SetAnimFrame(1, 0, 1); //skip frame 0 because it has the bolt back for some reason
        SetBoneLocation( 'MAC11_Bolt', ChargingHandleOffset, 100 ); //move the bolt back
    }
}

simulated function StartTweeningBolt()
{   
    bTweeningBolt = true; //start Bolt tweening
    TweenEndTime = Level.TimeSeconds + 0.2;
}

function AddReloadedAmmo()
{
    local int a;
    
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    a = MagCapacity;
    //if ( bShortReload )
    //    a++; // 1 bullet already bolted
    //removed +1 on tactical reload because MAC10 is an open bolt weapon
    
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
     ReloadShortAnim="Reload"
     ReloadShortRate=2.13 //2.1
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnMAC10Fire'
     PickupClass=Class'ScrnBalanceSrv.ScrnMAC10Pickup'
     ItemName="MAC10 SE"
     ChargingHandleOffset=(X=-0.035,Y=0.000,Z=0)
}
