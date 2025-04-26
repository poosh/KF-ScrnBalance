class ScrnPrepareToFightAvoidMarker extends AvoidMarker;

function PostBeginPlay()
{
    super.PostBeginPlay();
    StartleBots();
}

defaultproperties
{
    CollisionRadius=250
    LifeSpan=8.0
}