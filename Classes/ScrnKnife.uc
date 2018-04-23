class ScrnKnife extends Knife;

var transient bool bRestoreAltFire;
var transient float RestoreAltFireTime;
simulated state QuickMelee
{
    simulated function Timer()
    {
        if ( OldWeapon != none ) {
            Instigator.PendingWeapon = OldWeapon;
            if ( KFWeapon(OldWeapon) != none )
                KFWeapon(OldWeapon).ClientGrenadeState = GN_BringUp;
            PutDown();
        }
        else
            GotoState('');
    }

    simulated function bool PutDown()
    {
        local bool result;

        ClientGrenadeState = GN_TempDown;
        result = global.PutDown();
        ClientGrenadeState = GN_None;
        GotoState('');
        return result;
    }

    simulated event WeaponTick(float dt)
    {
        super.WeaponTick(dt);

        if ( bRestoreAltFire && Level.TimeSeconds > RestoreAltFireTime ) {
            Instigator.Controller.bAltFire = 0; // restore to original state
            bRestoreAltFire = false;
        }
    }


    simulated function BringUp(optional Weapon PrevWeapon)
    {
        local int Mode;

        HandleSleeveSwapping();
        KFHumanPawn(Instigator).SetAiming(false);
        bAimingRifle = false;
        bIsReloading = false;
        IdleAnim = default.IdleAnim;


        for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++) {
            FireMode[Mode].bIsFiring = false;
            FireMode[Mode].HoldTime = 0.0;
            FireMode[Mode].bServerDelayStartFire = false;
            FireMode[Mode].bServerDelayStopFire = false;
            FireMode[Mode].bInstantStop = false;
        }

        OldWeapon = PrevWeapon;
        ClientState = WS_ReadyToFire;
        bRestoreAltFire = Instigator.Controller.bAltFire == 0;
        if ( bRestoreAltFire ) {
            Instigator.Controller.bAltFire = 1; // this is required to properly play attack animation
            RestoreAltFireTime = Level.TimeSeconds + 0.2;
        }
        ClientStartFire(1);
        SetTimer(FireMode[1].FireRate * 0.8, false);
    }

    simulated function EndState()
    {
        bRestoreAltFire = false;
        OldWeapon = none;
        ScrnHumanPawn(Instigator).QuickMeleeFinished();
    }
}


simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    bCanThrow = KF_StoryGRI(Level.GRI) != none; // throw knife on dying only in story mode
}



defaultproperties
{
    PickupClass=Class'ScrnBalanceSrv.ScrnKnifePickup'
    ItemName="Knife SE"
    Description="Military Combat Knife"
    Priority=2

    // PutDownAnimRate=2.0
    // SelectAnimRate=2.0
    // BringUpTime=0.25
    // PutDownTime=0.25
}
