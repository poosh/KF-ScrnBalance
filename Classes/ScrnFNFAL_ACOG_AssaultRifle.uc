class ScrnFNFAL_ACOG_AssaultRifle extends FNFAL_ACOG_AssaultRifle
    config(user);

    
var int FireModeEx; // 0 - F/A, 1 - S/A, 2 - 2 bullet fire
var int FireModeExCount;

var         name             ReloadShortAnim;
var         float             ReloadShortRate;


var transient bool  bShortReload;
var vector BulletMoveOffset; //for tactical reload
var bool bBulletMoveQueued; //for tactical reload

replication
{
    reliable if(Role < ROLE_Authority)
        ServerChangeFireModeEx;
}

// Toggle semi/auto fire
simulated function DoToggle ()
{
    local PlayerController Player;

    Player = Level.GetLocalPlayerController();
    if ( Player!=None )
    {
        FireModeEx++;
        if (FireModeEx >= FireModeExCount) FireModeEx = 0;
        FireMode[0].bWaitForRelease = FireModeEx == 1;
        Player.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnFireModeSwitchMessage',FireModeEx);
    }

    ServerChangeFireModeEx(FireModeEx);
}

// Set the new fire mode on the server
function ServerChangeFireModeEx(int NewFireModeEx)
{
    FireModeEx = NewFireModeEx;
    FireMode[0].bWaitForRelease = NewFireModeEx == 1;
}

simulated function bool StartFire(int Mode)
{
    if ( FireModeEx <= 1 ) return super.StartFire(Mode);
    
    if (FireMode[Mode].IsInState('WaitingForFireButtonRelease'))
        return false;

    if( !super(KFWeapon).StartFire(Mode) )  // returns false when mag is empty
       return false;

    if( AmmoAmount(0) <= 0 )
    {
        return false;
    }

    AnimStopLooping();

    if( !FireMode[Mode].IsInState('FireBurst') && (AmmoAmount(0) > 0) )
    {   
        ScrnFNFALFire(FireMode[Mode]).BurstSize = FireModeEx;
        FireMode[Mode].GotoState('FireBurst');
        return true;
    }

    return false;
}

simulated function StopFire(int Mode)
{
    super.StopFire(Mode);
    if (FireMode[Mode].IsInState('WaitingForFireButtonRelease'))
        FireMode[Mode].GotoState('');
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

//make sure bullet doesn't have old offset when reload finishes
simulated function ClientFinishReloading()
{
    Super.ClientFinishReloading();
    ResetBulletPosition(); //undo offset 
}

//ClientReloadEffects is called by WeaponTick halfway through reload, perfect for a tactical reload 
simulated function ClientReloadEffects()
{
    ResetBulletPosition(); //undo offset 
}

simulated function ResetBulletPosition()
{
    SetBoneLocation('Bullets', BulletMoveOffset, 0); //undo offset
}

simulated function MoveMagBullet()
{
    SetBoneLocation('Bullets', BulletMoveOffset, 100); //apply offset
}

simulated function WeaponTick(float dt)
{   
    if (Level.NetMode != NM_DedicatedServer)
    {
        if ( bBulletMoveQueued && bIsReloading && MagAmmoRemaining > 1 && (Level.TimeSeconds - ReloadTimer) > ReloadRate*0.12 )
        {
            bBulletMoveQueued = false;
            MoveMagBullet();
        }
    }
    Super.WeaponTick(dt);
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
        if (MagAmmoRemaining >= 2)
        bBulletMoveQueued = true; //set flag for tactical reload
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
    ReloadShortAnim="Reload"
    ReloadShortRate=2.55
    FireModeExCount=3
    Weight=7.000000
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnFNFALFire'
    Description="Classic NATO battle rifle. Can penetrate small targets and has a fixed-burst mode."
    PickupClass=Class'ScrnBalanceSrv.ScrnFNFAL_ACOG_Pickup'
    ItemName="FNFAL SE"
    BulletMoveOffset=(X=0,Y=0,Z=0.03) //for tactical reload
}