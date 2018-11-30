class ScrnAchievementEarnedMsg extends CriticalEventPlus
    abstract;

var(Message) localized string EarnedString, InProgressString;
var texture BackGround;
var    texture    ProgressBarBackground;
var    texture    ProgressBarForeground;

var byte Align; // 0 - left, 1 - center, 2 - right


static function string GetString(
        optional int Switch,
        optional PlayerReplicationInfo RelatedPRI_1,
        optional PlayerReplicationInfo RelatedPRI_2,
        optional Object OptionalObject
        )
{
    local ScrnAchievements AchHandler;
    local int AchIndex;

    if ( !default.bComplexString ) {
        AchHandler = ScrnAchievements(OptionalObject);
        AchIndex = Switch;
        if ( AchHandler == none || !AchHandler.IsUnlocked(AchIndex) )
            return "";

        return default.EarnedString $ ": " $ AchHandler.AchDefs[AchIndex].DisplayName;
    }

    return "";
}



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
    local float X,Y, MaxWidth, MaxHeight, TextX, TextY, IconY;
    local ScrnPlayerController P;
    local ScrnAchievements AchHandler;
    local int AchIndex;
    local bool bUnlocked;
    local float TextWidth, TextHeight;
    local float OrgX, ClipX; //dunno if it should be restored, but just in case
    local byte Style;
    local float BarHeight, BarWidth, BarTop, BarLeft;
    local int CurProg, MaxProg;

    // don't draw a message if it is fully transparent
    if ( c.DrawColor.A < 10 )
        return;

    // log("RenderComplexMessage: "
        // @ "RelatedPRI_1="$RelatedPRI_1
        // @ "OptionalObject="$OptionalObject
        // , 'ScrnBalance');


    if ( RelatedPRI_1 != none )
        P = ScrnPlayerController(RelatedPRI_1.Owner);
    AchHandler = ScrnAchievements(OptionalObject);
    AchIndex = Switch;

    if ( P == none || AchHandler == none || AchHandler.AchDefs[AchIndex].CurrentProgress <= 0 )
        return;

    CurProg = AchHandler.AchDefs[AchIndex].CurrentProgress;
    MaxProg = AchHandler.AchDefs[AchIndex].MaxProgress;
    bUnlocked = CurProg >= MaxProg;

    ClipX = c.ClipX;
    OrgX = c.OrgX;
    Style = C.Style;

    //test max width
    C.Font = P.myHUD.LoadFontStatic(6);
    C.StrLen( AchHandler.AchDefs[AchIndex].DisplayName, TextWidth, TextHeight);

    MaxWidth = max(256, TextWidth + 104);
    MaxHeight = 120;

    BarHeight = 16;
    if ( !bUnlocked )
        MaxHeight += BarHeight;

    //X = C.CurX;
    switch ( default.Align ) {
        case 0:     X = C.OrgX; break;
        case 1:     X = (c.ClipX - C.OrgX - MaxWidth)/2; break;
        default:    X = c.ClipX - MaxWidth;
    }
    Y = C.ClipY - MaxHeight;

    //background
    C.SetPos(X, Y);
    C.DrawTileStretched(default.BackGround, MaxWidth, MaxHeight);

    c.OrgX = X;
    c.ClipX = MaxWidth - 8;

    // achievement earnied title
    if ( bUnlocked )
        MessageString = default.EarnedString;
    else
        MessageString = default.InProgressString;

    C.Font = P.myHUD.LoadFontStatic(7);
    C.SetDrawColor(127, 127, 127, c.DrawColor.A);
    C.StrLen(MessageString, TextWidth, TextHeight);
    C.SetPos((MaxWidth - TextWidth)/2, Y + 7);
    C.DrawTextClipped(MessageString);

    // PROGRESS BAR
    if ( !bUnlocked ) {
        // if not unlocked, draw a progress bar
        BarWidth = c.ClipX - 5;
        BarLeft = X + 6;
        BarTop = c.ClipY - BarHeight - 6;

        C.Style = ERenderStyle.STY_Alpha;
        C.SetDrawColor(255, 255, 255, c.DrawColor.A);
        C.SetPos(BarLeft, BarTop); //seems like DrawTileStretched doesn't use clip and org values
        C.DrawTileStretched(default.ProgressBarBackground, BarWidth, BarHeight);

        C.SetPos(BarLeft+2, BarTop+2);
        C.DrawTileStretched(default.ProgressBarForeground, BarWidth  * (float(CurProg) / float(MaxProg)) - 4, BarHeight-4);
        C.Style = Style;


        MessageString = CurProg$" / "$MaxProg;
        C.SetDrawColor(92, 92, 92, c.DrawColor.A);
        C.Font = P.myHUD.LoadFontStatic(7);
        C.StrLen(MessageString, TextWidth, TextHeight);
        C.SetPos((c.ClipX-TextWidth)/2, BarTop + (BarHeight - TextHeight)/2 );
        C.DrawTextClipped(MessageString);
    }



    IconY = Y + 40;
    TextX = 88;
    TextY = IconY;

    // ICON
    C.SetDrawColor(255, 255, 255, c.DrawColor.A);
    C.Style = ERenderStyle.STY_Alpha;
    C.SetPos(16, TextY); //top align with the achievement name
    C.DrawIcon(AchHandler.GetIcon(AchIndex), 1.0);
    C.Style = Style;


    c.OrgX += TextX;
    c.ClipX -= TextX;

    // achievement name
    C.SetPos(0, TextY);
    if ( bUnlocked )
        C.SetDrawColor(50, 192, 50, c.DrawColor.A);
    else
        C.SetDrawColor(127, 127, 127, c.DrawColor.A);
    C.Font = P.myHUD.LoadFontStatic(6);
    C.StrLen(AchHandler.AchDefs[AchIndex].DisplayName, TextWidth, TextHeight);
    C.DrawTextClipped(AchHandler.AchDefs[AchIndex].DisplayName);


    //description
    C.SetDrawColor(192, 192, 192, c.DrawColor.A);
    C.SetPos(0, TextY + TextHeight*1.1);
    C.Font = P.myHUD.LoadFontStatic(8);
    //to do set positions
    C.DrawText(AchHandler.AchDefs[AchIndex].Description);

    //restore original values
    c.OrgX = OrgX;
    c.ClipX = ClipX;
    C.Style = Style;
}

static function ClientReceive(
        PlayerController P,
        optional int Switch,
        optional PlayerReplicationInfo RelatedPRI_1,
        optional PlayerReplicationInfo RelatedPRI_2,
        optional Object OptionalObject
    )
{
    local ScrnHUD hud;
    local string s;

    s = P.ConsoleCommand("get ini:Engine.Engine.ViewportManager TextureDetailWorld");
    default.bComplexString = InStr(s, "Low") == -1;

    Super.ClientReceive(P,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);

    hud = ScrnHUD(P.MyHUD);
    if ( hud != none && hud.bCoolHud && !hud.bCoolHudLeftAlign)
        default.Align = 0 ; // align left, if hud is in center
    else
        default.Align = 1 ; // align right
}

defaultproperties
{
     EarnedString="Achievement Earned"
     InProgressString="Achievement Progress"
     Background=Texture'KF_InterfaceArt_tex.Menu.Med_border'
     ProgressBarBackground=Texture'KF_InterfaceArt_tex.Menu.Innerborder'
     ProgressBarForeground=Texture'InterfaceArt_tex.Menu.progress_bar'
     bComplexString=True
     Lifetime=10
     DrawColor=(G=255,R=255)
     PosY=0.800000
     FontSize=5
     Align=1
}
