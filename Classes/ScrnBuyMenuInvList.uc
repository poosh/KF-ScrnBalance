/*
 * List of Player's inventory
 */
class ScrnBuyMenuInvList extends SRKFBuyMenuInvList;

var localized string UpgradeArmorCaption;
var localized string NoWeightCaption;

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
    for ( i = 0; i < ItemCount; i++ )
    {
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
        ScrnPawnClass = class'ScrnBalanceSrv.ScrnHumanPawn';

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
    local GUIBuyable MyBuyable, KnifeBuyable, FragBuyable;
    local Inventory CurInv;
    local float CurAmmo, MaxAmmo;
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
    local class<ScrnVestPickup> VestClass;

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

    Perk = class<ScrnVeterancyTypes>(KFPRI.ClientVeteranSkill);
    if( Perk==None )
        Perk = Class'ScrnVeterancyTypes';

    ScrnPawn = ScrnHumanPawn(PlayerOwner().Pawn);
    if ( ScrnPawn != none )
        ScrnPawnClass = ScrnPawn.class;
    else
        ScrnPawnClass = class'ScrnBalanceSrv.ScrnHumanPawn';

    // Fill the Buyables
    for ( CurInv = PlayerOwner().Pawn.Inventory; CurInv != none; CurInv = CurInv.Inventory )
    {
        if ( KFWeapon(CurInv)==None || CurInv.IsA('Welder') || CurInv.IsA('Syringe') )
            continue;

        // weapons can be derived from another even if they aren't of the same type, e.g. Shotgun -> LAW
        // so it's better to compare their pickup classes.
        // Doing that will make easier to add custom weapon modification classes
        // (c) PooSH, 2012
        MyPickup = class<KFWeaponPickup>(CurInv.default.PickupClass);


        if ( MyPickup.IsA('DualDeaglePickup') || MyPickup.IsA('Dual44MagnumPickup')
                || MyPickup.IsA('DualMK23Pistol') || MyPickup.IsA('DualFlareRevolver')
                || KFWeapon(CurInv).DemoReplacement!=None ) {
            DualCoef = 0.5;
        }
        else DualCoef = 1;

        if ( KFWeapon(CurInv).bHasSecondaryAmmo )
            MyPrimaryPickup = MyPickup.default.PrimaryWeaponPickup;
        else
            MyPrimaryPickup = MyPickup;

        MyBuyable = AllocateEntry(KFLR);
        KFWeapon(CurInv).GetAmmoCount(MaxAmmo, CurAmmo);

        MyBuyable.ItemName       = MyPickup.default.ItemShortName;
        MyBuyable.ItemDescription= KFWeapon(CurInv).default.Description;
        MyBuyable.ItemCategorie  = "Melee"; // More dummy.
        MyBuyable.ItemImage      = KFWeapon(CurInv).default.TraderInfoTexture;
        MyBuyable.ItemWeaponClass= KFWeapon(CurInv).class;
        MyBuyable.ItemAmmoClass  = KFWeapon(CurInv).default.FireModeClass[0].default.AmmoClass;
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
            MyBuyable.ItemAmmoCost        =  ceil(MyPrimaryPickup.default.AmmoCost * Perk.static.GetAmmoCostScaling(KFPRI, MyPrimaryPickup) * Perk.static.GetMagCapacityMod(KFPRI, KFWeapon(CurInv)));
            MyBuyable.ItemFillAmmoCost    =  ceil((int(((MaxAmmo - CurAmmo) * float(MyPrimaryPickup.default.AmmoCost)) / float(KFWeapon(CurInv).default.MagCapacity))) * Perk.static.GetAmmoCostScaling(KFPRI, MyPrimaryPickup));
        }
        MyBuyable.ItemAmmoCurrent= CurAmmo;
        MyBuyable.ItemAmmoMax    = MaxAmmo;

        MyBuyable.ItemWeight     = KFWeapon(CurInv).Weight;
        MyBuyable.ItemPower      = MyPickup.default.PowerValue;
        MyBuyable.ItemRange      = MyPickup.default.RangeValue;
        MyBuyable.ItemSpeed      = MyPickup.default.SpeedValue;
        // Hack - setting negative ammo cost blocks weapon from refilling ammo in trader
        MyBuyable.bMelee         = KFWeapon(CurInv).bMeleeWeapon || MyBuyable.ItemAmmoClass==None || MyPickup.default.AmmoCost < 0;
        MyBuyable.bSaleList      = false;
        if ( Perk.static.OverridePerkIndex(MyPickup) )
            MyBuyable.ItemPerkIndex  = Perk.default.PerkIndex;
        else
            MyBuyable.ItemPerkIndex  = MyPickup.default.CorrespondingPerkIndex;

        // Changed from "!= -1" to ">= 0" to prevent possible issues in a future
        if ( KFWeapon(CurInv) != none && KFWeapon(CurInv).SellValue >= 0 )
            MyBuyable.ItemSellValue = KFWeapon(CurInv).SellValue;
        else
            MyBuyable.ItemSellValue = MyBuyable.ItemCost * 0.75;

        if ( PipeBombExplosive(CurInv) != none ) {
            //give 75% of all pipes, not 2 (even if there is only 1 left)
            // calc price per ammo and multiply by ammo count
            MyBuyable.ItemSellValue /= PipeBombExplosive(CurInv).default.FireModeClass[0].default.AmmoClass.default.InitialAmount;
            MyBuyable.ItemSellValue *= PipeBombExplosive(CurInv).AmmoAmount(0);
        }

        if ( !MyBuyable.bMelee && int(MaxAmmo)>int(CurAmmo) )
            AutoFillCost += MyBuyable.ItemFillAmmoCost;

        if ( CurInv.IsA('Knife') )
        {
            MyBuyable.bSellable    = false;
            KnifeBuyable = MyBuyable;
        }
        else if ( CurInv.IsA('Frag') )
        {
            MyBuyable.bSellable    = false;
            FragBuyable = MyBuyable;
        }
        else
        {
            MyBuyable.bSellable    = !KFWeapon(CurInv).default.bKFNeverThrow;
            MyBuyables.Insert(0,1);
            MyBuyables[0] = MyBuyable;
        }



        // =============================== SECONDARY AMMO ===============================
        if ( !KFWeapon(CurInv).bHasSecondaryAmmo )
            continue;

        // Add secondary ammo.

        MyBuyable = AllocateEntry(KFLR);

        KFWeapon(CurInv).GetSecondaryAmmoCount(MaxAmmo, CurAmmo);

        MyBuyable.ItemName        = MyPickup.default.SecondaryAmmoShortName;
        MyBuyable.ItemDescription = KFWeapon(CurInv).default.Description;
        MyBuyable.ItemCategorie   = "Melee";
        MyBuyable.ItemImage       = KFWeapon(CurInv).default.TraderInfoTexture;
        MyBuyable.ItemWeaponClass = KFWeapon(CurInv).class;
        MyBuyable.ItemAmmoClass   = KFWeapon(CurInv).default.FireModeClass[1].default.AmmoClass;
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

        MyBuyable.ItemWeight      = KFWeapon(CurInv).Weight;
        MyBuyable.ItemPower       = MyPickup.default.PowerValue;
        MyBuyable.ItemRange       = MyPickup.default.RangeValue;
        MyBuyable.ItemSpeed       = MyPickup.default.SpeedValue;
        MyBuyable.bMelee          = (KFMeleeGun(CurInv) != none);
        MyBuyable.bSaleList       = false;
        MyBuyable.ItemPerkIndex   = MyPickup.default.CorrespondingPerkIndex;
        MyBuyable.bSellable       = !KFWeapon(CurInv).default.bKFNeverThrow;

        if ( KFWeapon(CurInv) != none && KFWeapon(CurInv).SellValue >= 0 )
            MyBuyable.ItemSellValue = KFWeapon(CurInv).SellValue;
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
        VestClass = ScrnPawn.GetVestClass();
        ScrnPawn.CalcVestCost(VestClass, Cost, AmountToBuy, Price1p);

        MyBuyable.ItemName          = VestClass.default.ItemShortName;
        MyBuyable.ItemDescription   = VestClass.default.Description;
        MyBuyable.ItemWeight        = VestClass.default.Weight;
        MyBuyable.ItemImage         = VestClass.default.TraderInfoTexture;
        MyBuyable.ItemPerkIndex     = VestClass.default.CorrespondingPerkIndex;

        MyBuyable.ItemAmmoMax       = VestClass.default.ShieldCapacity;
        MyBuyable.ItemCost          = VestClass.default.ShieldCapacity * Price1p;
        MyBuyable.ItemAmmoCost      = Price1p;
        MyBuyable.ItemFillAmmoCost  = Cost;
    }
    else {
        MyBuyable.ItemName        = class'ScrnBalanceSrv.ScrnVestPickup'.default.ItemShortName;
        MyBuyable.ItemDescription = class'ScrnBalanceSrv.ScrnVestPickup'.default.Description;
        MyBuyable.ItemWeight      = class'ScrnBalanceSrv.ScrnVestPickup'.default.Weight;
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
    MyBuyable.bSellable       = false;

    // set nade icon corresponding to its type
    if ( FragBuyable != none ) {
        NadeType = Perk.static.GetNadeType(KFPRI);
        if ( NadeType == class'Nade' || NadeType == class'ScrnNade' )
            FragBuyable.ItemPerkIndex = 6; // set demo icon by default
        else
            FragBuyable.ItemPerkIndex = Perk.default.PerkIndex;
    }

    if( MyBuyables.Length<8 )
    {
        MyBuyables.Length = 11;
        MyBuyables[7] = none;
        MyBuyables[8] = KnifeBuyable;
        MyBuyables[9] = FragBuyable;
        MyBuyables[10] = MyBuyable; // ARMOR
    }
    else
    {
        MyBuyables.insert(MyBuyables.Length, 3);
        MyBuyables[MyBuyables.Length-3] = none;
        MyBuyables[MyBuyables.Length-2] = FragBuyable;
        MyBuyables[MyBuyables.Length-1] = MyBuyable; // ARMOR
    }

    //Now Update the list
    UpdateList();
}

function BuyClips(byte ClipAmount)
{
    local GUIBuyable Buyable;
    local class<Ammunition> MyAmmo;

    if ( Index < 0 || Index >= MyBuyables.Length )
        return;

    Buyable = MyBuyables[Index];
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


function bool InternalOnClick(GUIComponent Sender)
{
    local int NewIndex;
    local float RelativeMouseX;

    if ( IsInClientBounds() )
    {
        //  Figure out which Item we're clicking on
        NewIndex = CalculateIndex();
        RelativeMouseX = Controller.MouseX - ClientBounds[0];
        if ( RelativeMouseX < ActualWidth() * ItemBGWidthScale )
        {
            SetIndex(NewIndex);
            MouseOverXIndex = 0;
            return true;
        }
        else
        {
            RelativeMouseX -= ActualWidth() * (ItemBGWidthScale + AmmoBGWidthScale);

            if ( RelativeMouseX > 0 )
            {
                if ( MyBuyables[NewIndex].bIsVest )
                {
                    if ( (PlayerOwner().Pawn.ShieldStrength > 0 && PlayerOwner().PlayerReplicationInfo.Score >= MyBuyables[NewIndex].ItemAmmoCost) || PlayerOwner().PlayerReplicationInfo.Score >= MyBuyables[NewIndex].ItemCost )
                        OnBuyVestClick();
                }
                else if ( !MyBuyables[NewIndex].bMelee )
                {
                    if ( RelativeMouseX < ActualWidth() * (1.0 - ItemBGWidthScale - AmmoBGWidthScale) * ClipButtonWidthScale )
                        OnBuyClipClick(MyBuyables[NewIndex]); // Buy Clip
                    else
                        OnFillAmmoClick(MyBuyables[NewIndex]); // Fill Ammo
                }
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
                OnDblClick(Self); // sell item
                return true;
                break;
        }
    }
    return super.InternalOnKeyEvent(Key, State, delta);
}


defaultproperties
{
     UpgradeArmorCaption="Upgrade"
     NoWeightCaption="No Free Weight"
}
