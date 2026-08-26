class ScrnWorkqueue extends Info;

var const array< class<ScrnWorker> > WorkerClasses;
var const bool bManualTick;  // if true, ProcessTick() must be called manually
var bool bCanSleep;  // if WQ prematurely finished processing, should it speep until NextCycleTime or start a new cycle?


var protected array<ScrnWorker> Workers;
var protected array<float> WorkerWeights;
var protected float TotalWeigth;
var protected float CycleDuration;

var protected transient int CurrentWorkerIndex;
var transient float CycleStartTime;
var transient float NextCycleTime;
var int CycleCounter;

function PostBeginPlay()
{
    local int i;

    if (WorkerClasses.Length > 0) {
        Workers.Length = WorkerClasses.Length;
        for (i = 0; i < WorkerClasses.Length; ++i) {
            Workers[i] = spawn(WorkerClasses[i], self);
            Workers[i].PossessedBy(self);
        }
    }

    if (bManualTick || Workers.Length == 0) {
        Disable('Tick');
    }
}

function Destroyed()
{
    local int i;

    for (i = 0; i < Workers.Length; ++i) {
        if (Workers[i] != none && !Workers[i].bDeleteMe) {
            Workers[i].WQ = none;
            Workers[i].Destroy();
        }
    }
    Workers.Length = 0;

    super.Destroyed();
}

function bool AddWorker(ScrnWorker Worker)
{
    local int i;
    if (HasWorker(Worker))
        return false;

    i = Workers.length;
    Workers[i] = Worker;
    Worker.PossessedBy(self);
    BreakCycle();
    if (!bManualTick) {
        Enable('Tick');
    }
    return true;
}

function bool HasWorker(ScrnWorker Worker)
{
    return class'ScrnF'.static.SearchObj(Workers, Worker) != -1;
}

function bool RemoveWorker(ScrnWorker Worker)
{
    local int i;

    i = class'ScrnF'.static.SearchObj(Workers, Worker);
    if (i == -1)
        return false;

    Workers.remove(i, 1);
    BreakCycle();
    if (Workers.Length == 0) {
        Disable('Tick');
    }
    return true;
}

function float GetCycleDuration()
{
    return CycleDuration;
}

function SetCycleDuration(float value)
{
    if (value <= 0.1)
        return;
    CycleDuration = value;
}

protected function StartNextCycle()
{
    local ScrnWorker Worker;

    local int i;

    CurrentWorkerIndex = 0;
    CycleStartTime = Level.TimeSeconds;
    NextCycleTime = CycleStartTime + CycleDuration;

    WorkerWeights.Length = Workers.Length;
    TotalWeigth = 0;
    for (i = 0; i < Workers.Length; ++i) {
        Worker = Workers[i];
        Worker.StartNextCycle();
        if (Worker.bDone) {
            WorkerWeights[i] = 0;
        }
        else {
            WorkerWeights[i] = fmax(Worker.Weight, 0.01);
        }
        TotalWeigth += WorkerWeights[i];
    }
}

// Breaks current cycle and start with a new one on the next tick.
function BreakCycle()
{
    TotalWeigth = 0;
}

function Tick(float dt)
{
    ProcessTick(dt);
}

function bool ProcessTick(float dt)
{
    local bool result;
    local int FirstIndex;

    FirstIndex = CurrentWorkerIndex;
    while (TotalWeigth >= 0.001) {
        result = ProcessWorker(CurrentWorkerIndex, dt);

        if (++CurrentWorkerIndex >= Workers.Length)
            CurrentWorkerIndex = 0;

        if (result)
            return true;

        if (CurrentWorkerIndex == FirstIndex)
            break;
    }
    if (TotalWeigth < 0.001) {
        FinishedCycle();
    }
    return result;
}

protected function bool ProcessWorker(int Index, float dt)
{
    local bool result;
    local ScrnWorker Worker;
    local float TimeLeft;
    local int ItemCount;

    if (WorkerWeights[Index] <= 0.0) return false;

    Worker = Workers[Index];
    if (!Worker.bDone) {
        TimeLeft = (NextCycleTime - Level.TimeSeconds) * WorkerWeights[Index] / TotalWeigth;
        if (TimeLeft < dt) {
            ItemCount = Worker.TotalItemCount - Worker.CurrentItemIndex;
        }
        else {
            ItemCount = max(1, 0.5 + (Worker.TotalItemCount - Worker.CurrentItemIndex) * dt / TimeLeft);
        }
        // class'ScrnBalance'.default.Mut.TimeLog("Worker#" $ Index $ " process " $ ItemCount $ " items");
        result = Worker.Process(ItemCount);
    }
    if (Worker.bDone) {
        TotalWeigth -= WorkerWeights[Index];
        WorkerWeights[Index] = 0;
    }
    return result;
}

protected function FinishedCycle()
{
    // class'ScrnBalance'.default.Mut.TimeLog(name $ "WQ Cycle#" $ CycleCounter $ " finished in "
    //         $ (Level.TimeSeconds - CycleStartTime) $ "s");

    ++CycleCounter;
    if (bCanSleep && Level.TimeSeconds < NextCycleTime) {
        GotoState('Idle');
    }
    else {
        GotoState('WaitingForTick');
    }
}

state Idle
{
    function BeginState()
    {
        Disable('Tick');
        SetTimer(fmax(NextCycleTime - Level.TimeSeconds, 0.001), false);
    }

    function EndState()
    {
        SetTimer(0, false);
        if (!bManualTick) {
            Enable('Tick');
        }
    }

    function Timer()
    {
        GotoState('WaitingForTick');
    }

    function bool ProcessTick(float dt) {
        if (bCanSleep)
            return false;

        Timer();
        return true;
    }

    function BreakCycle()
    {
        Timer();
    }
}

state WaitingForTick
{
    function bool ProcessTick(float dt)
    {
        StartNextCycle();
        GotoState('');
        return global.ProcessTick(dt);
    }
}


defaultproperties
{
    CycleDuration=1.0
    bCanSleep=true
}