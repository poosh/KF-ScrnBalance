class ScrnAA12AutoShotgun extends AA12AutoShotgun;

var         name         ReloadShortAnim;
var         float         ReloadShortRate;

var transient bool bShortReload;
var transient bool bBoltClosed; //tracks state of bolt

var ScrnFakedProjectile FakedShell;

//added bBoltClosed bool
simulated function ClientFinishReloading()
{
    PlayIdle();
    bBoltClosed = false; //reset bool
    bIsReloading = false;

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
}

simulated function bool AllowReload()
{
    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    if(KFInvasionBot(Instigator.Controller) != none && !bIsReloading && MagAmmoRemaining < MagCapacity && AmmoAmount(0) > MagAmmoRemaining)
        return true;

    if(KFFriendlyAI(Instigator.Controller) != none && !bIsReloading && MagAmmoRemaining < MagCapacity && AmmoAmount(0) > MagAmmoRemaining)
        return true;

    if(FireMode[0].IsFiring() || FireMode[1].IsFiring() || bIsReloading || MagAmmoRemaining >= MagCapacity || ClientState == WS_BringUp || AmmoAmount(0) <= MagAmmoRemaining ||(FireMode[0].NextFireTime - Level.TimeSeconds) > 0.1 )
        return false;

    return true;
}

exec function ReloadMeNow()
{
    local float ReloadMulti;

    if(!AllowReload())
        return;

    if ( bHasAimingMode && bAimingRifle ) {
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
    //bShortReload = MagAmmoRemaining > 0 && ReloadShortAnim != '';
    bShortReload = !bBoltClosed;
    if ( bShortReload )
        ReloadRate = Default.ReloadShortRate / ReloadMulti;
    else
        ReloadRate = Default.ReloadRate / ReloadMulti;

    if( bHoldToReload )
        NumLoadedThisReload = 0;

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
    if ( bBoltClosed && ReloadShortAnim == '' )
    {
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
        if ( FakedShell != none )
            FakedShell.Destroy(); //try destroying the faked shell to prevent it from appearing
    }
    else if ( MagAmmoRemaining >= 1 )
    {
        PlayAnim(ReloadShortAnim, ReloadAnimRate*ReloadMulti, 0.1);
        SetAnimFrame(29.35, 0 , 1); //go straight to frame 29.35
        if ( FakedShell == none )
            AttachShell();
    }
}

simulated function AttachShell() {
    if ( Level.NetMode != NM_DedicatedServer )
    {
        if ( FakedShell == none ) //only spawn fakedshell once
            FakedShell = spawn(class'ScrnFakedShell',self);
        if ( FakedShell != none )
        {
            AttachToBone(FakedShell, 'Magazine'); //attach faked shell to AA12 magazine
            FakedShell.SetDrawScale(4.7); //4.7
            FakedShell.SetRelativeLocation(vect(0.15, 0, 4.00));
            FakedShell.SetRelativeRotation(rot(0,32768,0));
        }
    }
}

function AddReloadedAmmo()
{
    local int a;

    UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    a = MagCapacity;
    //if ( bShortReload )
    //  a++; // 1 bullet already bolted //disabled because aa-12 is an open bolt weapon
    if ( AmmoAmount(0) >= a )
        MagAmmoRemaining = a;
    else
        MagAmmoRemaining = AmmoAmount(0);

    if ( PlayerController(Instigator.Controller) != none && KFSteamStatsAndAchievements(PlayerController(Instigator.Controller).SteamStatsAndAchievements) != none )
    {
        KFSteamStatsAndAchievements(PlayerController(Instigator.Controller).SteamStatsAndAchievements).OnWeaponReloaded();
    }
}

simulated function ClientReloadEffects()
{
    //the faked shell should be destroyed after the tactical reload completes, but I'm not sure where to put this, how about here
    //if there is a fakedshell destroy it
    if ( FakedShell != none && !FakedShell.bDeleteMe )
        FakedShell.Destroy();
}

simulated function Destroyed()
{
    if ( FakedShell != none && !FakedShell.bDeleteMe )
        FakedShell.Destroy();

    super.Destroyed();
}

defaultproperties
{
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnAA12Fire'
    ReloadShortRate=2.10 //tactical reload
    ReloadShortAnim="Reload" //tactical reload
    ReloadAnimRate=1.000000
    Description="An advanced fully automatic shotgun. Delivers less per-bullet damage, but awesome penetration and fire rate make it the best choise to kill everything... while you have ammo remaining"
    PickupClass=Class'ScrnBalanceSrv.ScrnAA12Pickup'
    ItemName="AA12 SE"
}
