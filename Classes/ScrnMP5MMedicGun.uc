class ScrnMP5MMedicGun extends MP5MMedicGun;

var         float           ReloadShortRate;
var string NewAnimRef;
var string OldAnimRef;
var MeshAnimation NewAnim; //test
var ScrnMP5MBullets MP5MBullets; //for tactical reload

var transient bool  bShortReload;

static function PreloadAssets(Inventory Inv, optional bool bSkipRefCount)
{
    local ScrnMP5MMedicGun spawned;

    super.PreloadAssets(Inv, bSkipRefCount);

    if (default.NewAnimRef == "")
        return;
        
    default.NewAnim = MeshAnimation(DynamicLoadObject(default.NewAnimRef, class'MeshAnimation', true));

    spawned = ScrnMP5MMedicGun(Inv);
    if( spawned != none ) {
        spawned.NewAnim = default.NewAnim;
        spawned.AddNewAnim();
    }
}

static function bool UnloadAssets()
{
    default.NewAnim = none;
    return super.UnloadAssets();
}

//new anim in PostBeginPlay because adding it in PreloadAssets didn't work
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    AddNewAnim();

    if (Level.NetMode != NM_DedicatedServer) {
        //attach bullets to old mag for tactical reload
        if ( MP5MBullets == none ) {
            MP5MBullets = spawn(class'ScrnMP5MBullets',self);
        }
        if ( MP5MBullets != none ) {
            AttachToBone(MP5MBullets, 'Empty_Magazine');
        }
    }
}

simulated function AddNewAnim()
{
    if (NewAnim == none || NewAnimRef == "")
        return;

    LinkSkelAnim(NewAnim); //load new anim
    //for some reason linking the new anim removed the link to the old one, so we need to load it again
    LinkSkelAnim(MeshAnimation(DynamicLoadObject(OldAnimRef, class'MeshAnimation', true)));
}

//destroy mp5m bullets when done
simulated function Destroyed()
{
    if ( MP5MBullets != None )
        MP5MBullets.Destroy();
    super.Destroyed();
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
        if (MP5MBullets != none)
        {
            MP5MBullets.SetDrawScale(0.0);
        }
    }
    else if (MagAmmoRemaining >= 1)
    {
        bShortReload = true;

        if (NewAnim != none && HasAnim('reloadshort'))
        {
            PlayAnim('reloadshort', ReloadAnimRate*ReloadMulti, 0.1);
        }
        else
        {
            PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti*(ReloadRate/ReloadShortRate), 0.1);
        }
        if (MP5MBullets != none)
        {
            MP5MBullets.SetDrawScale(1.0);
            MP5MBullets.HandleBulletScale(MagAmmoRemaining);
        }
    }
}

//added delay after reload and moved idle into timer
simulated function ClientFinishReloading()
{
    bIsReloading = false;
    if (!bShortReload )
    {
        PlayIdle(); //don't play blend for tactical reload to avoid magazine tween
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
    ReloadShortRate=2.00
    ReloadAnim="Reload"
    ReloadRate=2.90
    ReloadAnimRate=1.3
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
    NewAnimRef="ScrnAnims.mp5_anim_new"
    OldAnimRef="KF_Wep_MP5.Mp5_anim"
}
