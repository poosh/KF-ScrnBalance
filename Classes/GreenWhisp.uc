class GreenWhisp extends BlueWhisp;

function vector GetFinalDestination()
{
    return TSCTeamBase(PlayerController(Owner).PlayerReplicationInfo.Team.HomeBase).Location;
}

defaultproperties
{
     mColorRange(0)=(R=0,G=255,B=0,A=255)
     mColorRange(1)=(R=0,G=255,B=0,A=255)
}