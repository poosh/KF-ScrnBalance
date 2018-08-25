// Base class for faked projectiles that are used in weapon animations
class ScrnFakedProjectile extends Actor
    abstract;

var(Display) string StaticMeshRef;

static function PreloadAssets()
{
    if( default.StaticMeshRef != "" )
        UpdateDefaultStaticMesh(StaticMesh(DynamicLoadObject(default.StaticMeshRef, class'StaticMesh', true)));
}

static function bool UnloadAssets()
{
    if( default.StaticMeshRef != "" )
        UpdateDefaultStaticMesh(none);

    return true;
}


defaultproperties
{
    // WARNING! Owner is responsible to destroy a faked projectile. Otherwise memory leak will occur
    LifeSpan=0

    bGameRelevant=True
    bCanBeDamaged=False

    DrawType=DT_StaticMesh
    DrawScale=1.0

    // This actor is not replicated. Needs to be spawned on client side.
    RemoteRole=ROLE_None
    bSkipActorPropertyReplication=true
    bReplicateMovement=false
    bUpdateSimulatedPosition=false
    bNetNotify=false
    bAlwaysRelevant=false

    Physics=PHYS_None
    bCollideActors=false
    bCollideWorld=false
    bBlockActors=false
    bBlockProjectiles=false
    bBlockHitPointTraces=false
    CollisionRadius=0.000000
    CollisionHeight=0.000000
    bUseCylinderCollision=True
}
