class ScrnKFQuickPerkSelect extends SRKFQuickPerkSelect;

function bool MyOnDraw(Canvas C)
{
    local ScrnClientPerkRepLink S;

    super(GUIMultiComponent).OnDraw(C);

    C.SetDrawColor(255, 255, 255, 255);

    // make em square
    if (!bResized) {
        ResizeIcons(C);
    }

    // Current perk background
    C.SetPos(WinLeft * C.ClipX , WinTop * C.ClipY);
    C.DrawTileScaled(CurPerkBack, (WinHeight * C.ClipY) / CurPerkBack.USize, (WinHeight * C.ClipY) / CurPerkBack.USize);

    S = Class'ScrnClientPerkRepLink'.Static.FindMe(C.Viewport.Actor);
    if (S == None)
        return false;
    // check if the current perk has changed recently
    CheckPerksX(S);

    // Draw current perk
    if( CurPerk!=255 )
        DrawCurrentPerkX(S, C, CurPerk);

    return false;
}

function ResizeIcons(Canvas C)
{
    PerkBack0.SetVisibility(false);
    PerkBack1.SetVisibility(false);
    PerkBack2.SetVisibility(false);
    PerkBack3.SetVisibility(false);
    PerkBack4.SetVisibility(false);
    PerkBack5.SetVisibility(false);

    PerkSelectIcon0.SetVisibility(false);
    PerkSelectIcon1.SetVisibility(false);
    PerkSelectIcon2.SetVisibility(false);
    PerkSelectIcon3.SetVisibility(false);
    PerkSelectIcon4.SetVisibility(false);
    PerkSelectIcon5.SetVisibility(false);

    bResized = true;
}

function bool InternalOnClick(GUIComponent Sender)
{
    return false;
}
