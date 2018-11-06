class ScrnChainsaw extends Chainsaw;

var float IdleFuelConsumeTime; // time between fuel consumption on idle

var sound  EngineStartSound, EngineStopSound;
var string EngineStartSoundRef, EngineStopSoundRef;

struct SoundList {
    var string SoundRef;
    var sound  Sound;
    var float  Duration;
};
var array<SoundList> ReloadSounds;
var float TotalReloadSoundDuration; // total duration of all reload sounds
var transient float TimeToNextReloadSound;
var transient int NextReloadSoundIndex;
var transient bool bBlownUpThisReload;

var transient int OldMagAmmoRemaining;
var ScrnFakedProjectile FakedGasCan; //adds a faked gas can during reload

replication
{
	reliable if(Role == ROLE_Authority)
		HideGasCan;
}

simulated function PostNetReceive()
{
    super.PostNetReceive();

    if ( Role < ROLE_Authority ) {
        if ( OldMagAmmoRemaining != MagAmmoRemaining ) {
            if ( MagAmmoRemaining == 0 ) {
                if ( ThirdPersonActor != none )
                    ThirdPersonActor.AmbientSound = none;
                TexPanner(Skins[1]).PanRate = 0; // stop saw cycling
                PlaySound(EngineStopSound);
            }
            else if ( OldMagAmmoRemaining < MagAmmoRemaining && MagAmmoRemaining > 0 ) {
                //just reloaded
                if ( IsInState('Reloading') )
                    GotoState('');
                if ( ThirdPersonActor != none )
                    ThirdPersonActor.AmbientSound = ThirdPersonActor.default.AmbientSound;
                TexPanner(Skins[1]).PanRate = 3; // start saw cycling
                PlaySound(EngineStartSound);
                if ( !IsAnimating() )
                    PlayIdle();
            }
            OldMagAmmoRemaining = MagAmmoRemaining;
        }
    }
}

static function PreloadAssets(Inventory Inv, optional bool bSkipRefCount)
{
    local int i;
    local ScrnChainsaw W;

    super.PreloadAssets(Inv, bSkipRefCount);

    W = ScrnChainsaw(Inv);

    default.EngineStartSound = sound(DynamicLoadObject(default.EngineStartSoundRef, class'sound'));
    default.EngineStopSound = sound(DynamicLoadObject(default.EngineStopSoundRef, class'sound'));

    for ( i = 0; i < default.ReloadSounds.Length; ++i ) {
        default.ReloadSounds[i].Sound = sound(DynamicLoadObject(default.ReloadSounds[i].SoundRef, class'sound'));
        if ( W != none ) {
            W.ReloadSounds[i].Sound = default.ReloadSounds[i].Sound;
        }
    }

    if ( W != none ) {
        W.EngineStartSound = default.EngineStartSound;
        W.EngineStopSound = default.EngineStopSound;

        W.CalcReloadSoundDuration();
        default.TotalReloadSoundDuration = W.TotalReloadSoundDuration;
    }
}
static function bool UnloadAssets()
{
    local int i;

    default.EngineStartSound = none;
    default.EngineStopSound = none;

    default.TotalReloadSoundDuration = 0;
    for ( i = 0; i < default.ReloadSounds.Length; ++i ) {
        default.ReloadSounds[i].Sound = none;
    }

    return super.UnloadAssets();
}


simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    AttachGasCan();

    CalcReloadSoundDuration();
}

simulated function AttachGasCan() {
    if ( Level.NetMode != NM_DedicatedServer )
    {
        if ( FakedGasCan == none ) //only spawn FakedGasCan once
            FakedGasCan = spawn(class'ScrnFakedGasCan',self);
        if ( FakedGasCan != none )
        {
            AttachToBone(FakedGasCan, 'Chainsaw'); //attach faked shell to chainsaw
            FakedGasCan.SetDrawScale(0.01);
            FakedGasCan.SetRelativeLocation(vect(-3, 2, 3)); //x y z
            FakedGasCan.SetRelativeRotation(rot(-4000, 38000, 12000)); //pitch yaw roll
        }
    }
}

simulated function CalcReloadSoundDuration()
{
    local int i;

    TotalReloadSoundDuration = 0;
    for ( i = 0; i < default.ReloadSounds.Length; ++i ) {
        ReloadSounds[i].Duration = GetSoundDuration(ReloadSounds[i].Sound);
        TotalReloadSoundDuration += ReloadSounds[i].Duration;
    }
}

simulated function bool ConsumeAmmo( int Mode, float Load, optional bool bAmountNeededIsMax )
{
    local Inventory Inv;
    local bool bOutOfAmmo;
    local KFWeapon KFWeap;

    if ( Super(Weapon).ConsumeAmmo(Mode, Load, bAmountNeededIsMax) )
    {
        if ( Load > 0 && (Mode == 0 || bReduceMagAmmoOnSecondaryFire) ) {
            MagAmmoRemaining -= Load; // Changed from "MagAmmoRemaining--"  -- PooSH
            if ( MagAmmoRemaining < 0 )
                MagAmmoRemaining = 0;
            if ( MagAmmoRemaining == 0 ) {
                ThirdPersonActor.AmbientSound = none;
                TexPanner(Skins[1]).PanRate = 0; // stop saw cycling
                PlaySound(EngineStopSound);
            }
        }
        OldMagAmmoRemaining = MagAmmoRemaining;

        NetUpdateTime = Level.TimeSeconds - 1;

        if ( FireMode[Mode].AmmoPerFire > 0 && InventoryGroup > 0 && !bMeleeWeapon && bConsumesPhysicalAmmo &&
             (Ammo[0] == none || FireMode[0] == none || FireMode[0].AmmoPerFire <= 0 || Ammo[0].AmmoAmount < FireMode[0].AmmoPerFire) &&
             (Ammo[1] == none || FireMode[1] == none || FireMode[1].AmmoPerFire <= 0 || Ammo[1].AmmoAmount < FireMode[1].AmmoPerFire) )
        {
            bOutOfAmmo = true;

            for ( Inv = Instigator.Inventory; Inv != none; Inv = Inv.Inventory )
            {
                KFWeap = KFWeapon(Inv);

                if ( Inv.InventoryGroup > 0 && KFWeap != none && !KFWeap.bMeleeWeapon && KFWeap.bConsumesPhysicalAmmo &&
                     ((KFWeap.Ammo[0] != none && KFWeap.FireMode[0] != none && KFWeap.FireMode[0].AmmoPerFire > 0 &&KFWeap.Ammo[0].AmmoAmount >= KFWeap.FireMode[0].AmmoPerFire) ||
                     (KFWeap.Ammo[1] != none && KFWeap.FireMode[1] != none && KFWeap.FireMode[1].AmmoPerFire > 0 && KFWeap.Ammo[1].AmmoAmount >= KFWeap.FireMode[1].AmmoPerFire)) )
                {
                    bOutOfAmmo = false;
                    break;
                }
            }

            if ( bOutOfAmmo )
            {
                PlayerController(Instigator.Controller).Speech('AUTO', 3, "");
            }
        }

        return true;
    }
    return false;
}



simulated function ClientReload()
{
    super.ClientReload();
    if (FakedGasCan != none)
        FakedGasCan.SetDrawScale(2); //test
        // if MagAmmoRemaining == 0, chaisaw is already stopped
    if ( MagAmmoRemaining > 0 )
        PlaySound(EngineStopSound);
    ThirdPersonActor.AmbientSound = none;

    GotoState('Reloading');
}


simulated function ActuallyFinishReloading()
{
    super.ActuallyFinishReloading();

    IdleFuelConsumeTime = default.IdleFuelConsumeTime;
    GotoState('');
    if ( MagAmmoRemaining > 0) {
        PlaySound(EngineStartSound);
        ThirdPersonActor.AmbientSound = ThirdPersonActor.default.AmbientSound;
        TexPanner(Skins[1]).PanRate = 3; // start saw cycling
        PlayIdle();
    }
}

simulated function ClientFinishReloading()
{
    super.ClientFinishReloading();
    if ( Level.NetMode != NM_DedicatedServer )
    {
        if (FakedGasCan != none)
            FakedGasCan.SetDrawScale(0.01); //hide gas can after reload
    }
}

simulated function WeaponTick(float dt)
{
    super.WeaponTick(dt);

    if ( Role == Role_Authority ) {
        if ( !bIsReloading ) {
            if ( MagAmmoRemaining <= 0) {
                ThirdPersonActor.AmbientSound = none;
                TexPanner(Skins[1]).PanRate = 0; // stop saw cycling
            }
            else {
                if ( Level.TimeSeconds - FireMode[0].NextFireTime > 1.0 && Level.TimeSeconds - FireMode[1].NextFireTime > 1.0 ) {
                    //consume ammo on idle
                    IdleFuelConsumeTime -= dt;
                    if ( IdleFuelConsumeTime <= 0 ) {
                        ConsumeAmmo(0, 1);
                        IdleFuelConsumeTime = default.IdleFuelConsumeTime;
                    }
                }
            }
        }
    }
}

// there is no reload animation for Chainsaw, so play slow put down animation
// taking sounds from flamethrower reload
simulated state Reloading
{
    simulated function BeginState()
    {
        NextReloadSoundIndex = 0;
        TimeToNextReloadSound = ReloadRate * 0.2;
        bBlownUpThisReload = false;
    }

    simulated function WeaponTick(float dt)
    {
        super.WeaponTick(dt);

        if ( NextReloadSoundIndex < ReloadSounds.length ) {
            // if ( NextReloadSoundIndex < ReloadSounds.length - 2 )
                // ThirdPersonActor.AmbientSound = none;
            TimeToNextReloadSound -= dt;
            if ( TimeToNextReloadSound <= 0 ) {
                PlaySound(ReloadSounds[NextReloadSoundIndex].Sound);
                TimeToNextReloadSound += 0.8*ReloadRate * ReloadSounds[NextReloadSoundIndex].Duration/TotalReloadSoundDuration;
                NextReloadSoundIndex++;
            }
        }
    }

    function TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional int HitIndex)
    {
        local ScrnFlameNade nade;
        local int FuelInTank;

        //blow the fuel inside a tank on fire damage received (excluding DoT)
        if ( bBlownUpThisReload || DamageType == none || Damage < 5 || DamageType == class'DamTypeFlamethrower' )
            return;

        if ( Level.TimeSeconds > ReloadTimer + ReloadRate*0.9 ) //almost finished reloading, don't blow up
            return;

        if ( DamageType.default.bFlaming || (class<KFWeaponDamageType>(DamageType) != none && class<KFWeaponDamageType>(DamageType).default.bDealBurningDamage) ) {
            bBlownUpThisReload = true;
            FuelInTank = MagAmmoRemaining + (MagCapacity - MagAmmoRemaining) * (Level.TimeSeconds - ReloadTimer) / ReloadRate;
            if ( FuelInTank > AmmoAmount(0) )
                FuelInTank = AmmoAmount(0);
            if ( FuelInTank < 1 )
                return;
            nade = spawn(class'ScrnBalanceSrv.ScrnFlameNade');
            HideGasCan();
            AttachToBone(nade, 'Chainsaw'); //attempt to move explosion onto chainsaw to make it obvious that the gas can caused the explosion
            nade.SetRelativeLocation(vect(-3, 2, 3)); //move nade to exact gas can location
            nade.SetTimer(0, false); // it will be blown up manualy
            nade.Instigator = Instigator;
            // the more fuel in tank, the higher is explosion
            nade.Damage = FuelInTank;
            AddAmmo(-FuelInTank, 0);
            nade.Explode(Location, vect(0,0,1));
        }
    }
}

simulated function HideGasCan()
{
    if ( Level.NetMode != NM_DedicatedServer )
    {
        FakedGasCan.SetDrawScale(0.01); //hide gas can after reload
    }
}

//destroy gas can on destroy
simulated function Destroyed()
{
    if ( FakedGasCan != none && !FakedGasCan.bDeleteMe )
        FakedGasCan.Destroy();

    super.Destroyed();
}

simulated function PlayIdle()
{
    if ( MagAmmoRemaining > 0 )
        super.PlayIdle();
}

defaultproperties
{
     IdleFuelConsumeTime=5.000000
     EngineStartSoundRef="KF_ChainsawSnd.Chainsaw_FalseStart4"
     EngineStopSoundRef="KF_ChainsawSnd.Chainsaw_Deselect1"
     ReloadSounds(0)=(SoundRef="KF_FlamethrowerSnd.FT_Reload1")
     ReloadSounds(1)=(SoundRef="KF_FlamethrowerSnd.FT_Reload2")
     ReloadSounds(2)=(SoundRef="KF_FlamethrowerSnd.FT_Reload3")
     ReloadSounds(3)=(SoundRef="KF_FlamethrowerSnd.FT_Reload4")
     ReloadSounds(4)=(SoundRef="KF_FlamethrowerSnd.FT_Reload5")
     ReloadSounds(5)=(SoundRef="KF_FlamethrowerSnd.FT_Reload5b")
     ReloadSounds(6)=(SoundRef="KF_FlamethrowerSnd.FT_Reload6")
     ReloadSounds(7)=(SoundRef="KF_ChainsawSnd.Chainsaw_FalseStart1")
     ReloadSounds(8)=(SoundRef="KF_ChainsawSnd.Chainsaw_FalseStart2")
     MagCapacity=105
     ReloadRate=2.666667
     ReloadAnim="PutDown"
     ReloadAnimRate=0.250000
     WeaponReloadAnim="Reload_Flamethrower"
     bAmmoHUDAsBar=True
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnChainsawFire'
     FireModeClass(1)=Class'ScrnBalanceSrv.ScrnChainsawAltFire'
     bMeleeWeapon=False
     bShowChargingBar=True
     Description="This legendary chainsaw is used through the centuries to fight evil forces"
     PickupClass=Class'ScrnBalanceSrv.ScrnChainsawPickup'
     ItemName="Ash's Chainsaw"
     AppID=0
}
