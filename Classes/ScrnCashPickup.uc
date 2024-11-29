class ScrnCashPickup extends CashPickup;

var() protected float FadeOutTime;
var() bool bAutoFadeOutTime;

var int ClientCashAmount;

replication {
    reliable if (Role == ROLE_Authority && bNetDirty)
        ClientCashAmount;
}

simulated function PostNetReceive()
{
    super.PostNetReceive();
    if (Role == ROLE_Authority)
        return;

    if (ClientCashAmount != CashAmount) {
        SetAmount(ClientCashAmount);
    }
}

function float GetFadeOutTime()
{
    return FadeOutTime;
}

function SetFadeOutTime(float value)
{
    FadeOutTime = value;
    LifeSpan = FadeOutTime + 2;
}

function CalcFadeOutTime()
{
    if ( CashAmount < 10 )
        FadeOutTime = 8; // default
    else if ( CashAmount < 50 )
        FadeOutTime = 15;
    else
        FadeOutTime = 120;

    SetFadeOutTime(FadeOutTime);
}

simulated function SetAmount(int value) {
    ClientCashAmount = value;
    CashAmount = value;
    if (Role == ROLE_Authority) {
        NetUpdateTime = Level.TimeSeconds - 1;
    }

    if (Level.NetMode != NM_DedicatedServer) {
        MakeCashPile();
    }
}

simulated function MakeCashPile() {
    local vector scale;

    if (CashAmount <= 1000) {
        scale.x = 1.0;
        scale.y = 1.0;
        scale.z = fmax(1.0, CashAmount / 250.0);
    }
    else {
        scale.x = sqrt(CashAmount / 1000.0);
        scale.y = scale.x;
        scale.z = 4.0;
    }
    SetDrawScale3D(scale);
}

function Combine(ScrnCashPickup Other)
{
    if (Other.bDeleteMe || !Other.bDroppedCash)
        return;

    SetAmount(CashAmount + Other.CashAmount);
    Other.Destroy();
}

auto state Pickup
{
    function BeginState()
    {
        UntriggerEvent(Event, self, None);
        if (bDropped)
        {
            AddToNavigation();
            SetFadeOutTime(FadeOutTime);
        }
        SetAmount(CashAmount);
    }

    function SetFadeOutTime(float value)
    {
        global.SetFadeOutTime(value);
        SetTimer(FadeOutTime, false);
    }

    function Touch( actor Other )
    {
        if (bDeleteMe)
            return;

        if (ScrnCashPickup(Other) != none) {
            Combine(ScrnCashPickup(Other));
            CalcFadeOutTime();
        }
        else if (ValidTouch(Other)) {
            GiveCashTo(Pawn(Other));
        }
    }
}


state FallingPickup
{
    function BeginState()
    {
        if ( bAutoFadeOutTime )
            CalcFadeOutTime();
        else
            SetFadeOutTime(FadeOutTime);
    }

    function SetFadeOutTime(float value)
    {
        global.SetFadeOutTime(value);
        SetTimer(FadeOutTime, false);
    }
}


defaultproperties
{
    FadeOutTime=8
    bAutoFadeOutTime=True
    bNetNotify=true
}