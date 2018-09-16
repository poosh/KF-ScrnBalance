class ScrnAA12AutoShotgun extends AA12AutoShotgun;

var         name         ReloadShortAnim;
var         float         ReloadShortRate;

var transient bool bShortReload;
//var bool bBoltClosed; //unused until bug free implementation is found due to aa12 reload mechanics (charge first)

var ScrnFakedProjectile FakedShell;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
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
            //attempt to set shell to have same skin as AA12 (for cases where player is using golden aa12 or something)
            if (self.Skins[1] != none)
                FakedShell.Skins[0] = self.Skins[1];
        }
    }
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
    bShortReload = MagAmmoRemaining > 0 && ReloadShortAnim != '';

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
    
    if ( MagAmmoRemaining <= 0 || ReloadShortAnim == '' )
    {
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
        HideFakedShell();
    }
    else 
    {
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
        SetTimer(0.25/ReloadMulti, false); //for tactical reload, skip reload animation only after 7.5 frames of anim so it looks good
        ShowFakedShell();
    }
}

//added this for a somewhat smoother transition for tactical reload start
simulated function Timer()
{
    if (bIsReloading)
    {
        SetAnimFrame(29.35, 0 , 1); //go straight to frame 29.35
    }
    Super.Timer();
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

simulated function ShowFakedShell()
{
    if ( FakedShell != none )
        FakedShell.SetDrawScale(4.7); //4.7
}

simulated function HideFakedShell()
{
    if ( FakedShell != none )
        FakedShell.SetDrawScale(0.01); //4.7
}

simulated function ClientReloadEffects()
{
    HideFakedShell();
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
    ReloadShortRate=2.35 //tactical reload (added 0.25)
    ReloadShortAnim="Reload" //tactical reload
    ReloadAnimRate=1.000000
    Description="An advanced fully automatic shotgun. Delivers less per-bullet damage, but awesome penetration and fire rate make it the best choise to kill everything... while you have ammo remaining"
    PickupClass=Class'ScrnBalanceSrv.ScrnAA12Pickup'
    ItemName="AA12 SE"
}
