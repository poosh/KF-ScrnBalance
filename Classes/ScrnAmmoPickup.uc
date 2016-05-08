class ScrnAmmoPickup extends KFAmmoPickup;

state Pickup
{
	// When touched by an actor.
	function Touch(Actor Other)
	{
		local Inventory CurInv;
		local bool bPickedUp;
		local int AmmoPickupAmount;
		local Boomstick DBShotty;
		local bool bResuppliedBoomstick;

		if ( Pawn(Other) != none && Pawn(Other).bCanPickupInventory && Pawn(Other).Controller != none &&
			 FastTrace(Other.Location, Location) )
		{
			for ( CurInv = Other.Inventory; CurInv != none; CurInv = CurInv.Inventory )
			{
				if( Boomstick(CurInv) != none )
				{
				    DBShotty = Boomstick(CurInv);
				}

                if ( KFAmmunition(CurInv) != none && KFAmmunition(CurInv).bAcceptsAmmoPickups )
				{
                    // changed from 1 to 0  -- PooSH
					if ( KFAmmunition(CurInv).AmmoPickupAmount > 0 )
					{
						if ( KFAmmunition(CurInv).AmmoAmount < KFAmmunition(CurInv).MaxAmmo )
						{
							if ( KFPlayerReplicationInfo(Pawn(Other).PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Pawn(Other).PlayerReplicationInfo).ClientVeteranSkill != none )
							{
								AmmoPickupAmount = float(KFAmmunition(CurInv).AmmoPickupAmount) * KFPlayerReplicationInfo(Pawn(Other).PlayerReplicationInfo).ClientVeteranSkill.static.GetAmmoPickupMod(KFPlayerReplicationInfo(Pawn(Other).PlayerReplicationInfo), KFAmmunition(CurInv));
							}
							else
							{
								AmmoPickupAmount = KFAmmunition(CurInv).AmmoPickupAmount;
							}

							KFAmmunition(CurInv).AmmoAmount = Min(KFAmmunition(CurInv).MaxAmmo, KFAmmunition(CurInv).AmmoAmount + AmmoPickupAmount);
							if( DBShotgunAmmo(CurInv) != none )
							{
                                bResuppliedBoomstick = true;
							}
							bPickedUp = true;
						}
					}
					else if ( KFAmmunition(CurInv).AmmoAmount < KFAmmunition(CurInv).MaxAmmo )
					{
						bPickedUp = true;

						if ( FRand() <= (1.0 / Level.Game.GameDifficulty) )
						{
							KFAmmunition(CurInv).AmmoAmount++;
						}
					}
				}
			}

			if ( bPickedUp )
			{
                if( bResuppliedBoomstick && DBShotty != none )
                {
                    DBShotty.AmmoPickedUp();
                }

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
