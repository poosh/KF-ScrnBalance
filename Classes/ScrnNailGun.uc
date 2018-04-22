class ScrnNailGun extends NailGun;

var transient ScrnAchievements.AchStrInfo ach_Nail100m, ach_NailToWall, ach_PushShiver, ach_ProNailer; //related achievements


replication
{
    reliable if(Role < ROLE_Authority)
        ServerChangeFireModeEx;
}

simulated function PostBeginPlay()
{
    local SRStatsBase Stats;
    
    super.PostBeginPlay();
    
    // cache achievements here, so each projectile won't be supposed to search to them in the list
    if ( Role == ROLE_Authority && Instigator != none && ScrnPlayerController(Instigator.Controller) != none ) {
        Stats = SRStatsBase(ScrnPlayerController(Instigator.Controller).SteamStatsAndAchievements);
        if ( Stats != none ) {
            ach_Nail100m = class'ScrnBalanceSrv.ScrnAchievements'.static.GetAchievementByID(Stats.Rep, 'NailPush100m', true);
            ach_NailToWall = class'ScrnBalanceSrv.ScrnAchievements'.static.GetAchievementByID(Stats.Rep, 'Nail250Zeds', true);
            ach_PushShiver = class'ScrnBalanceSrv.ScrnAchievements'.static.GetAchievementByID(Stats.Rep, 'NailPushShiver', true);
            ach_ProNailer = class'ScrnBalanceSrv.ScrnAchievements'.static.GetAchievementByID(Stats.Rep, 'ProNailer', true);
        }
    }
}


// Use alt fire to switch fire modes
simulated function AltFire(float F)
{
    if(ReadyToFire(0))
    {
        DoToggle();
    }
}

// Toggle semi/auto fire
simulated function DoToggle ()
{
    local PlayerController Player;
    
    Player = Level.GetLocalPlayerController();
    if ( Player != none ) {
        FireMode[0].AmmoPerFire = FireMode[0].default.AmmoPerFire - FireMode[0].AmmoPerFire + 1;
        if ( FireMode[0].AmmoPerFire == 1 )
            Player.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnFireModeSwitchMessage',4);
        else
            Player.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnFireModeSwitchMessage',5);

        ServerChangeFireModeEx(FireMode[0].AmmoPerFire);
    }
}

// Set the new fire mode on the server
function ServerChangeFireModeEx(byte NewAmmoPerFire)
{
    FireMode[0].AmmoPerFire = NewAmmoPerFire;
}

exec function SwitchModes()
{
    DoToggle();
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
        }

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

defaultproperties
{
     MagCapacity=42
     Weight=6.000000
     bTorchEnabled=False
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnNailGunFire'
     FireModeClass(1)=Class'KFMod.NoFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnNailGunPickup'
     ItemName="Nailgun SE"
}
