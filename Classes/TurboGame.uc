class TurboGame extends ScrnGameType;


State MatchInProgress
{
    function BeginState()
    {
        super.BeginState();
        SetGameSpeed(TurboScale);
    }
}
event Tick(float DeltaTime)
{
    super.Tick(DeltaTime);
    if ( !bZEDTimeActive )
        ZedTimeExtensionsUsed = -3; // + 3 zed time extensions to all perks
}

defaultproperties
{
    GameName="Turbo Floor"
    Description="Same KF but faster. Much Faster. And more ZED Time."

    TurboScale=1.5

    ZEDTimeDuration=4.5
    ZedTimeSlomoScale=0.50
}