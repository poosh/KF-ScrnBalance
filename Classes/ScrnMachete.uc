class ScrnMachete extends Machete;

var transient bool bRestoreAltFire;
var transient float RestoreAltFireTime;

simulated function PostNetBeginPlay() {
    local ScrnHumanPawn ScrnPawn;

    super.PostNetBeginPlay();

    ScrnPawn = ScrnHumanPawn(Instigator);
    if (ScrnPawn != none) {
        // The server may replicate ScrnHumanPawn.QuickMeleeWeapon before the actual weapon, making in none on the
        // client side. So we need to double-check it here.
        ScrnPawn.CheckQuickMeleeWeapon(self);
    }
}

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

simulated function float RateSelf()
{
    local ScrnHumanPawn ScrnPawn;

    ScrnPawn = ScrnHumanPawn(Instigator);
    if (ScrnPawn != none && ScrnPawn.bAllowMacheteBoost && ScrnPawn.ScrnPC != none
            && !ScrnPawn.ScrnPC.bNeverSwitchOnPickup) {
        return 1000;  // for machete-sprinting
    }
    return super.RateSelf();
}

defaultproperties
{
    FireModeClass(0)=class'ScrnMacheteFire'
    FireModeClass(1)=class'ScrnMacheteFireB'
    PickupClass=class'ScrnMachetePickup'
    ItemName="Machete SE"

    QuickPutDownTime=0.01  // 0.15
    QuickBringUpTime=0.01  // 0.15

    PutDownAnimRate=2.8889
    SelectAnimRate=6.6667
    BringUpTime=0.15
    PutDownTime=0.15

    HudImageRef="KillingFloorHUD.WeaponSelect.machette_unselected"
    SelectedHudImageRef="KillingFloorHUD.WeaponSelect.machette"
    SelectSoundRef="KF_MacheteSnd.Machete_Select"
    MeshRef="KF_Weapons_Trip.Machete_Trip"
    SkinRefs(0)="KF_Weapons_Trip_T.melee.Machete_cmb"
    SkinRefs(1)="KF_Weapons_Trip_T.hands.hands_1stP_military_cmb"
    BloodyMaterialRef="KF_Weapons_Trip_T.melee.machete_bloody_cmb"
}
