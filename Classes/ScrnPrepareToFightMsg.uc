class ScrnPrepareToFightMsg extends ScrnWaitingFontMsg;

var(Message) array<localized string> Messages;


static function string GetString(
    optional int sw,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    return default.Messages[sw];
}


defaultproperties
{
    DrawColor=(R=200,G=0,B=0,A=255)
    DrawPivot=DP_MiddleMiddle
    PosX=0.500000
    PosY=0.70
    FontSize=0
    bIsConsoleMessage=false
    bFadeMessage=true
    LifeTime=3

    Messages(0)="FIGHT"
    Messages(1)="1..."
    Messages(2)="2..."
    Messages(3)="3..."
    Messages(4)="PREPARE TO FIGHT..."
}