/*
 * List of Player's inventory
 */
class ScrnBuyMenuInvList extends SRKFBuyMenuInvList;

var localized string UpgradeArmorCaption;
var localized string NoWeightCaption;

var bool bHasOffPerkWeapons;

delegate OnSellClick(GUIBuyable Buyable);
delegate OnBuyablesLoaded(ScrnBuyMenuInvList List);

// all update checks now are perfomed in ScrnTab_BuyMenu
function Timer()
{
    SetTimer(0, false);
}

function UpdateList()
{
    local int i;
    local ClientPerkRepLink KFLR;

    KFLR = Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerOwner());

    if ( MyBuyables.Length < 1 )
    {
        bNeedsUpdate = true;
        return;
    }

    // Clear the arrays
    NameStrings.Remove(0, NameStrings.Length);
    AmmoStrings.Remove(0, AmmoStrings.Length);
    ClipPriceStrings.Remove(0, ClipPriceStrings.Length);
    FillPriceStrings.Remove(0, FillPriceStrings.Length);
    PerkTextures.Remove(0, PerkTextures.Length);

    // Update the ItemCount and select the first item
    ItemCount = MyBuyables.Length;

    // Update the players inventory list
    for (i = 0; i < ItemCount; i++) {
        if ( MyBuyables[i] == none )
            continue;

        NameStrings[i] = MyBuyables[i].ItemName;

        if ( !MyBuyables[i].bIsVest )
        {
            AmmoStrings[i] = int(MyBuyables[i].ItemAmmoCurrent)$"/"$int(MyBuyables[i].ItemAmmoMax);

            if ( MyBuyables[i].ItemAmmoCurrent < MyBuyables[i].ItemAmmoMax )
            {
                if ( MyBuyables[i].ItemAmmoCost > MyBuyables[i].ItemFillAmmoCost )
                {
                    ClipPriceStrings[i] = class'ScrnUnicode'.default.Dosh @ int(MyBuyables[i].ItemFillAmmoCost);
                }
                else
                {
                    ClipPriceStrings[i] = class'ScrnUnicode'.default.Dosh @ int(MyBuyables[i].ItemAmmoCost);
                }
            }
            else
            {
                ClipPriceStrings[i] = class'ScrnUnicode'.default.Dosh @ "0";
            }

            FillPriceStrings[i] = class'ScrnUnicode'.default.Dosh @ int(MyBuyables[i].ItemFillAmmoCost);
        }
        else
        {
            AmmoStrings[i] = int(MyBuyables[i].ItemAmmoCurrent)$"%";

            if ( MyBuyables[i].ItemAmmoCurrent == 0 ) {
                FillPriceStrings[i] = BuyString @ ": " $ class'ScrnUnicode'.default.Dosh @ int(MyBuyables[i].ItemFillAmmoCost);
            }
            else if ( MyBuyables[i].ItemAmmoCurrent >= MyBuyables[i].ItemAmmoMax ) {
                //if ( MyBuyables[i].ItemAmmoCurrent <= 25 )
                //    FillPriceStrings[i] = NoWeightCaption;
                //else
                FillPriceStrings[i] = PurchasedString;
            }
            else {
                FillPriceStrings[i] = RepairString @ ": " $ class'ScrnUnicode'.default.Dosh @ int(MyBuyables[i].ItemFillAmmoCost);
            }
        }
        if( KFLR!=None && KFLR.ShopPerkIcons.Length>MyBuyables[i].ItemPerkIndex )
            PerkTextures[i] = Texture(KFLR.ShopPerkIcons[MyBuyables[i].ItemPerkIndex]);
    }

    if ( bNotify )
        CheckLinkedObjects(Self);
    if ( MyScrollBar != none )
        MyScrollBar.AlignThumb();
    bNeedsUpdate = false;
}

// update ammo values of the current list
function UpdateMyAmmo()
{
    local GUIBuyable MyBuyable;
    local class<ScrnHumanPawn> ScrnPawnClass;
    local Ammunition MyAmmo;
    local int ClipSize;
    local float ClipPrice, FullRefillPrice;
    local int i;

    ScrnPawnClass = class<ScrnHumanPawn>(PlayerOwner().Pawn.class);
    if ( ScrnPawnClass == none )
        ScrnPawnClass = class'ScrnHumanPawn';

    AutoFillCost = 0;
    for ( i = 0; i < MyBuyables.Length; i++ ) {
        MyBuyable = MyBuyables[i];
        if ( MyBuyable == none || MyBuyable.ItemAmmoClass == none )
            continue;

        if ( ScrnPawnClass.static.CalcAmmoCost(PlayerOwner().Pawn, MyBuyable.ItemAmmoClass,
                MyAmmo, ClipPrice, FullRefillPrice, ClipSize) )
        {
            MyBuyable.ItemAmmoCost     = ceil(ClipPrice);
            MyBuyable.ItemFillAmmoCost = ceil(FullRefillPrice);
            MyBuyable.ItemAmmoCurrent  = MyAmmo.AmmoAmount;
        }
        AutoFillCost += MyBuyable.ItemAmmoCost;
    }
    UpdateList();
}

function UpdateMyBuyables()
{
    local GUIBuyable MyBuyable, PistolBuyable, KnifeBuyable, FragBuyable, TPBuyable;
    local bool bSpecial;
    local Inventory CurInv;
    local float CurAmmo, MaxAmmo;
    local KFWeapon KFWeap;
    local class<KFWeaponPickup> MyPickup,MyPrimaryPickup;
    local class<ScrnVeterancyTypes> Perk;
    local ClientPerkRepLink KFLR;
    local KFPlayerReplicationInfo KFPRI;
    local float DualCoef; //if replaceable gun's price is different than 2x like in standard dualies
    local class<Grenade> NadeType;
    local Ammunition MyAmmo;
    local float ClipPrice, FullRefillPrice;
    local int ClipSize;
    local ScrnHumanPawn ScrnPawn;
    local class<ScrnHumanPawn> ScrnPawnClass;
    // vars below are used in vest price calculation
    local float Price1p;
    local int Cost, AmountToBuy;
    local class<ScrnVestPickup> VestClass, DesiredVestClass;

    KFPRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);
    KFLR = Class'ScrnClientPerkRepLink'.Static.FindMe(PlayerOwner());
    if( KFLR==None || KFPRI==None )
        return; // Hmmmm?

    // Let's start with our current inventory
    if ( PlayerOwner().Pawn.Inventory == none )
    {
        log("Inventory is none!");
        return;
    }

    DualCoef = 1;
    AutoFillCost = 0.00000;

    //Clear the MyBuyables array
    CopyAllBuyables();
    MyBuyables.Length = 0;
    bHasOffPerkWeapons = false;

    Perk = class<ScrnVeterancyTypes>(KFPRI.ClientVeteranSkill);
    if( Perk==None )
        Perk = Class'ScrnVeterancyTypes';

    ScrnPawn = ScrnHumanPawn(PlayerOwner().Pawn);
    if ( ScrnPawn != none )
        ScrnPawnClass = ScrnPawn.class;
    else
        ScrnPawnClass = class'ScrnHumanPawn';

    // Fill the Buyables
    for ( CurInv = PlayerOwner().Pawn.Inventory; CurInv != none; CurInv = CurInv.Inventory ) {
        KFWeap = KFWeapon(CurInv);
        if ( KFWeap==None || CurInv.IsA('Welder') || CurInv.IsA('Syringe') )
            continue;

        if ( (ScrnDeagle(CurInv) != none && ScrnDeagle(CurInv).DualGuns != none)
                || (ScrnMK23Pistol(CurInv) != none && ScrnMK23Pistol(CurInv).DualGuns != none)
                || (ScrnMagnum44Pistol(CurInv) != none && ScrnMagnum44Pistol(CurInv).DualGuns != none)
                || (ScrnFlareRevolver(CurInv) != none && ScrnFlareRevolver(CurInv).DualGuns != none) )
            continue;

        // weapons can be derived from another even if they aren't of the same type, e.g. Shotgun -> LAW
        // so it's better to compare their pickup classes.
        // Doing that will make easier to add custom weapon modification classes
        // (c) PooSH, 2012
        MyPickup = class<KFWeaponPickup>(CurInv.default.PickupClass);

        DualCoef = 1;
        if ( Dualies(CurInv) != none ) {
            if ( KFWeap.DemoReplacement != None  // all ScrN Dual weapons
                    || MyPickup.IsA('DualDeaglePickup') || MyPickup.IsA('Dual44MagnumPickup')
                    || MyPickup.IsA('DualMK23Pistol') || MyPickup.IsA('DualFlareRevolver') ) {
                DualCoef = 0.5;
            }
        }

        if ( KFWeap.bHasSecondaryAmmo )
            MyPrimaryPickup = MyPickup.default.PrimaryWeaponPickup;
        else
            MyPrimaryPickup = MyPickup;

        MyBuyable = AllocateEntry(KFLR);

        MaxAmmo = 0;
        CurAmmo = 0;
        KFWeap.GetAmmoCount(MaxAmmo, CurAmmo);

        MyBuyable.ItemName       = MyPickup.default.ItemShortName;
        MyBuyable.ItemDescription= KFWeap.default.Description;
        MyBuyable.ItemCategorie  = "Melee"; // More dummy.
        MyBuyable.ItemImage      = KFWeap.default.TraderInfoTexture;
        MyBuyable.ItemWeaponClass= KFWeap.class;
        MyBuyable.ItemAmmoClass  = KFWeap.default.FireModeClass[0].default.AmmoClass;
        MyBuyable.ItemPickupClass= MyPrimaryPickup;
        MyBuyable.ItemCost       =  ceil(MyPickup.default.Cost * Perk.static.GetCostScaling(KFPRI, MyPickup) * DualCoef);

        // universal method to calculate prices both in trader menu and on server (when actually buying it)
        if ( ScrnPawnClass.static.CalcAmmoCost(PlayerOwner().Pawn, MyBuyable.ItemAmmoClass,
                MyAmmo, ClipPrice, FullRefillPrice, ClipSize) ) {
            MyBuyable.ItemAmmoCost =  ceil(ClipPrice);
            MyBuyable.ItemFillAmmoCost =  ceil(FullRefillPrice);
        }
        else {
            //this never shouldn't happen
            MyBuyable.ItemAmmoCost        =  ceil(MyPrimaryPickup.default.AmmoCost * Perk.static.GetAmmoCostScaling(KFPRI, MyPrimaryPickup) * Perk.static.GetMagCapacityMod(KFPRI, KFWeap));
            MyBuyable.ItemFillAmmoCost    =  ceil((int(((MaxAmmo - CurAmmo) * float(MyPrimaryPickup.default.AmmoCost)) / float(KFWeap.default.MagCapacity))) * Perk.static.GetAmmoCostScaling(KFPRI, MyPrimaryPickup));
        }
        MyBuyable.ItemAmmoCurrent= CurAmmo;
        MyBuyable.ItemAmmoMax    = MaxAmmo;

        MyBuyable.ItemWeight     = KFWeap.Weight;
        MyBuyable.ItemPower      = MyPickup.default.PowerValue;
        MyBuyable.ItemRange      = MyPickup.default.RangeValue;
        MyBuyable.ItemSpeed      = MyPickup.default.SpeedValue;
        // Hack - setting negative ammo cost blocks weapon from refilling ammo in trader
        MyBuyable.bMelee         = KFWeap.bMeleeWeapon || MyBuyable.ItemAmmoClass==None || MyPickup.default.AmmoCost < 0;
        MyBuyable.bSaleList      = false;
        if ( Perk.static.OverridePerkIndex(MyPickup) )
            MyBuyable.ItemPerkIndex  = Perk.default.PerkIndex;
        else
            MyBuyable.ItemPerkIndex  = MyPickup.default.CorrespondingPerkIndex;

        // Changed from "!= -1" to ">= 0" to prevent possible issues in a future
        if ( KFWeap.SellValue >= 0 )
            MyBuyable.ItemSellValue = KFWeap.SellValue;
        else
            MyBuyable.ItemSellValue = MyBuyable.ItemCost * 0.75;

        if ( !MyBuyable.bMelee && int(MaxAmmo)>int(CurAmmo) )
            AutoFillCost += MyBuyable.ItemFillAmmoCost;

        bSpecial = false;
        if (MyBuyable.ItemWeight <= 1) {
            bSpecial = true;
            if (CurInv.IsA('PipeBombExplosive')) {
                //give 75% of all pipes, not 2 (even if there is only 1 left)
                // calc price per ammo and multiply by ammo count
                MyBuyable.ItemSellValue /= KFWeap.default.FireModeClass[0].default.AmmoClass.default.InitialAmount;
                MyBuyable.ItemSellValue *= KFWeap.AmmoAmount(0);
                bSpecial = false;
            }
            else if (CurInv.IsA('Single')) {
                MyBuyable.bSellable = !KFWeap.default.bKFNeverThrow;
                PistolBuyable = MyBuyable;
            }
            else if (CurInv.IsA('Knife')) {
                MyBuyable.bSellable = false;
                KnifeBuyable = MyBuyable;
            }
            else if (CurInv.IsA('Frag')) {
                MyBuyable.bSellable = false;
                FragBuyable = MyBuyable;
            }
            else if (CurInv.IsA('ToiletPaper')) {
                MyBuyable.bSellable = false;
                TPBuyable = MyBuyable;
            }
            else {
                bSpecial = false;
            }
        }

        if (!bSpecial) {
            MyBuyable.bSellable = !KFWeap.default.bKFNeverThrow;
            MyBuyables.Insert(0,1);
            MyBuyables[0] = MyBuyable;
            if (MyBuyable.ItemWeight > 1 && MyBuyable.ItemPerkIndex != Perk.default.PerkIndex) {
                bHasOffPerkWeapons = true;
            }
        }

        // =============================== SECONDARY AMMO ===============================
        if ( !KFWeap.bHasSecondaryAmmo )
            continue;

        // Add secondary ammo.

        MyBuyable = AllocateEntry(KFLR);

        KFWeap.GetSecondaryAmmoCount(MaxAmmo, CurAmmo);

        MyBuyable.ItemName        = MyPickup.default.SecondaryAmmoShortName;
        MyBuyable.ItemDescription = KFWeap.default.Description;
        MyBuyable.ItemCategorie   = "Melee";
        MyBuyable.ItemImage       = KFWeap.default.TraderInfoTexture;
        MyBuyable.ItemWeaponClass = KFWeap.class;
        MyBuyable.ItemAmmoClass   = KFWeap.default.FireModeClass[1].default.AmmoClass;
        MyBuyable.ItemPickupClass = MyPickup;
        MyBuyable.ItemCost        =  ceil(MyPickup.default.Cost * Perk.static.GetCostScaling(KFPRI, MyPickup) * DualCoef);

        // universal method to calculate prices both in trader menu and on server
        if ( ScrnPawnClass.static.CalcAmmoCost(PlayerOwner().Pawn, MyBuyable.ItemAmmoClass,
                MyAmmo, ClipPrice, FullRefillPrice, ClipSize) ) {
            MyBuyable.ItemAmmoCost =  ceil(ClipPrice);
            MyBuyable.ItemFillAmmoCost =  ceil(FullRefillPrice);
        }
        else {
            //this never shouldn't happen
            MyBuyable.ItemAmmoCost        =  ceil(MyPickup.default.AmmoCost * Perk.static.GetAmmoCostScaling(KFPRI, MyPickup));
            MyBuyable.ItemFillAmmoCost    =  ceil((MaxAmmo - CurAmmo) * float(MyPickup.default.AmmoCost) * Perk.static.GetAmmoCostScaling(KFPRI, MyPrimaryPickup));
        }
        MyBuyable.ItemAmmoCurrent = CurAmmo;
        MyBuyable.ItemAmmoMax     = MaxAmmo;

        MyBuyable.ItemWeight      = KFWeap.Weight;
        MyBuyable.ItemPower       = MyPickup.default.PowerValue;
        MyBuyable.ItemRange       = MyPickup.default.RangeValue;
        MyBuyable.ItemSpeed       = MyPickup.default.SpeedValue;
        MyBuyable.bMelee          = (KFMeleeGun(CurInv) != none);
        MyBuyable.bSaleList       = false;
        MyBuyable.ItemPerkIndex   = MyPickup.default.CorrespondingPerkIndex;
        MyBuyable.bSellable       = !KFWeap.default.bKFNeverThrow;

        if ( KFWeap.SellValue >= 0 )
            MyBuyable.ItemSellValue = KFWeap.SellValue;
        else
            MyBuyable.ItemSellValue = MyBuyable.ItemCost * 0.75;



        if ( !MyBuyable.bMelee && int(MaxAmmo) > int(CurAmmo))
            AutoFillCost += MyBuyable.ItemFillAmmoCost;

        MyBuyables.Insert(1,1);
        MyBuyables[1] = MyBuyable;
    }


    // ARMOR
    MyBuyable = AllocateEntry(KFLR);


    MyBuyable.ItemCategorie         = "";
    MyBuyable.ItemAmmoCurrent       = PlayerOwner().Pawn.ShieldStrength;
    if ( ScrnPawn != none ) {
        VestClass = ScrnPawn.GetCurrentVestClass();
        DesiredVestClass = ScrnPawn.GetVestClass();
        ScrnPawn.CalcVestCost(DesiredVestClass, Cost, AmountToBuy, Price1p);

        MyBuyable.ItemName          = VestClass.default.ItemShortName;
        MyBuyable.ItemDescription   = VestClass.default.LocalizedDescription;
        MyBuyable.ItemWeight        = VestClass.default.Weight;
        MyBuyable.ItemImage         = VestClass.default.TraderInfoTexture;
        MyBuyable.ItemPerkIndex     = VestClass.default.CorrespondingPerkIndex;

        MyBuyable.ItemAmmoMax       = DesiredVestClass.default.ShieldCapacity;
        MyBuyable.ItemCost          = DesiredVestClass.default.ShieldCapacity * Price1p;
        MyBuyable.ItemAmmoCost      = Price1p;
        MyBuyable.ItemFillAmmoCost  = Cost;
    }
    else {
        MyBuyable.ItemName        = class'ScrnVestPickup'.default.ItemShortName;
        MyBuyable.ItemDescription = class'ScrnVestPickup'.default.LocalizedDescription;
        MyBuyable.ItemWeight      = class'ScrnVestPickup'.default.Weight;
        MyBuyable.ItemImage       = class'BuyableVest'.default.ItemImage;
        MyBuyable.ItemPerkIndex   = class'BuyableVest'.default.CorrespondingPerkIndex;

        MyBuyable.ItemAmmoMax       = 100;
        MyBuyable.ItemCost          =  class'BuyableVest'.default.ItemCost
                                         * Perk.static.GetCostScaling(KFPRI, class'Vest')
                                         * MyBuyable.ItemAmmoMax/100.0;
        MyBuyable.ItemAmmoCost      = MyBuyable.ItemCost / MyBuyable.ItemAmmoMax;
        MyBuyable.ItemFillAmmoCost  = int((MyBuyable.ItemAmmoMax - MyBuyable.ItemAmmoCurrent) * MyBuyable.ItemAmmoCost);
    }

    MyBuyable.bIsVest         = true;
    MyBuyable.bMelee          = false;
    MyBuyable.bSaleList       = false;
    MyBuyable.bSellable       = ScrnPawn != none;

    // set nade icon corresponding to its type
    if ( FragBuyable != none ) {
        NadeType = Perk.static.GetNadeType(KFPRI);
        if ( NadeType == class'Nade' || NadeType == class'ScrnNade' )
            FragBuyable.ItemPerkIndex = 6; // set demo icon by default
        else
            FragBuyable.ItemPerkIndex = Perk.default.PerkIndex;
    }

    if( MyBuyables.Length < 7 ) {
        MyBuyables.Length = 11;
        MyBuyables[6] = none;
        MyBuyables[7] = PistolBuyable;
        if (TPBuyable != none) {
            MyBuyables[8] = TPBuyable;
        }
        else {
            MyBuyables[8] = KnifeBuyable;
        }
        MyBuyables[9] = FragBuyable;
        MyBuyables[10] = MyBuyable; // ARMOR
    }
    else {
        MyBuyables.insert(MyBuyables.Length, 1);
        MyBuyables[MyBuyables.Length-1] = none;
        if (PistolBuyable != none) {
            MyBuyables.insert(MyBuyables.Length, 1);
            MyBuyables[MyBuyables.Length-1] = PistolBuyable;
        }
        if (TPBuyable != none) {
            MyBuyables.insert(MyBuyables.Length, 1);
            MyBuyables[MyBuyables.Length-1] = TPBuyable;
        }
        MyBuyables.insert(MyBuyables.Length, 2);
        MyBuyables[MyBuyables.Length-2] = FragBuyable;
        MyBuyables[MyBuyables.Length-1] = MyBuyable; // ARMOR
    }

    //Now Update the list
    UpdateList();
    OnBuyablesLoaded(self);
}

function GUIBuyable FindVest()
{
    if (MyBuyables.Length == 0)
        return none;
    if (MyBuyables[MyBuyables.Length-1].bIsVest)
        return MyBuyables[MyBuyables.Length-1];
    return none;
}

function SellAll(bool offperkOnly)
{
    local GUIBuyable MyBuyable;
    local int i;
    local KFPlayerReplicationInfo KFPRI;
    local byte MyPerkIndex;

    KFPRI = KFPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);
    if (KFPRI == none)
        return;  // wtf?
    MyPerkIndex = KFPRI.ClientVeteranSkill.default.PerkIndex;

    for (i = 0; i < ItemCount; i++) {
        MyBuyable = MyBuyables[i];
        if (MyBuyable == none)
            continue;

        if (!MyBuyable.bSellable || MyBuyable.ItemWeight <= 0 || MyBuyable.bIsVest)
            continue;

        if (offperkOnly) {
            // always consider 1kg items perked (machete, pipebombs)
            if (MyBuyable.ItemWeight == 1)
                continue;

             if (MyBuyable.ItemPerkIndex == MyPerkIndex)
                continue;
        }

        OnSellClick(MyBuyable);
    }
}

function GUIBuyable GetSelectedBuyable()
{
    if ( Index >= 0 && Index < MyBuyables.Length )
        return MyBuyables[Index];

    return none;
}

function BuyClips(byte ClipAmount)
{
    local GUIBuyable Buyable;
    local class<Ammunition> MyAmmo;

    Buyable = GetSelectedBuyable();
    if ( Buyable == none || Buyable.bIsVest || Buyable.bMelee)
        return;

    // Buyable list is completely rebuilding after each clip purchase.
    // Yes, that's lazy and lame. But I think it is impossible to teach
    // code optimization to a game developers, who are always orienting
    // on high-end computer hardware.
    //
    // Anyway - we need to be sure that after list rebuilding index is
    // pointing on the same ammo as we just bough
    MyAmmo = Buyable.ItemAmmoClass;

    while ( ClipAmount > 0 && Buyable != none
            && Buyable.ItemAmmoClass == MyAmmo && Buyable.ItemAmmoCurrent < Buyable.ItemAmmoMax )
    {
        OnBuyClipClick(Buyable);
        Buyable = MyBuyables[Index];
        ClipAmount--;
    }
}

function OnEnterKey()
{
    local GUIBuyable Buyable;

    Buyable = GetSelectedBuyable();
    if ( Buyable == none || Buyable.bMelee )
        return;

    if ( Buyable.bIsVest ) {
        OnBuyVestClick();
    }
    else {
        OnFillAmmoClick(Buyable);
    }
}

function DrawInvItem(Canvas Canvas, int CurIndex, float X, float Y, float Width, float Height, bool bSelected, bool bPending)
{
    local float IconBGSize, ItemBGWidth, AmmoBGWidth, ClipButtonWidth, FillButtonWidth;
    local float TempX, TempY;
    local float StringHeight, StringWidth;
    local ScrnHumanPawn ScrnPawn;
    local int Dosh;

    ScrnPawn = ScrnHumanPawn(PlayerOwner().Pawn);
    Dosh = ScrnPawn.GetAvailableDosh();

    OnClickSound=CS_Click;

    // Initialize the Canvas
    Canvas.Style = 1;
    // Canvas.Font = class'ROHUD'.Static.GetSmallMenuFont(Canvas);
    Canvas.SetDrawColor(255, 255, 255, 255);

    if ( MyBuyables[CurIndex]==None )
    {
        if( MyBuyables.Length==(CurIndex+1) || MyBuyables[CurIndex+1]==None )
            return;

        Canvas.SetPos(X + EquipmentBGXOffset, Y + Height - EquipmentBGYOffset - EquipmentBGHeightScale * Height);
        Canvas.DrawTileStretched(AmmoBackground, EquipmentBGWidthScale * Width, EquipmentBGHeightScale * Height);

        Canvas.SetDrawColor(175, 176, 158, 255);
        Canvas.StrLen(EquipmentString, StringWidth, StringHeight);
        Canvas.SetPos(X + EquipmentBGXOffset + ((EquipmentBGWidthScale * Width - StringWidth) / 2.0), Y + Height - EquipmentBGYOffset - EquipmentBGHeightScale * Height + ((EquipmentBGHeightScale * Height - StringHeight) / 2.0));
        Canvas.DrawText(EquipmentString);
    }
    else
    {
        // Calculate Widths for all components
        IconBGSize = Height;
        ItemBGWidth = (Width * ItemBGWidthScale) - IconBGSize;
        AmmoBGWidth = Width * AmmoBGWidthScale;

        if ( !MyBuyables[CurIndex].bIsVest )
        {
            FillButtonWidth = ((1.0 - ItemBGWidthScale - AmmoBGWidthScale) * Width) - ButtonSpacing;
            ClipButtonWidth = FillButtonWidth * ClipButtonWidthScale;
            FillButtonWidth -= ClipButtonWidth;
        }
        else
        {
            FillButtonWidth = ((1.0 - ItemBGWidthScale - AmmoBGWidthScale) * Width);
        }

        // Offset for the Background
        TempX = X;
        TempY = Y;

        // Draw Item Background
        Canvas.SetPos(TempX, TempY);

        if ( bSelected )
        {
            Canvas.DrawTileStretched(SelectedItemBackgroundLeft, IconBGSize, IconBGSize);
            Canvas.SetPos(TempX + 4, TempY + 4);
            Canvas.DrawTile(PerkTextures[CurIndex], IconBGSize - 8, IconBGSize - 8, 0, 0, 256, 256);

            TempX += IconBGSize;
            Canvas.SetPos(TempX, TempY + ItemBGYOffset);
            Canvas.DrawTileStretched(SelectedItemBackgroundRight, ItemBGWidth, IconBGSize - (2.0 * ItemBGYOffset));
        }
        else
        {
            Canvas.DrawTileStretched(ItemBackgroundLeft, IconBGSize, IconBGSize);
            Canvas.SetPos(TempX + 4, TempY + 4);
            Canvas.DrawTile(PerkTextures[CurIndex], IconBGSize - 8, IconBGSize - 8, 0, 0, 256, 256);

            TempX += IconBGSize;
            Canvas.SetPos(TempX, TempY + ItemBGYOffset);
            Canvas.DrawTileStretched(ItemBackgroundRight, ItemBGWidth, IconBGSize - (2.0 * ItemBGYOffset));
        }

        // Select Text color
        if ( CurIndex == MouseOverIndex && MouseOverXIndex == 0 )
            Canvas.SetDrawColor(255, 255, 255, 255);
        else Canvas.SetDrawColor(0, 0, 0, 255);

        // Draw the item's name
        Canvas.StrLen(NameStrings[CurIndex], StringWidth, StringHeight);
        Canvas.SetPos(TempX + ItemNameSpacing, Y + ((Height - StringHeight) / 2.0));
        Canvas.DrawText(NameStrings[CurIndex]);

        // Draw the item's ammo status if it is not a melee weapon
        if ( !MyBuyables[CurIndex].bMelee )
        {
            TempX += ItemBGWidth + AmmoSpacing;

            Canvas.SetDrawColor(255, 255, 255, 255);
            Canvas.SetPos(TempX, TempY + ((Height - AmmoBGHeightScale * Height) / 2.0));
            Canvas.DrawTileStretched(AmmoBackground, AmmoBGWidth, AmmoBGHeightScale * Height);

            Canvas.SetDrawColor(175, 176, 158, 255);
            Canvas.StrLen(AmmoStrings[CurIndex], StringWidth, StringHeight);
            Canvas.SetPos(TempX + ((AmmoBGWidth - StringWidth) / 2.0), TempY + ((Height - StringHeight) / 2.0));
            Canvas.DrawText(AmmoStrings[CurIndex]);

            TempX += AmmoBGWidth + AmmoSpacing;

            Canvas.SetDrawColor(255, 255, 255, 255);
            Canvas.SetPos(TempX, TempY + ((Height - ButtonBGHeightScale * Height) / 2.0));

            if ( !MyBuyables[CurIndex].bIsVest )
            {
                if ( MyBuyables[CurIndex].ItemAmmoCurrent >= MyBuyables[CurIndex].ItemAmmoMax ||
                     (Dosh < MyBuyables[CurIndex].ItemFillAmmoCost && Dosh < MyBuyables[CurIndex].ItemAmmoCost) )
                {
                    Canvas.DrawTileStretched(DisabledButtonBackground, ClipButtonWidth, ButtonBGHeightScale * Height);
                    Canvas.SetDrawColor(0, 0, 0, 255);
                }
                else if ( CurIndex == MouseOverIndex && MouseOverXIndex == 1 )
                {
                    Canvas.DrawTileStretched(HoverButtonBackground, ClipButtonWidth, ButtonBGHeightScale * Height);
                }
                else
                {
                    Canvas.DrawTileStretched(ButtonBackground, ClipButtonWidth, ButtonBGHeightScale * Height);
                    Canvas.SetDrawColor(0, 0, 0, 255);
                }

                Canvas.StrLen(ClipPriceStrings[CurIndex], StringWidth, StringHeight);
                Canvas.SetPos(TempX + ((ClipButtonWidth - StringWidth) / 2.0), TempY + ((Height - StringHeight) / 2.0));
                Canvas.DrawText(ClipPriceStrings[CurIndex]);

                TempX += ClipButtonWidth + ButtonSpacing;

                Canvas.SetDrawColor(255, 255, 255, 255);
                Canvas.SetPos(TempX, TempY + ((Height - ButtonBGHeightScale * Height) / 2.0));

                if ( MyBuyables[CurIndex].ItemAmmoCurrent >= MyBuyables[CurIndex].ItemAmmoMax ||
                     (Dosh < MyBuyables[CurIndex].ItemFillAmmoCost && Dosh < MyBuyables[CurIndex].ItemAmmoCost) )
                {
                    Canvas.DrawTileStretched(DisabledButtonBackground, FillButtonWidth, ButtonBGHeightScale * Height);
                    Canvas.SetDrawColor(0, 0, 0, 255);
                }
                else if ( CurIndex == MouseOverIndex && MouseOverXIndex == 2 )
                {
                    Canvas.DrawTileStretched(HoverButtonBackground, FillButtonWidth, ButtonBGHeightScale * Height);
                }
                else
                {
                    Canvas.DrawTileStretched(ButtonBackground, FillButtonWidth, ButtonBGHeightScale * Height);
                    Canvas.SetDrawColor(0, 0, 0, 255);
                }
            }
            else
            {
                if ( (PlayerOwner().Pawn.ShieldStrength > 0 && Dosh < MyBuyables[CurIndex].ItemAmmoCost) ||
                     (PlayerOwner().Pawn.ShieldStrength <= 0 && Dosh < MyBuyables[CurIndex].ItemCost) ||
                     MyBuyables[CurIndex].ItemAmmoCurrent >= MyBuyables[CurIndex].ItemAmmoMax )
                {
                    Canvas.DrawTileStretched(DisabledButtonBackground, FillButtonWidth, ButtonBGHeightScale * Height);
                    Canvas.SetDrawColor(0, 0, 0, 255);
                }
                else if ( CurIndex == MouseOverIndex && MouseOverXIndex >= 1 )
                {
                    Canvas.DrawTileStretched(HoverButtonBackground, FillButtonWidth, ButtonBGHeightScale * Height);
                }
                else
                {
                    Canvas.DrawTileStretched(ButtonBackground, FillButtonWidth, ButtonBGHeightScale * Height);
                    Canvas.SetDrawColor(0, 0, 0, 255);
                }
            }

            Canvas.StrLen(FillPriceStrings[CurIndex], StringWidth, StringHeight);
            Canvas.SetPos(TempX + ((FillButtonWidth - StringWidth) / 2.0), TempY + ((Height - StringHeight) / 2.0));
            Canvas.DrawText(FillPriceStrings[CurIndex]);
        }
        Canvas.SetDrawColor(255, 255, 255, 255);
    }
}

function bool InternalOnClick(GUIComponent Sender)
{
    local int NewIndex;
    local float RelativeMouseX;
    local ScrnHumanPawn ScrnPawn;
    local int Dosh;

    if (!IsInClientBounds())
        return false;

    ScrnPawn = ScrnHumanPawn(PlayerOwner().Pawn);
    if (ScrnPawn == none)
        return false;
    Dosh = ScrnPawn.GetAvailableDosh();

    //  Figure out which Item we're clicking on
    NewIndex = CalculateIndex();
    RelativeMouseX = Controller.MouseX - ClientBounds[0];
    if  (RelativeMouseX < ActualWidth() * ItemBGWidthScale) {
        SetIndex(NewIndex);
        MouseOverXIndex = 0;
        return true;
    }
    else {
        RelativeMouseX -= ActualWidth() * (ItemBGWidthScale + AmmoBGWidthScale);

        if (RelativeMouseX > 0) {
            if (MyBuyables[NewIndex].bIsVest) {
                if (Dosh >= MyBuyables[NewIndex].ItemCost || (ScrnPawn.ShieldStrength > 0
                        && Dosh >= MyBuyables[NewIndex].ItemAmmoCost)) {
                    OnBuyVestClick();
                }
            }
            else if (!MyBuyables[NewIndex].bMelee) {
                if ( RelativeMouseX < ActualWidth() * (1.0 - ItemBGWidthScale - AmmoBGWidthScale) * ClipButtonWidthScale )
                    OnBuyClipClick(MyBuyables[NewIndex]); // Buy Clip
                else
                    OnFillAmmoClick(MyBuyables[NewIndex]); // Fill Ammo
            }
        }
    }

    return false;
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if ( State == 1 ) { // key press
        if (Key >= 0x30 && Key <= 0x39) { // 0..9
            Controller.PlayInterfaceSound(CS_Up);
            if ( Key == 0x30 )
                BuyClips(10);
            else
                BuyClips(Key - 0x30);
            return true;
        }

        switch (Key) {
            case 0x08: // IK_Backspace
                Controller.PlayInterfaceSound(CS_Click);
                if (Controller.CtrlPressed) {
                    SellAll(!Controller.ShiftPressed);
                }
                else {
                    OnSellClick(GetSelectedBuyable()); // sell item
                }
                return true;

            case 13: // enter
                OnEnterKey();
                return true;

        }
    }
    return super.InternalOnKeyEvent(Key, State, delta);
}


defaultproperties
{
     UpgradeArmorCaption="Upgrade"
     NoWeightCaption="No Free Weight"
}
