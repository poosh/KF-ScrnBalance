class TurboGame extends ScrnGameType;

State MatchInProgress
{
    function BeginState()
    {
        super.BeginState();
        SetGameSpeed(TurboScale);
    }
}

defaultproperties
{
    GameName="Turbo Floor"
    Description="Same KF but faster. Much Faster. And more ZED Time."

    TurboScale=1.5

    ZEDTimeDuration=4.5
    ZedTimeSlomoScale=0.50
    ExtraZedTimeExtensions=3
}
