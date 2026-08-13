class ScrnFNFALFire extends ScrnFire_HighROF;

var int BurstSize;
var float BurstRecoilMod;
var float BurstSpreadMod;

var transient int BurstShotCount; //how many bullets were fired in the current burst?
var transient float FireBurstEndTime; //this is just to be sure we don't stuck inside FireBurst state, if shit happens


// fixes double shot bug -- PooSH
state WaitingForFireButtonRelease
{
    function PlayFiring() {}
    function ServerPlayFiring() {}
    function PlayFireEnd() {}
    function ModeDoFire() {}
}

state FireBurst
{
    function BeginState()
    {
        BurstShotCount = 0;
        NextFireTime = Level.TimeSeconds - 0.000001; //fire now!
        FireBurstEndTime = Level.TimeSeconds + ( FireRate * BurstSize ) + 0.1; // if shit happens - get us out of this state when this time hits
    }

    function EndState()
    {
        PlayFireEnd();
    }

    function StopFiring()
    {
        GotoState('');
    }

    function ModeTick(float dt)
    {
        super.ModeTick(dt);

        if (!bIsFiring || !AllowFire())  // stopped firing, magazine empty
            GotoState('');
        else if ( Level.TimeSeconds > FireBurstEndTime )
        {
            GotoState('');
            log("stuck inside FireBurst state after making "$BurstShotCount$" shots! Getting us out of it.", class.name);
        }
    }

    simulated function float GetSpread()
    {
        local float NewSpread;

        NewSpread = global.GetSpread();
        if (NumShotsInBurst < BurstSize) {
            NewSpread *= BurstSpreadMod;
        }
        return NewSpread;
    }

    simulated function HandleRecoil(float Rec)
    {
        if (NumShotsInBurst == 0) {
            maxVerticalRecoilAngle = default.maxVerticalRecoilAngle * BurstRecoilMod;
            maxHorizontalRecoilAngle = default.maxHorizontalRecoilAngle * BurstRecoilMod;
        }

        global.HandleRecoil(Rec);

        maxVerticalRecoilAngle = default.maxVerticalRecoilAngle;
        maxHorizontalRecoilAngle = default.maxHorizontalRecoilAngle;
    }

    function ModeDoFire()
    {
        if (!AllowFire())
            return;

        super(ScrnFire).ModeDoFire();

        if (++BurstShotCount >= BurstSize) {
            GotoState('WaitingForFireButtonRelease');
            return;
        }
    }
}


defaultproperties
{
    // vanilla
    FireEndSoundRef="KF_FNFALSnd.FNFAL_Fire_Loop_End_M"
    FireEndStereoSoundRef="KF_FNFALSnd.FNFAL_Fire_Loop_End_S"
    AmbientFireSoundRef="KF_FNFALSnd.FNFAL_Fire_Loop"
    RecoilRate=0.080000
    maxVerticalRecoilAngle=150
    maxHorizontalRecoilAngle=115
    ShellEjectClass=Class'KFMod.KFShellEjectFAL'
    ShellEjectBoneName="Shell_eject"
    bRandomPitchFireSound=False
    FireSoundRef="KF_FNFALSnd.FNFAL_Fire_Single_M"
    StereoFireSoundRef="KF_FNFALSnd.FNFAL_Fire_Single_S"
    NoAmmoSoundRef="KF_SCARSnd.SCAR_DryFire"
    Momentum=8500.000000
    FireRate=0.085700
    ShakeRotMag=(X=80.000000,Y=80.000000,Z=450.000000)
    ShakeRotRate=(X=7500.000000,Y=7500.000000,Z=7500.000000)
    ShakeRotTime=0.650000
    ShakeOffsetMag=(X=6.000000,Y=3.000000,Z=8.500000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=1.150000
    BotRefireRate=0.990000
    FlashEmitterClass=Class'ROEffects.MuzzleFlash1stSTG'
    aimerror=42.000000
    SpreadStyle=SS_Random

    // ScrN
    DamageType=class'ScrnDamTypeFNFALAssaultRifle'
    AmmoClass=class'ScrnFNFALAmmo'
    Spread=0.0075
    DamageMax=55
    PenDmgReduction=0.75
    MaxPenetrations=2

    bHasFireBurst=true
    BurstSize=2
    BurstRecoilMod=0.1
    BurstSpreadMod=0.5
}
