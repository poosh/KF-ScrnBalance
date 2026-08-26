class ScrnGameWorkqueue extends ScrnWorkqueue;

var ScrnGameType GT;

function PostBeginPlay()
{
    super.PostBeginPlay();

    GT = ScrnGameType(Level.Game);
}

defaultproperties
{
    bManualTick=true
    bCanSleep=true
    WorkerClasses[0]=class'ScrnGameWorker_ZVol'
    WorkerClasses[1]=class'ScrnGameWorker_Zed'
}