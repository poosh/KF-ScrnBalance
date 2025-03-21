class ScrnPipeBombExplosive extends PipeBombExplosive;

var transient float LastCountTime;

replication
{
    reliable if(Role < ROLE_Authority)
        ServerSendCount;
}

simulated function AltFire(float F)
{
    if (Level.TimeSeconds - LastCountTime > 1.0) {
          ServerSendCount();
          LastCountTime = Level.TimeSeconds;
    }
}

function ServerSendCount() {
     local ScrnPipeBombProjectile P;
     local int c;

     if (Instigator == none || PlayerController(Instigator.Controller) == none)
          return;

     if (Level.TimeSeconds - LastCountTime < 1.0)
          return;
     LastCountTime = Level.TimeSeconds;

     foreach DynamicActors(Class'ScrnPipeBombProjectile', P) {
          if (!P.bHidden && P.Instigator == Instigator && P.bDetectEnemies) {
               ++c;
          }
     }
     PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'ScrnPipebombMessage',
               (MaxAmmo(0) << 8) | min(c, 255),
               Instigator.PlayerReplicationInfo);
}

defaultproperties
{
     FireModeClass(0)=class'ScrnPipeBombFire'
     PickupClass=class'ScrnPipeBombPickup'
     ItemName="PipeBomb SE"
}
