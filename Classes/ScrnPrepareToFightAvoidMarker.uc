class ScrnPrepareToFightAvoidMarker extends AvoidMarker;

function PostBeginPlay()
{
    super.PostBeginPlay();
    StartleBots();
}

defaultproperties
{
    CollisionRadius=400
    LifeSpan=8.0
}