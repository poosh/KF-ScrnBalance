class ScrnBenelliShotgun extends BenelliShotgun;

var bool bChamberThisReload; //if full reload is uninterrupted, play chambering animation
var vector ReloadViewOffset, ReloadViewOffsetInterp, ReloadViewOffsetValue, TargetViewOffset; //offset used during reloads
var float ReloadTweenStartTime, ReloadTweenEndTime, ReloadTweenRate;

//tweens to ReloadViewOffset to get the shotgun to block the center of the screen less
simulated function ClientReload()
{
    bChamberThisReload = ( MagAmmoRemaining == 0 && (AmmoAmount(0) - MagAmmoRemaining > MagCapacity) ); //for chambering animation
    Super.ClientReload();
    TargetViewOffset = ReloadViewOffsetValue;
    ReloadTweenStartTime = Level.TimeSeconds;
    ReloadTweenEndTime = Level.TimeSeconds + ReloadTweenRate;
    ReloadViewOffsetInterp = ReloadViewOffset; //store values for interpolation
}

//tweens to reload offset when reloading and tweens back to 0,0,0 when reload ends or is interrupted by zoom or fire
simulated function TweenToReloadOffset()
{
    local float Alpha; //for lerp
    if (ReloadTweenEndTime == 0)
    {
        return; //do nothing
    }   
    if (Level.TimeSeconds > ReloadTweenEndTime)
    {
        ReloadViewOffset = TargetViewOffset; //set target
        ReloadTweenEndTime = 0; //set this to 0
    }
    Alpha = (Level.TimeSeconds-ReloadTweenStartTime)/ReloadTweenRate; //returns float between 0 and 1
    if ( Level.NetMode != NM_DedicatedServer )
    {
        //lerp from current interp value to target
        ReloadViewOffset.X = Lerp(Alpha, ReloadViewOffsetInterp.X, TargetViewOffset.X);
        ReloadViewOffset.Y = Lerp(Alpha, ReloadViewOffsetInterp.Y, TargetViewOffset.Y);
        ReloadViewOffset.Z = Lerp(Alpha, ReloadViewOffsetInterp.Z, TargetViewOffset.Z);
    }
}

//added function to calculate and apply reload view offset 
simulated function WeaponTick(float dt)
{
    Super.WeaponTick(dt);
    TweenToReloadOffset();
}

// Server forces the reload to be cancelled
simulated function bool InterruptReload()
{
    //solo testing kek
    if ( Level.NetMode != NM_DedicatedServer )
	{
        TargetViewOffset = Vect(0,0,0);
        ReloadTweenStartTime = Level.TimeSeconds;
        ReloadTweenEndTime = Level.TimeSeconds + ReloadTweenRate;
        ReloadViewOffsetInterp = ReloadViewOffset; //store values for interpolation
	}
    return Super.InterruptReload();
}

//copypaste to add additional offset
simulated event RenderOverlays( Canvas Canvas )
{
    local int m;
    local vector DrawOffset;
    if (Instigator == None)
        return;

    if ( Instigator.Controller != None )
        Hand = Instigator.Controller.Handedness;

    if ((Hand < -1.0) || (Hand > 1.0))
        return;

    // draw muzzleflashes/smoke for all fire modes so idle state won't
    // cause emitters to just disappear
    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m] != None)
        {
            FireMode[m].DrawMuzzleFlash(Canvas);
        }
    }
    DrawOffset = (90/DisplayFOV * ReloadViewOffset) >> Instigator.GetViewRotation(); //calculate additional offset
    SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) + DrawOffset); //add additional offset
    SetRotation( Instigator.GetViewRotation() + ZoomRotInterp);

    //PreDrawFPWeapon();    // Laurent -- Hook to override things before render (like rotation if using a staticmesh)

    bDrawingFirstPerson = true;
    Canvas.DrawActor(self, false, false, DisplayFOV);
    bDrawingFirstPerson = false;
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    if ( Level.NetMode != NM_DedicatedServer )
    {
        ReloadViewOffset = Vect(0,0,0);
    }
    Super.BringUp(PrevWeapon);
}

simulated function bool PutDown()
{
    //tween to 0, 0, 0
    TargetViewOffset = Vect(0,0,0);
    ReloadTweenStartTime = Level.TimeSeconds;
    ReloadTweenEndTime = Level.TimeSeconds + ReloadTweenRate;
    ReloadViewOffsetInterp = ReloadViewOffset; //store values for interpolation
    Super.PutDown();
}

simulated function ClientFinishReloading()
{
    bIsReloading = false;

    //do reload tween stuff
    TargetViewOffset = Vect(0,0,0);
    ReloadTweenStartTime = Level.TimeSeconds;
    ReloadTweenEndTime = Level.TimeSeconds + ReloadTweenRate;
    ReloadViewOffsetInterp = ReloadViewOffset; //store values for interpolation
    
    //play chambering animation if finished reloading from empty
    if ( !bChamberThisReload )
    {
        PlayIdle();
    }
    bChamberThisReload = false;

    if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
        Instigator.Controller.ClientSwitchToBestWeapon();
}

defaultproperties
{
     ReloadRate=0.750000
     ReloadAnimRate=1.074 //1.200000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnBenelliFire'
     Description="A military tactical shotgun with semi automatic fire capability. Holds up to 6 shells. Special shell construction allow pellets to penetrate fat much easier."
     PickupClass=Class'ScrnBalanceSrv.ScrnBenelliPickup'
     AttachmentClass=Class'ScrnBalanceSrv.ScrnBenelliAttachment' //New attachment to fix broken BenelliAttachment class
     ItemName="Combat Shotgun SE"
     PlayerViewPivot=(Pitch=-47,Roll=0,Yaw=-5) //fix to make sight centered
     ReloadViewOffset=(X=0.000000,Y=0.000000,Z=0.000000) //reload offset to get the weapon away from the center of the screen while reloading
     ReloadViewOffsetValue=(X=10.000000,Y=-5.000000,Z=-10.000000) //used to store the vector values
     ReloadTweenRate = 0.2 //little less than zoomtime
}