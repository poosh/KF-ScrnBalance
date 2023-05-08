class ScrnAmmoPickup extends KFAmmoPickup;

var name OriginalName;  // original name of KFAmmoPickup placed in the map

function float GetRespawnTime()
{
    local ScrnGameType ScrnGT;
    local float MinRespawnTime;

    MinRespawnTime = RespawnTime;
    ScrnGT = ScrnGameType(Level.Game);
    if ( ScrnGT != none && ScrnGT.AmmoPickups.length <= ScrnGT.DesiredAmmoBoxCount ) {
        // not anough ammo on the map - boost the spawn rate
        MinRespawnTime *= 0.7 * float(ScrnGT.AmmoPickups.length) /  ScrnGT.DesiredAmmoBoxCount;
        MinRespawnTime = fmax(MinRespawnTime, 5.0);
    }
    return fmin(MinRespawnTime, RespawnTime / clamp(Level.Game.NumPlayers, 1, 6));
}

static function bool AddPerkedAmmo(KFAmmunition Ammo, KFPlayerReplicationInfo KFPRI, optional int Amount)
{
    if (Amount == 0) {
        Amount = Ammo.AmmoPickupAmount;
    }
    if (Ammo.AmmoAmount >= Ammo.MaxAmmo) {
        return false;
    }
    if (KFPRI != none && KFPRI.ClientVeteranSkill != none) {
        Amount = float(Amount) * KFPRI.ClientVeteranSkill.static.GetAmmoPickupMod(KFPRI, ammo) + 0.0001;
    }
    if (Amount == 0) {
        return false;
    }
    Ammo.AddAmmo(Amount);
    return true;
}

function bool GiveAmmoTo(Pawn P) {
    local bool bPickedUp;
    local KFPlayerReplicationInfo KFPRI;
    local Inventory CurInv;
    local KFAmmunition ammo, SingleAmmo, FragAmmo, OtherAmmo;
    local int OtherCount;

    KFPRI = KFPlayerReplicationInfo(P.PlayerReplicationInfo);
    for ( CurInv = P.Inventory; CurInv != none; CurInv = CurInv.Inventory ) {
        ammo = KFAmmunition(CurInv);
        if ( ammo != none && ammo.bAcceptsAmmoPickups && ammo.AmmoAmount < ammo.MaxAmmo ) {
            bPickedUp = true;
            if ( ammo.AmmoPickupAmount > 0 ) {
                AddPerkedAmmo(ammo, KFPRI);
                if (ammo.IsA('FragAmmo')) {
                    FragAmmo = ammo;
                }
                else if (ammo.IsA('SingleAmmo')) {
                    SingleAmmo = ammo;
                }
                else if (++OtherCount == 1) {
                    OtherAmmo = ammo;
                }
            }
            else if ( FRand() <= (1.0 / Level.Game.GameDifficulty) ) {
                ammo.AddAmmo(1);
            }
        }
    }

    if (!bPickedUp) {
        return false;
    }

    if (OtherCount <= 1) {
        // If the player has only one extra gun (except 9mm or nades) - give twice amount to it.
        // If player has no other guns but 9mm+nades (or all are full), give two nades.
        // If nades are also full, give exra 60 9mm rounds.
        (OtherAmmo != none && AddPerkedAmmo(OtherAmmo, KFPRI))
            || (FragAmmo != none && AddPerkedAmmo(FragAmmo, KFPRI))
            || (SingleAmmo != none && AddPerkedAmmo(SingleAmmo, KFPRI, 60));
    }
    return true;
}

state Pickup
{
    function BeginState()
    {
        super.BeginState();
        if ( ScrnGameType(Level.Game) != none )
            ScrnGameType(Level.Game).CurrentAmmoBoxCount++;
    }

    function EndState()
    {
        super.EndState();
        if ( ScrnGameType(Level.Game) != none )
            ScrnGameType(Level.Game).CurrentAmmoBoxCount--;
    }

    // When touched by an actor.
    function Touch(Actor Other)
    {
        local Pawn P;

        P = Pawn(Other);
        if ( P == none || P.Controller == none || !P.bCanPickupInventory || !FastTrace(P.Location, Location) )
            return;

        if (GiveAmmoTo(P)) {
            AnnouncePickup(P);
            GotoState('Sleeping', 'Begin');
            if ( KFGameType(Level.Game) != none ) {
                KFGameType(Level.Game).AmmoPickedUp(self);
            }
        }
    }
}

auto state Sleeping
{
    ignores Touch;

    function bool ReadyToPickup(float MaxWait)
    {
        return (bPredictRespawns && LatentFloat < MaxWait);
    }

    function StartSleeping() {}

    function BeginState()
    {
        local int i;

        NetUpdateTime = Level.TimeSeconds - 1;
        bHidden = true;
        bSleeping = true;
        SetCollision(false, false);

        for ( i = 0; i < 4; i++ )
        {
            TeamOwner[i] = None;
        }
    }

    function EndState()
    {
        NetUpdateTime = Level.TimeSeconds - 1;
        bHidden = false;
        bSleeping = false;
        SetCollision(default.bCollideActors, default.bBlockActors);
    }

Begin:
    bSleeping = true;
    Sleep(1000000.0); // Sleep for 11.5 days(never wake up)

DelayedSpawn:
    bSleeping = false;
    Sleep(GetRespawnTime()); // Delay before respawning
    goto('Respawn');

TryToRespawnAgain:
    Sleep(1.0);

Respawn:
    bShowPickup = true;
    // ignore player visibility here  -- PooSH
    // for ( OtherPlayer = Level.ControllerList; OtherPlayer != none; OtherPlayer=OtherPlayer.NextController )
    // {
        // if ( PlayerController(OtherPlayer) != none && OtherPlayer.Pawn != none )
        // {
            // if ( FastTrace(self.Location, OtherPlayer.Pawn.Location) )
            // {
                // bShowPickup = false;
                // break;
            // }
        // }
    // }

    if ( bShowPickup )
    {
        RespawnEffect();
        Sleep(RespawnEffectTime);

        if ( PickUpBase != none )
        {
            PickUpBase.TurnOn();
        }

        GotoState('Pickup');
    }
    else
        Goto('TryToRespawnAgain');
}

defaultproperties
{
    RespawnTime=30
    RespawnEffectTime=0.5
    RotationRate=(Yaw=0)
}
