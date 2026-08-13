class ScrnM4203BulletFire extends ScrnM4Fire;

var ScrnM4203AssaultRifle ScrnWeap; // avoid typecasting

var int BurstSize;
var transient int BurstShotCount;       //how many bullets were fired in the current burst?
var transient float FireBurstEndTime;   //this is just to be sure we don't stuck inside FireBurst state, if shit happens

//those functions are used only in FireBurst
function PlayFiring() { }
function PlayFireEnd() { }
function ServerPlayFiring() { }

function PostBeginPlay()
{
    super.PostBeginPlay();
    ScrnWeap = ScrnM4203AssaultRifle(Weapon);
}


// client-side state
state WaitingForFireButtonRelease
{
    function PlayFiring() {}
    function ServerPlayFiring() {}
    function PlayFireEnd() {}
    function ModeDoFire() {}

    function ModeTick(float dt)
    {
        // allow fire as soon as player releases a fire button
        if (!IsFireButtonPressed())
            GotoState('');
    }
}

state FireBurst
{
    function PlayFiring() {}
    function ServerPlayFiring() {}

    function BeginState()
    {
        BurstShotCount = 0;
        NextFireTime = Level.TimeSeconds - 0.000001; //fire now!
        FireBurstEndTime = Level.TimeSeconds + ( FireRate * BurstSize ) + 0.1; // if shit happens - get us out of this state when this time hits

        if( KFWeap.bAimingRifle )
        {
            Weapon.LoopAnim(FireLoopAimedAnim, FireLoopAnimRate, TweenTime);
        }
        else
        {
            Weapon.LoopAnim(FireLoopAnim, FireLoopAnimRate, TweenTime);
        }

        PlayAmbientSound(AmbientFireSound);
    }

    function EndState()
    {
        super.PlayFireEnd();
        Weapon.AnimStopLooping();
        PlayAmbientSound(none);

        if( Weapon.Instigator != none && Weapon.Instigator.IsLocallyControlled() &&
           Weapon.Instigator.IsFirstPerson() && StereoFireSound != none )
        {
            Weapon.PlayOwnedSound(FireEndStereoSound,SLOT_None,AmbientFireVolume/127,,AmbientFireSoundRadius,,false);
        }
        else
        {
            Weapon.PlayOwnedSound(FireEndSound,SLOT_None,AmbientFireVolume/127,,AmbientFireSoundRadius);
        }

        ScrnWeap.ReallyStopFire(ThisModeNum);
        bIsFiring = false; // tbs
    }

    function StartFiring()
    {
        super(ScrnFire).StartFiring(); //bypass HighROF
    }

    function StopFiring()
    {
        GotoState('');
    }

    function ModeTick(float dt)
    {
        //log ("ScrnM4Fire.FireBurst.ModeTick()", 'ScrnBalance');
        Super.ModeTick(dt);

        if (!bIsFiring || !AllowFire()) {
            GotoState('');
        }
        else if (Level.TimeSeconds > FireBurstEndTime) {
            GotoState('');
            log("ScrnM4203BulletFire stuck inside FireBurst state after making "$BurstShotCount$" shots! Getting us out of it.", 'ScrnBalance');
        }
    }

    function ModeDoFire()
    {
        if (!AllowFire())
            return;

        super(ScrnFire).ModeDoFire();

        if (++BurstShotCount >= BurstSize) {
            //log ("ScrnM4203BulletFire.ChangeFireBurstState", 'ScrnBalance');
            //don't go to WaitingForFireButtonRelease state on server
            if (!IsFireButtonPressed() || ScrnWeap.MagAmmoRemaining < 1 || ScrnWeap.bTriggerReleased)
                GotoState('');
            else
                GotoState('WaitingForFireButtonRelease');
        }
    }
}

defaultproperties
{
    bHasFireBurst=true
    BurstSize=3
    DamageType=class'ScrnDamTypeM4203AssaultRifle'
    DamageMax=41
    FireAnimRate=0.75
    FireLoopAnimRate=1.4 //0.750000
    FireRate=0.100000
    AmmoClass=Class'KFMod.M4203Ammo'
}
