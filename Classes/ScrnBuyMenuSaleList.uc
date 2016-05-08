/*
 * List of Weapons avaliable for purchase
 */
 
 
class ScrnBuyMenuSaleList extends SRBuyMenuSaleList; 

var                 texture     ActiveGroupArrowLeft, ActiveGroupArrowRight;
var                 texture     GroupArrowLeft, GroupArrowRight;
var                 texture     GroupBackground;
var                  Color      GroupColor, ActiveGroupColor, SelectedGroupColor;

var                 bool        bMouseOverPrice;
var                 texture     PriceButton, PriceButtonDisabled, PriceButtonSelected;
var                 Color       PriceButtonColor, PriceButtonDisabledColor, PriceButtonSelectedColor;

var                 float       ItemXMargin; //Item margin in % of width

var                 float       PriceButtonWidthScale;

var                 int         InventoryCount;

var                 texture     FavoritesIcon;



// all update checks now are perfomed in ScrnTab_BuyMenu
function Timer()
{
    SetTimer(0, false);
}

event Opened(GUIComponent Sender)
{
    local ScrnHUD myHUD;
    
	super.Opened(Sender);

    // load config variables
	myHUD = ScrnHUD(PlayerOwner().myHUD);
    if ( myHUD != none ) {
        GroupColor = myHUD.TraderGroupColor;
        ActiveGroupColor = myHUD.TraderActiveGroupColor;
        SelectedGroupColor = myHUD.TraderSelectedGroupColor;
        PriceButtonColor = myHUD.TraderPriceButtonColor;
        PriceButtonDisabledColor = myHUD.TraderPriceButtonDisabledColor;
        PriceButtonSelectedColor = myHUD.TraderPriceButtonSelectedColor;
    }
}

//returns true also if any children of pickup class are found
function bool IsChildInInventory(class<Pickup> Item)
{
    local Inventory CurInv;

    for ( CurInv = PlayerOwner().Pawn.Inventory; CurInv != none; CurInv = CurInv.Inventory )
    {
        if ( ClassIsChildOf(CurInv.default.PickupClass, Item) )
        {
            return true;
        }
    }

    return false;
}


function UpdateForSaleBuyables()
{
    local class<KFVeterancyTypes> Perk;
    local KFPlayerReplicationInfo KFPRI;
    local ClientPerkRepLink CPRL;
    local GUIBuyable ForSaleBuyable;
    local class<KFWeaponPickup> ForSalePickup;
    local int j, i, z, Num;
    local class<KFWeapon> ForSaleWeapon;
    local float DualCoef; //if replaceable gun's price is different than 2x like in standard dualies
    local bool bHasDual;
    local ScrnHumanPawn ScrnPawn;
    local bool bVest;
    local int PerkedPos; //position after the last perked buyable to add new inventory there
    // vars below are used in vest price calculation
    local float Price1p;
    local int Cost, AmountToBuy;   
    local class<SRVeterancyTypes> Blocker;
    local KFShopVolume_Story CurrentShop;    
    local ScrnBalance Mut;
    local byte DLCLocked;
    local ScrnGUIBuyWeaponInfoPanel InfoPanel;

    // Clear the ForSaleBuyables array
    CopyAllBuyables();
    ForSaleBuyables.Length = 0;

    Mut = class'ScrnBalance'.static.Myself(PlayerOwner().Level);
    
    // Grab the items for sale
    CPRL = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());
    if( CPRL==None )
        return; // Hmmmm?
        
    if ( ScrnTab_BuyMenu(MenuOwner.MenuOwner) != none )
        InfoPanel = ScrnGUIBuyWeaponInfoPanel(ScrnTab_BuyMenu(MenuOwner.MenuOwner).ItemInfo);        

    // Grab Players Veterancy for quick reference
    if ( KFPlayerController(PlayerOwner()) != none )
        Perk = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).ClientVeteranSkill;
    if( Perk==None )
        Perk = class'KFVeterancyTypes';
    CurrentShop = GetCurrentShop();

    KFPRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);
    ScrnPawn = ScrnHumanPawn(PlayerOwner().Pawn);

    if( ActiveCategory>=-1 )
    {    
        // Grab the weapons!
        if( CurrentShop!=None )
            Num = CurrentShop.SaleItems.Length;
        else 
            Num = CPRL.ShopInventory.Length;
        for ( z=0; z<Num; z++ ) {
            //reset variables
            DualCoef = 1;
            bHasDual = false;
            
            // Use Story Mode shop, if defined, otherwise use classic level rules
            if( CurrentShop!=None )
            {
                // Allow story mode volume limit weapon availability.
                ForSalePickup = class<KFWeaponPickup>(CurrentShop.SaleItems[z]);
                if( ForSalePickup==None )
                    continue;
                for ( j=(CPRL.ShopInventory.Length-1); j>=CPRL.ShopInventory.Length; --j )
                    if( CPRL.ShopInventory[j].PC==ForSalePickup )
                        break;
                if( j<0 )
                    continue;
            }
            else
            {
                ForSalePickup = class<KFWeaponPickup>(CPRL.ShopInventory[z].PC);
                j = z;
            }

            if ( ForSalePickup==None || IsInInventory(ForSalePickup) )
                continue;
            if( ActiveCategory==-1 )
            {
                if( !Class'SRClientSettings'.Static.IsFavorite(ForSalePickup) )
                    continue;
            }
            else if( ActiveCategory!=CPRL.ShopInventory[j].CatNum )
                continue;
                
            ForSaleWeapon = class<KFWeapon>(ForSalePickup.default.InventoryType);
            if ( ForSaleWeapon != none && ForSaleWeapon.default.bKFNeverThrow )
                continue;
            
            bVest = ClassIsChildOf(ForSalePickup, class'ScrnBalanceSrv.ScrnVestPickup');
            if ( bVest ) {
                //vest
                if ( ScrnPawn == none || class<ScrnVestPickup>(ForSalePickup).default.ShieldCapacity <= 0
                        || (ScrnPawn.GetCurrentVestClass() == ForSalePickup && ScrnPawn.ShieldStrength >= ScrnPawn.GetShieldStrengthMax() ) )
                    continue; 
            }
            else if ( ForSaleWeapon != none ) {
                // Remove single weld.
                //Scrn pistols are linked through DemoReplacement, so no need to look for chilldren here
                if ( (ForSalePickup == class'DeaglePickup' && IsInInventory(class'DualDeaglePickup'))
                     || (ForSalePickup == class'Magnum44Pickup' && IsInInventory(class'Dual44MagnumPickup'))
                     || (ForSalePickup == class'MK23Pickup' && IsInInventory(class'DualMK23Pickup'))
                     || (ForSalePickup == class'FlareRevolverPickup' && IsInInventory(class'DualFlareRevolverPickup'))
                     || DualIsInInventory(ForSaleWeapon) )
                    continue;
                  
                // hide single and dual pistols, if player has laser variant
                if ( (ForSalePickup == class'Magnum44Pickup' || ForSalePickup == class'ScrnMagnum44Pickup'
                        || ForSalePickup == class'Dual44MagnumPickup' || ForSalePickup == class'ScrnDual44MagnumPickup')
                        && IsInInventory(class'ScrnDual44MagnumLaserPickup') )
                    continue;                
                if ( (ForSalePickup == class'MK23Pickup' || ForSalePickup == class'ScrnMK23Pickup'
                        || ForSalePickup == class'DualMK23Pickup' || ForSalePickup == class'ScrnDualMK23Pickup')
                        && IsInInventory(class'ScrnDualMK23LaserPickup') )
                    continue;

                // Make cheaper.
                if ( (ForSalePickup == class'DualDeaglePickup' && IsInInventory(class'DeaglePickup'))
                     || (ForSalePickup == class'Dual44MagnumPickup' && IsInInventory(class'Magnum44Pickup'))
                     || (ForSalePickup == class'DualMK23Pickup' && IsInInventory(class'MK23Pickup'))
                     || (ForSalePickup == class'DualFlareRevolverPickup' && IsInInventory(class'FlareRevolverPickup'))
                     || (ForSaleWeapon.Default.DemoReplacement!=None && IsInInventoryWep(ForSaleWeapon.Default.DemoReplacement)) ) {
                    DualCoef = 0.5;
                    bHasDual = true;
                }
            }

            Blocker = None;
            for( i=0; i<CPRL.CachePerks.Length; ++i )
                if( !CPRL.CachePerks[i].PerkClass.Static.AllowWeaponInTrader(ForSalePickup,KFPRI,CPRL.CachePerks[i].CurrentLevel) )
                {
                    Blocker = CPRL.CachePerks[i].PerkClass;
                    break;
                }
            if( Blocker!=None && Blocker.Default.DisableTag=="" )
                continue;

            ForSaleBuyable = AllocateEntry(CPRL);

            ForSaleBuyable.ItemName             = ForSalePickup.default.ItemName;
            ForSaleBuyable.ItemDescription      = ForSalePickup.default.Description;
            ForSaleBuyable.ItemCategorie        = "Melee"; // Dummy stuff..
            ForSaleBuyable.ItemAmmoCost         = 0;
            ForSaleBuyable.ItemFillAmmoCost     = 0;
            ForSaleBuyable.ItemPickupClass      = ForSalePickup;
            ForSaleBuyable.ItemWeaponClass      = ForSaleWeapon;
            ForSaleBuyable.ItemWeight           = ForSalePickup.default.Weight;
            if ( bVest ) {
                ForSaleBuyable.ItemImage        = class<ScrnVestPickup>(ForSalePickup).default.TraderInfoTexture;
                ScrnPawn.CalcVestCost(class<ScrnVestPickup>(ForSalePickup), Cost, AmountToBuy, Price1p);
                ForSaleBuyable.ItemCost         = Cost; 
                ForSaleBuyable.ItemWeight -= ScrnPawn.GetCurrentVestClass().default.Weight;
            } 
            else {
                ForSaleBuyable.ItemCost         = int( float(ForSalePickup.default.Cost)
                                                        * Perk.static.GetCostScaling(KFPRI, ForSalePickup) 
                                                        * DualCoef );
                if ( ForSaleWeapon != none ) {
                    ForSaleBuyable.ItemImage        = ForSaleWeapon.default.TraderInfoTexture;
                    ForSaleBuyable.ItemAmmoClass    = ForSaleWeapon.default.FireModeClass[0].default.AmmoClass;

                    ForSaleBuyable.ItemWeight       = ForSaleWeapon.default.Weight;

                    if( bHasDual ) {
                        if( ForSalePickup == Class'DualDeaglePickup' )
                            ForSaleBuyable.ItemWeight -= class'Deagle'.default.Weight;
                        else if( ForSalePickup == class'Dual44MagnumPickup' )
                            ForSaleBuyable.ItemWeight -= class'Magnum44Pistol'.default.Weight;
                        else if( ForSalePickup == class'DualMK23Pistol' )
                            ForSaleBuyable.ItemWeight -= class'MK23Pistol'.default.Weight;
                        else if( ForSalePickup == class'DualFlareRevolver' )
                            ForSaleBuyable.ItemWeight -= class'FlareRevolver'.default.Weight;
                        else ForSaleBuyable.ItemWeight -= Class<KFWeapon>(ForSaleWeapon.Default.DemoReplacement).Default.Weight;
                    }
                }
            }
            ForSaleBuyable.ItemPower            = ForSalePickup.default.PowerValue;
            ForSaleBuyable.ItemRange            = ForSalePickup.default.RangeValue;
            ForSaleBuyable.ItemSpeed            = ForSalePickup.default.SpeedValue;
            ForSaleBuyable.ItemAmmoCurrent      = 0;
            ForSaleBuyable.ItemAmmoMax          = 0;
            ForSaleBuyable.ItemPerkIndex        = ForSalePickup.default.CorrespondingPerkIndex;

            // Make sure we mark the list as a sale list
            ForSaleBuyable.bSaleList = true;

            // Sort same perk weapons in front.
            if( ForSalePickup.default.CorrespondingPerkIndex == Perk.default.PerkIndex ) {
                // fixed reverse order for perked inventory  -- PooSH
                i = PerkedPos++;
            }
            else {
                i = ForSaleBuyables.Length;
            }
            ForSaleBuyables.Insert(i, 1);
            ForSaleBuyables[i] = ForSaleBuyable;
            
            if ( Mut.bBeta )
                DLCLocked = 0;
            else
                DLCLocked = CPRL.ShopInventory[j].bDLCLocked;
            if( DLCLocked==0 && Blocker!=None )
            {
                ForSaleBuyable.ItemCategorie = Blocker.Default.DisableTag$":"$Blocker.Default.DisableDescription;
                DLCLocked = 3;
            }
            ForSaleBuyable.ItemAmmoCurrent = DLCLocked; // DLC info.    

            if ( InfoPanel != none ) {
                InfoPanel.LoadStats(ForSaleBuyable, 0, true);
                InfoPanel.LoadStats(ForSaleBuyable, 1, true);
            }
        }
    }

    // Now Update the list
    UpdateList();
}



// function bool PreDraw(Canvas Canvas)
// {
    // local result;
    
    // result = super.PreDraw(Canvas);
    // bMouseOverPrice =  IsMouseOverPrice();
    // return result;
// }


function DrawInvItem(Canvas Canvas, int CurIndex, float X, float Y, float Width, float Height, bool bSelected, bool bPending)
{
    local float TempX, TempY, TempHeight, TempWidth, IconSize;
    local float PriceLeft, PriceWidth;
    local float StringHeight, StringWidth;
    // local ClientPerkRepLink CPRL;
    local Material M, M2;
    local Color OriginalColor;
    local bool bGroup, bActiveGroup, bDisabled;

    OnClickSound = CS_Click;

    // Offset for the Background
    TempX = X;
    TempY = Y;
    TempHeight = Height - ItemSpacing;
    TempWidth = Width;

    // Initialize the Canvas
    Canvas.Style = 1;
    //Canvas.Font = class'ROHUD'.Static.GetSmallMenuFont(Canvas);
    Canvas.SetDrawColor(255, 255, 255, 255);
    OriginalColor = Canvas.DrawColor;

    bGroup = CanBuys[CurIndex] > 1;
    bActiveGroup = bGroup && (ActiveCategory == CanBuys[CurIndex] - 3); 
    bDisabled = CanBuys[CurIndex] == 0;

    if ( bGroup ) {
        // CATEGORY
        TempY += Height - TempHeight; // allign bottom
        IconSize = TempHeight - 4;

        // Background
        if ( bSelected )
            Canvas.DrawColor = SelectedGroupColor;
        else if ( bActiveGroup )
            Canvas.DrawColor = ActiveGroupColor;
        else
            Canvas.DrawColor = GroupColor;
        Canvas.SetPos(TempX, TempY);
        Canvas.DrawTileStretched(GroupBackground, TempWidth, TempHeight);
        Canvas.DrawColor = OriginalColor;
        
        // tree arrow
        Canvas.SetDrawColor(255, 255, 255, 128);
        Canvas.SetPos(TempX + 4, TempY + 2);
        if ( bActiveGroup ) {
            M = ActiveGroupArrowLeft;
            M2 = ActiveGroupArrowRight;
        }
        else {
            M = GroupArrowLeft;
            M2 = GroupArrowRight;
        }
        Canvas.SetPos(TempX, TempY);        
        Canvas.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
        Canvas.SetPos(TempX + TempWidth - IconSize - 4, TempY);        
        Canvas.DrawTile(M2, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
        Canvas.DrawColor = OriginalColor;
        
        // category name
        if ( CurIndex == MouseOverIndex )
            Canvas.SetDrawColor(255, 255, 255, 255);
        else
            Canvas.SetDrawColor(0, 0, 0, 255);    
        Canvas.StrLen(PrimaryStrings[CurIndex], StringWidth, StringHeight);
        Canvas.SetPos( TempX + (TempWidth - StringWidth)/2,  TempY + ((TempHeight - StringHeight) / 2)); // HCenter
        Canvas.DrawText(PrimaryStrings[CurIndex]);        
        
        // perk icon
        if ( CanBuys[CurIndex] == 2 )
            M = FavoritesIcon;
        else
            M = ListPerkIcons[CurIndex];
        if( M != None ) {
            Canvas.SetDrawColor(255, 255, 255, 255);
            Canvas.SetPos( TempX + (TempWidth - StringWidth)/2 - IconSize - 8,  TempY + ((TempHeight - IconSize) / 2)); // HCenter
            Canvas.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
            Canvas.SetPos( TempX + (TempWidth + StringWidth)/2 + 8,  TempY + ((TempHeight - IconSize) / 2)); // HCenter
            Canvas.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
        }        
    }
    else {
        // ITEM
        TempHeight += ItemSpacing/2; // less spacing between items
        TempY = Y; // align top
        TempWidth *= 1.0 - 2.0*ItemXMargin;
        IconSize = TempHeight - 4;

        // Background
        PriceWidth = Width * PriceButtonWidthScale;
        PriceLeft = TempX + TempWidth - PriceWidth;
        if ( bDisabled ) {
            M = DisabledItemBackgroundLeft;
            M2 = DisabledItemBackgroundRight;
        }
        else if ( bSelected ) {
            M = SelectedItemBackgroundLeft;
            M2 = SelectedItemBackgroundRight;
        }
        else {
            M = ItemBackgroundLeft;
            M2 = ItemBackgroundRight;
        }
        TempX = X + Width*ItemXMargin;
        Canvas.SetPos(TempX, TempY);
        Canvas.DrawTileStretched(M, TempHeight, TempHeight);
        Canvas.SetPos(TempX + TempHeight, TempY);
        Canvas.DrawTileStretched(M2, PriceLeft - TempX - TempHeight - 2, TempHeight);
        // price button
        if ( bDisabled ) {
            M = PriceButtonDisabled;
            Canvas.DrawColor = PriceButtonDisabledColor;
        }
        else if ( CurIndex == MouseOverIndex && IsMouseOverPrice() ) {
            M = PriceButtonSelected;
            Canvas.DrawColor = PriceButtonSelectedColor;
        }
        else {
            M = PriceButton;
            Canvas.DrawColor = PriceButtonColor;
            
        }        
        Canvas.SetPos(PriceLeft, TempY);
        Canvas.DrawTileStretched(M, PriceWidth, TempHeight);
        
        // item's perk icon
        // CPRL = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());
        // M = None;
        // if( CPRL!=None && ItemPerkIndexes[CurIndex] < CPRL.ShopPerkIcons.Length )
            // M = CPRL.ShopPerkIcons[ItemPerkIndexes[CurIndex]];
        M = ListPerkIcons[CurIndex];
        if ( M == None )
            M = NoPerkIcon;
        // v7
        if( M != None ) {
            Canvas.SetDrawColor(255, 255, 255, 255);
            Canvas.SetPos(TempX + 2, TempY + 2);
            Canvas.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
        }
            
        // item name
        if ( CurIndex == MouseOverIndex )
            Canvas.SetDrawColor(255, 255, 255, 255);
        else
            Canvas.SetDrawColor(0, 0, 0, 255);    
        Canvas.StrLen(PrimaryStrings[CurIndex], StringWidth, StringHeight);
        Canvas.SetPos(TempX + IconSize + 10, TempY + (TempHeight - StringHeight)/2);
        Canvas.DrawText(PrimaryStrings[CurIndex]);
        
        // item price
        Canvas.StrLen(SecondaryStrings[CurIndex], StringWidth, StringHeight);
        Canvas.SetPos(PriceLeft + (PriceWidth - StringWidth)/2, TempY + (TempHeight - StringHeight)/2);
        Canvas.DrawText(SecondaryStrings[CurIndex]);            
    }

    Canvas.DrawColor = OriginalColor;
}

function float SaleItemHeight(Canvas c)
{
    return (MenuOwner.ActualHeight() / ItemsPerPage - 1);
}

function bool GotoNextCategory()
{
    local int i;
    
    for ( i=Index+1; i<CanBuys.length; ++i ) {
        if ( CanBuys[i] > 1 ) {
            SetIndex(i);
            return true;
        }
    }
    return false;
}

function bool GotoPrevCategory()
{
    local int i;
    
    for ( i=Index-1; i>=0; --i ) {
        if ( CanBuys[i] > 1 ) {
            SetIndex(i);
            return true;
        }
    }
    return false;
}

function bool GotoNextItemInCategory()
{
    local int i;
    
    // special case when navigating from the very last item in the list
    if ( Index == CanBuys.length - 1 && CanBuys[Index] < 2)
        return GotoFirstItemInCategory();    
    
    for ( i=Index+1; i<CanBuys.length; ++i ) {
        if ( CanBuys[i] == 1 ) {
            SetIndex(i);
            return true;
        }
        else if ( CanBuys[i] >= 2 ) 
            return GotoFirstItemInCategory();        
    }
    return false;
}

function bool GotoPrevItemInCategory()
{
    local int i;
    
    for ( i=Index-1; i>=0; --i ) {
        if ( CanBuys[i] == 1 ) {
            SetIndex(i);
            return true;
        }
        else if ( CanBuys[i] >= 2 ) 
            return GotoLastItemInCategory();
    }
    return false;
}

function bool GotoLastItemInCategory()
{
    local int i;
    
    for ( i=CanBuys.length-1; i>=0; --i ) {
        if ( CanBuys[i] == 1 ) {
            SetIndex(i);
            return true;        
        }
    }
    return false;
}

function bool GotoFirstItemInCategory()
{
    local int i;
    
    for ( i=0; i<CanBuys.length; ++i ) {
        if ( CanBuys[i] == 1 ) {
            SetIndex(i);
            return true;    
        }
    }
    return false;
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if ( State == 1 ) { // key press
        if (Key >= 0x30 && Key <= 0x39) { // 0..9
            SetCategoryNum(Key - 0x31);
            return true;
        }
    
        switch (Key) {
            case 13: // enter
                if ( CanBuys[Index] > 1 )
                    SetCategoryNum(CanBuys[Index] - 3 ); // open/close group
                else
                    OnDblClick(Self); // buy item
                return true;
                break;
            case 33: // page up
                if ( GotoPrevCategory() )
                    SetCategoryNum(CanBuys[Index] - 3 );
                return true;
                break;        
            case 34: // page down
                if ( GotoNextCategory() )
                    SetCategoryNum(CanBuys[Index] - 3 );
                return true;
                break;
            case 35: // end
                if ( ItemCount > 0 ) {
                    if ( ActiveCategory == -2)
                        SetIndex(ItemCount-1);
                    else 
                        GotoLastItemInCategory();
                }
                return true;
                break;        
            case 36: // home
                if ( ActiveCategory == -2)
                    SetIndex(0);
                else
                    GotoFirstItemInCategory();
                return true;
                break;        
            case 37: // left
                if ( ActiveCategory > -2 )
                    SetCategoryNum(ActiveCategory);
                return true;
                break;    
            case 38: // up
                if ( ActiveCategory >= -1 ) {
                    // if category is open - navigate only through its items
                    // overwise - navigate through categories (native implementation)
                    GotoPrevItemInCategory();
                    return true;
                }            
                break;                    
            case 39: // right
                if ( ActiveCategory == -2 && CanBuys[Index] > 1 )
                    SetCategoryNum(CanBuys[Index] - 3 );
                return true;
                break;
            case 40: // down
                if ( ActiveCategory >= -1 ) {
                    // if category is open - navigate only through its items
                    // overwise - navigate through categories (native implementation)
                    GotoNextItemInCategory();
                    return true;
                }
                break;                    
        }
    }
    return super.InternalOnKeyEvent(Key, State, delta);
}

function bool IsMouseOverPrice()
{
    local float RelativeMouseX;
    
    RelativeMouseX =  Controller.MouseX - ClientBounds[0];
    
    return RelativeMouseX >=  ActualWidth() * (1.0 - PriceButtonWidthScale - ItemXMargin)
        && RelativeMouseX < ActualWidth() * (1.0 - ItemXMargin);
}

function bool InternalOnClick(GUIComponent Sender)
{
    local int NewIndex;
    
    
    if ( IsInClientBounds() && CanBuys.length > 0 ) {
        //  Figure out which Item we're clicking on
        NewIndex = CalculateIndex();    
        if ( NewIndex == -1 )
            return true;
            
        SetIndex(NewIndex);
        if ( CanBuys[NewIndex] >= 2 )
            SetCategoryNum(CanBuys[NewIndex] - 3 ); // clicked on group
        else if (IsMouseOverPrice())
            OnDblClick(Self); // buy item
    }
    return true;
}

defaultproperties
{
    FavoritesIcon=Texture'KillingFloor2HUD.Perk_Icons.Favorite_Perk_Icon'

    GroupArrowLeft=Texture'KF_InterfaceArt_tex.Menu.RightMark'
    ActiveGroupArrowLeft=Texture'KF_InterfaceArt_tex.Menu.DownMark'
    GroupArrowRight=Texture'KF_InterfaceArt_tex.Menu.LeftMark'
    ActiveGroupArrowRight=Texture'KF_InterfaceArt_tex.Menu.DownMark'
    GroupColor=(R=128,G=128,B=128,A=255)
    ActiveGroupColor=(R=192,G=192,B=255,A=255)
    SelectedGroupColor=(R=192,G=192,B=255,A=255)
    //SelectedGroupColor=(R=255,G=128,B=128,A=255)
    GroupBackground=Texture'KF_InterfaceArt_tex.Menu.Button'
    ItemsPerPage=14
    ItemXMargin=0.01
    ItemSpacing=8
    
    PriceButtonWidthScale=0.2
    PriceButton=Texture'KF_InterfaceArt_tex.Menu.Button'
    PriceButtonColor=(R=160,G=160,B=160,A=255)
    PriceButtonDisabled=Texture'KF_InterfaceArt_tex.Menu.button_Disabled'
    PriceButtonDisabledColor=(R=255,G=255,B=255,A=255)
    PriceButtonSelected=Texture'KF_InterfaceArt_tex.Menu.Button'
    PriceButtonSelectedColor=(R=255,G=128,B=160,A=255)
}
