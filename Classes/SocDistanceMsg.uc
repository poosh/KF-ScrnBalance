class SocDistanceMsg extends CriticalEventPlus
    abstract;

var localized string Title;
var array<localized string>Messages;
var texture Picture;
var string PictureRef;


static function RenderComplexMessage(
        Canvas C,
        out float XL,
        out float YL,
        optional String MessageString,
        optional int Switch,
        optional PlayerReplicationInfo RelatedPRI_1,
        optional PlayerReplicationInfo RelatedPRI_2,
        optional Object OptionalObject // must be ScrnAchievementInfo
        )
{
    local float TextWidth, TextHeight, IconSize;
    local float x, y, tx;
    local int i;

    C.Style = ERenderStyle.STY_Alpha;

    C.Font = class'ScrnHUD'.static.LoadSmallFontStatic(default.FontSize);
    C.StrLen(default.Title, tx, TextHeight);
    x = c.ClipX - 4;
    y = C.ClipY * default.PosY;
    IconSize = C.ClipX * 0.10;

    C.SetPos(x - tx, y - TextHeight);
    C.DrawTextClipped(default.Title);

    C.SetPos(x - IconSize, y - TextHeight - IconSize);
    C.DrawTile(default.Picture, IconSize, IconSize, 0, 0, 1024, 1024);


    C.Font = class'ScrnHUD'.static.LoadSmallFontStatic(7);
    C.StrLen(default.Messages[0], TextWidth, TextHeight);
    for ( i = 0; i < default.Messages.Length; ++i ) {
        C.StrLen(default.Messages[i], TextWidth, TextHeight);
        C.SetPos(x - TextWidth, y);
        // C.SetPos(x - tx + (tx - TextWidth)/2, y);
        C.DrawTextClipped(default.Messages[i]);
        y += TextHeight;
    }
}

static function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    if ( default.Picture == none )
        default.Picture = texture(DynamicLoadObject(default.PictureRef, class'texture'));

    Super.ClientReceive(P,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
}

defaultproperties
{
     bIsConsoleMessage=false
     bComplexString=true
     Lifetime=2.0
     DrawColor=(B=64,G=64,R=255)
     PosY=0.500000
     FontSize=1
     Title="KEEP DISTANCE"
     Messages(0)="You are too close to other players!"
     Messages(1)="Move away to prevent virus spreading."
     PictureRef="ScrnTex.HUD.Virus"
}
