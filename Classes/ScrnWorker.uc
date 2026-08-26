class ScrnWorker extends Info
    abstract;

var int TotalItemCount;  // Must be set in a subclass

var ScrnWorkqueue WQ;
var float Weight;

var transient bool bDone;  // Worker finished all jobs in the current cycle
var transient int CurrentItemIndex;

// all children must override this
function bool ProcessItem(int Index) { return false; }

function Destroyed()
{
    PossessedBy(none);
    super.Destroyed();
}

function PossessedBy(ScrnWorkqueue NewWQ)
{
    if (WQ == NewWQ)
        return;

    if (WQ != none) {
        WQ.RemoveWorker(self);
    }
    WQ = NewWQ;
}

function StartNextCycle()
{
    bDone = false;
    CurrentItemIndex = 0;
}

function CycleCompleted()
{
    bDone = true;
}

function bool Process(int ItemCount)
{
    local bool result;

    while (ItemCount > 0 && CurrentItemIndex < TotalItemCount) {
        if (ProcessItem(CurrentItemIndex++)) {
            --ItemCount;
            result = true;
        }
    }
    if (CurrentItemIndex >= TotalItemCount) {
        CycleCompleted();
    }
    return result;
}


defaultproperties
{
    Weight=1.0
}
