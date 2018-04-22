class ScrnGUIWeaponBar extends GUIProgressBar;

var bool bHighlighted;
var color HighlightColor;
var color CaptionColor;
var float CaptionMargin; // margin in % of bar width, if CaptionAlign = TXTA_Left or TXTA_Right

var private color OriginalBarColor;

function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
    Super.InitComponent(MyController,MyOwner);
    
    OriginalBarColor = BarColor;
}

function SetHighlight(bool bValue)
{
    bHighlighted = bValue;
    if ( !bHighlighted )
        BarColor = OriginalBarColor;
    else
        BarColor = HighlightColor;
}

function InternalOnRendered(canvas Canvas)
{
    local float w, h;
    //ClientBounds[0]

    if ( !bVisible )
        return;
        
    Canvas.DrawColor = CaptionColor;
    Canvas.StrLen(Caption, w, h);
    switch ( CaptionAlign ) {
        case TXTA_Left:
            Canvas.SetPos(ClientBounds[0] + (ClientBounds[2] - ClientBounds[0]) * CaptionMargin, ClientBounds[1] + (ClientBounds[3] - ClientBounds[1] - h) / 2);
            break;
        case TXTA_Right:
            Canvas.SetPos(ClientBounds[0] + (ClientBounds[2] - ClientBounds[0]) * (1.0 - CaptionMargin) - w, ClientBounds[1] + (ClientBounds[3] - ClientBounds[1] - h) / 2);
            break;
        default:
            Canvas.SetPos(ClientBounds[0] + (ClientBounds[2] - ClientBounds[0] - w) / 2, ClientBounds[1] + (ClientBounds[3] - ClientBounds[1] - h) / 2);
    }
    Canvas.DrawText(Caption);
}


/*
function ResetColor()
{
    BarColor.R=255;
    BarColor.G=255;
    BarColor.B=255;
    BarColor.A=255;
}
*/

defaultproperties
{
    OnRendered=InternalOnRendered;

    BarBack=Texture'KF_InterfaceArt_tex.Menu.Innerborder_transparent'
    BarTop=Texture'InterfaceArt_tex.Menu.progress_bar'
    BarColor=(B=128,G=128,R=128,A=255)
    HighlightColor=(B=128,G=192,R=128,A=255)
    CaptionColor=(B=192,G=192,R=192,A=255)
    High=100
    CaptionWidth=0.0
    ValueRightWidth=0.000000
    bShowValue=False
    CaptionAlign=TXTA_Center
    CaptionMargin=0.05
    FontScale=FNS_Small
    bCaptureMouse=True
    Begin Object Class=GUIToolTip Name=GUIButtonToolTip
    End Object
    ToolTip=GUIToolTip'XInterface.GUIButton.GUIButtonToolTip'    
}