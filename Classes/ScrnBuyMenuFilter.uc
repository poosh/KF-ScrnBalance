// Mostly, copied from SRBuyMenuFilter. Not inherited due to "final" overuse
class ScrnBuyMenuFilter extends KFBuyMenuFilter;

var ScrnBuyMenuSaleList SaleListBox;
var array<KFIndexedGUIImage> CatButtons;
var array<GUIImage> CatBG;
var() Texture NonSelectedBack;
var int OldPerkIndex,OldGroupIndex;
var bool bHasInit;

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    Super(GUIMultiComponent).InitComponent(MyController, MyOwner);
    if( !bHasInit )
        UpdatePerkIcons();
}

event Opened(GUIComponent Sender)
{
    super(GUIMultiComponent).Opened( Sender );
    if( !bHasInit )
        UpdatePerkIcons();
}

function KFIndexedGUIImage AddButton( int Index )
{
    local KFIndexedGUIImage S;
    local GUIImage B;

    if (CatButtons.Length >= MaxPerks)
        return None;

    S = KFIndexedGUIImage(AddComponent(string(Class'KFIndexedGUIImage')));
    S.WinWidth = BoxSizeX;
    S.WinHeight = BoxSizeY;
    S.WinLeft = 0.98;
    S.WinTop = 0.052;
    S.ImageStyle = ISTY_Scaled;
    S.Renderweight = 0.6;
    S.OnClick = InternalOnClick;
    S.Index = Index;
    S.bBoundToParent = true;
    CatButtons[CatButtons.Length] = S;

    B = GUIImage(AddComponent(string(Class'GUIImage')));
    B.WinWidth = BoxSizeX;
    B.WinHeight = BoxSizeY;
    B.WinLeft = 0.98;
    B.WinTop = 0.05;
    B.Image = NonSelectedBack;
    B.ImageStyle = ISTY_Scaled;
    B.Renderweight = 0.5;
    B.bBoundToParent = true;
    CatBG[CatBG.Length] = B;

    return S;
}

function UpdatePerkIcons()
{
    local ClientPerkRepLink CPRL;
    local int i,j,Index;
    local KFIndexedGUIImage S;

    CPRL = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());
    if( CPRL==None || !CPRL.bRepCompleted )
        return;
    bHasInit = true;

    AddButton(-1); // Add favorites button.
    for( i=0; i<CPRL.ShopCategories.Length; ++i )
    {
        Index = CPRL.ShopCategories[i].PerkIndex;
        if( Index<CPRL.ShopPerkIcons.Length )
        {
            for( j=(CatButtons.Length-1); j>=0; --j )
                if( CatButtons[j].Index==Index )
                    break;
            if( j>=0 )
                continue; // Already added.

            S = AddButton(Index);
            if( S==None )
                continue;

            for( j=(CPRL.CachePerks.Length-1); j>=0; --j )
                if( Index==CPRL.CachePerks[j].PerkClass.Default.PerkIndex )
                {
                    S.Hint = CPRL.CachePerks[j].PerkClass.Default.VeterancyName;
                    S.Image = CPRL.CachePerks[j].PerkClass.Default.OnHUDIcon;
                    break;
                }

            if( j==-1 )
            {
                S.Hint = Class'KFBuyMenuFilter'.Default.PerkSelectIcon7.Hint;
                S.Image = NoPerkIcon;
            }
        }
    }

    // Name em approprietly.
    CatButtons[0].Hint = Class'KFBuyMenuFilter'.Default.PerkSelectIcon8.Hint;
    CatButtons[0].Image = FavoritesIcon;
    bResized = false;
}

function int GroupToPerkIndex( int In )
{
    return Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner()).ShopCategories[In].PerkIndex;
}

function bool MyOnDraw(Canvas C)
{
    local int i,CurIndex,CurGroup;
    local KFPlayerReplicationInfo KFPRI;

    if( !bHasInit )
    {
        UpdatePerkIcons();
        if( !bHasInit )
            return false;
    }

    // make em square
    if ( !bResized )
    {
        ResizeIcons(C);
        RealignIcons();
    }

    KFPRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);
    CurIndex = -2;
    if( KFPRI!=None && KFPRI.ClientVeteranSkill!=None )
        CurIndex = KFPRI.ClientVeteranSkill.Default.PerkIndex;

    CurGroup = SaleListBox.ActiveCategory;

    if( OldPerkIndex!=CurIndex || OldGroupIndex!=CurGroup )
    {
        OldPerkIndex = CurIndex;
        OldGroupIndex = CurGroup;
        if( CurGroup>=0 )
            CurGroup = GroupToPerkIndex(CurGroup);

        // Draw the available perks
        for( i=0; i<CatButtons.Length; ++i )
        {
            // Check if current perk player uses now.
            if( CatButtons[i].Index==CurIndex )
                CatButtons[i].ImageColor.A = 255;
            else CatButtons[i].ImageColor.A = 95;

            // Check if corresponding group index is open on buy menu.
            if( CatButtons[i].Index==CurGroup )
                CatBG[i].Image = CurPerkBack;
            else CatBG[i].Image = NonSelectedBack;
        }
    }
    return false;
}

function int GetNextCategory( int Index )
{
    local ClientPerkRepLink C;
    local int i,First;
    local bool bFoundCurrent;

    C = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());
    First = -1;
    for( i=0; i<C.ShopCategories.Length; ++i )
    {
        if( Index==C.ShopCategories[i].PerkIndex )
        {
            if( First==-1 )
                First = i;
            if( OldGroupIndex==i )
                bFoundCurrent = true;
            else if( bFoundCurrent )
                return i;
        }
    }
    return First;
}
function bool InternalOnClick(GUIComponent Sender)
{
    local int Index;

    if ( Sender.IsA('KFIndexedGUIImage') )
    {
        Index = KFIndexedGUIImage(Sender).Index;
        if( Index>=0 )
            Index = GetNextCategory(Index);
        SaleListBox.SetCategoryNum(Index,true);
    }
    return false;
}

function ResizeIcons(Canvas C)
{
    local int i;

    BoxSizeY = fmin(1.0 / CatButtons.Length, default.BoxSizeY);
    BoxSizeX *= C.ClipY / C.ClipX;

    for (i=0; i<CatButtons.Length; ++i) {
        CatButtons[i].WinWidth = BoxSizeX;
        CatButtons[i].WinHeight = BoxSizeY;
        CatBG[i].WinWidth = BoxSizeX;
        CatBG[i].WinHeight = BoxSizeY;
    }
    bResized = true;
}

function RealignIcons()
{
    local int i;
    local float TotalWidth, IconPadding, x;

    TotalWidth = BoxSizeX * CatButtons.Length;
    IconPadding = (1.0 - TotalWidth) / CatButtons.Length;

    x = IconPadding / 2.0;
    for (i = 0; i < CatButtons.Length; ++i) {
        CatButtons[i].WinLeft = x;
        CatBG[i].WinLeft = x;
        x += BoxSizeX + IconPadding;
    }
}

defaultproperties
{
    MaxPerks=12

    NonSelectedBack=Texture'KF_InterfaceArt_tex.Menu.Perk_box_unselected'
    OldPerkIndex=9999
    OldGroupIndex=9999

    PerkBack0=None
    PerkBack1=None
    PerkBack2=None
    PerkBack3=None
    PerkBack4=None
    PerkBack5=None
    PerkBack6=None
    PerkBack7=None
    PerkBack8=None

    PerkSelectIcon0=None
    PerkSelectIcon1=None
    PerkSelectIcon2=None
    PerkSelectIcon3=None
    PerkSelectIcon4=None
    PerkSelectIcon5=None
    PerkSelectIcon6=None
    PerkSelectIcon7=None
    PerkSelectIcon8=None
}