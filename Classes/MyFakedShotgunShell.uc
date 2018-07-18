class MyFakedShotgunShell extends ScrnM79MGrenadeProjectile;

simulated function PostBeginPlay()
{
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
}

simulated function Disintegrate(vector HitLocation, vector HitNormal)
{
}

simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
}

simulated function Tick( float DeltaTime )
{
    Disable('Tick');
}

defaultproperties
{
    StaticMesh=StaticMesh'kf_generic_sm.Bullet_Shells.12Guage_Shell'
    LifeSpan=0

    RemoteRole=ROLE_None
    bSkipActorPropertyReplication=true
    bReplicateMovement=false
    bUpdateSimulatedPosition=false
    bNetNotify=false
    bAlwaysRelevant=true


    Physics=PHYS_None
    bCollideActors=false
    bCollideWorld=false
    bBlockActors=false
    bBlockProjectiles=false
    bBlockHitPointTraces=false
    DrawScale=3.5
}
