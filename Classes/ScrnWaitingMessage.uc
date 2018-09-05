class ScrnWaitingMessage extends WaitingMessage;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    local ScrnGameReplicationInfo ScrnGRI;
    local string s;

    s = super.GetString(switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    if ( switch == 1 || switch == 3 ) {
        ScrnGRI = ScrnGameReplicationInfo(class'ScrnBalance'.default.Mut.Level.GRI);
        if ( ScrnGRI != none ) {
            if ( ScrnGRI.WaveHeader != "" )
                s = ScrnGRI.WaveHeader; // overwrite default "NEXT/FINAL WAVE INBOUND"

            s $= "|" $ ScrnGRI.WaveTitle;
            if ( ScrnGRI.WaveMessage != "" )
                s $= "|" $ ScrnGRI.WaveMessage;
        }
    }
    return s;
}

static function RenderComplexMessage(
    Canvas Canvas,
    out float XL,
    out float YL,
    optional string MessageString,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    local int i;
    local float TempY;

    i = InStr(MessageString, "|");

    TempY = Canvas.CurY;

    Canvas.FontScaleX = Canvas.ClipX / 1024.0;
    Canvas.FontScaleY = Canvas.FontScaleX;

    if ( i < 0 ) {
        Canvas.TextSize(MessageString, XL, YL);
        Canvas.SetPos((Canvas.ClipX / 2.0) - (XL / 2.0), TempY);
        Canvas.DrawTextClipped(MessageString, false);
    }
    else {
        Canvas.TextSize(Left(MessageString, i), XL, YL);
        Canvas.SetPos((Canvas.ClipX / 2.0) - (XL / 2.0), TempY);
        Canvas.DrawTextClipped(Left(MessageString, i), false);
        TempY += YL;

        MessageString = Mid(MessageString, i + 1);
        i = InStr(MessageString, "|");
        if ( i < 0 ) {
            Canvas.TextSize(MessageString, XL, YL);
            Canvas.SetPos((Canvas.ClipX / 2.0) - (XL / 2.0), TempY);
            Canvas.DrawTextClipped(MessageString, false);
        }
        else {
            Canvas.TextSize(Left(MessageString, i), XL, YL);
            Canvas.SetPos((Canvas.ClipX / 2.0) - (XL / 2.0), TempY);
            Canvas.DrawTextClipped(Left(MessageString, i), false);
            TempY += YL;

            Canvas.FontScaleX *= 0.25;
            Canvas.FontScaleY *= 0.25;
            MessageString = Mid(MessageString, i + 1);
            Canvas.TextSize(MessageString, XL, YL);
            Canvas.SetPos((Canvas.ClipX / 2.0) - (XL / 2.0), TempY);
            Canvas.DrawTextClipped(MessageString, false);
        }
    }

    Canvas.FontScaleX = 1.0;
    Canvas.FontScaleY = 1.0;
}
