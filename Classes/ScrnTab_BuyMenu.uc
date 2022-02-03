class ScrnTab_BuyMenu extends SRKFTab_BuyMenu;

var protected int LastDosh, LastInvCount, LastAmmoCount, LastShieldStrength,  LastPerkLevel;
var protected class<KFVeterancyTypes> LastPerk;
var protected class<ScrnVestPickup> LastVestClass;

var protected float LastAutoFillTime;

var automated   GUIButton                       RefreshButton;

var protected transient bool bJustOpened;

var automated   ScrnTraderRequirementsListBox   ItemRequirements;
var localized string strSelectedItemRequirements;
var localized string strIntoScrnLocked;
var byte InfoPageNum, ForceInfoPageNum;
var localized string SaleButtonCaption, strSale0, strNoSale;

var transient ScrnClientPerkRepLink PerkLink;
var transient KFPlayerReplicationInfo KFPRI;

var private transient bool bOnAnyChangeInProgress;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local ScrnBuyMenuInvList ScrnInvList;

    Super.InitComponent(MyController, MyOwner);

    ScrnInvList = ScrnBuyMenuInvList(InvSelect.List);
    ScrnInvList.OnSellClick = SellBuyable;
}

function ShowPanel(bool bShow)
{
    super(UT2K4TabPanel).ShowPanel(bShow);

    if ( !bShow ) {
        SetTimer(0, false);
        return;
    }
    KFPRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);
    PerkLink = Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerOwner());
    bJustOpened = true;
    bClosed = false;
    LastInvCount = -1; // force item update on timer
    SetTimer(0.1, true);

    ResetInfo();
    TheBuyable = none;

    /*
    if ( InvSelect.List.MyBuyables.Length > 0 ) {
        for ( i = 0; i < InvSelect.List.MyBuyables.Length; i++ ) {
            if ( InvSelect.List.MyBuyables[i] != none && (InvSelect.List.MyBuyables[i].ItemWeaponClass == class'Single' ||
                    InvSelect.List.MyBuyables[i].ItemWeaponClass == class'Dualies') ) {
                TheBuyable = InvSelect.List.MyBuyables[i];
                InvSelect.List.Index = i;
                break;
            }
        }
    }

    if ( KFPlayerController(PlayerOwner()) != none )
        KFPlayerController(PlayerOwner()).bDoTraderUpdate = true;
    */

    LastBuyable = TheBuyable;

    InvSelect.SetPosition(InvBG.WinLeft + 7.0 / float(Controller.ResX),
                          InvBG.WinTop + 55.0 / float(Controller.ResY),
                          InvBG.WinWidth - 15.0 / float(Controller.ResX),
                          InvBG.WinHeight - 45.0 / float(Controller.ResY),
                          true);

    SaleSelect.SetPosition(SaleBG.WinLeft + 7.0 / float(Controller.ResX),
                           SaleBG.WinTop + 55.0 / float(Controller.ResY),
                           SaleBG.WinWidth - 15.0 / float(Controller.ResX),
                           SaleBG.WinHeight - 63.0 / float(Controller.ResY),
                           true);
}


//overloaded to show Item description -- PooSH
function SetInfoText()
{
    local string TempString;

    if ( TheBuyable == none && !bDidBuyableUpdate )
    {
        InfoScrollText.SetContent(InfoText[0]);
        bDidBuyableUpdate = true;

        return;
    }

    if ( TheBuyable != none && OldPickupClass != TheBuyable.ItemPickupClass )
    {
        if ( InfoPageNum == 1 ) {
            // Custom lock
            InfoScrollText.SetContent(strIntoScrnLocked);
        }
        else if ( TheBuyable.ItemCost > PlayerOwner().PlayerReplicationInfo.Score && TheBuyable.bSaleList )
        {
            // Too expensive
            InfoScrollText.SetContent(InfoText[2]);
        }
        else if ( TheBuyable.bSaleList && TheBuyable.ItemWeight + KFHumanPawn(PlayerOwner().Pawn).CurrentWeight > KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight )
        {
            // Too heavy
            TempString = Repl(Infotext[1], "%1", int(TheBuyable.ItemWeight));
            TempString = Repl(TempString, "%2", int(KFHumanPawn(PlayerOwner().Pawn).MaxCarryWeight - KFHumanPawn(PlayerOwner().Pawn).CurrentWeight));
            InfoScrollText.SetContent(TempString);
        }
        else {
            //show idem description, if it is avaliable for buying -- PooSH
            InfoScrollText.SetContent(TheBuyable.ItemDescription);
        }

        bDidBuyableUpdate = false;
        OldPickupClass = TheBuyable.ItemPickupClass;
    }
}

function DoBuyKevlar()
{
    local KFPawn KFP;

    KFP = KFPawn(PlayerOwner().Pawn);
    if ( KFP != none && KFP.ShieldStrength < KFP.GetShieldStrengthMax() ) {
        KFP.ServerBuyKevlar();
        MakeSomeBuyNoise(class'Vest');
    }
}

function DoBuy()
{
    if ( TheBuyable != none && KFPawn(PlayerOwner().Pawn) != none && TheBuyable.ItemPickupClass != none ) {
        if ( ClassIsChildOf(TheBuyable.ItemPickupClass, class'ScrnVestPickup') ) {
            if ( ScrnHumanPawn(PlayerOwner().Pawn) != none ) {
                ScrnHumanPawn(PlayerOwner().Pawn).ServerBuyShield(class<ScrnVestPickup>(TheBuyable.ItemPickupClass));
                MakeSomeBuyNoise(class'Vest');
            }
        }
        else if (TheBuyable.ItemWeaponClass != none ){
            KFPawn(PlayerOwner().Pawn).ServerBuyWeapon(TheBuyable.ItemWeaponClass, 0);
            MakeSomeBuyNoise();
        }

        SaleSelect.List.Index = -1;
        TheBuyable = none;
        LastBuyable = none;
    }
}

function SaleChange(GUIComponent Sender)
{
    InvSelect.List.Index = -1;

    TheBuyable = SaleSelect.GetSelectedBuyable();

    if( TheBuyable==None ) // Selected category.
    {
        GUIBuyMenu(OwnerPage()).WeightBar.NewBoxes = 0;
        // if( SaleSelect.List.Index>=0 && SaleSelect.List.CanBuys[SaleSelect.List.Index]>1 )
        // {
            // DO NOT automatically open category - in cases user navigates buy arrow keys
            //SRBuyMenuSaleList(SaleSelect.List).SetCategoryNum(SaleSelect.List.CanBuys[SaleSelect.List.Index]-3);
        // }
    }
    else GUIBuyMenu(OwnerPage()).WeightBar.NewBoxes = TheBuyable.ItemWeight;
    OnAnychange();
}

function OnAnychange()
{
    if ( bOnAnyChangeInProgress )
        return; // prevent recursion
    bOnAnyChangeInProgress = true;

    RefreshSelection();
    if ( LastBuyable != TheBuyable ) {
        LastBuyable = TheBuyable;
        ForceInfoPageNum = 255;
    }
    // ItemAmmoCurrent of items for sale stores DLCLocked value
    // DLCLocked = 5 for ScrN locks
    if ( TheBuyable != none && TheBuyable.bSaleList && ForceInfoPageNum != 0
            && (ForceInfoPageNum == 1 || TheBuyable.ItemAmmoCurrent == 5) )
    {
        ItemRequirements.List.Display(TheBuyable);
        ItemRequirements.SetVisibility(true);
        ItemInfo.SetVisibility(false);
        SelectedItemLabel.Caption = strSelectedItemRequirements;
        InfoPageNum = 1;
    }
    else {
        if (TheBuyable != none && TheBuyable.bIsVest && !TheBuyable.bSaleList) {
            ScrnBuyMenuSaleList(SaleSelect.List).SelectVestCategory();
            TheBuyable = LastBuyable;
        }
        ItemInfo.Display(TheBuyable);
        ItemRequirements.SetVisibility(false);
        ItemInfo.SetVisibility(true);
        SelectedItemLabel.Caption = default.SelectedItemLabel.Caption;
        InfoPageNum = 0;
    }
    SetInfoText();
    UpdatePanel();
    UpdateBuySellButtons();

    bOnAnyChangeInProgress = false;
}

function UpdateBuySellButtons()
{
    super.UpdateBuySellButtons();

    if ( SaleButton.MenuState == MSAT_Disabled || TheBuyable == none ) {
        SaleButton.Caption = strNoSale;
    }
    else if ( TheBuyable.bIsVest ) {
        SaleButton.Caption = ScrnHumanPawn(PlayerOwner().Pawn).LightVestClass.default.ItemName;
    }
    else if ( TheBuyable.ItemSellValue <= 0 ) {
        SaleButton.Caption = strSale0;
    }
    else {
        SaleButton.Caption = SaleButtonCaption;
    }
}

function ResetInfo()
{
    ScrnGUIBuyWeaponInfoPanel(ItemInfo).ResetValues();
}

// calculates inventory item count and total ammo count.
function MyInventoryStats(out int ItemCount, out int TotalAmmoAmount)
{
    local Inventory Inv;

    ItemCount = 0;
    TotalAmmoAmount = 0;

    if ( PlayerOwner().Pawn == none )
        return; // wtf?

    // limit to 1000 to prevent circular loops
    for ( Inv = PlayerOwner().Pawn.Inventory; Inv != none && ItemCount < 1000 ; Inv = Inv.Inventory ) {
        ItemCount++;
        if ( Ammunition(Inv) != none )
            TotalAmmoAmount += Ammunition(Inv).AmmoAmount;
    }
}

function Timer()
{
    MoneyLabel.Caption = MoneyCaption $ int(PlayerOwner().PlayerReplicationInfo.Score);

    if ( bClosed ) {
        SetTimer(0, false);
    }
    else if ( bJustOpened ) {
        UpdateAll();
        SetFocus(SaleSelect.List);
        if ( SaleSelect.List.ItemCount > 0 && SaleSelect.List.Index == -1 )
            SaleSelect.List.SetIndex(0);
        bJustOpened = false;
    }
    else {
        UpdateCheck();
    }
}

// update lists in inventory count or score (money) is changed
// if ammo count changed - update ammo only without rebuilding the list
function UpdateCheck()
{
    local int MyInvCount, MyAmmoCount;

    MyInventoryStats(MyInvCount, MyAmmoCount);
    // ignore KFPC.bDoTraderUpdate and do it the right way
    if ( LastDosh != int(PlayerOwner().PlayerReplicationInfo.Score)
            || LastPerk != KFPRI.ClientVeteranSkill
            || LastPerkLevel != KFPRI.ClientVeteranSkillLevel
            || LastInvCount != MyInvCount
            || (ScrnHumanPawn(PlayerOwner().Pawn) != none
                && LastVestClass != ScrnHumanPawn(PlayerOwner().Pawn).GetCurrentVestClass()) )
    {
        UpdateAll();
    }
    else if ( LastAmmoCount != MyAmmoCount || LastShieldStrength != PlayerOwner().Pawn.ShieldStrength ) {
        // no need to update inventory list, just update the ammo values
        UpdateAmmo();
        LastAmmoCount = MyAmmoCount;
        LastShieldStrength = PlayerOwner().Pawn.ShieldStrength;
    }

}

function UpdateAll()
{
    if ( PerkLink != none )
        PerkLink.ParseLocks();
    super.UpdateAll();
    LastDosh = int(PlayerOwner().PlayerReplicationInfo.Score);
    LastPerk = KFPRI.ClientVeteranSkill;
    LastPerkLevel = KFPRI.ClientVeteranSkillLevel;
    MyInventoryStats(LastInvCount, LastAmmoCount);
    LastShieldStrength = PlayerOwner().Pawn.ShieldStrength;
    if ( ScrnHumanPawn(PlayerOwner().Pawn) != none )
        LastVestClass = ScrnHumanPawn(PlayerOwner().Pawn).GetCurrentVestClass();
}

function UpdateAmmo()
{
    ScrnBuyMenuInvList(InvSelect.List).UpdateMyAmmo();

    RefreshSelection();
    GetUpdatedBuyable();
    UpdatePanel();
}


// removed MyAmmos and UpdateMyBuyables() call
function UpdateAutoFillAmmo()
{
    AutoFillButton.Caption = AutoFillString @ "(" $ class'ScrnUnicode'.default.Dosh $ int(InvSelect.List.AutoFillCost)$")";

    if ( int(InvSelect.List.AutoFillCost) < 1 )
        AutoFillButton.DisableMe();
    else
        AutoFillButton.EnableMe();
}

// Fills the ammo of all weapons in the inv to the max
// Just cycles though the my buyables and buys ammo.
// Would you make gay love to neighboor's donkey, just because your code still works after that?.. But I know a company that does.
function DoFillAllAmmo()
{
    local int i;
    local GUIBuyable MyBuyable;
    local byte PassNo;
    local bool bBoughtSomething;
    local bool bForceBuy;
    // if player second time clicked on this button, be he probably REALY NEEDS TO BUY THOSE GOD DAMNED FRAGS!!!
    // not to wait for data replication
    bForceBuy = PlayerOwner().Level.TimeSeconds - LastAutoFillTime < 3;

    While ( PassNo < 2 && !bBoughtSomething ) {
        bBoughtSomething = false;
        for ( i = 0; i < InvSelect.List.MyBuyables.Length; i++ ) {
            MyBuyable = InvSelect.List.MyBuyables[i];
            if ( MyBuyable == none || MyBuyable.ItemAmmoClass == none )
                continue;

            if ( !bForceBuy && PassNo == 0 ) {
                if ( ClassIsChildOf(MyBuyable.ItemAmmoClass, class'FragAmmo')
                        || ClassIsChildOf(MyBuyable.ItemAmmoClass, class'PipeBombAmmo')
                        || ClassIsChildOf(MyBuyable.ItemAmmoClass, class'ToiletPaperAmmo') )
                    continue; // don't buy expensive ammunition at first pass
            }

            if ( MyBuyable.ItemAmmoCurrent < MyBuyable.ItemAmmoMax ) {
                bBoughtSomething = true;
                KFPawn(PlayerOwner().Pawn).ServerBuyAmmo(MyBuyable.ItemAmmoClass, false);
            }
        }
        PassNo++;
    }
    UpdateAmmo();
    LastAutoFillTime = PlayerOwner().Level.TimeSeconds;
}

function SellBuyable(GUIBuyable item) {
    if ( item != none ) {
        TheBuyable = item;
        DoSell();
    }
}

function DoSell()
{
    local ScrnHumanPawn ScrnPawn;

    if ( TheBuyable == none )
        return;

    if ( TheBuyable.bIsVest ) {
        ScrnPawn = ScrnHumanPawn(PlayerOwner().Pawn);
        // there is no reason to sell the light armor as it has no weight.
        // So instead of selling armor, buy the light one
        if ( ScrnPawn != none ) {
            ScrnPawn.ServerBuyShield(ScrnPawn.LightVestClass);
            MakeSomeBuyNoise(class'Vest');
        }
    }
    else {
        super.DoSell();
    }
}

function bool InternalOnClick(GUIComponent Sender)
{
    switch ( Sender ) {
        case RefreshButton:
            ResetInfo();
            UpdateAll();
            break;

        default:
            return super.InternalOnClick(Sender);
    }
    return true;
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if ( State == 1 ) { // key press
        switch ( Key ) {
            case 0x70: // IK_F1
                Controller.PlayInterfaceSound(CS_Click);
                SetFocus(InvSelect.List);
                if ( InvSelect.List.ItemCount > 0 && InvSelect.List.Index == -1 )
                    InvSelect.List.SetIndex(0);
                return true;
                break; // is this break needed here?
            case 0x71: // IK_F2
                Controller.PlayInterfaceSound(CS_Click);
                SetFocus(SaleSelect.List);
                if ( SaleSelect.List.ItemCount > 0 && SaleSelect.List.Index == -1 )
                    SaleSelect.List.SetIndex(0);
                return true;
                break;
            case 0x72: // IK_F3
                Controller.PlayInterfaceSound(CS_Click);
                ForceInfoPageNum = 1 - InfoPageNum;
                OnAnychange();
                return true;
                break;
            case 0x74: // IK_F5
                Controller.PlayInterfaceSound(CS_Click);
                RefreshButton.OnClick(RefreshButton);
                return true;
                break;
            case 0x76: // IK_F7
                DoBuyKevlar();
                return true;
                break;
            case 0x77: // IK_F8
                Controller.PlayInterfaceSound(CS_Up);
                AutoFillButton.OnClick(AutoFillButton);
                return true;
                break;
        }
    }
    return false;
}


defaultproperties
{
     Begin Object Class=ScrnBuyMenuInvListBox Name=InventoryBox
         OnCreateComponent=InventoryBox.InternalOnCreateComponent
         WinTop=0.070841
         WinLeft=0.000108
         WinWidth=0.328204
         WinHeight=0.521856
        TabOrder=10
     End Object
     InvSelect=InventoryBox

     Begin Object Class=ScrnBuyMenuSaleListBox Name=SaleBox
         OnCreateComponent=SaleBox.InternalOnCreateComponent
         WinTop=0.064312
         WinLeft=0.672632
         WinWidth=0.325857
         WinHeight=0.674039
        TabOrder=20
     End Object
     SaleSelect=SaleBox

     Begin Object Class=ScrnGUIBuyWeaponInfoPanel Name=ItemInf
         WinTop=0.193730
         WinLeft=0.332571
         WinWidth=0.333947
         WinHeight=0.489407
     End Object
     ItemInfo=ItemInf

     Begin Object Class=ScrnTraderRequirementsListBox Name=ItemReq
         WinTop=0.183730
         WinLeft=0.3335
         WinWidth=0.33
         WinHeight=0.529407
         bVisible=False
     End Object
     ItemRequirements=ItemReq
    ForceInfoPageNum=255

     Begin Object Class=GUILabel Name=SelectedItemL
         Caption="Selected Item Info"
         TextAlign=TXTA_Center
         TextColor=(B=158,G=176,R=175)
         TextFont="UT2SmallFont"
         FontScale=FNS_Small
         WinTop=0.138
         WinLeft=0.332571
         WinWidth=0.333947
         WinHeight=20.000000
         RenderWeight=0.510000
     End Object
     SelectedItemLabel=SelectedItemL
     strSelectedItemRequirements="Requirements for Unlocking Selected Item"
     strIntoScrnLocked="You have to meet the above requirements for unlocking the selected item. If multiple requirements have the same leading number in square brackets [X], then you need only one of those. Press F3 for item's description."


     Begin Object Class=GUIButton Name=SaleB
         Caption="Sell Weapon"
         Hint="Sell selected item [BACKSPACE]"
         WinTop=0.004750
         WinLeft=0.000394
         WinWidth=0.162886
         WinHeight=35.000000
         RenderWeight=0.450000
         OnClick=KFTab_BuyMenu.InternalOnClick
         OnKeyEvent=SaleB.InternalOnKeyEvent
         bTabStop=False
     End Object
     SaleButton=SaleB
     SaleButtonCaption="Sell Weapon"
     strSale0="Donate to Charity"
     strNoSale="Not Sellable"

     Begin Object Class=GUIButton Name=PurchaseB
         Caption="Purchase Weapon"
         Hint="Buy selected weapon [ENTER]"
         WinTop=0.004750
         WinLeft=0.729647
         WinWidth=0.220714
         WinHeight=35.000000
         RenderWeight=0.450000
         OnClick=KFTab_BuyMenu.InternalOnClick
         OnKeyEvent=PurchaseB.InternalOnKeyEvent
         bTabStop=False
     End Object
     PurchaseButton=PurchaseB

     Begin Object Class=GUIButton Name=AutoFill
         Caption="[F8] Auto Fill Ammo"
         Hint="First click fills up all weapons except hand grenades and pipebombs. Second click buys pipebombs and grenades."
         WinTop=0.79
         WinLeft=0.725646
         WinWidth=0.220714
         WinHeight=0.050852
         RenderWeight=0.450000
         OnClick=KFTab_BuyMenu.InternalOnClick
         OnKeyEvent=AutoFill.InternalOnKeyEvent
         TabOrder=100
     End Object
     AutoFillButton=AutoFill
     AutoFillString="[F8] Fill All Ammo"

     Begin Object Class=GUIButton Name=Refresh
         Caption="[F5] Refresh"
         Hint="Reload the Trader Menu, including max value reset of weapon info bars."
         WinTop=0.85
         WinLeft=0.725646
         WinWidth=0.220714
         WinHeight=0.050852
         RenderWeight=0.450000
         OnClick=KFTab_BuyMenu.InternalOnClick
         OnKeyEvent=Refresh.InternalOnKeyEvent
         TabOrder=101
     End Object
     RefreshButton=Refresh

     Begin Object Class=GUIButton Name=Exit
         Caption="[ESC] Exit Trader Menu"
         Hint="Close The Trader Menu"
         WinTop=0.91
         WinLeft=0.725646
         WinWidth=0.220714
         WinHeight=0.050852
         RenderWeight=0.450000
         OnClick=KFTab_BuyMenu.InternalOnClick
         OnKeyEvent=Exit.InternalOnKeyEvent
         TabOrder=102
     End Object
     ExitButton=Exit

     InfoText(0)="Welcome to my shop, powered by ScrN Balance!   HOTKEYS:|F1/F2: go to inventory/sale list|ENTER/BACKPACE: buy/sell item. F7/F8: autofill armor/ammo|0-9: Quick group selection / buy X clips.|PAGE UP/DOWN: Select previous/next group. LEFT/RIGHT: close/open current group.|UP/DOWN: select previous/next item in the same group."

     OnKeyEvent=InternalOnKeyEvent
}
