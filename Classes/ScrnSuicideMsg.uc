class ScrnSuicideMsg extends CriticalEventPlus
    abstract;

var texture Icon;
var Color CriticalColor;
var int OldValue;

static function RenderComplexMessage(
        Canvas C,
        out float XL,
        out float YL,
        optional String MessageString,
        optional int Beep,
        optional PlayerReplicationInfo RelatedPRI_1,
        optional PlayerReplicationInfo RelatedPRI_2,
        optional Object OptionalObject // must be ScrnGameReplicationInfo
        )
{
    local ScrnPlayerController PC;
    local ScrnGameReplicationInfo ScrnGRI;
    local ScrnHUD hud;
    local int TimeLeft, Minutes, Seconds;
    local float TextWidth, TextHeight;
    local float IconSize;
    local float x, y;
    local String str;

    ScrnGRI = ScrnGameReplicationInfo(OptionalObject);
    if ( ScrnGRI == none || ScrnGRI.bStopCountDown )
        return;
    PC = ScrnPlayerController(RelatedPRI_1.Owner);
    if ( PC == none )
        return;
    if ( !RelatedPRI_1.bIsSpectator && (PC.Pawn == none || PC.Pawn.Health <= 0) )
        return;
    hud = ScrnHUD(PC.myHud);
    if ( hud == none )
        return;

    TimeLeft = ScrnGRI.RemainingTime;
    if ( TimeLeft >= 3600 )
        return;

    if ( TimeLeft <= 30 ) {
        Minutes = 0;
        Seconds = TimeLeft;
        C.DrawColor = default.CriticalColor;
        C.DrawColor.A = hud.PulseAlpha;
        if ( Beep > 0 && hud.PulseAlpha > default.OldValue) {
            // beep on pulse's peek
            PC.Pawn.PlaySound(class'ScrnSuicideBomb'.default.BeepSound, SLOT_Misc, 2.0, , 150.0);
        }
        default.OldValue = hud.PulseAlpha;
    }
    else {
        Minutes = TimeLeft / 60;
        Seconds = TimeLeft % 60;
        // C.Color = DrawColor;
        // C.Color.A = KFHUDAlpha;
        if ( Beep > 0 && TimeLeft != default.OldValue ) {
            // beep once per second
            PC.Pawn.PlaySound(class'ScrnSuicideBomb'.default.BeepSound, SLOT_Misc, 2.0, , 150.0);
            default.OldValue = TimeLeft;
        }
    }

    C.Style = ERenderStyle.STY_Alpha;
    C.Font = hud.LoadWaitingFont(0);

    str = class'ScrnFunctions'.static.LPad(string(Minutes), 2, "0") $ ":"
        $ class'ScrnFunctions'.static.LPad(string(Seconds), 2, "0");

    C.StrLen("00:00", TextWidth, TextHeight);
    y = C.ClipY * 0.15;
    x = (C.ClipX - TextWidth) / 2;

    C.SetPos(x, y);
    C.DrawTextClipped(str);

    IconSize = TextHeight;
    y += TextHeight * 0.15;
    C.SetPos(x - IconSize - TextWidth*0.2, y);
    C.DrawTile(default.Icon, IconSize, IconSize, 0, 0, 256, 256);
    C.SetPos(x + TextWidth*1.2, y);
    C.DrawTile(default.Icon, IconSize, IconSize, 0, 0, 256, 256);
}


defaultproperties
{
     bComplexString=True
     Lifetime=10
     DrawColor=(R=255,G=64,B=64)
     CriticalColor=(R=210,G=50,B=0)
     Icon=Texture'KillingFloor2HUD.Trader_Weapon_Icons.Trader_Pipe_Bomb'
}
