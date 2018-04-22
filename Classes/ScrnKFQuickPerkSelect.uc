class ScrnKFQuickPerkSelect extends SRKFQuickPerkSelect;

function bool MyOnDraw(Canvas C)
{                                                                                                         
    local int i, j;
    local ClientPerkRepLink S;
    local Material M,SM;

    super(GUIMultiComponent).OnDraw(C);
    
    C.SetDrawColor(255, 255, 255, 255);
    
    // make em square
    if ( !bResized )
    {
        ResizeIcons(C);
    }    
        
    // Current perk background
    C.SetPos(WinLeft * C.ClipX , WinTop * C.ClipY);
    C.DrawTileScaled(CurPerkBack, (WinHeight * C.ClipY) / CurPerkBack.USize, (WinHeight * C.ClipY) / CurPerkBack.USize);

    S = Class'ScrnClientPerkRepLink'.Static.FindMe(C.Viewport.Actor);
    if( S!=None )
    {
        // check if the current perk has changed recently
        CheckPerksX(S);

        j = 0;
    
        // Draw the available perks
        for ( i=0; j < MaxPerks && i < S.CachePerks.length; i++ )
        {
            if ( i != CurPerk )
            {
                S.CachePerks[i].PerkClass.Static.PreDrawPerk(C,Max(S.CachePerks[i].CurrentLevel,1)-1,M,SM);
                PerkSelectIcons[j].Image = M;
                PerkSelectIcons[j].Index = i;
                PerkSelectIcons[j].ImageColor = C.DrawColor;
                PerkSelectIcons[j].ImageColor.A = 255;
                j++;
            }
        }
        for( i=j; i<ArrayCount(PerkSelectIcons); ++i )
        {
            PerkSelectIcons[i].Image = None;
            PerkSelectIcons[i].Index = -1;
        }

        // Draw current perk
        if( CurPerk!=255 )
            DrawCurrentPerkX(S, C, CurPerk);
    }
    
    return false;
}

function bool InternalOnClick(GUIComponent Sender)
{
    local ClientPerkRepLink L;

    if ( Sender.IsA('KFIndexedGUIImage') && KFIndexedGUIImage(Sender).Index>=0 )
    {
        L = Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerOwner());
        if ( L!=None ) {
            ScrnPlayerController(PlayerOwner()).SelectVeterancy(L.CachePerks[KFIndexedGUIImage(Sender).Index].PerkClass);
        }
        bPerkChange = true;
    }
    return false;    
}
