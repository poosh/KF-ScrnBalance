class ScrnAchievementsList extends GUIVertList;

// Settings
var()    float    OuterBorder;
var()    float    ItemBorder;
var()    float    TextTopOffset;
var()    float    ItemSpacing;
var()    float    IconToNameSpacing;
var()    float    NameToDescriptionSpacing;
var()    float    ProgressBarWidth;
var()    float    ProgressBarHeight;
var()    float    ProgressTextSpacing;
var()    float    TextHeight, TextWidth;

// Display
var    texture    ItemBackground;
var    texture    ProgressBarBackground;
var    texture    ProgressBarForeground;

// State
var ClientPerkRepLink MyClientPerkRepLink;
var array<ScrnAchievements> AchievementHandlers;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    OnDrawItem = DrawAchievement;
    Super.InitComponent(MyController, MyOwner);
}

function Closed(GUIComponent Sender, bool bCancelled)
{
    MyClientPerkRepLink = none;

    super.Closed(Sender, bCancelled);
}

function InitList(ClientPerkRepLink L, optional name GroupName, optional bool bOnlyLocked)
{
    //log("ScrnAchievementsList.InitList", 'ScrnBalance');
    // Hold onto our reference
    MyClientPerkRepLink = L;

    // Update the ItemCount and select the first item
    ItemCount = class'ScrnBalanceSrv.ScrnAchievements'.static.GetAllAchievements(
        L, AchievementHandlers, class'ScrnBalance'.default.Mut.AchievementFlags
        ,GroupName, bOnlyLocked);
    SetIndex(0);

    if ( bNotify )
     {
        CheckLinkedObjects(Self);
    }

    if ( MyScrollBar != none )
    {
        MyScrollBar.AlignThumb();
    }
}

// returns AchHandler and AchIndex of the given ListIndex
function bool ListIndexToAch(int ListIndex, out ScrnAchievements AchHandler, out int AchIndex)
{
    local int i, vCount;
    
    for ( i=0; i < AchievementHandlers.Length; ++i ) {
        vCount = AchievementHandlers[i].GetVisibleAchCount();
        if ( ListIndex < vCount ) {
            AchIndex = AchievementHandlers[i].GetVisibleAchIndex(ListIndex);
            if ( AchIndex == -1 )
                return false;
            AchHandler = AchievementHandlers[i];
            return true;
        }
        else
            ListIndex -= vCount;
    }
}

function DrawAchievement(Canvas Canvas, int Index, float X, float Y, float Width, float Height, bool bSelected, bool bPending)
{
    local float TempX, TempY, BarX, BarY;
    //local float OrgX, ClipX, ClipY;
    local float IconSize;
    local string ProgressString;
    local eMenuState TextStyle;
    local ScrnAchievements AchHandler;
    local int AchIndex;

    // Offset for the Background
    TempX = X + OuterBorder * Width;
    TempY = Y + ItemSpacing / 2.0;

    // Initialize the Canvas
    Canvas.Style = 1;

    // Draw Item Background
    Canvas.SetDrawColor(255, 255, 255, 192);
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawTileStretched(ItemBackground, Width - (OuterBorder * Width * 2.0), Height - ItemSpacing);
    
    if ( !ListIndexToAch(Index, AchHandler, AchIndex) )
        return; //wtf?
        
    if ( AchHandler.IsUnlocked(AchIndex) ) {
        Canvas.SetDrawColor(255, 255, 255, 255);
        TextStyle = MSAT_Blurry;
    }
    else {
        Canvas.SetDrawColor(127, 127, 127, 255);
        TextStyle = MSAT_Disabled;
    }

    // Offset and Calculate Icon's Size
    TempX += ItemBorder * Height;
    TempY += ItemBorder * Height;
    IconSize = Height - ItemSpacing - (ItemBorder * Height * 2.0);

    // Draw Icon
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawTile(AchHandler.GetIcon(AchIndex), IconSize, IconSize, 0, 0, 64, 64);

    TempX += IconSize + IconToNameSpacing * Width;
    TempY += TextTopOffset * Height;

    BarY = TempY;
    //Draw the Display Name
    SectionStyle.DrawText(Canvas, TextStyle, TempX, TempY, Width * TextWidth, TextHeight * Height, TXTA_Left, AchHandler.AchDefs[AchIndex].DisplayName, FNS_Medium);
    //Draw the Description
    TempY += (TextHeight + NameToDescriptionSpacing) * Height;
    SectionStyle.DrawText(Canvas, TextStyle, TempX, TempY, Width * TextWidth, Height*0.5, TXTA_Left, 
        AchHandler.AchDefs[AchIndex].Description, FNS_Small); 
     
    // OrgX = Canvas.OrgX;        
    // ClipX = Canvas.ClipX;        
    // ClipY = Canvas.ClipY;        
    
    
    // Canvas.SetPos(TempX, TempY);
    // Canvas.OrgX = TempX;
    // Canvas.ClipX = Width - OuterBorder * Width;
    // Canvas.ClipY = Height - (Y + ItemSpacing*2.0);
    // Canvas.DrawText( AchHandler.AchDefs[AchIndex].Description);
    
    // Canvas.OrgX = OrgX;        
    // Canvas.ClipX = ClipX;        
    // Canvas.ClipY = ClipY;       
    
    if ( AchHandler.AchDefs[AchIndex].MaxProgress > 1 && !AchHandler.IsUnlocked(AchIndex) ) {
        // Show  progress
        BarX = X + Width - (OuterBorder * Width) - (ItemBorder * Height * 2.0) - (ProgressBarWidth * Width);

        // Draw Progress Bar
        Canvas.SetPos(BarX, BarY);
        Canvas.DrawTileStretched(ProgressBarBackground, ProgressBarWidth * Width, ProgressBarHeight * Height);
        Canvas.SetPos(BarX + 3.0, BarY + 3.0);
        if ( AchHandler.AchDefs[AchIndex].CurrentProgress < AchHandler.AchDefs[AchIndex].MaxProgress )
        {
            Canvas.DrawTileStretched(ProgressBarForeground, ((ProgressBarWidth * Width) - 6.0) * (float(AchHandler.AchDefs[AchIndex].CurrentProgress) / float(AchHandler.AchDefs[AchIndex].MaxProgress)), ProgressBarHeight * Height - 6.0);
        }
        else
        {
            Canvas.DrawTileStretched(ProgressBarForeground, ProgressBarWidth * Width - 6.0, ProgressBarHeight * Height - 6.0);
        }

        // Draw Progress Text
        ProgressString = AchHandler.AchDefs[AchIndex].CurrentProgress $"/"$ AchHandler.AchDefs[AchIndex].MaxProgress;
        //SectionStyle.DrawText(Canvas, MSAT_Blurry, BarX - 150 - (ProgressTextSpacing * Width), BarY, 150, (TextHeight * Height), TXTA_Right, ProgressString, FNS_Medium);
        SectionStyle.DrawText(Canvas, MSAT_Blurry, BarX, BarY, ProgressBarWidth * Width, (ProgressBarHeight * Height), TXTA_Center, ProgressString, FNS_Medium);
    }

}

function float AchievementHeight(Canvas c)
{
    return (MenuOwner.ActualHeight() / 8.0) - 1.0;
}

defaultproperties
{
     OuterBorder=0.015000
     ItemBorder=0.050000
     TextTopOffset=0.082000
     ItemSpacing=3.000000
     IconToNameSpacing=0.018000
     NameToDescriptionSpacing=0.040000
     ProgressBarWidth=0.227000
     ProgressBarHeight=0.35 // 0.225
     ProgressTextSpacing=0.009000
     TextHeight=0.300000
     TextWidth=0.850000
     ItemBackground=Texture'KF_InterfaceArt_tex.Menu.Thin_border_SlightTransparent'
     ProgressBarBackground=Texture'KF_InterfaceArt_tex.Menu.Innerborder'
     ProgressBarForeground=Texture'InterfaceArt_tex.Menu.progress_bar'
     GetItemHeight=ScrnAchievementsList.AchievementHeight
     FontScale=FNS_Medium
}
