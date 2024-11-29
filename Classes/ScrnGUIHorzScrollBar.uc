// Fixed Incorrect Style
class ScrnGUIHorzScrollBar extends GUIHorzScrollBar;

defaultproperties
{
    StyleName="VertGrip"

    Begin Object Class=GUIHorzScrollButton Name=HRightBut
        bIncreaseButton=True
        StyleName="VertGrip"
        OnClick=GUIHorzScrollBar.IncreaseClick
        OnKeyEvent=HRightBut.InternalOnKeyEvent
    End Object
    MyIncreaseButton=HRightBut

    Begin Object Class=GUIHorzScrollButton Name=HLeftBut
        StyleName="VertGrip"
        OnClick=GUIHorzScrollBar.DecreaseClick
        OnKeyEvent=HLeftBut.InternalOnKeyEvent
    End Object
    MyDecreaseButton=HLeftBut

    Begin Object Class=GUIHorzGripButton Name=HGrip
        StyleName="VertGrip"
        ImageIndex=-1
        OnMousePressed=GUIHorzScrollBar.GripPressed
        OnKeyEvent=HGrip.InternalOnKeyEvent
    End Object
    MyGripButton=HGrip

}