class ScrnTab_BuyMenu extends SRKFTab_BuyMenu;

var int LastDosh, LastTeamDosh, LastInvCount, LastAmmoCount, LastShieldStrength,  LastPerkLevel;
var class<KFVeterancyTypes> LastPerk;
var class<ScrnVestPickup> LastVestClass;
var byte LastShopUpdateCounter;

var protected float LastAutoFillTime;

var automated GUIButton RequestDoshButton;
var automated GUIButton GiveDoshButton;
var automated GUIButton BuyKevlarButton;
var automated GUIButton ShareDoshButton;

var protected transient bool bJustOpened;

const INFOPAGE_ITEM = 0;
const INFOPAGE_ITEM_REQUIREMENTS = 1;
const INFOPAGE_GIVE_DOSH = 2;
const INFOPAGE_DEFAULT = 255;
var automated ScrnTraderRequirementsListBox ItemRequirements;
var automated ScrnTraderGiveDoshPanel GiveDoshPanel;
var localized string strSelectedItemRequirements;
var localized string strIntoScrnLocked;
var byte InfoPageNum, ForceInfoPageNum, InfoPageCount;
var localized string SaleButtonCaption, strSale0, strNoSale;
var localized string PurchaseButtonCaption;

var ScrnGuiBuyMenu TraderMenu;
var transient ScrnPlayerController ScrnPC;
var transient ScrnHumanPawn ScrnPawn;
var transient ScrnClientPerkRepLink PerkLink;
var transient KFPlayerReplicationInfo KFPRI;

var private transient bool bOnAnyChangeInProgress;
var transient string GiveDoshButtonCaption;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local ScrnBuyMenuInvList ScrnInvList;

    Super.InitComponent(MyController, MyOwner);

    ScrnInvList = ScrnBuyMenuInvList(InvSelect.List);
    ScrnInvList.OnSellClick = SellBuyable;

    GiveDoshPanel.BuyMenu = self;
    GiveDoshButtonCaption = GiveDoshButton.Caption;
}

function Free()
{
    super.Free();

    // reset all actor references
    LastPerk = none;
    LastVestClass = none;
    PerkLink = none;
    KFPRI = none;
    ScrnPC = none;
    ScrnPawn = none;

    SelectedItem = none;
    OldPerkClass = none;
    MyAmmos.Length = 0;
    OldPickupClass = none;
}

function ShowPanel(bool bShow)
{
    local ScrnBuyMenuInvList invList;

    super(UT2K4TabPanel).ShowPanel(bShow);

    if ( !bShow ) {
        SetTimer(0, false);
        return;
    }


    ScrnPC = ScrnPlayerController(PlayerOwner());
    KFPRI = KFPlayerReplicationInfo(ScrnPC.PlayerReplicationInfo);
    PerkLink = Class'ScrnClientPerkRepLink'.Static.FindMe(ScrnPC);
    ScrnPawn = ScrnHumanPawn(ScrnPC.Pawn);
    bJustOpened = true;
    bClosed = false;
    LastInvCount = -1; // force item update on timer
    ForceInfoPageNum = INFOPAGE_DEFAULT;
    SetTimer(0.1, true);

    ResetInfo();
    TheBuyable = none;
    LastBuyable = none;

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

    invList = ScrnBuyMenuInvList(InvSelect.List);

    MagBG.WinLeft = InvSelect.WinLeft + InvSelect.WinWidth * (invList.ItemBGWidthScale + invList.AmmoBGWidthScale);
    MagBG.WinWidth = InvSelect.WinWidth * (1.0 - invList.ItemBGWidthScale - invList.AmmoBGWidthScale) * invList.ClipButtonWidthScale;
    MagLabel.WinLeft = MagBG.WinLeft;
    MagLabel.WinWidth = MagBG.WinWidth;

    FillBG.WinLeft = MagBG.WinLeft + MagBG.WinWidth;
    FillBG.WinWidth = InvSelect.WinWidth * (1.0 - invList.ItemBGWidthScale - invList.AmmoBGWidthScale) * (1.0 - invList.ClipButtonWidthScale);
    FillLabel.WinLeft = FillBG.WinLeft;
    FillLabel.WinWidth = FillBG.WinWidth;

    OnAnyChange();
}

//overloaded to show Item description -- PooSH
function SetInfoText()
{
    local string TempString;
    local int Dosh;

    if (ScrnPawn == none || TheBuyable == none) {
        if (!bDidBuyableUpdate) {
            SetCustomInfoText(InfoText[0]);
            bDidBuyableUpdate = true;
        }
        return;
    }

    Dosh = ScrnPawn.GetAvailableDosh();

    // if (OldPickupClass == TheBuyable.ItemPickupClass)
    //     return;

    if ( InfoPageNum == 1 ) {
        // Custom lock
        SetCustomInfoText(strIntoScrnLocked);
    }
    else if (TheBuyable.bSaleList && TheBuyable.ItemCost > Dosh) {
        // Too expensive
        SetCustomInfoText(InfoText[2]);
    }
    else if (TheBuyable.bSaleList && TheBuyable.ItemWeight + ScrnPawn.CurrentWeight > ScrnPawn.MaxCarryWeight )
    {
        // Too heavy
        TempString = Repl(Infotext[1], "%1", int(TheBuyable.ItemWeight));
        TempString = Repl(TempString, "%2", int(ScrnPawn.MaxCarryWeight - ScrnPawn.CurrentWeight));
        SetCustomInfoText(TempString);
    }
    else {
        //show idem description, if it is avaliable for buying -- PooSH
        SetCustomInfoText(TheBuyable.ItemDescription);
    }

    bDidBuyableUpdate = false;
    OldPickupClass = TheBuyable.ItemPickupClass;
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
    if (TheBuyable == none || ScrnPawn == none || TheBuyable.ItemPickupClass == none)
        return;

    if ( ClassIsChildOf(TheBuyable.ItemPickupClass, class'ScrnVestPickup') ) {
        ScrnPawn.ServerBuyShield(class<ScrnVestPickup>(TheBuyable.ItemPickupClass));
        MakeSomeBuyNoise(class'Vest');
    }
    else if (TheBuyable.ItemWeaponClass != none ){
        ScrnPawn.ServerBuyWeapon(TheBuyable.ItemWeaponClass, 0);
        MakeSomeBuyNoise();
    }

    SaleSelect.List.Index = -1;
    TheBuyable = none;
    LastBuyable = none;
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
    OnAnyChange();
}

function OnAnyChange()
{
    if ( bOnAnyChangeInProgress )
        return; // prevent recursion
    bOnAnyChangeInProgress = true;

    RefreshSelection();
    if (LastBuyable != TheBuyable) {
        if (ForceInfoPageNum == INFOPAGE_ITEM_REQUIREMENTS || TheBuyable != none) {
            ForceInfoPageNum = INFOPAGE_DEFAULT;
        }
        LastBuyable = TheBuyable;
    }

    // ItemAmmoCurrent of items for sale stores DLCLocked value
    // DLCLocked = 5 for ScrN locks
    if (ForceInfoPageNum == INFOPAGE_GIVE_DOSH) {
        ItemInfo.SetVisibility(false);
        ItemRequirements.SetVisibility(false);
        GiveDoshPanel.SetVisibility(true);
        SelectedItemLabel.Caption = GiveDoshPanel.Title;
        InfoPageNum = INFOPAGE_GIVE_DOSH;
    }
    else if (TheBuyable != none && TheBuyable.bSaleList && ForceInfoPageNum != INFOPAGE_ITEM
            && (ForceInfoPageNum == INFOPAGE_ITEM_REQUIREMENTS || TheBuyable.ItemAmmoCurrent == 5)) {
        ItemRequirements.List.Display(TheBuyable);
        ItemRequirements.SetVisibility(true);
        ItemInfo.SetVisibility(false);
        GiveDoshPanel.SetVisibility(false);
        SelectedItemLabel.Caption = strSelectedItemRequirements;
        InfoPageNum = INFOPAGE_ITEM_REQUIREMENTS;
    }
    else {
        if (TheBuyable != none && TheBuyable.bIsVest && !TheBuyable.bSaleList) {
            ScrnBuyMenuSaleList(SaleSelect.List).SelectVestCategory();
            TheBuyable = LastBuyable;
        }
        ItemInfo.Display(TheBuyable);
        ItemRequirements.SetVisibility(false);
        ItemInfo.SetVisibility(true);
        GiveDoshPanel.SetVisibility(false);
        SelectedItemLabel.Caption = default.SelectedItemLabel.Caption;
        InfoPageNum = INFOPAGE_ITEM;
    }
    GiveDoshButton.Caption = eval(InfoPageNum == INFOPAGE_GIVE_DOSH, class'ScrnGuiBuyMenu'.default.strCancel,
            GiveDoshButtonCaption);
    SetInfoText();
    UpdatePanel();
    UpdateBuySellButtons();

    bOnAnyChangeInProgress = false;
}

function UpdateBuySellButtons()
{
    RefreshSelection();
    SaleButton.SetVisibility(InvSelect.List.Index >= 0 && TheBuyable != none);
    if (SaleButton.bVisible) {
        if (!TheBuyable.bSellable) {
            SaleButton.DisableMe();
            SaleButton.Caption = strNoSale;
        }
        else {
            SaleButton.EnableMe();
            if (TheBuyable.bIsVest) {
                SaleButton.Caption = ScrnPawn.LightVestClass.default.ItemName;
            }
            else if (TheBuyable.ItemSellValue <= 0) {
                SaleButton.Caption = strSale0;
            }
            else {
                SaleButton.Caption = SaleButtonCaption $ " (" $ class'ScrnUnicode'.default.Dosh $ TheBuyable.ItemSellValue $ ")";
            }
        }

    }

    PurchaseButton.SetVisibility(SaleSelect.List.Index >= 0 && TheBuyable != none);
    if (PurchaseButton.bVisible) {
        if (SaleSelect.List.CanBuys[SaleSelect.List.Index] != 1) {
            PurchaseButton.DisableMe();
        }
        else {
            PurchaseButton.EnableMe();
        }

        if (TheBuyable.ItemCost > 0) {
            PurchaseButton.Caption = PurchaseButtonCaption $ " (" $ class'ScrnUnicode'.default.Dosh $ int(TheBuyable.ItemCost) $ ")";
        }
        else {
            PurchaseButton.Caption = PurchaseButtonCaption;
        }
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
    local Ammunition ammo;

    ItemCount = 0;
    TotalAmmoAmount = 0;

    if ( ScrnPawn == none )
        return; // wtf?

    // limit to 1000 to prevent circular loops
    for (Inv = ScrnPawn.Inventory; Inv != none && ItemCount < 1000 ; Inv = Inv.Inventory) {
        ++ItemCount;
        ammo = Ammunition(Inv);
        if (ammo != none) {
            TotalAmmoAmount += ammo.AmmoAmount;
        }
    }
}

function UpdateDosh()
{
    local String str;

    if (KFPRI == none)
        return;

    str = MoneyCaption $ int(KFPRI.Score);
    if (KFPRI.Team != none && KFPRI.Team.Score >= 1) {
        str $= "+" $ int(KFPRI.Team.Score);
    }
    MoneyLabel.Caption = str;

    class'ScrnGUI'.static.ButtonEnable(ShareDoshButton, int(KFPRI.Score) > 0);
}

function Timer()
{

    if (bClosed) {
        SetTimer(0, false);
        return;
    }

    UpdateDosh();

    if (bJustOpened) {
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

function UpdatePanel()
{
    if (TheBuyable != none && !TheBuyable.bSaleList && TheBuyable.bSellable) {
        SaleValueLabel.Caption = SaleValueCaption $ TheBuyable.ItemSellValue;
        SaleValueLabel.bVisible = true;
    }
    else {
        SaleValueLabel.bVisible = false;
    }
    SaleValueLabelBG.bVisible = SaleValueLabel.bVisible;

    if (TheBuyable == none || !TheBuyable.bSaleList) {
        GUIBuyMenu(OwnerPage()).WeightBar.NewBoxes = 0;
    }

    ItemInfo.Display(TheBuyable);
    UpdateAutoFillAmmo();
    SetInfoText();
    UpdateDosh();
}

// update lists in inventory count or score (money) is changed
// if ammo count changed - update ammo only without rebuilding the list
function UpdateCheck()
{
    local int MyInvCount, MyAmmoCount;

    MyInventoryStats(MyInvCount, MyAmmoCount);
    // ignore KFPC.bDoTraderUpdate and do it the right way
    if (LastShopUpdateCounter != ScrnPawn.ShopUpdateCounter
            || LastDosh != int(KFPRI.Score)
            || (KFPRI.Team != none && LastTeamDosh != int(KFPRI.Team.Score))
            || LastPerk != KFPRI.ClientVeteranSkill
            || LastPerkLevel != KFPRI.ClientVeteranSkillLevel
            || LastInvCount != MyInvCount
            || LastVestClass != ScrnPawn.GetCurrentVestClass())
    {
        UpdateAll();
    }
    else if ( LastAmmoCount != MyAmmoCount || LastShieldStrength != ScrnPawn.ShieldStrength ) {
        // no need to update inventory list, just update the ammo values
        UpdateAmmo();
        LastAmmoCount = MyAmmoCount;
        LastShieldStrength = ScrnPawn.ShieldStrength;
    }

}

function UpdateAll()
{
    if ( PerkLink != none )
        PerkLink.ParseLocks();
    super.UpdateAll();
    LastShopUpdateCounter = ScrnPawn.ShopUpdateCounter;
    LastDosh = int(KFPRI.Score);
    LastTeamDosh = int(KFPRI.Team.Score);
    LastPerk = KFPRI.ClientVeteranSkill;
    LastPerkLevel = KFPRI.ClientVeteranSkillLevel;
    MyInventoryStats(LastInvCount, LastAmmoCount);
    LastShieldStrength = ScrnPawn.ShieldStrength;
    LastVestClass = ScrnPawn.GetCurrentVestClass();
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
    local GUIBuyable VestBuyable;

    AutoFillButton.Caption = AutoFillString $ " (" $ class'ScrnUnicode'.default.Dosh $ int(InvSelect.List.AutoFillCost)$")";
    class'ScrnGUI'.static.ButtonEnable(AutoFillButton, int(InvSelect.List.AutoFillCost) > 0);

    VestBuyable = ScrnBuyMenuInvList(InvSelect.List).FindVest();
    class'ScrnGUI'.static.ButtonEnable(BuyKevlarButton, VestBuyable == none
            || VestBuyable.ItemAmmoCurrent < VestBuyable.ItemAmmoMax);
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
    if ( TheBuyable == none )
        return;

    if ( TheBuyable.bIsVest ) {
        // there is no reason to sell the light armor as it has no weight.
        // So instead of selling armor, buy the light one
        ScrnPawn.ServerBuyShield(ScrnPawn.LightVestClass);
        MakeSomeBuyNoise(class'Vest');
    }
    else {
        super.DoSell();
    }
}

function bool RequestDoshClick(GUIComponent Sender)
{
    PlayerOwner().Speech('SUPPORT', 2, "");  // v13
    return true;
}

function bool GiveDoshClick(GUIComponent Sender)
{
    if (ForceInfoPageNum == INFOPAGE_GIVE_DOSH) {
        ForceInfoPageNum = INFOPAGE_DEFAULT;
    }
    else {
        ForceInfoPageNum = INFOPAGE_GIVE_DOSH;
    }
    OnAnyChange();
    return true;
}

function OnPlayerDoshRequest(PlayerReplicationInfo SenderPRI, string Msg)
{
    if (ScrnPC.bAutoOpenGiveDosh && ForceInfoPageNum != INFOPAGE_GIVE_DOSH) {
        GiveDoshClick(none);
    }
    SetCustomInfoText(class'ScrnF'.static.ColoredPlayerName(SenderPRI) $ ": " $ Msg);
}

function SetCustomInfoText(string Text)
{
    InfoScrollText.SetContent(class'ScrnF'.static.ParseColorTags(Text));
}

function DoShareAllDosh()
{
    if (ScrnPawn != none) {
        ScrnPawn.ServerDoshTransfer(KFPRI.Score);
    }
}

function CloseSale()
{
    ScrnGuiBuyMenu(OwnerPage()).CloseSale(false);
}

function bool InternalOnClick(GUIComponent Sender)
{
    switch (Sender) {
        case PurchaseButton:
            RefreshSelection();
            DoBuy();
            TheBuyable = none;
            break;
        case SaleButton:
            RefreshSelection();
            if (!TheBuyable.bSellable) {
                return true;
            }
            DoSell();
            TheBuyable = none;
            break;
        case BuyKevlarButton:
            DoBuyKevlar();
            break;
        case AutoFillButton:
            DoFillAllAmmo();
            break;
        case ShareDoshButton:
            DoShareAllDosh();
            break;
        case ExitButton:
            CloseSale();
            return true;
        default:
            return false;
    }
    UpdateAll();
    return true;
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if (State != 1)
        return false;  // interested in key press only

    if (Key < 0x20) {
        // control characters
        switch ( Key ) {
            case 0x08: // IK_Backspace
                if (Controller.CtrlPressed) {
                    Controller.PlayInterfaceSound(CS_Click);
                    ScrnBuyMenuInvList(InvSelect.List).SellAll(!Controller.ShiftPressed);
                }
                return true;
            case  0x1B: // IK_Escape
                ExitButton.OnClick(ExitButton);
                return true;
        }
    }
    else if (Key >= 0x70 && Key < 0x7C) {
        // F keys
        switch ( Key ) {
            case 0x70: // IK_F1
                Controller.PlayInterfaceSound(CS_Down);
                SetFocus(InvSelect.List);
                if ( InvSelect.List.ItemCount > 0 && InvSelect.List.Index == -1 )
                    InvSelect.List.SetIndex(0);
                return true;
            case 0x71: // IK_F2
                Controller.PlayInterfaceSound(CS_Down);
                SetFocus(SaleSelect.List);
                if ( SaleSelect.List.ItemCount > 0 && SaleSelect.List.Index == -1 )
                    SaleSelect.List.SetIndex(0);
                return true;
            case 0x72: // IK_F3
                Controller.PlayInterfaceSound(CS_Edit);
                ScrnGUIBuyMenu(OwnerPage()).ActivateSearch();
                return true;
            case 0x73: // IK_F4
                Controller.PlayInterfaceSound(CS_Down);
                if (!Controller.ShiftPressed) {
                    GiveDoshButton.OnClick(GiveDoshButton);
                }
                else if (++ForceInfoPageNum >= InfoPageCount) {
                    ForceInfoPageNum = 0;
                }
                OnAnyChange();
                return true;
            case 0x74: // IK_F5
                Controller.PlayInterfaceSound(CS_Down);
                ResetInfo();
                UpdateAll();
                return true;
            case 0x75: // IK_F6
                Controller.PlayInterfaceSound(CS_Down);
                ScrnGUIBuyMenu(OwnerPage()).ActivatePerkTab();
                return true;
            case 0x76: // IK_F7
                BuyKevlarButton.OnClick(BuyKevlarButton);
                return true;
            case 0x77: // IK_F8
                Controller.PlayInterfaceSound(CS_Click);
                AutoFillButton.OnClick(AutoFillButton);
                return true;
            case 0x78: // IK_F9
                Controller.PlayInterfaceSound(CS_Up);
                ShareDoshButton.OnClick(ShareDoshButton);
                return true;
            case 0x79: // IK_F10
                Controller.PlayInterfaceSound(CS_Click);
                ExitButton.OnClick(ExitButton);
                return true;
        }
    }
    return false;
}


defaultproperties
{
    Begin Object Class=GUIImage Name=Cash
        Image=Texture'PatchTex.Statics.BanknoteSkin'
        ImageStyle=ISTY_Scaled
        WinTop=0.015
        WinLeft=0.34
        WinWidth=0.10
        WinHeight=0.105
    End Object
    BankNote=Cash

    Begin Object Class=GUILabel Name=Money
        Caption="$0"
        TextColor=(B=158,G=176,R=175)
        TextFont="UT2HeaderFont"
        FontScale=FNS_Large
        WinTop=0.015
        WinLeft=0.46
        WinWidth=0.20
        WinHeight=0.05
    End Object
    MoneyLabel=Money

    Begin Object Class=GUIButton Name=RequestDosh
        Caption="Request"
        Hint="v13 - I need some money"
        WinTop=0.08
        WinLeft=0.46
        WinWidth=0.09
        WinHeight=0.035
        RenderWeight=0.47
        OnClick=RequestDoshClick
        OnKeyEvent=RequestDosh.InternalOnKeyEvent
        TabOrder=11
    End Object
    RequestDoshButton=RequestDosh

    Begin Object Class=GUIButton Name=GiveDosh
        Caption="Give..."
        Hint="Opens/Closes the Didital Dosh Transfer window [F4]"
        WinTop=0.08
        WinLeft=0.56
        WinWidth=0.09
        WinHeight=0.035
        RenderWeight=0.47
        OnClickSound=CS_Down
        OnClick=GiveDoshClick
        OnKeyEvent=GiveDosh.InternalOnKeyEvent
        TabOrder=12
    End Object
    GiveDoshButton=GiveDosh

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

    Begin Object Class=ScrnTraderGiveDoshPanel Name=GiveDoshPanelDef
        WinTop=0.183730
        WinLeft=0.3335
        WinWidth=0.33
        WinHeight=0.529407
        bVisible=False
    End Object
    GiveDoshPanel=GiveDoshPanelDef

    InfoPageCount=3

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
        WinTop=0.000
        WinLeft=0.000394
        WinWidth=0.162886
        WinHeight=35.000000
        RenderWeight=0.450000
        OnClickSound=CS_Click
        OnClick=InternalOnClick
        OnKeyEvent=SaleB.InternalOnKeyEvent
        bTabStop=False
    End Object
    SaleButton=SaleB
    SaleButtonCaption="Sell"
    strSale0="Donate to Charity"
    strNoSale="Not Sellable"

    Begin Object Class=GUIImage Name=MagB
        Image=Texture'KF_InterfaceArt_tex.Menu.Innerborder_transparent'
        ImageStyle=ISTY_Stretched
        WinTop=0.000
        WinLeft=0.205986
        WinWidth=0.054624
        WinHeight=35.000000
        RenderWeight=0.500000
    End Object
    MagBG=GUIImage'MagB'

    Begin Object Class=GUIImage Name=FillB
        Image=Texture'KF_InterfaceArt_tex.Menu.Innerborder_transparent'
        ImageStyle=ISTY_Stretched
        WinTop=0.000
        WinLeft=0.266769
        WinWidth=0.054624
        WinHeight=35.000000
        RenderWeight=0.500000
    End Object
    FillBG=GUIImage'FillB'

    Begin Object Class=GUILabel Name=MagL
        Caption="Mag"
        TextAlign=TXTA_Center
        TextColor=(B=158,G=176,R=175)
        TextFont="UT2SmallFont"
        FontScale=FNS_Small
        WinTop=0.000
        WinLeft=0.205986
        WinWidth=0.054624
        WinHeight=35.000000
        RenderWeight=0.510000
    End Object
    MagLabel=GUILabel'MagL'

    Begin Object Class=GUILabel Name=FillL
        Caption="Fill"
        TextAlign=TXTA_Center
        TextColor=(B=158,G=176,R=175)
        TextFont="UT2SmallFont"
        FontScale=FNS_Small
        WinTop=0.000
        WinLeft=0.266769
        WinWidth=0.054624
        WinHeight=35.000000
        RenderWeight=0.510000
    End Object
    FillLabel=GUILabel'FillL'

    Begin Object Class=GUIButton Name=PurchaseB
        Caption="Purchase Weapon"
        Hint="Buy selected weapon [ENTER]"
        WinTop=0.000
        WinLeft=0.729647
        WinWidth=0.220714
        WinHeight=35.000000
        RenderWeight=0.450000
        OnClick=InternalOnClick
        OnKeyEvent=PurchaseB.InternalOnKeyEvent
        bTabStop=False
    End Object
    PurchaseButton=PurchaseB
    PurchaseButtonCaption="Buy"

    Begin Object Class=GUIButton Name=BuyKevlar
        Caption="F7 Armor"
        Hint="Buy or repair the armor."
        WinTop=0.77
        WinLeft=0.68
        WinWidth=0.15
        WinHeight=0.05
        RenderWeight=0.450000
        OnClickSound=CS_None
        OnClick=InternalOnClick
        OnKeyEvent=BuyKevlar.InternalOnKeyEvent
        TabOrder=100
    End Object
    BuyKevlarButton=BuyKevlar

        Begin Object Class=GUIButton Name=AutoFill
        Caption="F8 Auto Ammo"
        Hint="1st click - buy all ammo. 2nd - buy nades and pipebombs"
        WinTop=0.77
        WinLeft=0.84
        WinWidth=0.15
        WinHeight=0.05
        RenderWeight=0.45
        OnClick=InternalOnClick
        OnKeyEvent=AutoFill.InternalOnKeyEvent
        TabOrder=101
    End Object
    AutoFillButton=AutoFill
    AutoFillString="F8 Ammo"

     // WinTop=0.85

    Begin Object Class=GUIButton Name=ShareDosh
        Caption="F9 Share Dosh"
        Hint="Share dosh with the team. Transfers all you money to the Team Wallet, where anybody can use it."
        WinTop=0.935
        WinLeft=0.68
        WinWidth=0.15
        WinHeight=0.05
        RenderWeight=0.45
        OnClickSound=CS_Up
        OnClick=InternalOnClick
        OnKeyEvent=ShareDosh.InternalOnKeyEvent
        TabOrder=102
    End Object
    ShareDoshButton=ShareDosh

    Begin Object Class=GUIButton Name=Exit
        Caption="F10 Exit"
        Hint="Close The Trader Menu."
        WinTop=0.935
        WinLeft=0.84
        WinWidth=0.15
        WinHeight=0.05
        RenderWeight=0.45
        OnClick=InternalOnClick
        OnKeyEvent=Exit.InternalOnKeyEvent
        TabOrder=103
    End Object
    ExitButton=Exit

    InfoText(0)="Welcome to my shop, powered by ScrN Balance!        HOTKEYS:|F1/F2: Go to inventory/sale list|ENTER/BACKPACE: buy/sell item. |0-9: Quick group selection / buy X clips.|PAGE UP/DOWN: Select previous/next group. LEFT/RIGHT: close/open current group.|UP/DOWN: select previous/next item in the same group."

    OnKeyEvent=InternalOnKeyEvent
}
