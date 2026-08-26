class ScrnGameWorker_ZVol extends ScrnWorker;

var ScrnGameType GT;

function PostBeginPlay()
{
    super.PostBeginPlay();

    GT = ScrnGameType(Level.Game);
    TotalItemCount = GT.ZVolInfos.length;
}

function bool ProcessItem(int Index)
{
    return GT.ZVolCheck(GT.ZVolInfos[Index]);
}
