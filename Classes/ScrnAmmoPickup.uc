class ScrnAmmoPickup extends KFAmmoPickup;

function float GetRespawnTime()
{
    return RespawnTime / clamp(Level.Game.NumPlayers, 1, 6);
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
        local Inventory CurInv;
        local bool bPickedUp;
        local int AmmoPickupAmount;
        local Boomstick DBShotty;
        local bool bResuppliedBoomstick;
        local KFAmmunition ammo;
        local KFPlayerReplicationInfo KFPRI;

        if ( Pawn(Other) != none && Pawn(Other).bCanPickupInventory && Pawn(Other).Controller != none &&
             FastTrace(Other.Location, Location) )
        {
            KFPRI = KFPlayerReplicationInfo(Pawn(Other).PlayerReplicationInfo);

            for ( CurInv = Other.Inventory; CurInv != none; CurInv = CurInv.Inventory )
            {
                if( Boomstick(CurInv) != none )
                {
                    DBShotty = Boomstick(CurInv);
                }

                ammo = KFAmmunition(CurInv);
                if ( ammo != none && ammo.bAcceptsAmmoPickups )
                {
                    // changed from 1 to 0  -- PooSH
                    if ( ammo.AmmoPickupAmount > 0 )
                    {
                        if ( ammo.AmmoAmount < ammo.MaxAmmo )
                        {
                            if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
                            {
                                AmmoPickupAmount = float(ammo.AmmoPickupAmount) * KFPRI.ClientVeteranSkill.static.GetAmmoPickupMod(KFPRI, ammo);
                            }
                            else
                            {
                                AmmoPickupAmount = ammo.AmmoPickupAmount;
                            }

                            ammo.AmmoAmount = Min(ammo.MaxAmmo, ammo.AmmoAmount + AmmoPickupAmount);
                            if( DBShotgunAmmo(CurInv) != none )
                            {
                                bResuppliedBoomstick = true;
                            }
                            bPickedUp = true;
                        }
                    }
                    else if ( ammo.AmmoAmount < ammo.MaxAmmo )
                    {
                        bPickedUp = true;

                        if ( FRand() <= (1.0 / Level.Game.GameDifficulty) )
                        {
                            ammo.AmmoAmount++;
                        }
                    }
                }
            }

            if ( bPickedUp )
            {
                // TODO: test if this KF hack is still needed in ScrN
                // if( bResuppliedBoomstick && DBShotty != none )
                // {
                //     DBShotty.AmmoPickedUp();
                // }

                AnnouncePickup(Pawn(Other));
                GotoState('Sleeping', 'Begin');

                if ( KFGameType(Level.Game) != none )
                {
                    KFGameType(Level.Game).AmmoPickedUp(self);
                }
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
