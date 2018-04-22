class ScrnTraderRequirementsList extends GUIVertList
dependson(ScrnBalance);

#exec OBJ LOAD FILE=ScrnTex.utx
#exec OBJ LOAD FILE=ScrnAch_T.utx

var array<int> LockIndex;
var protected GUIBuyable CurBuyable;
var ScrnClientPerkRepLink PerkLink;



// Settings
var()    float    ItemMargin;  // amount of pixels between left or right side of the list box and item border
var()    float    ItemSpacing; // amount of pixels between list items
var()    float    ItemPadding; // amount of pixels between item border and elements

var()    float    ProgressBarWidth;

// Display
var    texture    ItemBackground;
var    texture    ProgressBarBackground;
var    texture    ProgressBarForeground;


function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    OnDrawItem = DrawAchievement;
    Super.InitComponent(MyController, MyOwner);
}


function Display(GUIBuyable NewBuyable)
{
    PerkLink = Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerOwner());
    if ( CurBuyable != NewBuyable ) {
        CurBuyable = NewBuyable;
        UpdateList();
        SetIndex(0);
    }

    if ( MyScrollBar != none )
    {
        MyScrollBar.AlignThumb();
    }
}

function UpdateList()
{
    local int i;
    
    LockIndex.Length = 0;
    if ( PerkLink != none && CurBuyable != none && CurBuyable.ItemPickupClass != none ) {
        for ( i=0; i<PerkLink.Locks.length; ++i ) {
            if ( PerkLink.Locks[i].PickupClass == CurBuyable.ItemPickupClass )
                LockIndex[LockIndex.length] = i;
        }
    }
    ItemCount = LockIndex.Length;
}


function DrawAchievement(Canvas Canvas, int Index, float X, float Y, float Width, float Height, bool bSelected, bool bPending)
{
    local float TempX, TempY, TempWidth, TempHeight, IconSize, BarWidth, BarHeight;
    local float ClipX, ClipY;
    local string s;
    local Color TextColor; 

    Index = LockIndex[Index];
    // remember to restore those in the end
    ClipX = Canvas.ClipX;
    ClipY = Canvas.ClipY;
    // Initialize the Canvas
    Canvas.Style = 1;

    ItemMargin = default.ItemMargin;
    if ( Canvas.ClipY < 900 )
        ItemMargin /= 2;
    // Offset for the Background
    X += ItemMargin;
    Y += ItemSpacing / 2.0;
    Width -= ItemMargin * 2.0;
    Height -= ItemSpacing;
    // Draw Item Background
    Canvas.SetDrawColor(255, 255, 255, 192);
    Canvas.SetPos(X, Y);
    Canvas.DrawTileStretched(ItemBackground, Width, Height);
        
    if ( PerkLink.Locks[Index].CurProgress >= PerkLink.Locks[Index].MaxProgress ) {
        TextColor = Canvas.MakeColor(255, 255, 255, 255);
    }
    else {
        TextColor = Canvas.MakeColor(92, 92, 92, 255);
    }

    // Offset and Calculate Icon's Size
    TempX = X + ItemPadding;
    TempY = Y + ItemPadding;

    // Draw Icon
    Canvas.DrawColor = TextColor;
    IconSize = Height - 2.0*ItemPadding;
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawTile(PerkLink.Locks[Index].Icon, IconSize, IconSize, 0, 0, PerkLink.Locks[Index].Icon.MaterialUSize(), PerkLink.Locks[Index].Icon.MaterialVSize());

    TempX += IconSize + ItemPadding;

    //Draw the Display Name
    s = PerkLink.Locks[Index].Title;
    if ( PerkLink.Locks[Index].Group > 0 )
        s = "["$PerkLink.Locks[Index].Group$"] " $ s;
    Canvas.Font = class'ScrnHUD'.static.GetStaticFontSizeIndex(Canvas, -3);
    Canvas.TextSize("A", TempWidth, TempHeight);
    TempWidth = Width - IconSize - 3.0*ItemPadding;
    Canvas.SetClip(TempX + TempWidth, TempY + Height - ItemPadding);
    // shadow
    Canvas.SetDrawColor(0, 0, 0, 127);
    Canvas.SetPos(TempX+1, TempY+1);
    Canvas.DrawTextClipped(s);
    // real text
    Canvas.DrawColor = TextColor;
    Canvas.SetPos(TempX, TempY);
    Canvas.DrawTextClipped(s);
    
    //Draw the Description
    Canvas.SetClip(ClipX, ClipY); // always restore proper clipping before calling GetStaticFontSize
    Canvas.Font = class'ScrnHUD'.static.GetStaticFontSizeIndex(Canvas, -5);
    Canvas.SetOrigin(TempX, TempY);
    Canvas.SetClip(TempWidth, Height - ItemPadding);
    Canvas.SetPos(0, TempHeight + ItemPadding);
    Canvas.DrawText(PerkLink.Locks[Index].Text);
    // restore origin and clipping
    Canvas.SetOrigin(0, 0);
    Canvas.SetClip(TempX + TempWidth, TempY + Height - ItemPadding);
    
    if ( PerkLink.Locks[Index].MaxProgress > 1 && PerkLink.Locks[Index].CurProgress < PerkLink.Locks[Index].MaxProgress ) {
        // align top-right with title
        BarWidth = ProgressBarWidth * Width;
        BarHeight = TempHeight;
        TempX = X + Width - ItemPadding - BarWidth;
        TempY = Y + Height - ItemPadding - BarHeight;
        // Draw Progress Bar
        Canvas.SetPos(TempX, TempY);
        Canvas.DrawTileStretched(ProgressBarBackground, BarWidth, BarHeight);
        Canvas.SetPos(TempX + 3.0, TempY + 3.0);
        Canvas.DrawTileStretched(ProgressBarForeground, (BarWidth - 6.0) 
            * (float(PerkLink.Locks[Index].CurProgress) / float(PerkLink.Locks[Index].MaxProgress)), BarHeight - 6.0);
            
        // Draw Progress Text
        s = PerkLink.Locks[Index].CurProgress $"/"$ PerkLink.Locks[Index].MaxProgress;
        Canvas.Font = class'ScrnHUD'.static.GetStaticFontSizeIndex(Canvas, -3);
        Canvas.TextSize(s, TempWidth, TempHeight);
        TempX += (BarWidth - TempWidth )/2.0;
        TempY += (BarHeight - TempHeight )/2.0;
        // shadow
        Canvas.SetDrawColor(0, 0, 0, 127);
        Canvas.SetPos(TempX+1, TempY+1);
        Canvas.DrawText(s);
        // real text
        Canvas.SetDrawColor(160, 160, 160, 255);
        Canvas.SetPos(TempX, TempY);
        Canvas.DrawText(s);
    }
    Canvas.SetClip(ClipX, ClipY);
}

function float ListItemHeight(Canvas c)
{
    return (MenuOwner.ActualHeight() / 5.0) - 1.0;
}

defaultproperties
{
    ItemSpacing=6
    ItemMargin=8
    ItemPadding=8
    ProgressBarWidth=0.227000

    ItemBackground=Texture'KF_InterfaceArt_tex.Menu.Thin_border_SlightTransparent'
    ProgressBarBackground=Texture'KF_InterfaceArt_tex.Menu.Innerborder'
    ProgressBarForeground=Texture'InterfaceArt_tex.Menu.progress_bar'
    GetItemHeight=ScrnTraderRequirementsList.ListItemHeight
    FontScale=FNS_Small
}
