class ScrnCashPickup extends CashPickup;

var() protected float FadeOutTime;
var() bool bAutoFadeOutTime;

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

auto state Pickup
{
    function BeginState()
    {
        UntriggerEvent(Event, self, None);
        if ( bDropped )
        {
            AddToNavigation();
            SetFadeOutTime(FadeOutTime);
        }
    }
    
    function SetFadeOutTime(float value)
    {
        global.SetFadeOutTime(value);
        SetTimer(FadeOutTime, false);
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
}