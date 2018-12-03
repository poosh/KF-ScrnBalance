class ScrnBoomStick extends BoomStick;

var() float SingleShellReloadRatio; //comparing to full reload rate. 2.0 = twice faster reload
var string NewAnimRef;
var string OldAnimRef;
var MeshAnimation NewAnim;
var float ReloadHalfAnimRate; //animation playrate modifier for reload_half
var name ReloadHalfAnim;

replication
{
    reliable if(Role == ROLE_Authority)
        ClientPlayReloadAnim, ClientSetWaitingToLoadShotty;
}

static function PreloadAssets(Inventory Inv, optional bool bSkipRefCount)
{
    local ScrnBoomStick spawned;

    super.PreloadAssets(Inv, bSkipRefCount);
    
    if (default.NewAnimRef == "")
        return;

    default.NewAnim = MeshAnimation(DynamicLoadObject(default.NewAnimRef, class'MeshAnimation', true));

    spawned = ScrnBoomStick(Inv);
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
}

simulated function AddNewAnim()
{
    if (NewAnim == none || NewAnimRef == "")
        return;

    LinkSkelAnim(NewAnim); //load new anim
    //for some reason linking the new anim removed the link to the old one, so we need to load it again
    LinkSkelAnim(MeshAnimation(DynamicLoadObject(OldAnimRef, class'MeshAnimation', true)));
}

simulated function WeaponTick(float dt)
{
    super(KFWeaponShotgun).WeaponTick(dt);

    if( Role == ROLE_Authority )
    {
        if( bWaitingToLoadShotty )
        {
            CurrentReloadCountDown -= dt;

            if( CurrentReloadCountDown <= 0 )
            {
                if( AmmoAmount(0) > 0 )
                {
                    MagAmmoRemaining = Min(AmmoAmount(0), 2);
                    SingleShotCount = MagAmmoRemaining;
                    ClientSetSingleShotCount(SingleShotCount);
                    bWaitingToLoadShotty = false;
                    ClientSetWaitingToLoadShotty(bWaitingToLoadShotty); // replicate it to clients too
                    NetUpdateTime = Level.TimeSeconds - 1;
                }
            }
        }

        if( SingleShotReplicateCountdown > 0 )
        {
            SingleShotReplicateCountdown -= dt;

            if( SingleShotReplicateCountdown <= 0 )
            {
                ClientSetSingleShotCount(SingleShotCount);
            }
        }
    }
}

function SetPendingReload()
{
    if ( !bWaitingToLoadShotty && AmmoAmount(0) > 0 ) {
        bWaitingToLoadShotty = true;
        ClientSetWaitingToLoadShotty(bWaitingToLoadShotty); // replicate it to clients too
        CurrentReloadCountDown = ReloadCountDown;
    }
}


simulated function bool ConsumeAmmo( int Mode, float Load, optional bool bAmountNeededIsMax )
{
    local bool result;

    result = super.ConsumeAmmo(0, Load, bAmountNeededIsMax);

    if ( AmmoAmount(0) == 0 && MagAmmoRemaining == 0 ) {
        SingleShotCount = 0;
        if ( bWaitingToLoadShotty ) {
            bWaitingToLoadShotty = false;
            ClientSetWaitingToLoadShotty(bWaitingToLoadShotty); // replicate it to clients too
        }
    }

    return result;
}

simulated function ClientSetWaitingToLoadShotty(bool bNewWaitingToLoadShotty)
{
    bWaitingToLoadShotty = bNewWaitingToLoadShotty;
}

simulated function ClientPlayReloadAnim(float AnimRatio)
{
    if (AnimRatio ~= 0)
        AnimRatio = 1.0;

    bWaitingToLoadShotty = true;
    if ( NewAnim != none )
    {
        PlayAnim(ReloadHalfAnim, ReloadHalfAnimRate, 0.1);  //noreload multi because no firerate bonus for boomstick
    }
    else
    {
        PlayAnim(BoomStickAltFire(FireMode[0]).FireLastAnim,
            FireMode[0].FireAnimRate * AnimRatio,
            FireMode[0].TweenTime, 0);
        SetAnimFrame(4, 0 , 1); //skip fire animation and jump to reload
    }
}

//allow reload single shell
function bool AllowReload()
{
    if ( bWaitingToLoadShotty )
        return false;

    return super(KFWeaponShotgun).AllowReload();
}

exec function ReloadMeNow()
{
    if(!AllowReload())
        return;

    if ( SingleShotCount < MagCapacity && !bWaitingToLoadShotty && AmmoAmount(0) > 0 ) {
        bWaitingToLoadShotty = true;
        if ( SingleShotCount > 0 ) {
            CurrentReloadCountDown = ReloadCountDown / SingleShellReloadRatio;
            ClientPlayReloadAnim(SingleShellReloadRatio);
        }
        else {
            CurrentReloadCountDown = ReloadCountDown;
            ClientPlayReloadAnim(1.0);
        }
    }
}


simulated function bool PutDown()
{
    if ( bWaitingToLoadShotty && Instigator != none && Instigator.PendingWeapon != none && AmmoAmount(0) > 1 ) {
        Instigator.PendingWeapon = none;
        return false;
    }

    return super.PutDown();
}



function GiveAmmo(int m, WeaponPickup WP, bool bJustSpawned)
{
    super(KFWeapon).GiveAmmo(m,WP,bJustSpawned);

        // Update the singleshotcount if we pick this weapon up
    if( WP != none )
    {
        if( m == 0 && AmmoAmount(0) < 2 )
        {
            SingleShotCount = AmmoAmount(0);
            MagAmmoRemaining = SingleShotCount;
            ClientSetSingleShotCount(SingleShotCount);
            NetUpdateTime = Level.TimeSeconds - 1;
        }
        else if( BoomStickPickup(WP) != none )
        {
            SingleShotCount = BoomStickPickup(WP).SingleShotCount;
            MagAmmoRemaining = SingleShotCount;
            ClientSetSingleShotCount(SingleShotCount);
            NetUpdateTime = Level.TimeSeconds - 1;
        }
    }
}

simulated function ClientSetSingleShotCount(float NewSingleShotCount)
{
    SingleShotCount = NewSingleShotCount;
    MagAmmoRemaining = SingleShotCount;
}


defaultproperties
{
    ReloadRate=2.750000 // set here to properly calc stats
    SingleShellReloadRatio=1.750000
    ReloadHalfAnim="reload_half"
    ReloadHalfAnimRate = 1.4633 //to play 69 frames in 1.5714 seconds
    FireModeClass(0)=Class'ScrnBalanceSrv.ScrnBoomStickAltFire'
    FireModeClass(1)=Class'ScrnBalanceSrv.ScrnBoomStickFire'
    Description="This is my BOOMstick (c) Ash, Evil Dead - Army of Darkness, 1992.|Has been used through the centuries to hunt down Demons, Aliens and Zombies. Now it's time for the ZEDs.|Can shoot from one or two barrels simultaneousely. Single shell reload is avaliable."
    PickupClass=Class'ScrnBalanceSrv.ScrnBoomStickPickup'
    ItemName="Boomstick"
    //Priority=220 // 160 - switch before aa12
    NewAnimRef="ScrnAnims.boomstick_anim_new"
    OldAnimRef="KF_Weapons_Trip.boomstick_anim"
}
