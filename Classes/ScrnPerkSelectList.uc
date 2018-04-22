class ScrnPerkSelectList extends SRPerkSelectList;

var float ProgressBarBottomOffset;


function float PerkHeight(Canvas c)
{
    return (MenuOwner.ActualHeight() / ItemsPerPage ) - 1.0;
}


function DrawPerk(Canvas Canvas, int CurIndex, float X, float Y, float Width, float Height, bool bSelected, bool bPending)
{
    local float TempX, TempY;
    local float IconSize, ProgressBarWidth;
    local float TempWidth, TempHeight;
    local ClientPerkRepLink ST;
    local Material M,SM;

    ST = Class'ScrnClientPerkRepLink'.Static.FindMe(Canvas.Viewport.Actor);
    if( ST==None )
        return;

    // Offset for the Background
    TempX = X;
    TempY = Y + ItemSpacing / 2.0;
    TempHeight = Height - ItemSpacing;

    // Initialize the Canvas
    Canvas.Style = 1;
    Canvas.Font = class'ROHUD'.Static.GetSmallMenuFont(Canvas);
    Canvas.SetDrawColor(255, 255, 255, 255);

    // Draw Item Background
    Canvas.SetPos(TempX, TempY);
    if ( bSelected )
    {
        Canvas.DrawTileStretched(SelectedPerkBackground, IconSize, IconSize);
        Canvas.SetPos(TempX + IconSize - 1.0, TempY);
        Canvas.DrawTileStretched(SelectedInfoBackground, Width - IconSize, TempHeight);
    }
    else
    {
        Canvas.DrawTileStretched(PerkBackground, IconSize, IconSize);
        Canvas.SetPos(TempX + IconSize - 1.0, TempY);
        Canvas.DrawTileStretched(InfoBackground, Width - IconSize, TempHeight);
    }

    // Offset and Calculate Icon's Size
    TempX += ItemBorder * Height;
    TempY += ItemBorder * Height;
    IconSize = TempHeight - (ItemBorder * 2.0 * Height);

    // Draw Icon
    Canvas.SetPos(TempX, TempY);
    ST.CachePerks[CurIndex].PerkClass.Static.PreDrawPerk(Canvas,Max(ST.CachePerks[CurIndex].CurrentLevel,1)-1,M,SM);
    Canvas.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());

    TempX += IconSize + (IconToInfoSpacing * Width);
    TempY += TextTopOffset * Height;

    ProgressBarWidth = Width - (TempX - X) - (IconToInfoSpacing * Width);

    // Select Text Color
    if ( CurIndex == MouseOverIndex )
        Canvas.SetDrawColor(255, 0, 0, 255);
    else Canvas.SetDrawColor(255, 255, 255, 255);

    // Draw the Perk's Level Name
    Canvas.StrLen(PerkName[CurIndex], TempWidth, TempHeight);
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawText(PerkName[CurIndex]);

    // Draw the Perk's Level
    if ( PerkLevelString[CurIndex] != "" )
    {
        Canvas.StrLen(PerkLevelString[CurIndex], TempWidth, TempHeight);
        Canvas.SetPos(TempX + ProgressBarWidth - TempWidth, TempY);
        Canvas.DrawText(PerkLevelString[CurIndex]);
    }

    TempY += TempHeight + (0.01 * Height);

    // Draw Progress Bar
    TempHeight = fmin(ProgressBarHeight*Height, Y + Height - ItemSpacing/2.0 - Height*(ItemBorder+ProgressBarBottomOffset) - TempY);
    TempY = Y + Height - ItemSpacing/2.0 - Height*(ItemBorder+ProgressBarBottomOffset) - TempHeight;
    Canvas.SetDrawColor(255, 255, 255, 255);
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawTileStretched(ProgressBarBackground, ProgressBarWidth, TempHeight);
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawTileStretched(ProgressBarForeground, ProgressBarWidth * PerkProgress[CurIndex], TempHeight);
}

defaultproperties
{
    ItemsPerPage=8 // reserve space for our lovely Gunslinger
    ProgressBarHeight=0.30
    ItemSpacing=8
    ItemBorder=0.02
    ProgressBarBottomOffset=0.1
}
