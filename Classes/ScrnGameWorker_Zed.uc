class ScrnGameWorker_Zed extends ScrnWorker;

var ScrnGameRules GameRules;

function PostBeginPlay()
{
    super.PostBeginPlay();

    GameRules = class'ScrnBalance'.default.Mut.GameRules;
}

function StartNextCycle()
{
    super.StartNextCycle();

    TotalItemCount = GameRules.MonsterInfos.length;
}

function bool ProcessItem(int Index)
{
    if (Index >= GameRules.MonsterInfos.length)
        return false;
    return GameRules.ProcessMonster(GameRules.MonsterInfos[Index]);
}
