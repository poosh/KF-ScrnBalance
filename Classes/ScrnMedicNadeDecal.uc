class ScrnMedicNadeDecal extends MedicNadeDecal;

simulated function BeginPlay()
{
    Super(ProjectedDecal).BeginPlay();
}

defaultproperties
{
     LifeSpan=6.0
     DrawScale=0.5
}
