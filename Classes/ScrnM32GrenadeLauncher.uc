/** A M32 with fancy code copied from Poosh's Colt
 * @author Scuddles
 * @see https://steamcommunity.com/groups/ScrNBalance/discussions/6/1696049513783762669/
 */
class ScrnM32GrenadeLauncher extends M32GrenadeLauncher;

var float ReloadMulti;
var float BulletLoadRate;   // how long does it takes to load a single bullet
var transient bool bInterruptedReload;
var transient float NextBulletLoadTime;

// Implemented M32-specific reloading
// Reload State 1 (interruptable): opening cylinders and loading 40mm shells, each shell takes BulletLoadRate seconds. If all 6 shells are loaded in a cycle, don't skip to closing animation.
// Reload State 2: if 5 or less shells are loaded, skip to closing cylinder (0.4s).

simulated function WeaponTick(float dt)
{
    local float LastSeenSeconds;

    if( bHasAimingMode ) {
        if( bForceLeaveIronsights ) {
            if( bAimingRifle ) {
                ZoomOut(true);

                if( Role < ROLE_Authority)
                    ServerZoomOut(false);
            }
            bForceLeaveIronsights = false;
        }

        if( ForceZoomOutTime > 0 ) {
            if( bAimingRifle ) {
                if( Level.TimeSeconds - ForceZoomOutTime > 0 ) {
                    ForceZoomOutTime = 0;
                    ZoomOut(true);
                    if( Role < ROLE_Authority)
                        ServerZoomOut(false);
                }
            }
            else {
                ForceZoomOutTime = 0;
            }
        }
    }

    if ( Role < ROLE_Authority )
    return;

    if ( bIsReloading ) {
        if( Level.TimeSeconds >= ReloadTimer ) {
            ActuallyFinishReloading();
        }
        else if ( !bInterruptedReload && Level.TimeSeconds >= NextBulletLoadTime ) {
            if ( MagAmmoRemaining >= MagCapacity || MagAmmoRemaining >= AmmoAmount(0) ) {
                NextBulletLoadTime += 1000; // don't load bullets anymore
                InterruptReload(); //Interrupt reload because finished loading in under 6 shells
            }
            else {
                MagAmmoRemaining++;
                NumLoadedThisReload++;
                if (NumLoadedThisReload == 6) {
                    bInterruptedReload = True; //prevents interrupt if loaded 6 rounds, since it's actually built into the animation
                    ActuallyFinishReloading(); //force reload to finish
                }

                //interrupt if full
                if ( MagAmmoRemaining > 5 || MagAmmoRemaining >= AmmoAmount(0) ) {
                    if ( NumLoadedThisReload != 6)
                    {
                        InterruptReload();
                    }
                }
                NextBulletLoadTime += BulletLoadRate;
                Instigator.SetAnimAction(WeaponReloadAnim); //Loop thirdperson reload animation
            }
        }
    }
    else if( !Instigator.IsHumanControlled() ) { // bot
        LastSeenSeconds = Level.TimeSeconds - Instigator.Controller.LastSeenTime;
        if(MagAmmoRemaining == 0 || ((LastSeenSeconds >= 5 || LastSeenSeconds > MagAmmoRemaining) && MagAmmoRemaining < MagCapacity))
        ReloadMeNow();
    }

    // Turn it off on death  / battery expenditure
    if (FlashLight != none)
    {
        // Keep the 1Pweapon client beam up to date.
        AdjustLightGraphic();
        if (FlashLight.bHasLight)
        {
            if (Instigator.Health <= 0 || KFHumanPawn(Instigator).TorchBatteryLife <= 0 || Instigator.PendingWeapon != none )
            {
                //Log("Killing Light...you're out of batteries, or switched / dropped weapons");
                KFHumanPawn(Instigator).bTorchOn = false;
                ServerSpawnLight();
            }
        }
    }
}


simulated function bool AllowReload()
{
    if ( bIsReloading || MagAmmoRemaining >= AmmoAmount(0) )
        return false;

    UpdateMagCapacity(Instigator.PlayerReplicationInfo);
    if ( MagAmmoRemaining >= MagCapacity )
        return false;

    if( KFInvasionBot(Instigator.Controller) != none || KFFriendlyAI(Instigator.Controller) != none )
        return true;

    return !FireMode[0].IsFiring() && !FireMode[1].IsFiring()
            && Level.TimeSeconds > (FireMode[0].NextFireTime - 0.1);
}


// Since vanilla reloading replication is totally fucked, I moved base code into separate,
// replication-free function, which is executed on both server and client side
// -- PooSH
simulated function DoReload()
{
    if ( bHasAimingMode && bAimingRifle ) {
        FireMode[1].bIsFiring = False;
        ZoomOut(false);
        // ZoomOut() just a moment ago was executed on server side - why to force it again?  -- PooSH
        // if( Role < ROLE_Authority)
        // ServerZoomOut(false);
    }

    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
        ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo), self);
    else
        ReloadMulti = 1.0;

    bIsReloading = true;
    bInterruptedReload = false;

    //BulletUnloadRate = default.BulletUnloadRate / ReloadMulti;
    BulletLoadRate = default.BulletLoadRate / ReloadMulti;
    //NextBulletLoadTime = Level.TimeSeconds + BulletUnloadRate + BulletLoadRate; //BulletUnloadRate disabled
    NextBulletLoadTime = Level.TimeSeconds + BulletLoadRate;
    // more bullets left = less time to reload
    ReloadRate = default.ReloadRate / ReloadMulti;
    ReloadRate -= MagAmmoRemaining * BulletLoadRate;
    ReloadTimer = Level.TimeSeconds + ReloadRate;
    if ( MagAmmoRemaining != MagCapacity && AmmoAmount(0) > MagAmmoRemaining)
        Instigator.SetAnimAction(WeaponReloadAnim); //loop animation unless full or out of ammo
}
// This function is triggered by client, replicated to server and NOT EXECUTED on client,
// even if marked as simulated

exec function ReloadMeNow()
{
    local KFPlayerController PC;

    if ( !AllowReload() )
        return;

    DoReload();
    ClientReload();

    NumLoadedThisReload = 0;

    PC = KFPlayerController(Instigator.Controller);
    if ( PC != none && Level.Game.NumPlayers > 1 && KFGameType(Level.Game).bWaveInProgress
            && Level.TimeSeconds - PC.LastReloadMessageTime > PC.ReloadMessageDelay )
    {
        KFPlayerController(Instigator.Controller).Speech('AUTO', 2, "");
        KFPlayerController(Instigator.Controller).LastReloadMessageTime = Level.TimeSeconds;
    }
}

function ServerRequestAutoReload()
{
    ReloadMeNow();
}

// This function now is triggered by ReloadMeNow() and executed on local side only
simulated function ClientReload()
{
    DoReload();
    PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
}

// This function now is triggered by ReloadMeNow() and executed on local side only



function AddReloadedAmmo() {} // magazine is filled in WeaponTick now


simulated function bool StartFire(int Mode)
{
    if ( MagAmmoRemaining <= 0 )
        return false;
    if ( bIsReloading ) {
        InterruptReload();
        return false;
    }
    return super(Weapon).StartFire(Mode);
}

simulated function AltFire(float F)
{
    InterruptReload();
}

// another fucked up replication...
// By the looks if it, InterruptReload() is called only on client, which triggers ServerInterruptReload().
// Anyway, why server would want to interrupt reload by its own?..
simulated function bool InterruptReload()
{
    if( bIsReloading && !bInterruptedReload && (ReloadTimer - Level.TimeSeconds)*ReloadMulti > 0.4 )
    {
        // that's very lame how to do stuff like that - don't repeat it at home ;)
        // in theory client should send server a request to interrupt the reload,
        // and the server send back accept to client.
        // But in such case we have a double chance of screwing the shit up, so let's just
        // do it lazy way.
        ServerInterruptReload();
        ClientInterruptReload();
        return true;
    }

    return false;
}

function ServerInterruptReload()
{
    if ( Role == ROLE_Authority && bInterruptedReload == false ) {
        ReloadTimer = Level.TimeSeconds + 0.4/ReloadMulti;
        bInterruptedReload = true;
        //PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1); //added this
        SetAnimFrame(279, 0 , 1);  // go to closing drum stage
    }
}

simulated function ClientInterruptReload()
{
    if ( Role < ROLE_Authority && bInterruptedReload == false) {
        bInterruptedReload = true;
        PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1); //added this
        SetAnimFrame(279, 0 , 1);  // go to closing drum stage
        //ShowAllBullets();
    }
}

simulated exec function ToggleIronSights()
{
    if( bHasAimingMode ) {
        if( bAimingRifle )
            PerformZoom(false);
        else
            IronSightZoomIn();
    }
}

simulated exec function IronSightZoomIn()
{
    if( bHasAimingMode ) {
        if( Owner != none && Owner.Physics == PHYS_Falling
                && Owner.PhysicsVolume.Gravity.Z <= class'PhysicsVolume'.default.Gravity.Z )
        return;

        if( bIsReloading ) {
            InterruptReload(); // finish reloading while zooming in  -- PooSH
        }
        PerformZoom(True);
    }
}

simulated function bool PutDown()
{
    local int Mode;

    // continue here, because there is nothing to stop us from interrupting the reload  -- PooSH
    if ( bIsReloading )
        InterruptReload();

    if( bAimingRifle )
        ZoomOut(False);

    // From Weapon.uc
    if (ClientState == WS_BringUp || ClientState == WS_ReadyToFire)
    {
        if ( (Instigator.PendingWeapon != None) && !Instigator.PendingWeapon.bForceSwitch )
        {
            for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
            {
                // if _RO_
                if( FireMode[Mode] == none )
                    continue;
                // End _RO_

                if ( FireMode[Mode].bFireOnRelease && FireMode[Mode].bIsFiring )
                    return false;
                if ( FireMode[Mode].NextFireTime > Level.TimeSeconds + FireMode[Mode].FireRate*(1.f - MinReloadPct))
                    DownDelay = FMax(DownDelay, FireMode[Mode].NextFireTime - Level.TimeSeconds - FireMode[Mode].FireRate*(1.f - MinReloadPct));
            }
        }

        if (Instigator.IsLocallyControlled())
        {
            for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
            {
                // if _RO_
                if( FireMode[Mode] == none )
                    continue;
                // End _RO_

                if ( FireMode[Mode].bIsFiring )
                    ClientStopFire(Mode);
            }

            if (  DownDelay <= 0  || KFPawn(Instigator).bIsQuickHealing > 0)
            {
                if ( ClientState == WS_BringUp || KFPawn(Instigator).bIsQuickHealing > 0 )
                    TweenAnim(SelectAnim,PutDownTime);
                else if ( HasAnim(PutDownAnim) )
                {
                    if( ClientGrenadeState == GN_TempDown || KFPawn(Instigator).bIsQuickHealing > 0)
                        PlayAnim(PutDownAnim, PutDownAnimRate * (PutDownTime/QuickPutDownTime), 0.0);
                    else
                        PlayAnim(PutDownAnim, PutDownAnimRate, 0.0);

                }
            }
        }
        ClientState = WS_PutDown;
        if ( Level.GRI.bFastWeaponSwitching )
            DownDelay = 0;
        if ( DownDelay > 0 )
        {
            SetTimer(DownDelay, false);
        }
        else
        {
            if( ClientGrenadeState == GN_TempDown )
            {
                SetTimer(QuickPutDownTime, false);
            }
            else
            {
                SetTimer(PutDownTime, false);
            }
        }
    }
    for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
    {
        // if _RO_
        if( FireMode[Mode] == none )
            continue;
        // End _RO_

        FireMode[Mode].bServerDelayStartFire = false;
        FireMode[Mode].bServerDelayStopFire = false;
    }
    Instigator.AmbientSound = None;
    OldWeapon = None;
    return true; // return false if preventing weapon switch
}

defaultproperties
{
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnM32Fire'
     ReloadRate=9.604 //added to support new reload
     BulletLoadRate=1.40 // increased base reload speed from original value 1.634
     ReloadAnimRate=1.17857 //speed up animation to match

     PickupClass=Class'ScrnBalanceSrv.ScrnM32Pickup'
     ItemName="M32 Grenade Launcher SE"
}
