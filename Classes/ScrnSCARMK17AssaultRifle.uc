//=============================================================================
// SCAR MK17 Inventory class
//=============================================================================
class ScrnSCARMK17AssaultRifle extends SCARMK17AssaultRifle
    config(user);

var         name             ReloadShortAnim;
var         float             ReloadShortRate;

var transient bool  bShortReload;

//bolt moving things
var vector ChargingHandleOffset;
var rotator BoltReleaseRotation;
var bool bBoltReleased;
var transient bool bBoltLockQueued;
var float BoltLockTime;
var float BoltReleaseTime;

//allow firemode switch even if empty
simulated function AltFire(float F)
{
    DoToggle();
}

//called to set bolt at end position at end of timer
simulated function MoveBoltForward()
{
    SetBoneLocation( 'Charging_Bolt', ChargingHandleOffset, 0 ); //move bolt to forward position
    SetBoneRotation( 'Bolt_Release', BoltReleaseRotation, , 0 ); //move bolt release to not locked back rotation
}

//called to set bolt at end position at end of timer
simulated function MoveBoltToLocked()
{
    SetBoneLocation( 'Charging_Bolt', ChargingHandleOffset, 100 ); //move bolt to locked open position
    SetBoneRotation( 'Bolt_Release', BoltReleaseRotation, , 100 ); //move bolt release to locked open rotation
}

//lock bolt if empty and selected
simulated function BringUp(optional Weapon PrevWeapon)
{
    Super.BringUp(PrevWeapon);
    if (MagAmmoRemaining == 0 )
        MoveBoltToLocked();
}

simulated function WeaponTick(float dt)
{
    //handles locking bolt
    if (BoltLockTime > 0)
    {
        if( bBoltLockQueued && Level.TimeSeconds > BoltLockTime)
        {
            MoveBoltToLocked(); //lock bolt back
            BoltLockTime = 0;
        }
    }
    //handles releasing bolt after reload
    if(bIsReloading && !bBoltReleased && Level.TimeSeconds >= BoltReleaseTime)
    {
        bBoltReleased = true;
        MoveBoltForward(); //move bolt forward (only noticeable for empty reload)
    }
    Super.WeaponTick(dt);
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
    bBoltLockQueued = false;
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
        MoveBoltToLocked(); //shouldn't be needed but I put it here anyway to make sure it works
        BoltReleaseTime = Level.TimeSeconds + 0.89*Default.ReloadRate/ReloadMulti;
    }
    else if (MagAmmoRemaining >= 1)
    {
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.1);
    }
}

simulated function ClientFinishReloading()
{
    bBoltReleased = false; //allow bolt to be released again
    MoveBoltForward(); //force bolt forward in case setting it in weapontick is broken
    Super.ClientFinishReloading();
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
    ReloadShortAnim="Reload"
    ReloadShortRate=2.27 //2.966000
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnSCARMK17Fire'
    PickupClass=Class'ScrnBalanceSrv.ScrnSCARMK17Pickup'
    ItemName="SCARMK17 SE"
    ChargingHandleOffset=(X=-0.067,Y=0.0,Z=0.0)
    BoltReleaseRotation=(Pitch=0,Yaw=0,Roll=10)
}
