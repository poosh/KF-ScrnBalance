class ScrnSyringe extends Syringe;

var bool bSoloHealBoost;
var int SoloHealBoostAmount;
var int AmmoRegenCharge;

simulated function PostBeginPlay()
{
    super(KFMeleeGun).PostBeginPlay();

    // allow dropping syringe in Story Mode
    bKFNeverThrow = KF_StoryGRI(Level.GRI) == none;
    bCanThrow = !bKFNeverThrow; // prevent dropping syringe on dying
    if (bCanThrow) {
        AmmoCharge[0] = 0; // prevent dropping exploit
    }
    UpdateCharge();
}

simulated function ClientSuccessfulHeal(String HealedName)
{
    SyringeFire(FireMode[0]).SuccessfulHeal();
    // Replaced by ScrnHealMessage
    // if( PlayerController(Instigator.Controller) != none ) {
    //     PlayerController(Instigator.controller).ClientMessage(SuccessfulHealMessage$HealedName, 'CriticalEvent');
    // }
}

function UpdateCharge()
{
    local KFPlayerReplicationInfo KFPRI;
    local ScrnGameType ScrnGT;

    AmmoRegenCharge = default.AmmoRegenCharge;

    ScrnGT = ScrnGameType(Level.Game);
    if (Instigator != none)
        KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
    if (KFPRI != none)
        AmmoRegenCharge *= KFPRI.ClientVeteranSkill.Static.GetSyringeChargeRate(KFPRI);

    bSoloHealBoost = Level.Game.NumPlayers == 1 || (KFPRI != none && KFPRI.Team != none
            && (KFPRI.Team.Size == 1 || (ScrnGT != none && ScrnGT.AliveTeamPlayerCount[KFPRI.Team.TeamIndex] == 1)));
}

simulated function Tick(float dt)
{
    if (AmmoCharge[0] < MaxAmmoCount && RegenTimer < Level.TimeSeconds) {
        RegenTimer = Level.TimeSeconds + AmmoRegenRate;
        if (Level.NetMode != NM_Client) {
            AmmoCharge[0] += AmmoRegenCharge;
            if (AmmoCharge[0] > MaxAmmoCount)
                AmmoCharge[0] = MaxAmmoCount;
        }

        if (Level.NetMode != NM_DedicatedServer && Instigator != none && PlayerController(Instigator.Controller) != none
                && Viewport(PlayerController(Instigator.Controller).Player) != none
                && ScrnHUD(PlayerController(Instigator.Controller).myHUD) != none) {
            ScrnHUD(PlayerController(Instigator.Controller).myHUD).ShowQuickSyringe();
        }
    }
}


defaultproperties
{
    FireModeClass(0)=class'ScrnSyringeFire'
    FireModeClass(1)=class'ScrnSyringeAltFire'
    PickupClass=class'ScrnSyringePickup'
    ItemName="Med-Syringe SE"
    TraderInfoTexture=Texture'KillingFloorHUD.WeaponSelect.Syringe'
    HealBoostAmount=20
    SoloHealBoostAmount=50
    AmmoRegenCharge=10

    PutDownAnimRate=2.2222
    SelectAnimRate=2.4444
    BringUpTime=0.15
    PutDownTime=0.15
}
