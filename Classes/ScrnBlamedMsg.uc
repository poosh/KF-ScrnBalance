class ScrnBlamedMsg extends CriticalEventPlus
    abstract;
    
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
    local float TextWidth, TextHeight;
    local float IconSize;
    local float y, ty;
    local int i;
    
    IconSize = C.ClipY * fmin(0.9, 0.25 + Switch*0.05);
    C.Style = ERenderStyle.STY_Alpha;
    
    C.Font = class'ScrnBalanceSrv.ScrnHUD'.static.LoadSmallFontStatic(7);
    C.StrLen(default.Messages[0], TextWidth, TextHeight);
    y = max( (C.ClipY - IconSize ) / 2, 0 );
    ty = max( y - TextHeight * default.Messages.Length, C.ClipY * 0.12 );
    
    for ( i = 0; i < default.Messages.Length; ++i ) {
        C.StrLen(default.Messages[i], TextWidth, TextHeight);
        C.SetPos(c.ClipX - TextWidth - 4, ty);
        C.DrawTextClipped(default.Messages[i]);
        ty += TextHeight;
    }
    
    C.SetPos(C.ClipX - IconSize, y);
    C.DrawTile(default.Picture, IconSize, IconSize, 0, 0, 256, 256);

    // C.SetPos(0, y);
    // C.DrawTile(default.Picture, IconSize, IconSize, 0, 0, 256, 256);
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
     bComplexString=True
     Lifetime=120
     DrawColor=(B=64,G=64,R=255)
     PosY=0.800000
     FontSize=5
     Messages(0)="You are blamed by the team!"
     Messages(1)="As a punishment you have to"
     Messages(2)="look at this for 2 minutes:"
     PictureRef="ScrnTex.HUD.Crap256"
}    