class ScrnBoomStick extends BoomStick;

var() float SingleShellReloadRatio; //comparing to full reload rate. 2.0 = twice faster reload 


replication
{
    reliable if(Role == ROLE_Authority)
		ClientPlayReloadAnim, ClientSetWaitingToLoadShotty;
}

simulated function WeaponTick(float dt)
{
    super(KFWeaponShotgun).WeaponTick(dt);

    if( Role == ROLE_Authority ) 
    {
        if( bWaitingToLoadShotty )
        {
            CurrentReloadCountDown -= dt;

            if( CurrentReloadCountDown <= 0 )
            {
                if( AmmoAmount(0) > 0 )
                {
                    MagAmmoRemaining = Min(AmmoAmount(0), 2);
                    SingleShotCount = MagAmmoRemaining;
                    ClientSetSingleShotCount(SingleShotCount);
                    bWaitingToLoadShotty = false;
    				ClientSetWaitingToLoadShotty(bWaitingToLoadShotty); // replicate it to clients too
                    NetUpdateTime = Level.TimeSeconds - 1;
                }
            }
        }

        if( SingleShotReplicateCountdown > 0 )
        {
            SingleShotReplicateCountdown -= dt;

            if( SingleShotReplicateCountdown <= 0 )
            {
                ClientSetSingleShotCount(SingleShotCount);
            }
        }
    }
}

function SetPendingReload()
{
    if ( !bWaitingToLoadShotty && AmmoAmount(0) > 0 ) {
        bWaitingToLoadShotty = true;
        ClientSetWaitingToLoadShotty(bWaitingToLoadShotty); // replicate it to clients too
        CurrentReloadCountDown = ReloadCountDown;
    }
}


simulated function bool ConsumeAmmo( int Mode, float Load, optional bool bAmountNeededIsMax )
{
	local bool result;
	
	result = super.ConsumeAmmo(0, Load, bAmountNeededIsMax);

	if ( AmmoAmount(0) == 0 && MagAmmoRemaining == 0 ) {
		SingleShotCount = 0;
        if ( bWaitingToLoadShotty ) {
            bWaitingToLoadShotty = false;
    		ClientSetWaitingToLoadShotty(bWaitingToLoadShotty); // replicate it to clients too
        }
	}

	return result;
}

simulated function ClientSetWaitingToLoadShotty(bool bNewWaitingToLoadShotty)
{
    bWaitingToLoadShotty = bNewWaitingToLoadShotty;
}


simulated function ClientPlayReloadAnim(float AnimRatio)
{
	if (!Instigator.IsLocallyControlled())
		return;

	if (AnimRatio ~= 0) 
        AnimRatio = 1.0;
        
    bWaitingToLoadShotty = true;    

	PlayAnim(BoomStickAltFire(FireMode[0]).FireLastAnim, 
		FireMode[0].FireAnimRate * AnimRatio, 
		FireMode[0].TweenTime, 0);
	SetAnimFrame(4, 0 , 1); //skip fire animation and jump to reload
}



//allow reload single shell
function bool AllowReload()
{
    if ( bWaitingToLoadShotty )
        return false;
        
	return super(KFWeaponShotgun).AllowReload();
}

exec function ReloadMeNow()
{
	if(!AllowReload())
		return;
		
	if ( SingleShotCount < MagCapacity && !bWaitingToLoadShotty && AmmoAmount(0) > 0 ) {
        bWaitingToLoadShotty = true;
        if ( SingleShotCount > 0 ) {
            CurrentReloadCountDown = ReloadCountDown / SingleShellReloadRatio;
            ClientPlayReloadAnim(SingleShellReloadRatio);
        }
        else {
            CurrentReloadCountDown = ReloadCountDown;
            ClientPlayReloadAnim(1.0);
        }
	} 
}


simulated function bool PutDown()
{
    if ( bWaitingToLoadShotty && Instigator != none && Instigator.PendingWeapon != none && AmmoAmount(0) > 1 ) {
        Instigator.PendingWeapon = none;
        return false;
    }

    return super.PutDown();
}


// When TWI starts thinking about modders? 
// Copy-pasted entire function, applied BoomstickPickup class comparement for 
// subclasses too 
// (c) PooSH, 2012
function GiveAmmo(int m, WeaponPickup WP, bool bJustSpawned)
{
	local bool bJustSpawnedAmmo;
	local int addAmount, InitialAmount;

	UpdateMagCapacity(Instigator.PlayerReplicationInfo);

	if ( FireMode[m] != None && FireMode[m].AmmoClass != None )
	{
		Ammo[m] = Ammunition(Instigator.FindInventoryType(FireMode[m].AmmoClass));
		bJustSpawnedAmmo = false;

		if ( bNoAmmoInstances )
		{
			if ( (FireMode[m].AmmoClass == None) || ((m != 0) && (FireMode[m].AmmoClass == FireMode[0].AmmoClass)) )
				return;

			InitialAmount = FireMode[m].AmmoClass.Default.InitialAmount;

			if(WP!=none && WP.bThrown==true)
				InitialAmount = WP.AmmoAmount[m];
			else
			{
				// Other change - if not thrown, give the gun a full clip
				//MagAmmoRemaining = MagCapacity;
			}

			if ( Ammo[m] != None )
			{
				addamount = InitialAmount + Ammo[m].AmmoAmount;
				Ammo[m].Destroy();
			}
			else
				addAmount = InitialAmount;

			AddAmmo(addAmount,m);
		}
		else
		{
			if ( (Ammo[m] == None) && (FireMode[m].AmmoClass != None) )
			{
				Ammo[m] = Spawn(FireMode[m].AmmoClass, Instigator);
				Instigator.AddInventory(Ammo[m]);
				bJustSpawnedAmmo = true;
			}
			else if ( (m == 0) || (FireMode[m].AmmoClass != FireMode[0].AmmoClass) )
				bJustSpawnedAmmo = ( bJustSpawned || ((WP != None) && !WP.bWeaponStay) );

	  	      // and here is the modification for instanced ammo actors

			if(WP!=none && WP.bThrown==true)
			{
				addAmount = WP.AmmoAmount[m];
			}
			else if ( bJustSpawnedAmmo )
			{
				if (default.MagCapacity == 0)
					addAmount = 0;  // prevent division by zero.
				else
					addAmount = Ammo[m].InitialAmount * (float(MagCapacity) / float(default.MagCapacity));
			}

			//removed: WP.Class == class'BoomstickPickup' -- (c) PooSH
			if ( WP != none && m > 0 )
			{
				return;
			}

			Ammo[m].AddAmmo(addAmount);
			Ammo[m].GotoState('');
		}
	}
    
    // Update the singleshotcount if we pick this weapon up
    if( WP != none )
    {
        if( m == 0 && AmmoAmount(0) < 2 )
        {
            SingleShotCount = AmmoAmount(0);
            MagAmmoRemaining = SingleShotCount;
            ClientSetSingleShotCount(SingleShotCount);
            NetUpdateTime = Level.TimeSeconds - 1;
        }
        else if( BoomStickPickup(WP) != none )
        {
            SingleShotCount = BoomStickPickup(WP).SingleShotCount;
            MagAmmoRemaining = SingleShotCount;
            ClientSetSingleShotCount(SingleShotCount);
            NetUpdateTime = Level.TimeSeconds - 1;
        }
    }    
}

simulated function ClientSetSingleShotCount(float NewSingleShotCount)
{
    SingleShotCount = NewSingleShotCount;
    MagAmmoRemaining = SingleShotCount;
}


defaultproperties
{
	ReloadRate=2.750000 // set here to properly calc stats
	SingleShellReloadRatio=1.750000
	FireModeClass(0)=Class'ScrnBalanceSrv.ScrnBoomStickAltFire'
	FireModeClass(1)=Class'ScrnBalanceSrv.ScrnBoomStickFire'
	Description="This is my BOOMstick (c) Ash, Evil Dead - Army of Darkness, 1992.|Has been used through the centuries to hunt down Demons, Aliens and Zombies. Now it's time for the ZEDs.|Can shoot from one or two barrels simultaneousely. Single shell reload is avaliable."
	PickupClass=Class'ScrnBalanceSrv.ScrnBoomStickPickup'
	ItemName="Boomstick"
}
