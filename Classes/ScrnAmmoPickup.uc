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
        local Inventory CurInv;
        local bool bPickedUp;
        local int AmmoPickupAmount;
        local KFAmmunition ammo;
        local KFPlayerReplicationInfo KFPRI;
        local class<KFVeterancyTypes> Perk;

        P = Pawn(Other);
        if ( P == none || P.Controller == none || !P.bCanPickupInventory || !FastTrace(P.Location, Location) )
            return;
        KFPRI = KFPlayerReplicationInfo(P.PlayerReplicationInfo);
        if (KFPRI != none )
            Perk = KFPRI.ClientVeteranSkill;

        for ( CurInv = Other.Inventory; CurInv != none; CurInv = CurInv.Inventory ) {
            ammo = KFAmmunition(CurInv);
            if ( ammo != none && ammo.bAcceptsAmmoPickups ) {
                // changed from 1 to 0  -- PooSH
                if ( ammo.AmmoPickupAmount > 0 ) {
                    if ( ammo.AmmoAmount < ammo.MaxAmmo ) {
                        if ( Perk != none ) {
                            AmmoPickupAmount = float(ammo.AmmoPickupAmount)
                                    * Perk.static.GetAmmoPickupMod(KFPRI, ammo);
                        }
                        else {
                            AmmoPickupAmount = ammo.AmmoPickupAmount;
                        }
                        ammo.AmmoAmount = Min(ammo.MaxAmmo, ammo.AmmoAmount + AmmoPickupAmount);
                        bPickedUp = true;
                    }
                }
                else if ( ammo.AmmoAmount < ammo.MaxAmmo ) {
                    bPickedUp = true;
                    if ( FRand() <= (1.0 / Level.Game.GameDifficulty) )
                        ammo.AmmoAmount++;
                }
            }
        }

        if ( bPickedUp ) {
            AnnouncePickup(Pawn(Other));
            GotoState('Sleeping', 'Begin');

            if ( KFGameType(Level.Game) != none )
                KFGameType(Level.Game).AmmoPickedUp(self);
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
