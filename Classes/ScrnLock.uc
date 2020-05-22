class ScrnLock extends Info
    config(ScrnLock)
    dependson(ScrnBalance);

var globalconfig array<ScrnBalance.SDLCLock> DLCLocks; // replicated via ScrnClientPerkRepLink
var protected transient int DLCLockCount;

function LoadDLCLocks(bool bUseLevelLocks)
{
    local int i;

    DLCLockCount = 0;
    if ( DLCLocks.length == 0 )
        return;

    for ( i=0; i<DLCLocks.length; ++i ) {
        if ( DLCLocks[i].Item != "" ) {
            DLCLocks[i].PickupClass = class<Pickup>(DynamicLoadObject(DLCLocks[i].Item, Class'Class'));
        }
        if ( DLCLocks[i].PickupClass != none && (bUseLevelLocks || DLCLocks[i].Type != LOCK_Level) ) {
            ++DLCLockCount;
        }
    }

    if ( DLCLockCount == DLCLocks.length ) {
        log("Loaded all " $ DLCLockCount $ " DLC locks", 'ScrnBalance');
    }
    else {
        log("Loaded " $ DLCLockCount $ " / " $ DLCLocks.length $ " DLC locks", 'ScrnBalance');
    }
}

function int GetDLCDLCLockCount()
{
    return DLCLockCount;
}
