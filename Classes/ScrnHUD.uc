class ScrnHUD extends SRHUDKillingFloor
    config (ScrnUser);

#exec OBJ LOAD FILE=ScrnTex.utx
#exec OBJ LOAD FILE=ScrnAch_T.utx

//var byte colR, colG, colB;

var localized string strCowboyMode;

var array<localized string> HudStyles;
var const byte HUDSTL_CLASSIC;
var const byte HUDSTL_MODERN;
var const byte HUDSTL_COOL;
var const byte HUDSTL_COOL_LEFT;
var config byte HudStyle;

var array<localized string> BarStyles;
var const byte BARSTL_CLASSIC;
var const byte BARSTL_MODERN;
var const byte BARSTL_MODERN_EX;
var const byte BARSTL_COOL;
var config byte BarStyle;
var deprecated byte PlayerInfoVersionNumber;
var config float PlayerInfoScale, PlayerInfoOffset;  // BarScale

var config int                  MinMagCapacity; //don't show low ammo warning, if weapon magazine smaller than this
var config float                LowAmmoPercent;
// set inside CalculateAmmo()
var transient bool              bLowAmmo;
var transient float             WeaponChargePct; //0..1
var transient int               WeaponMaxCharge;
var transient float             MaxAmmoSecondary; // including perk bonus
var transient int               CurMagAmmo;
var transient bool              bHasLeftGun;
var transient int               CurLeftGunAmmo; // for dual wield: ammo in the left gun. CurMagAmmo displays total ammo in both guns
var transient bool              bLeftGunLowAmmo;
var transient bool              bRightGunLowAmmo;

var() texture                   texCowboy;
var() config float              CowboyTileWidth;
var() float                     CowboyTileY;

var()   SpriteWidget            BlamedIcon;
var     float                   BlamedIconSize;

var()   SpriteWidget            SingleNadeIcon;

var()   SpriteWidget            LeftGunAmmoBG;
var()   SpriteWidget            LeftGunAmmoIcon;
var()   NumericWidget           LeftGunAmmoDigits;


// configurable variables from ScrnBuyMenuSaleList
var globalconfig color TraderGroupColor, TraderActiveGroupColor, TraderSelectedGroupColor;
var globalconfig Color TraderPriceButtonColor, TraderPriceButtonDisabledColor, TraderPriceButtonSelectedColor;

var protected class<ScrnScoreBoard> ScrnScoreBoardClass; // modder friendly interface

// vars below are set inside LinkActors()
var protected transient class<ScrnVeterancyTypes> ScrnPerk;
var private transient class<KFVeterancyTypes> PrevPerk;
var protected transient ScrnPlayerController ScrnPC;
var protected transient ScrnHumanPawn ScrnPawnOwner; // ScrN Pawn we are playing or spectating
var protected transient KFWeapon OwnerWeapon;
var protected transient class<KFWeapon> OwnerWeaponClass;
var protected transient ScrnGameReplicationInfo ScrnGRI;
var protected transient ScrnCustomPRI ScrnPRI;
var protected transient bool bSpecialPortrait; // if true, then player's avatar is drawn instead of character
var protected transient bool bSpectating; // are we spectating?
var protected transient bool bSpectatingScrn; // are we spectating ScrnHumanPawn
var protected transient bool bSpectatingZED; // are we spectating KFMonster
var protected transient bool bCoolHudActive; // is new hud active atm?

var HudOverlay PerkOverlay;
var Material   CriticalOverlay;
var transient float CriticalOverlayTimer;

var config byte SpecHeaderFont;
var localized string strFollowing;
var localized string strTrader;

var bool bCoolHud, bCoolHudLeftAlign;
var config float CoolHudScale;
var config float CoolHudAmmoOffsetX, CoolHudAmmoOffsetY, CoolHudAmmoScale;
var bool bCoolHudTeamColor;
var color CoolHudColor, CoolHudAmmoColor;
var config byte PerkStarsMax;
var config bool bShowLeftGunAmmo;
var Material CoolBarBase,CoolBarOverlay;
var int CoolBarSize, CoolHealthBarTop, CoolHealthBarHeight;
var color HealthBarColor, HealingBarColor, FullHealthColor, OverchargeHealthColor, LowHealthColor, ArmorBarColor, BigArmorColor;
var float CoolPerkToBarSize, CoolStarToBarSize, CoolStarAngleRad, CoolPerkOffsetY, CoolPerkLevelOffsetY;
var float CoolIconToBarSize;
var transient bool bHealthFadeOut;
var transient float HealthFading;
var protected transient int OldHealth, OldArmor;
var config float CoolHealthFadeOutTime;
var localized string strBonusLevel;
var()   NumericWidget           CoolPerkLevelDigits;
var()   SpriteWidget            CoolCashIcon;
var()   NumericWidget           CoolCashDigits;
var Color LowAmmoColor;
var Color NoAmmoColor;

var transient float PulseAlpha;
var float PulseRate;

var transient byte BlinkAlpha;
var transient float BlinkPhase;
var float BlinkRate;

var transient bool bDrawingBonusLevel, bXPBonusFadingOut, bXPBonusFadingIn;
var transient float CoolPerkAlpha;
var transient float XPBonusNextPlaseTime, XPBonusFadeTime;

var float XPLevelShowTime, BonusLevelShowTime, XPBonusFadeRate;

var protected transient float MsgTopY; // top Y coordinate up upper console message displayed on the HUD

enum EScrnEffect {
    EFF_NONE,
    EFF_PULSE,
    EFF_BLINK
};

struct SHitInfo
{
    var string Text;
    var float LastHit;
};

struct DamageInfo
{
    var int Damage;
    var float HitTime;
    var Vector HitLocation;
    var byte DamTypeNum;
    var float RandX, RandY;
    var color FontColor;
};

const DAMAGEPOPUP_COUNT = 32;
var DamageInfo DamagePopups[32];
var int NextDamagePopupIndex;


const DAM_HIDE      = 0;
const DAM_COMBO     = 1;
const DAM_FULL      = 2;
var config byte ShowDamages;
var config byte DamagePopupFont;
var config float DamagePopupFadeOutTime;

var config bool bShowSpeed;
var config float SpeedometerX, SpeedometerY;
var config byte SpeedometerFont;

var bool bHidePlayerInfo;

var class<KFMonster> BlamedMonsterClass;
var float BlameCountdown;
var float BlameDrawDistance; // max distance to draw a turn on blamed pawn's head

var config bool bDrawSpecDeaths;

var Color WhiteAlphaColor; // white color with applied KFHUDAlpha. It is safe to use default.WhiteAlphaColor as well
var array<color> PerkColors;
var color TeamColors[2]; // moved from TSCHUD
var color TextColors[2];

var localized string strPendingItems;
var material ChatIcon;

var bool bZedHealthShow;
var bool bDebugSpectatingHUD;

function PostBeginPlay()
{
    super.PostBeginPlay();

    // prevent using spedometer as crosshair
    if ( SpeedometerX > 0.4 && SpeedometerX < 0.6
            && SpeedometerY > 0.4 && SpeedometerY < 0.6 ) {
        SpeedometerX = 0.985;
        SpeedometerY = 0.80;
        PlayerOwner.ClientMessage("HUD Cheat Prevention: Speedometer position set to default");
    }

    if ( MyColorMod==None ) {
        MyColorMod = ColorModifier(Level.ObjectPool.AllocateObject(class'ColorModifier'));
        MyColorMod.AlphaBlend = True;
        MyColorMod.Color.R = 255;
        MyColorMod.Color.B = 255;
        MyColorMod.Color.G = 255;
    }

    SpecHeaderFont = clamp(SpecHeaderFont, 0, 1);

    // force update
    SetHudStyle(HudStyle);
    SetBarStyle(BarStyle);
}

function Destroyed()
{
    if ( PerkOverlay != none )
        PerkOverlay.Destroy();
    super.Destroyed();
}

// Draw Health Bars for damage opened doors.
function DrawDoorHealthBars(Canvas C)
{
    local KFDoorMover DamageDoor;
    local vector CameraLocation, CamDir, TargetLocation, HBScreenPos;
    local rotator CameraRotation;
    local name DoorTag;
    local int i;
    local float Distance;

    if( PawnOwner==None )
        return;

    if ( (Level.TimeSeconds>LastDoorBarHealthUpdate) || (Welder(PawnOwner.Weapon)!=none && PlayerOwner.bFire==1) )
    {
        Distance = 300.00;
        //while holding welder door health bars are visible from longer distance
        if ( ScrnPerk != none && Welder(PawnOwner.Weapon) != none) {
            Distance *= ScrnPerk.static.GetDoorHealthVisibilityScaling(KFPRI, PawnOwner);
        }

        DoorCache.Length = 0;

        foreach CollidingActors(class'KFDoorMover', DamageDoor, Distance, PlayerOwner.CalcViewLocation)
        {
            if ( DamageDoor.WeldStrength<=0 )
                continue;

            DoorCache[DoorCache.Length] = DamageDoor;

            C.GetCameraLocation(CameraLocation, CameraRotation);
            TargetLocation = DamageDoor.WeldIconLocation;
            TargetLocation.Z = CameraLocation.Z;
            CamDir    = vector(CameraRotation);

            if ( Normal(TargetLocation - CameraLocation) dot Normal(CamDir) >= 0.1 && DamageDoor.Tag != DoorTag && FastTrace(DamageDoor.WeldIconLocation - ((DoorCache[i].WeldIconLocation - CameraLocation) * 0.25), CameraLocation) )
            {
                HBScreenPos = C.WorldToScreen(TargetLocation);
                DrawDoorBar(C, HBScreenPos.X, HBScreenPos.Y, DamageDoor.WeldStrength / DamageDoor.MaxWeld, 255);
                DoorTag = DamageDoor.Tag;
            }
        }
        LastDoorBarHealthUpdate = Level.TimeSeconds+0.2;
    }
    else
    {
        for ( i = 0; i < DoorCache.Length; i++ )
        {
            if ( DoorCache[i].WeldStrength<=0 )
                continue;
             C.GetCameraLocation(CameraLocation, CameraRotation);
            TargetLocation = DoorCache[i].WeldIconLocation;
            TargetLocation.Z = CameraLocation.Z;
            CamDir    = vector(CameraRotation);

            if ( Normal(TargetLocation - CameraLocation) dot Normal(CamDir) >= 0.1 && DoorCache[i].Tag != DoorTag && FastTrace(DoorCache[i].WeldIconLocation - ((DoorCache[i].WeldIconLocation - CameraLocation) * 0.25), CameraLocation) )
            {
                HBScreenPos = C.WorldToScreen(TargetLocation);
                DrawDoorBar(C, HBScreenPos.X, HBScreenPos.Y, DoorCache[i].WeldStrength / DoorCache[i].MaxWeld, 255);
                DoorTag = DoorCache[i].Tag;
            }
        }
    }
}


simulated function DrawCowboyMode(Canvas C)
{
    C.SetDrawColor(255, 64, 64, KFHUDAlpha);
    C.SetPos(0.5 * C.ClipX * (1.0 - CowboyTileWidth), C.ClipY * CowboyTileY);
    C.DrawTile(texCowboy, C.ClipX * CowboyTileWidth, 64 * (C.ClipX * CowboyTileWidth)/512.0, 0, 0, 512, 64);
}

simulated function string GetSpeedStr(Canvas C)
{
    local int Speed;
    local string s;
    local vector Velocity2D;

    if ( PawnOwner == none )
        return s;

    Velocity2D = PawnOwner.Velocity;
    Velocity2D.Z = 0;
    Speed = round(VSize(Velocity2D));
    s = string(Speed);
    if ( PlayerOwner.Pawn == PawnOwner ) {
        // GroundSpeed is replicated to owner pawn only
        Speed = round(PawnOwner.GroundSpeed);
        s $= "/" $ Speed;
    }

    if ( Speed > 240 ) {
        // speed bonus - in blue
        C.DrawColor.R = 0;
        C.DrawColor.G = 100;
        C.DrawColor.B = 255;
    }
    else if ( Speed > 200 ) {
        // melee speed - in green
        C.DrawColor.R = 0;
        C.DrawColor.G = 206;
        C.DrawColor.B = 0;
    }
    else {
        // red
        C.DrawColor.R = 255;
        C.DrawColor.G = 64;
        C.DrawColor.B = 64;
    }
    C.DrawColor.A = KFHUDAlpha;
    return s;
}


simulated function DrawCookingBar(Canvas C)
{
    //local inventory inv;
    local ScrnFrag aFrag;
    local float MyBarPercentage;
    local float MyBarLength, MyBarHeight, PosX, PosY;
    local float colR, colG;

    if ( KFPawn(PawnOwner) == none )
        return;

    aFrag = ScrnFrag(KFPawn(PawnOwner).SecondaryItem);
    if ( aFrag == none || !aFrag.bCooking)
        return;

    if ( ScrnPerk == none || !ScrnPerk.static.CanShowNadeCookingBar(KFPRI) )
        return;

    MyBarPercentage = 1.0 - fclamp((aFrag.CookExplodeTimer - Level.TimeSeconds)
        / class'ScrnNade'.default.ExplodeTimer, 0, 1);

    MyBarLength = C.ClipX * 0.2;
    MyBarHeight = 12;
    PosX = (C.ClipX - MyBarLength) / 2;
    PosY = C.ClipY * 0.8; //bottom center

    //border
    C.SetPos(PosX, PosY);
    C.SetDrawColor(192, 192, 192, KFHUDAlpha);
    C.DrawTileStretched(WhiteMaterial, MyBarLength, MyBarHeight);

    //fill
    C.SetPos(PosX + 1.0, PosY + 1.0);
    // green -> yellow -> red
    if ( MyBarPercentage > 0.5 )
        colR = 255;
    if ( MyBarPercentage < 0.75 )
        colG = 255;
    C.SetDrawColor(colR, colG, 0, KFHUDAlpha);
    C.DrawTileStretched(WhiteMaterial, (MyBarLength - 2.0) * MyBarPercentage, MyBarHeight - 2.0);
}


simulated function DrawEndGameHUD(Canvas C, bool bVictory)
{
    super.DrawEndGameHUD(C, bVictory);
    //display end-game achievements
    C.Reset();
    DisplayLocalMessages(C);
}


simulated function DrawHudPassA (Canvas C)
{
    DrawStoryHUDInfo(C);
    DrawDoorHealthBars(C);
    if ( ScrnPawnOwner != none && ScrnPawnOwner.bCowboyMode && !bShowScoreBoard && !bSpectating )
        DrawCowboyMode(C);

    if ( bCoolHudActive ) {
        // draw new HUD
        DrawCoolHud(C);
        // some old HUD items
        if ( HealthFading > 5 ) {
            if ( bCoolHudLeftAlign ) {
                HealthDigits.OffsetX = 64*(CoolHudScale-2) - 4*CoolHudScale - 48;
                ArmorDigits.OffsetX = 128*(CoolHudScale-2) + 4*CoolHudScale + 32;
                HealthDigits.OffsetY = -72*CoolHudScale + 16;
                ArmorDigits.OffsetY = HealthDigits.OffsetY;
            }
            HealthIcon.Tints[0].A = HealthFading;
            HealthIcon.Tints[1].A = HealthFading;
            HealthDigits.Tints[0].A = HealthFading;
            HealthDigits.Tints[1].A = HealthFading;
            if ( !bCoolHudLeftAlign )
                DrawSpriteWidget(C, HealthIcon);
            DrawNumericWidget(C, HealthDigits, DigitsSmall);

            if ( ArmorDigits.Value > 0 ) {
                ArmorIcon.Tints[0].A = HealthFading;
                ArmorIcon.Tints[1].A = HealthFading;
                ArmorDigits.Tints[0].A = HealthFading;
                ArmorDigits.Tints[1].A = HealthFading;
                if ( !bCoolHudLeftAlign )
                    DrawSpriteWidget(C, ArmorIcon);
                DrawNumericWidget(C, ArmorDigits, DigitsSmall);
            }
            HealthDigits.OffsetX = 0;
            ArmorDigits.OffsetX = 0;
            HealthDigits.OffsetY = 0;
            ArmorDigits.OffsetY = 0;
        }
        if ( bDisplayQuickSyringe )
            DrawQuickSyringe(C);
    }
    else {
        // restore health alpha to default
        HealthIcon.Tints[0].A = KFHUDAlpha;
        HealthIcon.Tints[1].A = KFHUDAlpha;
        HealthDigits.Tints[0].A = KFHUDAlpha;
        HealthDigits.Tints[1].A = KFHUDAlpha;
        ArmorIcon.Tints[0].A = KFHUDAlpha;
        ArmorIcon.Tints[1].A = KFHUDAlpha;
        ArmorDigits.Tints[0].A = KFHUDAlpha;
        ArmorDigits.Tints[1].A = KFHUDAlpha;
        // classic hud
        DrawOldHudItems(C);
    }

    if ( bZedHealthShow )
        DrawZedHealth(C);
    else if ( ScrnPerk != none )
        ScrnPerk.Static.SpecialHUDInfo(KFPRI, C);

    if ( Level.TimeSeconds - LastVoiceGainTime < 0.333 )  {
        if ( !bUsingVOIP && PlayerOwner != None && PlayerOwner.ActiveRoom != None &&
             PlayerOwner.ActiveRoom.GetTitle() == "Team" )
        {
            bUsingVOIP = true;
            PlayerOwner.NotifySpeakingInTeamChannel();
        }
        DisplayVoiceGain(C);
    }
    else
        bUsingVOIP = false;

    if ( bDisplayInventory || bInventoryFadingOut )
        DrawInventory(C);

    if ( BlamedMonsterClass != none )
        DrawBlameIcons(C);
    if ( ShowDamages > 0 )
        DrawDamage(C);

    if ( bSpectatingScrn || bSpectatingZED )
        DrawFirstPersonSpectatorHUD(C);
    else {
        if ( ScrnPawnOwner != none ) {
            DrawCookingBar(C);
        }
        if ( Level.NetMode == NM_Client && ScrnClientPerkRepLink(ClientRep) != none && ScrnClientPerkRepLink(ClientRep).PendingItems > 0 ) {
            C.Font = GetConsoleFont(C);
            C.SetPos(0, 0);
            C.SetDrawColor(160, 160, 160, 255);
            C.DrawText(strPendingItems @ ScrnClientPerkRepLink(ClientRep).PendingItems);
        }
    }
}

simulated function DrawHudPassC(Canvas C)
{
    DrawFadeEffect(C);

    if ( bShowScoreBoard && ScoreBoard != None )
        ScoreBoard.DrawScoreboard(C);

    // portrait
    if ( bShowPortrait && (Portrait != None) )
        DrawPortraitSE(C); // finally this is not final :)  -- PooSH

    if( bCrosshairShow && bShowKFDebugXHair )
        DrawCrosshair(C);

    // Slow, for debugging only
    if( bDebugPlayerCollision && (class'ROEngine.ROLevelInfo'.static.RODebugMode() || Level.NetMode == NM_StandAlone) )
        DrawPointSphere();
}

simulated function DrawQuickSyringe(Canvas C)
{
    local float t;
    local byte A;
    local Syringe S;

    t = Level.TimeSeconds - QuickSyringeStartTime; // time elapsed
    if ( t > QuickSyringeDisplayTime ) {
        bDisplayQuickSyringe = false;
        return;
    }

    S = Syringe(PawnOwner.FindInventoryType(class'Syringe'));
    if ( S == none ) {
        QuickSyringeDigits.Value = 0;
    }
    else
        QuickSyringeDigits.Value = S.ChargeBar() * 100;

    if ( QuickSyringeDigits.Value < 50 ) {
        QuickSyringeDigits.Tints[0].R = 128;
        QuickSyringeDigits.Tints[0].G = 128;
        QuickSyringeDigits.Tints[0].B = 128;
    }
    else if ( QuickSyringeDigits.Value < 100 ) {
        QuickSyringeDigits.Tints[0].R = 192;
        QuickSyringeDigits.Tints[0].G = 96;
        QuickSyringeDigits.Tints[0].B = 96;
    }
    else {
        QuickSyringeDigits.Tints[0] = TeamColors[TeamIndex];
    }
    QuickSyringeDigits.Tints[1] = QuickSyringeDigits.Tints[0];


    if ( bCoolHudActive && !bCoolHudLeftAlign ) {
        QuickSyringeIcon.PosX = WeightIcon.PosX;
        QuickSyringeDigits.PosX = WeightDigits.PosX;
    }
    else {
        QuickSyringeIcon.PosX = default.QuickSyringeIcon.PosX;
        QuickSyringeDigits.PosX = default.QuickSyringeDigits.PosX;
    }

    A = KFHUDAlpha;
    if ( t < QuickSyringeFadeInTime )
        A = 255 * t / QuickSyringeFadeInTime;
    else {
        t = QuickSyringeDisplayTime - t; // time remaining
        if ( t < QuickSyringeFadeOutTime )
            A = 255 * t / QuickSyringeFadeOutTime;
    }
    A = min(A, KFHUDAlpha);
    QuickSyringeBG.Tints[0].A = A;
    QuickSyringeBG.Tints[1].A = A;
    QuickSyringeIcon.Tints[0].A = A;
    QuickSyringeIcon.Tints[1].A = A;
    QuickSyringeDigits.Tints[0].A = A;
    QuickSyringeDigits.Tints[1].A = A;

    if ( !bLightHud && !bCoolHudActive )
        DrawSpriteWidget(C, QuickSyringeBG);
    DrawSpriteWidget(C, QuickSyringeIcon);
    DrawNumericWidget(C, QuickSyringeDigits, DigitsSmall);
}

simulated function DrawOldHudItems(Canvas C)
{
    local byte Counter, TempLevel;
    local float TempX, TempY, TempSize, BonusPerkX;
    local Material TempMaterial, TempStarMaterial;

    if ( bShowSpeed ) {
        C.Font = LoadSmallFontStatic(SpeedometerFont);
        C.SetPos(C.ClipX * SpeedometerX, C.ClipY * SpeedometerY);
        C.DrawText(GetSpeedStr(C) $ " ups");
    }

    // HEALTH
    if ( !bLightHud && !bSpectatingZED )
        DrawSpriteWidget(C, HealthBG);
    DrawSpriteWidget(C, HealthIcon);
    DrawNumericWidget(C, HealthDigits, DigitsSmall);

    if ( bSpectatingZED )
        return;

    // ARMOR
    if ( !bLightHud )
        DrawSpriteWidget(C, ArmorBG);
    if ( !bLightHud || ArmorDigits.Value > 0 ) {
        DrawSpriteWidget(C, ArmorIcon);
        DrawNumericWidget(C, ArmorDigits, DigitsSmall);
    }

    // WEIGHT
    if ( ScrnPawnOwner != none ) {
        C.SetPos(C.ClipX * WeightBG.PosX, C.ClipY * WeightBG.PosY);

        if ( !bLightHud )
            C.DrawTile(WeightBG.WidgetTexture, WeightBG.WidgetTexture.MaterialUSize() * WeightBG.TextureScale * 1.5 * HudCanvasScale * ResScaleX * HudScale, WeightBG.WidgetTexture.MaterialVSize() * WeightBG.TextureScale * HudCanvasScale * ResScaleY * HudScale, 0, 0, WeightBG.WidgetTexture.MaterialUSize(), WeightBG.WidgetTexture.MaterialVSize());

        DrawSpriteWidget(C, WeightIcon);

        C.Font = LoadSmallFontStatic(5);
        C.FontScaleX = C.ClipX / 1024.0;
        C.FontScaleY = C.FontScaleX;
        C.SetPos(C.ClipX * WeightDigits.PosX, C.ClipY * WeightDigits.PosY);
        C.DrawColor = WeightDigits.Tints[0];
        if ( bSpectating )
            C.DrawText(string(ScrnPawnOwner.SpecWeight));
        else
            C.DrawText(int(ScrnPawnOwner.CurrentWeight)$"/"$int(ScrnPawnOwner.MaxCarryWeight));
        C.FontScaleX = 1;
        C.FontScaleY = 1;
    }

    // NADES
    if ( !bLightHud )
        DrawSpriteWidget(C, GrenadeBG);
    DrawSpriteWidget(C, GrenadeIcon);
    DrawNumericWidget(C, GrenadeDigits, DigitsSmall);

    if ( bDisplayQuickSyringe && !ClassIsChildOf(OwnerWeaponClass, class'Syringe') )
        DrawQuickSyringe(C);

    if ( OwnerWeaponClass != none ) {
        if ( KFMedicGun(OwnerWeapon) != none ) {
            MedicGunDigits.Value = KFMedicGun(OwnerWeapon).ChargeBar() * 100.0;
            if ( MedicGunDigits.Value * 5 < OwnerWeapon.FireModeClass[1].default.AmmoPerFire ) {
                MedicGunDigits.Tints[0].R = 128;
                MedicGunDigits.Tints[0].G = 128;
                MedicGunDigits.Tints[0].B = 128;
            }
            else if ( MedicGunDigits.Value < 100 ) {
                MedicGunDigits.Tints[0].R = 192;
                MedicGunDigits.Tints[0].G = 96;
                MedicGunDigits.Tints[0].B = 96;
            }
            else {
                MedicGunDigits.Tints[0] = default.MedicGunDigits.Tints[0];
            }
            MedicGunDigits.Tints[0].A = KFHUDAlpha;
            MedicGunDigits.Tints[1] = MedicGunDigits.Tints[0];
            if ( !bLightHud )
                DrawSpriteWidget(C, MedicGunBG);
            DrawSpriteWidget(C, MedicGunIcon);
            DrawNumericWidget(C, MedicGunDigits, DigitsSmall);
        }

        if ( ClassIsChildOf(OwnerWeaponClass, class'Syringe') ) {
            if ( !bLightHud )
                DrawSpriteWidget(C, SyringeBG);
            DrawSpriteWidget(C, SyringeIcon);
            DrawNumericWidget(C, SyringeDigits, DigitsSmall);
        }
        else if ( ClassIsChildOf(OwnerWeaponClass, class'Welder') ) {
            if ( !bLightHud )
                DrawSpriteWidget(C, WelderBG);
            DrawSpriteWidget(C, WelderIcon);
            DrawNumericWidget(C, WelderDigits, DigitsSmall);
        }
        else if ( !OwnerWeaponClass.default.bMeleeWeapon && OwnerWeaponClass.default.bConsumesPhysicalAmmo ) {
            if ( !bLightHud )
                DrawSpriteWidget(C, ClipsBG);

            DrawNumericWidget(C, ClipsDigits, DigitsSmall);

            if ( ClassIsChildOf(OwnerWeaponClass, class'LAW') )
                DrawSpriteWidget(C, LawRocketIcon);
            else if ( ClassIsChildOf(OwnerWeaponClass, class'Crossbow') )
                DrawSpriteWidget(C, ArrowheadIcon);
            else if ( ClassIsChildOf(OwnerWeaponClass, class'CrossBuzzSaw') )
                DrawSpriteWidget(C, SawAmmoIcon);
            else if ( ClassIsChildOf(OwnerWeaponClass, class'PipeBombExplosive') )
                DrawSpriteWidget(C, PipeBombIcon);
            else if ( ClassIsChildOf(OwnerWeaponClass, class'M79GrenadeLauncher') )
                DrawSpriteWidget(C, M79Icon);
            else if ( OwnerWeaponClass == class'HuskGun' ) // ScrnHuskGun handled differently
                DrawSpriteWidget(C, HuskAmmoIcon);
            else if ( ClassIsChildOf(OwnerWeaponClass, class'M99SniperRifle') )
                DrawSpriteWidget(C, SingleBulletIcon);
            else {
                // Ammo in magazine
                if ( !bLightHud )
                    DrawSpriteWidget(C, BulletsInClipBG);
                DrawNumericWidget(C, BulletsInClipDigits, DigitsSmall);

                if ( ClassIsChildOf(OwnerWeaponClass, class'Flamethrower')
                        || ClassIsChildOf(OwnerWeaponClass, class'ScrnChainsaw') )
                {
                    DrawSpriteWidget(C, FlameIcon);
                    DrawSpriteWidget(C, FlameTankIcon);
                }
                else if ( ClassIsChildOf(OwnerWeaponClass, class'Shotgun')
                        || ClassIsChildOf(OwnerWeaponClass, class'BoomStick')
                        || ClassIsChildOf(OwnerWeaponClass, class'Winchester')
                        || ClassIsChildOf(OwnerWeaponClass, class'BenelliShotgun') )
                {
                    DrawSpriteWidget(C, SingleBulletIcon);
                    DrawSpriteWidget(C, BulletsInClipIcon);
                }
                else if ( ClassIsChildOf(OwnerWeaponClass, class'ZEDGun')
                        || ClassIsChildOf(OwnerWeaponClass, class'ZEDMKIIWeapon') )
                {
                    DrawSpriteWidget(C, ClipsIcon);
                    DrawSpriteWidget(C, ZedAmmoIcon);
                }
                else if ( ClassIsChildOf(OwnerWeaponClass, class'SealSquealHarpoonBomber')
                        || ClassIsChildOf(OwnerWeaponClass, class'SeekerSixRocketLauncher') )
                {
                    DrawSpriteWidget(C, ClipsIcon);
                    DrawSpriteWidget(C, SingleNadeIcon);
                }
                else if ( ClassIsChildOf(OwnerWeaponClass, class'M32GrenadeLauncher') ) {
                    DrawSpriteWidget(C, M79Icon);
                    DrawSpriteWidget(C, SingleNadeIcon);
                }
                else if ( ClassIsChildOf(OwnerWeaponClass, class'ScrnHuskGun') ) {
                    DrawSpriteWidget(C, HuskAmmoIcon);
                    DrawSpriteWidget(C, ZedAmmoIcon);
                }
                else {
                    DrawSpriteWidget(C, ClipsIcon);
                    DrawSpriteWidget(C, BulletsInClipIcon);
                }
            }
        }

        // FLASHLIGHT
        if ( OwnerWeapon != none && OwnerWeapon.bTorchEnabled ) {
            if ( !bLightHud )
                DrawSpriteWidget(C, FlashlightBG);
            DrawNumericWidget(C, FlashlightDigits, DigitsSmall);

            if ( OwnerWeapon.FlashLight != none && OwnerWeapon.FlashLight.bHasLight )
                DrawSpriteWidget(C, FlashlightIcon);
            else
                DrawSpriteWidget(C, FlashlightOffIcon);
        }


        // SECONDARY AMMO or LEFT GUN of dual pistols
        if ( bHasLeftGun ) {
            if ( !bLightHud )
                DrawSpriteWidget(C, LeftGunAmmoBG);
            DrawNumericWidget(C, LeftGunAmmoDigits, DigitsSmall);
            DrawSpriteWidget(C, LeftGunAmmoIcon);
        }
        else if ( (OwnerWeapon != none && OwnerWeapon.bHasSecondaryAmmo) || (bSpectating && CurClipsSecondary > 0) ) {
            if ( !bLightHud )
                DrawSpriteWidget(C, SecondaryClipsBG);
            DrawNumericWidget(C, SecondaryClipsDigits, DigitsSmall);
            DrawSpriteWidget(C, SecondaryClipsIcon);
        }
    }

    // DOSH
    if ( KFGRI != none && KFGRI.bHUDShowCash ) {
        DrawSpriteWidget(C, CashIcon);
        DrawNumericWidget(C, CashDigits, DigitsBig);
    }

    // PERK - RELATED STUFF
    if ( ScrnPerk == none )
        return;

    // EXPERIENCE LEVEL
    TempSize = 36 * VeterancyMatScaleFactor * 1.4;
    TempX = C.ClipX * 0.007;
    TempY = C.ClipY * 0.93 - TempSize;
    C.DrawColor = WhiteColor;

    TempLevel = KFPRI.ClientVeteranSkillLevel;
    if( ClientRep!=None && (TempLevel+1)<ClientRep.MaximumLevel ) {
        // Draw progress bar.
        bDisplayingProgress = true;
        if( NextLevelTimer<Level.TimeSeconds ) {
            NextLevelTimer = Level.TimeSeconds+3.f;
            LevelProgressBar = ScrnPerk.Static.GetTotalProgress(ClientRep,TempLevel+1);
        }
        ScrnScoreBoardClass.Static.DrawProgressBar(C,TempX,TempY-TempSize*0.12f,TempSize*2.f,TempSize*0.1f,VisualProgressBar);
    }

    C.DrawColor.A = KFHUDAlpha;
    TempLevel = ScrnPerk.Static.PreDrawPerk(C,TempLevel,TempMaterial,TempStarMaterial);
    C.SetPos(TempX, TempY);
    C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());

    TempX += (TempSize - VetStarSize);
    TempY += (TempSize - (2.0 * VetStarSize));

    TempLevel = min(TempLevel, PerkStarsMax);
    while( TempLevel > 0 ) {
        C.SetPos(TempX, TempY-(Counter*VetStarSize*0.8f));
        C.DrawTile(TempStarMaterial, VetStarSize, VetStarSize, 0, 0, TempStarMaterial.MaterialUSize(), TempStarMaterial.MaterialVSize());

        if( ++Counter==5 ) {
            Counter = 0;
            TempX+=VetStarSize;
        }
        --TempLevel;
    }

    BonusPerkX = TempX + VetStarSize;
    TempX = BonusPerkX + (TempSize - VetStarSize);
    TempY = C.ClipY * 0.93 - TempSize;
    // bonus level
    if ( KFPRI != none && ScrnPerk.static.GetClientVeteranSkillLevel(KFPRI) != KFPRI.ClientVeteranSkillLevel ) {
        TempLevel = ScrnPerk.static.GetClientVeteranSkillLevel(KFPRI);
        Counter = 0;
        TempLevel = ScrnPerk.Static.PreDrawPerk(C,TempLevel,TempMaterial,TempStarMaterial);
        C.SetPos(BonusPerkX, TempY);
        C.DrawColor = WhiteAlphaColor;
        C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());

        TempY += (TempSize - (2.0 * VetStarSize));

        TempLevel = min(TempLevel, PerkStarsMax);
        while( TempLevel > 0 ) {
            C.SetPos(TempX, TempY-(Counter*VetStarSize*0.8f));
            C.DrawTile(TempStarMaterial, VetStarSize, VetStarSize, 0, 0, TempStarMaterial.MaterialUSize(), TempStarMaterial.MaterialVSize());

            if( ++Counter==5 ) {
                Counter = 0;
                TempX+=VetStarSize;
            }
            -- TempLevel;
        }
    }
    // adjust console message location
    ConsoleMessagePosX = fmax((TempX + 2*VetStarSize) / C.ClipX, 0.105);
    ConsoleMessagePosY = default.ConsoleMessagePosY;


    // AVATAR AND CLAN ICON
    if ( ScrnPRI != none ) {
        if ( KFGRI != none && !KFGRI.bWaveInProgress ) {
            TempMaterial = ScrnPRI.GetSpecialIcon();
            if ( TempMaterial != none ) {
                TempX = C.ClipX * 0.007;
                TempY = C.ClipY * 0.93 - 2.24*TempSize;
                // TempX += VetStarSize*2;
                // TempY = C.ClipY * 0.93 - TempSize;
                C.SetPos(TempX, TempY);
                C.DrawColor = WhiteAlphaColor;
                C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());

                if ( ScrnPRI.GetClanIcon() != TempMaterial ) {
                    TempMaterial = ScrnPRI.GetClanIcon();
                    if ( TempMaterial != none ) {
                        C.SetPos(BonusPerkX, TempY);
                        C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());
                    }
                }
            }
        }
    }
}

// allows child classes to shift Cool HUD, they need to draw something beneath it
simulated function CalcCoolHudCoords(Canvas C, float BaseSize, out float XCenter, out float YBottom)
{
    if ( bCoolHudLeftAlign )
        XCenter = BaseSize * (0.6 + CoolIconToBarSize);
    else
        XCenter = C.ClipX / 2;
    YBottom = C.ClipY;
}

simulated function DrawCoolHud(Canvas C)
{
    local float XL, YL, TempX, TempY, BaseSize, TempSize, Offset, Pct;
    local float XCenter, YBottom, StatusBarHeight, fZoom;
    local Material TempMaterial;
    local byte Counter, TempLevel;
    local String s;

    if ( KFPRI == none )
        return;

    // init
    fZoom = CoolHudScale * C.ClipY/1080; // scale by resolution/aspect ratio
    BaseSize = 64.f * fZoom;
    C.Font = GetFontSizeIndex(C, 2*fZoom-8);
    CalcCoolHudCoords(C, BaseSize, XCenter, YBottom);

    s = class'ScrnUnicode'.default.Dosh @ int(KFPRI.Score);
    C.TextSize(s, XL, StatusBarHeight);
    YBottom -= StatusBarHeight;

    // perk progress for myself
    if ( bDrawingBonusLevel && KFPRI.ClientVeteranSkillLevel != ScrnPerk.static.GetClientVeteranSkillLevel(KFPRI) )
    {
        C.DrawColor = C.MakeColor(255, 255, 125, CoolPerkAlpha);
        C.TextSize(strBonusLevel, XL, YL);
        C.SetPos(XCenter-XL/2, YBottom);
        C.DrawText(strBonusLevel);
    }
    else {
        TempLevel = KFPRI.ClientVeteranSkillLevel+1;
        if ( ClientRep != none && ScrnPerk != none && TempLevel < ClientRep.MaximumLevel ) {
            bDisplayingProgress = true;
            if( NextLevelTimer<Level.TimeSeconds ) {
                NextLevelTimer = Level.TimeSeconds+3.f;
                LevelProgressBar = ScrnPerk.Static.GetTotalProgress(ClientRep,TempLevel);
            }
            C.DrawColor = WhiteAlphaColor;
            if ( KFPRI.ClientVeteranSkillLevel != ScrnPerk.static.GetClientVeteranSkillLevel(KFPRI) )
                C.DrawColor.A = CoolPerkAlpha;
            ScrnScoreBoardClass.Static.DrawProgressBar(C, XCenter - BaseSize/2,YBottom, BaseSize , StatusBarHeight, VisualProgressBar);
        }

        // Draw dosh on the top of XP bar
        if ( KFGRI != none && KFGRI.bHUDShowCash ) {
            C.DrawColor = ScrnScoreBoardClass.default.DoshColor;
            C.TextSize(s, XL, YL);
            C.SetPos(XCenter-XL/2, YBottom);
            C.DrawText(s);
        }
    }
    if ( KFGRI != none && KFGRI.bHUDShowCash && (bShowPoints || !KFGRI.bWaveInProgress) ) {
        DrawSpriteWidget(C, CoolCashIcon);
        DrawNumericWidget(C, CoolCashDigits, DigitsSmall);
    }



    // CENTRAL INFO --------------------------------------------------------------------------------
    TempY = DrawCoolBar(C, ScrnPawnOwner, KFPRI, XCenter-BaseSize/2, YBottom - BaseSize, BaseSize);
    // ---------------------------------------------------------------------------------------------
    ConsoleMessagePosX = 0.005;
    // adjust console message location
    if ( bCoolHudLeftAlign )
        ConsoleMessagePosY = TempY/C.ClipY - 0.01;
    else
        ConsoleMessagePosY = default.ConsoleMessagePosY;


    TempSize = BaseSize * CoolIconToBarSize;
    TempX = XCenter - BaseSize * 0.55 - TempSize;
    TempY = YBottom - TempSize;
    C.DrawColor = WhiteAlphaColor;
    // Avatar
    if ( ScrnPRI != none ) {
        TempMaterial = ScrnPRI.GetSpecialIcon();
        if ( TempMaterial != none ) {
            C.SetPos(TempX, TempY);
            C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());
        }
    }



    // Draw sleed in the middle below avatar
    if ( bShowSpeed ) {
        s = GetSpeedStr(C) $ " ups";
        C.TextSize(s, XL, YL);
        C.SetPos(TempX +  (TempSize-XL)/2, YBottom + StatusBarHeight - YL);
        C.DrawText(s);
    }


    // chat icon
    C.DrawColor = WhiteAlphaColor;
    TempX = XCenter + BaseSize * 0.55;
    if ( ScrnPawnOwner.bIsTyping ) {
        C.SetPos(TempX, TempY);
        C.DrawTile(ChatIcon, TempSize, TempSize, 0, 0, ChatIcon.MaterialUSize(), ChatIcon.MaterialVSize());
        TempX += TempSize;
    }
    else {
        TempMaterial = none;
        if ( OwnerWeapon != none ) {
            TempMaterial = OwnerWeapon.TraderInfoTexture;
            if ( TempMaterial != none ) {
                C.SetPos(TempX, TempY);
                C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());
            }
            if ( !OwnerWeapon.bMeleeWeapon ) {
                Offset = TempSize * 0.05;
                YL = TempSize * 0.10;
                if ( OwnerWeapon.bHasSecondaryAmmo && MaxAmmoSecondary > 0 )
                    DrawBar(C, TempX + Offset, YBottom - 3.2*YL, TempSize - 2*Offset, YL,
                        CurClipsSecondary/MaxAmmoSecondary, C.MakeColor(128, 192, 255, KFHUDAlpha));
                else if ( KFMedicGun(OwnerWeapon) != none ) {
                    Pct = KFMedicGun(OwnerWeapon).ChargeBar();
                    if ( Pct * 500 >= OwnerWeapon.FireModeClass[1].default.AmmoPerFire )
                        C.DrawColor = C.MakeColor(206, 64, 64, KFHUDAlpha);
                    else
                        C.DrawColor = C.MakeColor(128, 128, 128, KFHUDAlpha);
                    DrawBar(C, TempX + Offset, YBottom - 3.2*YL, TempSize - 2*Offset, YL,
                        KFMedicGun(OwnerWeapon).ChargeBar(), C.DrawColor);
                }

                if ( MaxAmmoPrimary > 0 ) {
                    if ( Syringe(OwnerWeapon) != none ) {
                        if ( Syringe(OwnerWeapon).ChargeBar() < 0.5 )
                            C.DrawColor = C.MakeColor(128, 128, 128, KFHUDAlpha);
                        else
                            C.DrawColor = C.MakeColor(206, 64, 64, KFHUDAlpha);
                    }
                    else
                        C.DrawColor = C.MakeColor(160, 160, 160, KFHUDAlpha);

                    DrawBar(C, TempX + Offset, YBottom - 2.1*YL, TempSize - 2*Offset, YL,
                        CurAmmoPrimary/MaxAmmoPrimary, C.DrawColor);
                }
                if ( OwnerWeapon.MagCapacity > 1) {
                    if ( bLowAmmo )
                        C.DrawColor = C.MakeColor(255, 206, 92, KFHUDAlpha);
                    else
                        C.DrawColor = C.MakeColor(92, 192, 92, KFHUDAlpha);
                    DrawBar(C, TempX + Offset, YBottom - YL, TempSize - 2*Offset, YL,
                        float(CurMagAmmo)/OwnerWeapon.MagCapacity, C.DrawColor);
                }
            }
        }
        // weight
        C.DrawColor.R = 192;
        C.DrawColor.G = 192;
        C.DrawColor.B = 192;
        s = int(ScrnPawnOwner.CurrentWeight)$"/"$int(ScrnPawnOwner.MaxCarryWeight)$ " kg";
        C.TextSize(s, XL, YL);
        C.SetPos(TempX + (TempSize-XL)/2, YBottom + StatusBarHeight - YL);
        C.DrawText(s);

        // draw nades
        if ( PlayerGrenade != none ) {
            C.DrawColor = WhiteAlphaColor;
            TempLevel = GrenadeDigits.Value;
            TempX += TempSize;
            TempMaterial = PlayerGrenade.TraderInfoTexture;
            if ( TempLevel > 0 && TempMaterial != none ) {

                Counter = 1;
                Offset = 0;
                YL = TempSize * 0.20;
                TempY = YBottom - YL;
                while ( TempLevel > 0 ) {
                    C.SetPos(TempX, TempY);
                    C.DrawTile(TempMaterial, YL*2, YL, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());
                    if ( Counter == 5 ) {
                        Counter = 1;
                        TempX += YL + Offset;
                        TempY = YBottom - YL;
                    }
                    else {
                        ++Counter;
                        TempY -= YL;
                        TempY -= Offset;
                    }
                    --TempLevel;
                }
            }
        } // nades
    }




    //  ammo counter
    if ( OwnerWeapon != none && !OwnerWeapon.bMeleeWeapon && OwnerWeapon.bConsumesPhysicalAmmo ) {
        TempX = CoolHudAmmoOffsetX * C.ClipX;
        TempY = CoolHudAmmoOffsetY * C.ClipY;
        C.FontScaleX = CoolHudAmmoScale * fZoom;
        C.FontScaleY = CoolHudAmmoScale * fZoom;
        C.DrawColor = CoolHudAmmoColor;
        C.DrawColor.A = KFHUDAlpha;

        // total ammo
        if ( WeaponMaxCharge > 0 )
            s = string(int(CurAmmoPrimary));
        else if ( OwnerWeapon.MagCapacity > 1 )
            s = string(int(CurAmmoPrimary - CurMagAmmo));
        else
            s = " ";
        C.Font = LoadWaitingFont(1);// 0 - big, 1 - smaller
        C.TextSize(s, XL, YL);
        C.SetPos(TempX - XL, TempY - YL); // align bottom right
        C.DrawText(s);
        TempX -= XL;
        TempY -= YL*0.5;

        // magazine ammo
        if ( WeaponMaxCharge > 0 )
            s = string(int(WeaponChargePct*WeaponMaxCharge));
        else if ( OwnerWeapon.MagCapacity > 1 )
            s = string(CurMagAmmo - CurLeftGunAmmo);
        else
            s = string(int(CurAmmoPrimary));
        C.Font = LoadWaitingFont(0);// 0 - big, 1 - smaller
        C.TextSize(s, XL, YL);
        C.SetPos(TempX - XL, TempY - YL);
        if ( bLowAmmo || (bHasLeftGun && bRightGunLowAmmo) || WeaponMaxCharge > 0 ) {
            C.DrawColor = BulletsInClipDigits.Tints[0];
        }
        C.DrawText(s);

        if (bHasLeftGun) {
            s = string(CurLeftGunAmmo);
            C.TextSize(s, XL, YL);
            C.SetPos(C.ClipX - TempX, TempY - YL);
            if ( bLeftGunLowAmmo ) {
                C.DrawColor = LeftGunAmmoDigits.Tints[0];
            }
            else {
                C.DrawColor = CoolHudAmmoColor;
                C.DrawColor.A = KFHUDAlpha;
            }
            C.DrawText(s);
        }
        else if ( (OwnerWeapon != none && OwnerWeapon.bHasSecondaryAmmo) || (bSpectating && CurClipsSecondary > 0) ) {
            s = string(int(CurClipsSecondary));
            C.TextSize(s, XL, YL);
            C.SetPos(C.ClipX - TempX, TempY - YL);
            if ( CurClipsSecondary == 0 ) {
                C.DrawColor = NoAmmoColor;
            }
            else {
                C.DrawColor = CoolHudAmmoColor;
            }
            C.DrawColor.A = KFHUDAlpha;
            C.DrawText(s);
        }

        // restore
        C.FontScaleX = 1.0;
        C.FontScaleY = 1.0;
    }

}

simulated function DrawWeaponName(Canvas C)
{
    local string CurWeaponName;
    local float XL,YL;

    if ( PawnOwner == None || bCoolHudActive )
        return;

    if ( PawnOwner.Weapon != none )
        CurWeaponName = PawnOwner.Weapon.GetHumanReadableName();
    else if ( PlayerOwner.Pawn != PawnOwner && ScrnPawnOwner != none
            && ScrnPawnOwner.SpecWeapon != none )
        CurWeaponName = ScrnPawnOwner.SpecWeapon.default.ItemName;

    if ( CurWeaponName == "" )
        return;


    C.Font  = GetFontSizeIndex(C, -1);
    C.SetDrawColor(255, 50, 50, KFHUDAlpha);
    C.Strlen(CurWeaponName, XL, YL);

    // Diet Hud needs to move the weapon name a little bit or it looks weird
    if ( !bLightHud )
        C.SetPos((C.ClipX * 0.983) - XL, C.ClipY * 0.90);
    else
        C.SetPos((C.ClipX * 0.97) - XL, C.ClipY * 0.915);

    C.DrawText(CurWeaponName);
}

simulated function SetLowAmmoColor(out Color C, int ammo)
{
    if ( ammo > 0 ) {
        C = LowAmmoColor;
    }
    else {
        C = NoAmmoColor;
    }
    C.A = PulseAlpha;
}

simulated function PulseColorIf(out Color C, bool req)
{
    if (req) {
        C.A = PulseAlpha;
    }
    else {
        C.A = KFHUDAlpha;
    }
}

simulated function SetAlphaColor(out Color C, Color NewColor)
{
    C = NewColor;
    C.A = KFHUDAlpha;
}

simulated function SetAlphaColorRGB(out Color C, byte R, byte G, byte B)
{
    C.R = R;
    C.G = G;
    C.B = B;
    C.A = KFHUDAlpha;
}

simulated function UpdateHud()
{
    TeamColors[0].A = KFHUDAlpha;
    TeamColors[1].A = KFHUDAlpha;
    TextColors[0].A = KFHUDAlpha;
    TextColors[1].A = KFHUDAlpha;

    if( PawnOwner == none ) {
        super.UpdateHud();
        return;
    }

    CalculateAmmo();

    if ( OldHealth != HealthDigits.Value || OldArmor != ArmorDigits.Value ) {
        OldHealth = HealthDigits.Value;
        OldArmor = ArmorDigits.Value;
        HealthFading = 255;
        bHealthFadeOut = CoolHealthFadeOutTime > 0;
    }

    if ( ScrnPawnOwner != none )
        FlashlightDigits.Value = 100 * (float(ScrnPawnOwner.TorchBatteryLife) / float(ScrnPawnOwner.default.TorchBatteryLife));

    //reset to default values
    ClipsDigits.Tints[0]                = TeamColors[TeamIndex];
    ClipsDigits.Tints[1]                = TeamColors[TeamIndex];
    BulletsInClipDigits.Tints[0]        = TeamColors[TeamIndex];
    BulletsInClipDigits.Tints[1]        = TeamColors[TeamIndex];
    SecondaryClipsDigits.Tints[0]       = TeamColors[TeamIndex];
    SecondaryClipsDigits.Tints[1]       = TeamColors[TeamIndex];
    LeftGunAmmoDigits.Tints[0]          = TeamColors[TeamIndex];
    LeftGunAmmoDigits.Tints[1]          = TeamColors[TeamIndex];

    if ( OwnerWeapon != none )  {
        if ( WeaponMaxCharge > 0 ) {
            BulletsInClipDigits.Value = WeaponChargePct * WeaponMaxCharge;
            BulletsInClipDigits.Tints[0].R = 206 * (1.0-WeaponChargePct);
            BulletsInClipDigits.Tints[0].G = 206 * WeaponChargePct;
            BulletsInClipDigits.Tints[0].B = 0;
            if (WeaponChargePct > 0.9999)
                BulletsInClipDigits.Tints[0].A = PulseAlpha;
            BulletsInClipDigits.Tints[1] = BulletsInClipDigits.Tints[0];
        }
        else
            BulletsInClipDigits.Value = CurMagAmmo - CurLeftGunAmmo;

        if ( bLowAmmo || (bHasLeftGun && bRightGunLowAmmo) ) {
            SetLowAmmoColor(BulletsInClipDigits.Tints[0], BulletsInClipDigits.Value);
            BulletsInClipDigits.Tints[1] = BulletsInClipDigits.Tints[0];
        }

        if ( PlayerGrenade == none )
            FindPlayerGrenade();
        if ( PlayerGrenade != none )
            GrenadeDigits.Value =  PlayerGrenade.AmmoAmount(0);
        else
            GrenadeDigits.Value = 0;
    }
    else if ( bSpectatingScrn ) {
        // spectating
        BulletsInClipDigits.Value = CurMagAmmo;
        GrenadeDigits.Value = ScrnPawnOwner.SpecNades;
    }

    ClipsDigits.Value = CurClipsPrimary;

    if (bHasLeftGun) {
        LeftGunAmmoDigits.Value = CurLeftGunAmmo;
        if ( bLeftGunLowAmmo ) {
            SetLowAmmoColor(LeftGunAmmoDigits.Tints[0], LeftGunAmmoDigits.Value);
            LeftGunAmmoDigits.Tints[1] = LeftGunAmmoDigits.Tints[0];
        }
    }

    SecondaryClipsDigits.Value = CurClipsSecondary;
    if ( SecondaryClipsDigits.Value == 0 ) {
        SetLowAmmoColor(SecondaryClipsDigits.Tints[0], SecondaryClipsDigits.Value);
        SecondaryClipsDigits.Tints[1] = SecondaryClipsDigits.Tints[0];
    }

    if( Vehicle(PawnOwner)!=None ) {
        if( Vehicle(PawnOwner).Driver!=None )
            HealthDigits.Value = Vehicle(PawnOwner).Driver.Health;
        ArmorDigits.Value = PawnOwner.Health;
    }
    else {
        HealthDigits.Value = PawnOwner.Health;
        ArmorDigits.Value = PawnOwner.ShieldStrength;
    }

    // "Poison" the health meter
    if ( VomitHudTimer > Level.TimeSeconds ) {
        HealthDigits.Tints[0].R = 196;
        HealthDigits.Tints[0].G = 206;
        HealthDigits.Tints[0].B = 0;
    }
    else if ( PawnOwner.Health < 50 ) {
        if ( Level.TimeSeconds < SwitchDigitColorTime )    {
            HealthDigits.Tints[0].R = 255;
            HealthDigits.Tints[0].G = 200;
            HealthDigits.Tints[0].B = 0;
        }
        else {
            HealthDigits.Tints[0].R = 255;
            HealthDigits.Tints[0].G = 0;
            HealthDigits.Tints[0].B = 0;

            if ( Level.TimeSeconds > SwitchDigitColorTime + 0.2 )
                SwitchDigitColorTime = Level.TimeSeconds + 0.2;
        }
    }
    else {
        HealthDigits.Tints[0] = TeamColors[TeamIndex];
    }
    HealthDigits.Tints[1] = HealthDigits.Tints[0];

    CashDigits.Value = PawnOwnerPRI.Score;
    CoolCashDigits.Value = PawnOwnerPRI.Score;
    WelderDigits.Value = 100 * CurAmmoPrimary/MaxAmmoPrimary;
    SyringeDigits.Value = WelderDigits.Value;
    if ( SyringeDigits.Value < 50 ) {
        SyringeDigits.Tints[0].R = 128;
        SyringeDigits.Tints[0].G = 128;
        SyringeDigits.Tints[0].B = 128;

    }
    else if ( SyringeDigits.Value < 100 ) {
        SyringeDigits.Tints[0].R = 192;
        SyringeDigits.Tints[0].G = 96;
        SyringeDigits.Tints[0].B = 96;
    }
    else {
        SyringeDigits.Tints[0] = TeamColors[TeamIndex];
    }
    SyringeDigits.Tints[1] = SyringeDigits.Tints[0];

    // bypass ServerPerks and vanilla KF
    Super(HudBase).UpdateHud();
}

simulated function CalculateLeftGunAmmo()
{
    if ( ScrnDualDeagle(OwnerWeapon) != none ) {
        bHasLeftGun = true;
        CurLeftGunAmmo = ScrnDualDeagle(OwnerWeapon).LeftGunAmmoRemaining;
    }
    else if ( ScrnDualMK23Pistol(OwnerWeapon) != none ) {
        // exact class check to avoid ScrnDualMK23Laser
        bHasLeftGun = true;
        CurLeftGunAmmo = ScrnDualMK23Pistol(OwnerWeapon).LeftGunAmmoRemaining;
    }
    else if ( ScrnDual44Magnum(OwnerWeapon) != none ) {
        bHasLeftGun = true;
        CurLeftGunAmmo = ScrnDual44Magnum(OwnerWeapon).LeftGunAmmoRemaining;
    }
}

simulated function CalculateAmmo()
{
    local int i;

    MaxAmmoPrimary = 1;
    CurAmmoPrimary = 0;
    MaxAmmoSecondary = 0;
    CurClipsSecondary = 0;
    CurClipsPrimary = 0;
    bLowAmmo = false;
    WeaponChargePct = 0;
    WeaponMaxCharge = 0;
    CurMagAmmo = 0;
    bHasLeftGun = false;
    CurLeftGunAmmo = 0;
    bLeftGunLowAmmo = false;
    bRightGunLowAmmo = false;

    if ( PawnOwner == None  )
        return;

    if ( OwnerWeapon != none ) {
        OwnerWeapon.GetAmmoCount(MaxAmmoPrimary,CurAmmoPrimary);
        CurMagAmmo = OwnerWeapon.MagAmmoRemaining;

        if( OwnerWeapon.bHoldToReload )
            CurClipsPrimary = max(CurAmmoPrimary-CurMagAmmo,0); // Single rounds reload, just show the true ammo count.
        else if ( OwnerWeapon.MagCapacity <= 1 )
            CurClipsPrimary = CurAmmoPrimary;
        else if ( CurAmmoPrimary <= 0 || CurAmmoPrimary <= CurMagAmmo )
            CurClipsPrimary = 0;
        else
            CurClipsPrimary = ceil((CurAmmoPrimary - CurMagAmmo) / OwnerWeapon.MagCapacity);

        if( OwnerWeapon.bHasSecondaryAmmo && OwnerWeapon.FireModeClass[1].default.AmmoClass != none ) {
            OwnerWeapon.GetSecondaryAmmoCount(MaxAmmoSecondary, CurClipsSecondary);
        }

        if ( ScrnHuskGun(OwnerWeapon) != none ) {
            WeaponChargePct = ScrnHuskGun(OwnerWeapon).ChargeAmount;
            WeaponMaxCharge = ScrnHuskGunFire(OwnerWeapon.GetFireMode(0)).MaxChargeAmmo;
        }
        else {
            if ( bShowLeftGunAmmo && Dualies(OwnerWeapon) != none ) {
                CalculateLeftGunAmmo();
            }

            if ( OwnerWeapon.MagCapacity > MinMagCapacity ) {
                i = max(OwnerWeapon.MagCapacity*LowAmmoPercent, 2);
                bLowAmmo = CurMagAmmo <= i;
                if (bHasLeftGun) {
                    i = max(i/2, 2);
                    bLeftGunLowAmmo = CurLeftGunAmmo <= i;
                    bRightGunLowAmmo = (CurMagAmmo-CurLeftGunAmmo) <= i;
                }
            }
        }
    }
    else if ( ScrnPawnOwner != none && PlayerOwner.Pawn != ScrnPawnOwner && ScrnPawnOwner.SpecWeapon != none ) {
        CurMagAmmo = ScrnPawnOwner.SpecMagAmmo;
        CurClipsPrimary = ScrnPawnOwner.SpecMags;
        CurClipsSecondary = ScrnPawnOwner.SpecSecAmmo;
        if ( ClassIsChildOf(ScrnPawnOwner.SpecWeapon, class'Welder') )
            MaxAmmoPrimary = 300; // lame, but this value is used by welder only
    }
}

simulated function SetScoreBoardClass (class<Scoreboard> ScoreBoardClass)
{
    super.SetScoreBoardClass(ScoreBoardClass);

    if ( ScoreBoard != none )
        ScrnScoreBoardClass = class<ScrnScoreBoard>(ScoreBoard.class);
    if ( ScrnScoreBoardClass == none )
        ScrnScoreBoardClass = class'ScrnScoreBoard';
}

exec function TogglePlayerInfo()
{
    bHidePlayerInfo = !bHidePlayerInfo;
}

exec function SetBarStyle(byte value)
{
    if ( value >= BarStyles.length )
        return;

    BarStyle = value;
    if ( BarStyle < BARSTL_COOL ) {
        ScrnDrawPlayerInfoBase = ScrnDrawPlayerInfoClassic;
    }
    else {
        ScrnDrawPlayerInfoBase = ScrnDrawPlayerInfoNew;
    }
    if ( BarStyle == BARSTL_CLASSIC ) {
        PlayerInfoOffset = 1.0;
    }
}

exec function ToggleBarStyle()
{
    if ( BarStyle + 1 < BarStyles.length )
        SetBarStyle(BarStyle + 1);
    else {
        SetBarStyle(0);
    }
    SaveConfig();
}

exec function BarScale(float value)
{
    if ( value == 0.0 ) {
        PlayerOwner.ClientMessage("BarScale="$PlayerInfoScale);
        return;
    }
    PlayerInfoScale = value;
}

exec function BarOffset(float value)
{
    if ( value == 0.0 ) {
        PlayerOwner.ClientMessage("BarOffset="$PlayerInfoScale);
        return;
    }
    PlayerInfoOffset = value;
}

exec function SetHudStyle(byte value)
{
    if ( value >= HudStyles.length )
        return;

    HudStyle = value;
    bCoolHudLeftAlign = HudStyle == HUDSTL_COOL_LEFT;
    bCoolHud = bCoolHudLeftAlign || HudStyle == HUDSTL_COOL;
    class'ScrnVeterancyTypes'.default.bOldStyleIcons = HudStyle == HUDSTL_CLASSIC;
}

exec function ToggleHudStyle()
{
    if ( HudStyle + 1 < HudStyles.length )
        SetHudStyle(HudStyle + 1);
    else {
        SetHudStyle(0);
    }
    SaveConfig();
}

exec function CoolHudSize(float value)
{
    if ( value <= 0 ) {
        PlayerConsole.Message("Current Cool HUD Size = " $ CoolHudScale, 0);
        return;
    }
    CoolHudScale = fclamp(value, 1.5, 4.0);
    SaveConfig();
}

exec function CoolHudAmmoSize(float value)
{
    if ( value <= 0 ) {
        PlayerConsole.Message("Current Cool HUD Ammo Counter Size = " $ CoolHudAmmoScale, 0);
        return;
    }
    CoolHudAmmoScale = fclamp(value, 0.0, 4.0);
    SaveConfig();
}

exec function CoolHudAmmoX(float value)
{
    if ( value <= 0 ) {
        PlayerConsole.Message("Current Cool HUD Ammo Counter Position: X="$CoolHudAmmoOffsetX $ ". Y="$CoolHudAmmoOffsetY, 0);
        return;
    }
    CoolHudAmmoOffsetX = fclamp(value, 0.0, 1.0);
    SaveConfig();
}

exec function CoolHudAmmoY(float value)
{
    if ( value <= 0 ) {
        PlayerConsole.Message("Current Cool HUD Ammo Counter Position: X="$CoolHudAmmoOffsetX $ ". Y="$CoolHudAmmoOffsetY, 0);
        return;
    }
    CoolHudAmmoOffsetY = fclamp(value, 0.0, 1.0);
    SaveConfig();
}

function DrawPlayerInfo(Canvas C, Pawn P, float ScreenLocX, float ScreenLocY)
{
    local float Dist;
    local float OldZ, fZoom;
    local bool bSameTeam;
    local KFPlayerReplicationInfo EnemyPRI;

    if ( bHidePlayerInfo )
        return;

    EnemyPRI = KFPlayerReplicationInfo(P.PlayerReplicationInfo);
    if ( P == none || EnemyPRI == none || KFPRI == none || KFPRI.bViewingMatineeCinematic )
        return;

    bSameTeam = KFPRI.Team == none || EnemyPRI.Team == none
        || KFPRI.Team.TeamIndex == EnemyPRI.Team.TeamIndex;
    HealthBarFullVisDist = default.HealthBarFullVisDist;
    if ( ScrnPerk != none )
        HealthBarFullVisDist *= ScrnPerk.static.GetHealPotency(KFPRI); // medic see HP bars better
    Dist = vsize(P.Location - PlayerOwner.CalcViewLocation);
    if ( Dist <= HealthBarFullVisDist )
        fZoom = 1.0;
    else {
        if ( !bSameTeam )
            return; // shorter distance on enemy team
        fZoom = 1.0 - (Dist - HealthBarFullVisDist) / (HealthBarCutoffDist - HealthBarFullVisDist);
        if ( fZoom < 0.01 )
            return; // too far away
    }
    if ( BarStyle >= BARSTL_MODERN ) {
        fZoom = 1.0 - 0.5*Dist/HealthBarCutoffDist;
        if ( ScrnPerk != none )
            fZoom *= fclamp(ScrnPerk.static.GetHealPotency(KFPRI), 1.0, 1.5); // larger HP bars for medic
        fZoom *= PlayerInfoScale;
    }
    else
        fZoom = 1.0;

    OldZ = C.Z;
    C.Z = 1;
    C.Style = ERenderStyle.STY_Alpha;

    // call delegate function
    ScrnDrawPlayerInfoBase(C, P, ScreenLocX, ScreenLocY, fZoom, EnemyPRI, bSameTeam);

    C.Z = OldZ;
    VetStarSize = default.VetStarSize; // restore from drawing in other places
}

delegate simulated ScrnDrawPlayerInfoBase(Canvas C, Pawn P, float ScreenLocX, float ScreenLocY, float fZoom,
    KFPlayerReplicationInfo EnemyPRI, bool bSameTeam);


simulated function ScrnDrawPlayerInfoClassic(Canvas C, Pawn P, float ScreenLocX, float ScreenLocY, float fZoom,
    KFPlayerReplicationInfo EnemyPRI, bool bSameTeam)
{
    local float XL, YL, TempX, TempY, TempSize;
    local float Offset;
    local byte BeaconAlpha,Counter;
    local Material TempMaterial, TempStarMaterial;
    local byte i, TempLevel;
    local ScrnHumanPawn EnemyScrnPawn;
    local ScrnCustomPRI EnemyScrnPRI;

    // zoom
    BeaconAlpha = clamp(255*fZoom, 50, KFHUDAlpha);
    BarLength = default.BarLength * fZoom;
    BarHeight = default.BarHeight * fZoom;
    HealthIconSize = default.HealthIconSize * fZoom;
    ArmorIconSize = HealthIconSize;
    TempSize = 36.f * VeterancyMatScaleFactor * fZoom;
    VetStarSize = default.VetStarSize * fZoom;
    Offset = (TempSize * 0.6) - (HealthIconSize + 2.0);


    // player name
    C.Font = GetFontSizeIndex(C, 4*fmin(fZoom,1.0)-8);
    if ( bSameTeam )
        C.SetDrawColor(255, 255, 255, BeaconAlpha);
    else {
        C.DrawColor = TextColors[EnemyPRI.Team.TeamIndex];
        C.DrawColor.A = BeaconAlpha;
    }
    ScrnScoreBoardClass.Static.TextSizeCountrySE(C,EnemyPRI,XL,YL);
    TempX = ScreenLocX - Offset - (0.5 * BarLength) - HealthIconSize - 2.0; // left pos of health icon
    ScrnScoreBoardClass.Static.DrawCountryNameSE(C, EnemyPRI, ScreenLocX - Offset - XL/2, ScreenLocY-(YL * 0.75), 0, !bSameTeam); // align center

    if ( bSameTeam || (ScrnPerk != none && ScrnPerk.static.ShowEnemyHealthBars(KFPRI, EnemyPRI)))
    {
        EnemyScrnPawn = ScrnHumanPawn(P);

        // Draw Tourney Icon only during trader time
        if ( BarStyle >= BARSTL_MODERN_EX || (KFGRI != none && !KFGRI.bWaveInProgress) ) {
            EnemyScrnPRI = class'ScrnCustomPRI'.static.FindMe(EnemyPRI);
            if ( EnemyScrnPRI != none && EnemyScrnPRI.GetSpecialIcon() != none ) {
                TempMaterial = EnemyScrnPRI.GetSpecialIcon();
                TempX -= TempSize + 2.0;
                TempY = ScreenLocY - YL*0.75 - TempSize; // just above the name
                C.SetPos(TempX, TempY);
                C.SetDrawColor(255,255,255,KFHUDAlpha);
                C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());
            }
        }

        // perk
        if ( Class<SRVeterancyTypes>(EnemyPRI.ClientVeteranSkill)!=none
                && EnemyPRI.ClientVeteranSkill.default.OnHUDIcon!=none )
        {
            TempX = ScreenLocX + ((BarLength + HealthIconSize) * 0.5) - (TempSize * 0.25) - Offset;
            TempY = ScreenLocY - YL - (TempSize * 0.75);
            C.DrawColor.A = BeaconAlpha;
            TempLevel = Class<SRVeterancyTypes>(EnemyPRI.ClientVeteranSkill).Static.PreDrawPerk(C,
                        EnemyPRI.ClientVeteranSkillLevel,
                        TempMaterial,TempStarMaterial);
            C.SetPos(TempX, TempY);
            C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());

            TempX += (TempSize - (VetStarSize * 0.75));
            TempY += (TempSize - (VetStarSize * 1.5));

            for ( i = 0; i < TempLevel; i++ )
            {
                C.SetPos(TempX, TempY-(Counter*VetStarSize*0.7f));
                C.DrawTile(TempStarMaterial, VetStarSize * 0.7, VetStarSize * 0.7, 0, 0, TempStarMaterial.MaterialUSize(), TempStarMaterial.MaterialVSize());

                if( ++Counter==5 )
                {
                    Counter = 0;
                    TempX+=VetStarSize;
                }
            }
        }

        // Health
        if ( P.Health > 0 ) {
            if ( EnemyScrnPawn != none && EnemyScrnPawn.ClientHealthToGive > 0 ) {
                DrawKFBarEx(C, ScreenLocX - Offset, (ScreenLocY - YL) - 0.4 * BarHeight, FClamp(P.Health / P.HealthMax, 0, 1), BeaconAlpha, false,
                    FClamp(float(EnemyScrnPawn.ClientHealthToGive) / P.HealthMax, 0, 1.0 - P.Health / P.HealthMax));
            }
            else
                DrawKFBarEx(C, ScreenLocX - Offset, (ScreenLocY - YL) - 0.4 * BarHeight, FClamp(P.Health / P.HealthMax, 0, 1), BeaconAlpha, false);
        }
        // Armor
        if ( P.ShieldStrength > 0 )
            DrawKFBarEx(C, ScreenLocX - Offset, (ScreenLocY - YL) - 1.5 * BarHeight, FClamp(P.ShieldStrength / 100.f, 0, 3), BeaconAlpha, true);
    }
    else
        TempX = ScreenLocX + ((BarLength + HealthIconSize) * 0.5) - (TempSize * 0.25) - Offset;


    TempX+=VetStarSize;
    TempY = ScreenLocY - YL - (TempSize * 0.75);
    C.SetDrawColor(255, 255, 255, BeaconAlpha);
    if ( P.bIsTyping ) {
        C.SetPos(TempX, TempY);
        C.DrawTile(ChatIcon, TempSize, TempSize, 0, 0, ChatIcon.MaterialUSize(), ChatIcon.MaterialVSize());
    }
    else if ( bSameTeam && EnemyScrnPawn != none && EnemyScrnPawn.SpecWeapon != none && BarStyle >= BARSTL_MODERN_EX ){
        // draw weapon icon and ammo status
        TempMaterial = EnemyScrnPawn.SpecWeapon.default.TraderInfoTexture;
        if ( TempMaterial != none ) {
            Offset = TempSize * 0.05;
            YL = TempSize * 0.15;
            C.SetPos(TempX, TempY);
            C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());
            if (EnemyScrnPawn.AmmoStatus > 0 ) {
                // AmmoStatus=1 indicates that weapon is empty, but it consumes ammo
                DrawBar(C, TempX + Offset, ScreenLocY - YL - Offset, TempSize - 2*Offset, YL,
                    (EnemyScrnPawn.AmmoStatus-1)/254.0, C.MakeColor(160, 160, 160, BeaconAlpha));
            }
        }
    }
}


simulated function ScrnDrawPlayerInfoNew(Canvas C, Pawn P, float ScreenLocX, float ScreenLocY, float fZoom,
    KFPlayerReplicationInfo EnemyPRI, bool bSameTeam)
{
    local float XL, YL, TempX, TempY, BaseSize, TempSize, Offset;
    local float BottomBarHeight;
    local byte BeaconAlpha;
    local Material TempMaterial;
    local ScrnHumanPawn EnemyScrnPawn;
    local ScrnCustomPRI EnemyScrnPRI;

    // init
    EnemyScrnPawn = ScrnHumanPawn(P);
    fZoom *= C.ClipY/1080; // scale by resolution/aspect ratio
    //BeaconAlpha = clamp(255*fZoom, 50, KFHUDAlpha);
    BeaconAlpha = 255;
    BaseSize = 64.f * fZoom;
    C.Font = GetFontSizeIndex(C, 4*fmin(fZoom,1.0)-8);
    C.TextSize("0", XL, BottomBarHeight);
    ScreenLocY -= BottomBarHeight;

    // player name
    if ( bSameTeam )
        C.SetDrawColor(255, 255, 255, BeaconAlpha);
    else {
        C.DrawColor = TextColors[EnemyPRI.Team.TeamIndex];
        C.DrawColor.A = BeaconAlpha;
    }
    ScrnScoreBoardClass.Static.TextSizeCountrySE(C,EnemyPRI,XL,YL);
    ScreenLocY -= YL;
    ScrnScoreBoardClass.Static.DrawCountryNameSE(C, EnemyPRI, ScreenLocX - XL/2, ScreenLocY, 0, !bSameTeam); // align center

    // CENTRAL INFO --------------------------------------------------------------------------------
    if ( bSameTeam || (ScrnPerk != none && ScrnPerk.static.ShowEnemyHealthBars(KFPRI, EnemyPRI)))
        DrawCoolBar(C, P, EnemyPRI, ScreenLocX - BaseSize/2, ScreenLocY - BaseSize, BaseSize);
    // ---------------------------------------------------------------------------------------------

    C.SetDrawColor(255,255,255,BeaconAlpha);
    TempSize = BaseSize * CoolIconToBarSize;
    TempX = ScreenLocX - BaseSize * 0.55 - TempSize;
    TempY = ScreenLocY - TempSize;
    C.SetDrawColor(255,255,255,BeaconAlpha);
    // Avatar
    EnemyScrnPRI = class'ScrnCustomPRI'.static.FindMe(EnemyPRI);
    if ( EnemyScrnPRI != none ) {
        TempMaterial = EnemyScrnPRI.GetSpecialIcon();
        if ( TempMaterial != none ) {
            C.SetPos(TempX, TempY);
            C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());
        }
    }

    // chat icon
    TempX = ScreenLocX + BaseSize * 0.55;
    if ( P.bIsTyping ) {
        C.SetPos(TempX, TempY);
        C.DrawTile(ChatIcon, TempSize, TempSize, 0, 0, ChatIcon.MaterialUSize(), ChatIcon.MaterialVSize());
    }
    else if ( bSameTeam && EnemyScrnPawn != none && EnemyScrnPawn.SpecWeapon != none ){
        // draw weapon icon and ammo status
        TempMaterial = EnemyScrnPawn.SpecWeapon.default.TraderInfoTexture;
        if ( TempMaterial != none ) {
            Offset = TempSize * 0.05;
            YL = TempSize * 0.15;
            C.SetPos(TempX, TempY);
            C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());
            if (EnemyScrnPawn.AmmoStatus > 0 ) {
                // AmmoStatus=1 indicates that weapon is empty, but it consumes ammo
                DrawBar(C, TempX + Offset, ScreenLocY - YL - Offset, TempSize - 2*Offset, YL,
                    (EnemyScrnPawn.AmmoStatus-1)/254.0, C.MakeColor(160, 160, 160, BeaconAlpha));
            }
        }
    }
}


simulated function float DrawCoolBar(Canvas C, Pawn P, KFPlayerReplicationInfo PawnPRI,
    float BaseX, float BaseY, float BaseSize)
{
    local float UpperBound;
    local float TempSize, TempX, TempY, XL, YL;
    local float Radius, Angle, Pct, Offset;
    local material TempMaterial,TempStarMaterial;
    local byte Counter, TempLevel, PerkLevel;
    local ScrnHumanPawn EnemyScrnPawn;
    local int shield;
    local class<ScrnVeterancyTypes> EnemyPerk;

    C.Style = ERenderStyle.STY_Alpha;
    PassStyle = STY_Alpha; // required for DrawNumericWidget()

    UpperBound = BaseY;
    EnemyScrnPawn = ScrnHumanPawn(P);
    if ( PawnPRI != none )
        EnemyPerk = Class<ScrnVeterancyTypes>(PawnPRI.ClientVeteranSkill);
    // perk
    if ( EnemyPerk!=none && EnemyPerk.default.OnHUDIcon!=none )
    {
        TempSize = BaseSize * CoolPerkToBarSize;
        TempX = BaseX + (BaseSize-TempSize)/2;
        TempY = BaseY + BaseSize*CoolPerkOffsetY;
        PerkLevel = EnemyPerk.static.GetClientVeteranSkillLevel(PawnPRI);
        if ( PerkLevel != PawnPRI.ClientVeteranSkillLevel ) {
            C.DrawColor.A = CoolPerkAlpha;
            if ( !bDrawingBonusLevel )
                PerkLevel = PawnPRI.ClientVeteranSkillLevel;
        }
        TempLevel = EnemyPerk.Static.PreDrawPerk(C, PerkLevel, TempMaterial,TempStarMaterial);
        C.SetPos(TempX, TempY);
        C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());

        // draw stars in arc
        TempSize = BaseSize * CoolStarToBarSize;
        Radius = BaseSize/2 - TempSize;
        // center point
        TempX = BaseX + (BaseSize-TempSize)/2;
        TempY = BaseY + BaseSize*0.35 - TempSize/2;
        TempLevel = min(TempLevel, PerkStarsMax);
        while (TempLevel > 0) {
            if (Counter == 0 ) {
                Counter = 10;
                Angle = PI/2;
                Radius += TempSize;
                if ( TempLevel < 10 && (TempLevel&1) == 1) {
                    YL = Radius;
                    XL = 0;
                }
                else {
                    Angle -= CoolStarAngleRad/2;
                    YL = Radius * sin(Angle);
                    XL = Radius * cos(Angle);
                }
                UpperBound = fmin(UpperBound, TempY - Radius);
            }
            else if (XL > 0)
                XL = -XL;
            else {
                Angle -= CoolStarAngleRad;
                YL = Radius * sin(Angle);
                XL = Radius * cos(Angle);
            }
            C.SetPos(TempX+XL, TempY - YL);
            C.DrawTile(TempStarMaterial, TempSize, TempSize, 0, 0, TempStarMaterial.MaterialUSize(), TempStarMaterial.MaterialVSize());
            --Counter;
            --TempLevel;
        }
    }

    // Health
    TempSize = BaseSize/2; // size in screen units
    XL = CoolBarSize/2;   // size of texture
    if (P.Health >= P.HealthMax) {
        C.SetPos(BaseX, BaseY);
        C.DrawColor = FullHealthColor;
        C.DrawTile(CoolBarOverlay, TempSize, BaseSize, 0, 0, XL, CoolBarSize);

        if ( P.Health > P.HealthMax ) {
            // overcharge
            Pct = fmax(2.0 - P.Health/P.HealthMax, 0);
            Offset = CoolHealthBarTop + CoolHealthBarHeight*Pct;
            YL = Offset * BaseSize / CoolBarSize;
            C.SetPos(BaseX, BaseY + YL);
            C.DrawColor = OverchargeHealthColor;
            C.DrawTile(CoolBarOverlay, TempSize, BaseSize-YL, 0, Offset, XL, CoolBarSize - Offset);
        }
    }
    else {
       // healed by not restored yet
       if ( EnemyScrnPawn != none && EnemyScrnPawn.ClientHealthToGive > 0 ) {
            Pct = fmax(1.0 - (EnemyScrnPawn.Health+float(EnemyScrnPawn.ClientHealthToGive))/P.HealthMax,0);
            Offset = CoolHealthBarTop + CoolHealthBarHeight*Pct;
            YL = Offset * BaseSize / CoolBarSize;
            C.SetPos(BaseX, BaseY + YL);
            C.DrawColor = HealingBarColor;
            C.DrawTile(CoolBarOverlay, TempSize, BaseSize-YL, 0, Offset, XL, CoolBarSize - Offset);
        }

        // current health
        Pct = 1.0 - float(P.Health)/P.HealthMax;
        Offset = CoolHealthBarTop + CoolHealthBarHeight*Pct;
        YL = Offset * BaseSize / CoolBarSize;
        C.SetPos(BaseX, BaseY + YL);
        if ( P.Health < 50 || (P == PlayerOwner.Pawn && VomitHudTimer > Level.TimeSeconds) )
            C.DrawColor = LowHealthColor;
        else if ( EnemyScrnPawn != none && EnemyScrnPawn.Health + EnemyScrnPawn.ClientHealthToGive >=P.HealthMax )
            C.DrawColor = FullHealthColor;
        else
            C.DrawColor = HealthBarColor;
        C.DrawTile(CoolBarOverlay, TempSize, BaseSize-YL, 0, Offset, XL, CoolBarSize - Offset);
    }

    // armor
    shield = P.ShieldStrength;
    if ( shield > 0 ) {
        C.DrawColor = ArmorBarColor;
        if ( shield >= 100 ) {
            // full armor
            C.SetPos(BaseX+TempSize, BaseY);
            C.DrawTile(CoolBarOverlay, TempSize, BaseSize, XL, 0, XL, CoolBarSize);
            shield -= 100;
            C.DrawColor = BigArmorColor;
        }

        if ( shield > 0 ) {
            Pct = 1.0 - (shield / 100.0);
            Offset = CoolHealthBarTop + CoolHealthBarHeight*Pct;
            YL = Offset * BaseSize / CoolBarSize;
            C.SetPos(BaseX+TempSize, BaseY + YL);
            C.DrawTile(CoolBarOverlay, TempSize, BaseSize-YL, XL, Offset, XL, CoolBarSize - Offset);
        }
    }

    // bar base
    C.SetPos(BaseX, BaseY);
    if ( bCoolHudTeamColor && PawnPRI.Team != none && PawnPRI.Team.TeamIndex < 2 )
        C.DrawColor = TeamColors[PawnPRI.Team.TeamIndex];
    else
        C.DrawColor = CoolHudColor;
    C.DrawTile(CoolBarBase, BaseSize, BaseSize, 0, 0, CoolBarBase.MaterialUSize(), CoolBarBase.MaterialVSize());

    // perk text
    CoolPerkLevelDigits.TextureScale = BaseSize/512.0 * 1080.0/C.ClipY; // NumericWidget scales itself according to resolution
    CoolPerkLevelDigits.PosX = (BaseX + BaseSize/2) / C.ClipX;
    CoolPerkLevelDigits.PosY = (BaseY + BaseSize*CoolPerkLevelOffsetY) / C.ClipY;
    CoolPerkLevelDigits.Value = PerkLevel;
    CoolPerkLevelDigits.Tints[0] = PerkColor(PerkLevel);
    CoolPerkLevelDigits.Tints[1] = CoolPerkLevelDigits.Tints[0];
    DrawNumericWidget(C, CoolPerkLevelDigits, DigitsSmall);

    return UpperBound;
}



simulated function DrawBar(Canvas C, float X, float Y, float W, float H, float Pct, Color BarColor,
    optional bool bNoBackground, optional bool bVertical, optional int Margin)
{
    if ( !bNoBackground ) {
        C.SetDrawColor(92, 92, 92, BarColor.A);
        C.SetPos(X, Y);
        C.DrawTileStretched(WhiteMaterial, W, H);
    }

    if ( Pct > 0 ) {
        if ( Pct > 1.0 )
            Pct = 1.0;
        if ( Margin < 0 )
            Margin = 0;
        else if ( Margin == 0 )
            Margin = 1;
        X += Margin;
        Y += Margin;
        W -= 2*Margin;
        H -= 2*Margin;
        if ( bVertical )
            H *= Pct;
        else
            W *= Pct;

        C.DrawColor = BarColor;
        C.SetPos(X, Y);
        C.DrawTileStretched(WhiteMaterial, W, H);
    }
}

simulated function DrawKFBarEx(Canvas C, float XCentre, float YCentre, float BarPercentage, byte BarAlpha, optional bool bArmor, optional float BarPercentage2)
{
    C.SetDrawColor(92, 92, 92, BarAlpha);
    C.SetPos(XCentre - 0.5 * BarLength, YCentre - 0.5 * BarHeight);
    C.DrawTileStretched(WhiteMaterial, BarLength, BarHeight);

    if ( bArmor )
    {
        C.SetDrawColor(255, 255, 255, BarAlpha);
        C.SetPos(XCentre - (0.5 * BarLength) - ArmorIconSize - 2.0, YCentre - (ArmorIconSize * 0.5));
        C.DrawTile(ArmorIcon.WidgetTexture, ArmorIconSize, ArmorIconSize, 0, 0, ArmorIcon.WidgetTexture.MaterialUSize(), ArmorIcon.WidgetTexture.MaterialVSize());

        C.SetDrawColor(0, 0, 255, BarAlpha);
        if ( BarPercentage > 1.0 ) {
            C.DrawColor = BigArmorColor;
            BarPercentage -= 1.0;
        }
        else
            C.DrawColor = ArmorBarColor;
    }
    else
    {
        C.SetDrawColor(255, 255, 255, BarAlpha);
        C.SetPos(XCentre - (0.5 * BarLength) - HealthIconSize - 2.0, YCentre - (HealthIconSize * 0.5));
        C.DrawTile(HealthIcon.WidgetTexture, HealthIconSize, HealthIconSize, 0, 0, HealthIcon.WidgetTexture.MaterialUSize(), HealthIcon.WidgetTexture.MaterialVSize());

        if ( BarStyle >= BARSTL_MODERN && BarPercentage + BarPercentage2 >= 1.0 )
            C.DrawColor = FullHealthColor;
        else
            C.DrawColor = HealthBarColor;
    }

    C.DrawColor.A = BarAlpha;
    C.SetPos(XCentre - (0.5 * BarLength) + 1.0, YCentre - (0.5 * BarHeight) + 1.0);
    C.DrawTileStretched(WhiteMaterial, (BarLength - 2.0) * BarPercentage, BarHeight - 2.0);

    if ( BarPercentage2 > 0 ) {
        C.SetDrawColor(255, 128, 128, BarAlpha);
        C.SetPos(XCentre - (0.5 * BarLength) + 1.0 + (BarLength - 2.0) * BarPercentage, YCentre - (0.5 * BarHeight) + 1.0);
        C.DrawTileStretched(WhiteMaterial, (BarLength - 2.0) * BarPercentage2, BarHeight - 2.0);
    }
}

simulated function DrawBlamedIcon(Canvas C, float XCentre, float YBottom, byte BarAlpha)
{
    C.SetDrawColor(255, 255, 255, BarAlpha);
    C.SetPos(XCentre - (0.5 * BlamedIconSize), YBottom - BlamedIconSize);
    C.DrawTile(BlamedIcon.WidgetTexture, BlamedIconSize, BlamedIconSize, 0, 0, BlamedIcon.WidgetTexture.MaterialUSize(), BlamedIcon.WidgetTexture.MaterialVSize());
}

simulated function ShowDamage(int Damage, float HitTime, vector HitLocation, byte DamTypeNum)
{
    local color c;

    DamagePopups[NextDamagePopupIndex].damage = Damage;
    DamagePopups[NextDamagePopupIndex].HitTime = HitTime;
    DamagePopups[NextDamagePopupIndex].DamTypeNum = DamTypeNum;
    DamagePopups[NextDamagePopupIndex].HitLocation = HitLocation;
    //ser random speed of fading out, so multiple damages in the same hit location don't overlap each other
    DamagePopups[NextDamagePopupIndex].RandX = 2.0 * frand();
    DamagePopups[NextDamagePopupIndex].RandY = 1.0 + frand();

    c.A = 255;
    if ( DamTypeNum == 1 ) { // headshots

        c.R = 0;
        c.G = 100;
        c.B = 255;
    }
    else if ( DamTypeNum == 2 ) { // fire DoT
        c.R = 206;
        c.G = 103;
        c.B = 0;
    }
    else if ( DamTypeNum == 10 ) { // player-to-player damage
        c.R = 206;
        c.G = 0;
        c.B = 206;
    }
    else if ( Damage >= 500 ) {
        c.R = 0;
        c.G = 206;
        c.B = 0;
    }
    else if ( Damage >= 175 ) {
        c.R = 206;
        c.G = 206;
        c.B = 0;
    }
    /*
    else if ( Damage >= 100 ){
        c.R = 206;
        c.G = 64;
        c.B = 103;
    }
    */
    else if ( Damage > 0 ) {
        c.R = 206;
        c.G = 64;
        c.B = 64;
    }
    else {
        c.R = 127;
        c.G = 127;
        c.B = 127;
    }
    DamagePopups[NextDamagePopupIndex].FontColor = c;

    if( ++NextDamagePopupIndex >= DAMAGEPOPUP_COUNT)
        NextDamagePopupIndex=0;
}

simulated function DrawDamage(Canvas C)
{
    local int i;
    local float TimeSinceHit;
    local vector CameraLocation, CamDir;
    local rotator CameraRotation;
    local vector HBScreenPos;
    local float TextWidth, TextHeight, x;

    C.GetCameraLocation(CameraLocation, CameraRotation);
    CamDir    = vector(CameraRotation);

    if ( C.ClipX <= 800 )
        DamagePopupFont = 7;
    else if ( C.ClipX <= 1024 )
        DamagePopupFont = 6;
    else if ( C.ClipX < 1400 )
        DamagePopupFont = 5;
    else if ( C.ClipX < 1700 )
        DamagePopupFont = 4;
    else
        DamagePopupFont = 3;

    C.Font = LoadFont(DamagePopupFont);

    for( i=0; i < DAMAGEPOPUP_COUNT ; i++ ) {
        TimeSinceHit = Level.TimeSeconds - DamagePopups[i].HitTime;
        if( TimeSinceHit > DamagePopupFadeOutTime
                || ( Normal(DamagePopups[i].HitLocation - CameraLocation) dot Normal(CamDir) < 0.1 ) ) //don't draw if player faced back to the hit location
            continue;

        HBScreenPos = C.WorldToScreen(DamagePopups[i].HitLocation);
        C.StrLen(DamagePopups[i].damage, TextWidth, TextHeight);
        //draw just on the hit location
        HBScreenPos.Y -= TextHeight/2;
        HBScreenPos.X -= TextWidth/2;

        //let numbers to fly up
        HBScreenPos.Y -= TimeSinceHit * TextHeight * DamagePopups[i].RandY;
        x = Sin(2*Pi * TimeSinceHit/DamagePopupFadeOutTime) * TextWidth * DamagePopups[i].RandX;
        // odd numbers start to flying to the right side, even - left
        // So in situations of decapitaion player could see both damages
        if ( i % 2 == 0)
            x *= -1.0;
        HBScreenPos.X += x;

        C.DrawColor = DamagePopups[i].FontColor;
        C.DrawColor.A = 255 * cos(0.5*Pi * TimeSinceHit/DamagePopupFadeOutTime);

        C.SetPos( HBScreenPos.X, HBScreenPos.Y);
        C.DrawText(DamagePopups[i].damage);
    }
}

simulated function MyPerkChanged(class<KFVeterancyTypes> OldPerk)
{
    // destroy current PerkOverlay, unless new perk has the same one
    if ( PerkOverlay != none && (ScrnPerk == none || ScrnPerk.default.HUDOverlay != PerkOverlay.class) ) {
        PerkOverlay.Destroy();
        PerkOverlay = none;
    }

    if ( PerkOverlay == none && ScrnPerk != none && ScrnPerk.default.HUDOverlay != none ) {
        PerkOverlay = spawn(ScrnPerk.default.HUDOverlay, self);
        if ( PerkOverlay != none )
            AddHudOverlay(PerkOverlay);
    }
}

simulated function LinkActors()
{
    super.LinkActors();

    ScrnGRI = ScrnGameReplicationInfo(PlayerOwner.GameReplicationInfo);

    if ( PlayerOwner != ScrnPC ) {
        ScrnPC = ScrnPlayerController(PlayerOwner);
    }

    if ( PawnOwner != none ) {
        if ( PawnOwner != ScrnPawnOwner )
            ScrnPawnOwner = ScrnHumanPawn(PawnOwner);
        if ( PawnOwner.Weapon != OwnerWeapon )
            OwnerWeapon = KFWeapon(PawnOwner.Weapon);
        // update KFPRI for spectators too
        if ( KFPRI != PawnOwner.PlayerReplicationInfo ) {
            KFPRI = KFPlayerReplicationInfo(PawnOwner.PlayerReplicationInfo);
            ScrnPRI = none; // it will be set later in this code
        }
    }
    else {
        ScrnPawnOwner = none;
        OwnerWeapon = none;
        if ( PlayerOwner != none ) {
            if ( KFPRI != PlayerOwner.PlayerReplicationInfo ) {
                KFPRI = KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
                ScrnPRI = none; // it will be set later in this code
            }
        }
        else {
            // wtf?
            KFPRI = none;
            ScrnPRI = none;
        }
    }

    // prevent square portrait of standard characters
    bSpecialPortrait = bSpecialPortrait && PortraitPRI != None
        && (PortraitPRI.PlayerID == LastPlayerIDTalking || LastPlayerIDTalking == 0);

    bSpectating = PawnOwner == none || PlayerOwner.Pawn != PawnOwner;
    bSpectatingScrn = bSpectating && ScrnPawnOwner != none;
    bSpectatingZED = bSpectating && !bSpectatingScrn && PawnOwner != none && KFMonster(PawnOwner) != none;

    bCoolHudActive = bCoolHud && !bShowScoreBoard && !bSpectating && ScrnPawnOwner != none;

    if ( OwnerWeapon != none )
        OwnerWeaponClass = OwnerWeapon.Class;
    else if ( bSpectatingScrn )
        OwnerWeaponClass = ScrnPawnOwner.SpecWeapon;

    if ( KFPRI != none ) {
        if ( ScrnPRI == none )
            ScrnPRI = class'ScrnCustomPRI'.static.FindMe(KFPRI);

        if ( PawnOwner != none ) {
            if ( PrevPerk != KFPRI.ClientVeteranSkill ) {
                ScrnPerk = class<ScrnVeterancyTypes>(KFPRI.ClientVeteranSkill);
                MyPerkChanged(PrevPerk);
                PrevPerk = KFPRI.ClientVeteranSkill;
            }
        }
    }
    else {
        ScrnPRI = none;
        ScrnPerk = none;
        if ( PrevPerk != none ) {
            MyPerkChanged(PrevPerk);
            PrevPerk = none;
        }
    }
}

simulated function Tick(float deltaTime)
{
    super.Tick(deltaTime);

    if ( BlamedMonsterClass != none ) {
        BlameCountdown -= deltaTime;
        if ( BlameCountdown <= 0 ) {
            BlamedMonsterClass = none;
            BlameCountdown = default.BlameCountdown; // set for the next blame
        }
    }

    if ( bHealthFadeOut ) {
        HealthFading -= deltaTime * 255.0 / CoolHealthFadeOutTime;
        if ( HealthFading <= 0 )
            bHealthFadeOut = false;
    }

    if ( PulseAlpha < 100 )
        PulseAlpha = 250;
    else
        PulseAlpha -= PulseRate * deltaTime / Level.TimeDilation;

    BlinkPhase -= BlinkRate * deltaTime / Level.TimeDilation;
    if (BlinkPhase < 0) {
        BlinkPhase = 512;
    }
    BlinkAlpha = clamp(BlinkPhase, 0, 255);

    if ( bXPBonusFadingOut ) {
        CoolPerkAlpha -= XPBonusFadeRate * deltaTime;
        if ( CoolPerkAlpha <= 10) {
            CoolPerkAlpha = 10;
            bXPBonusFadingOut = false;
            bDrawingBonusLevel = !bDrawingBonusLevel;
            bXPBonusFadingIn = true;
        }
    }
    else if ( bXPBonusFadingIn ) {
        CoolPerkAlpha += XPBonusFadeRate * deltaTime;
        if ( CoolPerkAlpha >= 255 ) {
            CoolPerkAlpha = 255;
            bXPBonusFadingIn = false;
            if ( bDrawingBonusLevel )
                XPBonusNextPlaseTime = Level.TimeSeconds + BonusLevelShowTime;
            else
                XPBonusNextPlaseTime = Level.TimeSeconds + XPLevelShowTime;
        }
    }
    else if ( Level.TimeSeconds > XPBonusNextPlaseTime )
        bXPBonusFadingOut = true;
}


simulated function DrawHealthBar(Canvas C, Actor A, int Health, int MaxHealth, float Height)
{
    local vector CameraLocation, CamDir, TargetLocation, HBScreenPos;
    local rotator CameraRotation;
    local float Dist, HealthPct;
    local color OldDrawColor;

    // rjp --  don't draw the health bar if menus are open
    // exception being, the Veterancy menu

    if ( PlayerOwner.Player.GUIController.bActive && GUIController(PlayerOwner.Player.GUIController).ActivePage.Name != 'GUIVeterancyBinder' )
    {
        return;
    }

    OldDrawColor = C.DrawColor;

    C.GetCameraLocation(CameraLocation, CameraRotation);
    if ( KFMonster(A) != none && KFMonster(A).bUseExtendedCollision )
        TargetLocation = A.Location + vect(0, 0, 1) * (KFMonster(A).ColHeight + KFMonster(A).ColOffset.Z);
    else
        TargetLocation = A.Location + vect(0, 0, 1) * A.CollisionHeight;
    Dist = VSize(TargetLocation - CameraLocation);

    EnemyHealthBarLength = FMin(default.EnemyHealthBarLength * (float(C.SizeX) / 1024.f),default.EnemyHealthBarLength);
    EnemyHealthBarHeight = FMin(default.EnemyHealthBarHeight * (float(C.SizeX) / 1024.f),default.EnemyHealthBarHeight);


    CamDir  = vector(CameraRotation);

    // Check Distance Threshold / behind camera cut off
    if ( Dist > HealthBarCutoffDist || (Normal(TargetLocation - CameraLocation) dot CamDir) < 0 )
    {
        return;
    }

    // Target is located behind camera
    HBScreenPos = C.WorldToScreen(TargetLocation);

    if ( HBScreenPos.X <= 0 || HBScreenPos.X >= C.SizeX || HBScreenPos.Y <= 0 || HBScreenPos.Y >= C.SizeY)
    {
        return;
    }

    if ( FastTrace(TargetLocation, CameraLocation) )
    {
        C.SetDrawColor(192, 192, 192, 255);
        C.SetPos(HBScreenPos.X - EnemyHealthBarLength * 0.5, HBScreenPos.Y - EnemyHealthBarHeight);
        C.DrawTileStretched(WhiteMaterial, EnemyHealthBarLength, EnemyHealthBarHeight);

        HealthPct = 1.0f * Health / MaxHealth;

        C.SetDrawColor(255, 0, 0, 255);
        C.SetPos(HBScreenPos.X - EnemyHealthBarLength * 0.5 + 1.0, HBScreenPos.Y - EnemyHealthBarHeight + 1.0);
        C.DrawTileStretched(WhiteMaterial, (EnemyHealthBarLength - 2.0) * HealthPct, EnemyHealthBarHeight - 2.0);
    }

    C.DrawColor = OldDrawColor;
}


function DrawBlameIcons(Canvas C)
{
    local KFMonster M;
    local vector CameraLocation, CamDir, TargetLocation, HBScreenPos;
    local rotator CameraRotation;
    local float Dist, IconSize;
    local color OldDrawColor;

    if ( BlamedMonsterClass == none )
        return;

    // rjp --  don't draw the health bar if menus are open
    // exception being, the Veterancy menu

    if ( PlayerOwner.Player.GUIController.bActive && GUIController(PlayerOwner.Player.GUIController).ActivePage.Name != 'GUIVeterancyBinder' )
    {
        return;
    }

    OldDrawColor = C.DrawColor;

    C.GetCameraLocation(CameraLocation, CameraRotation);

    foreach C.ViewPort.Actor.VisibleCollidingActors(class'KFMonster',M,BlameDrawDistance,C.ViewPort.Actor.CalcViewLocation) {
        if ( ClassIsChildOf(M.class, BlamedMonsterClass) && M.Health > 0 && !M.Cloaked() ) {
            if ( M.bUseExtendedCollision)
                TargetLocation = M.Location + vect(0, 0, 1) * (M.ColHeight + M.ColOffset.Z);
            else
                TargetLocation = M.Location + vect(0, 0, 1) * M.CollisionHeight;
            Dist = VSize(TargetLocation - CameraLocation);
            IconSize = BlamedIconSize * fmax(0.5, (BlameDrawDistance - Dist) / BlameDrawDistance);
            IconSize *= float(C.SizeX) / 1024.f;

            CamDir  = vector(CameraRotation);

            // Check Distance Threshold / behind camera cut off
            if ( Dist > HealthBarCutoffDist || (Normal(TargetLocation - CameraLocation) dot CamDir) < 0 )
            {
                continue;
            }

            // Target is located behind camera
            HBScreenPos = C.WorldToScreen(TargetLocation);

            if ( HBScreenPos.X <= 0 || HBScreenPos.X >= C.SizeX || HBScreenPos.Y <= 0 || HBScreenPos.Y >= C.SizeY)
            {
                continue;
            }

            if ( FastTrace(TargetLocation, CameraLocation) )
            {
                C.SetDrawColor(192, 192, 192, 255);
                C.SetPos(HBScreenPos.X - IconSize * 0.5, HBScreenPos.Y - IconSize);
                C.DrawTile(BlamedIcon.WidgetTexture, IconSize, IconSize, 0, 0, BlamedIcon.WidgetTexture.MaterialUSize(), BlamedIcon.WidgetTexture.MaterialVSize());
            }
        }
    }

    C.DrawColor = OldDrawColor;
}


simulated function DrawDirPointer(Canvas C, KFShopDirectionPointer DirPointer, Vector PointAt,
    int Row, int Col, optional bool bHideText, optional string TextPrefix, optional bool bRightSide,
    optional EScrnEffect Effect)
{
    local color OldDrawColor;
    local float size;
    local vector   ScreenPos, WorldPos, FixedZPos;
    local rotator  DirPointerRotation;
    local vector MyLocation;
    local actor dummy;

    if ( DirPointer == none )
        return;

    if ( bHideHud ) {
        DirPointer.bHidden = true;
        return;
    }

    OldDrawColor = C.DrawColor;
    switch (Effect) {
        case EFF_NONE:
            DirPointer.SetDrawScale(DirPointer.default.DrawScale);
            C.DrawColor.A = KFHUDAlpha;
            break;
        case EFF_PULSE:
            DirPointer.SetDrawScale(DirPointer.default.DrawScale * PulseAlpha / 255.0);
            C.DrawColor.A = PulseAlpha;
            break;
        case EFF_BLINK:
            DirPointer.SetDrawScale(DirPointer.default.DrawScale * BlinkAlpha / 255.0);
            C.DrawColor.A = BlinkAlpha;
            break;

    }

    size = C.SizeX / 16.0;
    if ( bRightSide )
        ScreenPos.X = c.ClipX - size * (0.8 + Row*2.1);
    else
        ScreenPos.X = size * (0.8 + Row*2.1);
    ScreenPos.Y = size * (1.0 + Col*1.5);
    WorldPos = PlayerOwner.Player.Console.ScreenToWorld(ScreenPos) * 10.f * (PlayerOwner.default.DefaultFOV / PlayerOwner.FovAngle) + PlayerOwner.CalcViewLocation;
    DirPointer.SetLocation(WorldPos);

    // Let's check for a real Z difference (i.e. different floor) doesn't make sense to rotate the arrow
    // only because the trader is a midget or placed slightly wrong
    if ( PawnOwner != none )
        MyLocation = PawnOwner.Location;
    else
        PlayerOwner.PlayerCalcView(dummy, MyLocation, DirPointerRotation);

    if ( PointAt.Z > MyLocation.Z + 50.f || PointAt.Z < MyLocation.Z - 50.f )
    {
        DirPointerRotation = rotator(PointAt - MyLocation);
    }
    else
    {
        FixedZPos = PointAt;
        FixedZPos.Z = MyLocation.Z;
        DirPointerRotation = rotator(FixedZPos - MyLocation);
    }
       DirPointer.SetRotation(DirPointerRotation);

    C.DrawActor(None, False, True); // Clear Z.
    DirPointer.bHidden = false;
    C.DrawActor(DirPointer, False, false);
    DirPointer.bHidden = true;

    if ( !bHideText ) {
        C.SetPos(ScreenPos.X, ScreenPos.Y + size * 0.5);
        DrawPointerDistance(C, PointAt, TextPrefix, MyLocation);
    }
    C.DrawColor = OldDrawColor;
}

// must be called only from DrawDirPointer!
protected simulated function DrawPointerDistance(Canvas C, Vector PointAt, string TextPrefix, Vector MyLocation)
{
    local int       FontSize;
    local float     XL, YL;
    local string    S;

    S = TextPrefix $ int(VSize(PointAt - MyLocation) / 50) $ DistanceUnitString;
    if ( C.ClipX <= 800 )
        FontSize = 7;
    else if ( C.ClipX <= 1024 )
        FontSize = 6;
    else if ( C.ClipX < 1400 )
        FontSize = 5;
    else if ( C.ClipX < 1700 )
        FontSize = 4;
    else
        FontSize = 3;
    C.Font = LoadFont(FontSize);
    C.StrLen(S, XL, YL);
    C.CurX -= XL/2;
    C.DrawText(S);
}


function DisplayPortrait(PlayerReplicationInfo PRI)
{
    local Material NewPortrait;
    local ScrnCustomPRI CPRI;

    if ( LastPlayerIDTalking > 0 )
        return;

    CPRI = class'ScrnCustomPRI'.static.FindMe(PRI);
    if ( CPRI != none )
        NewPortrait = CPRI.GetAvatar();

    if ( NewPortrait != none )
        bSpecialPortrait = true;
    else {
        NewPortrait = PRI.GetPortrait();
        bSpecialPortrait = false;
    }

    if ( NewPortrait == None )
        return;

    if ( Portrait == None )
        PortraitX = 1;

    Portrait = NewPortrait;
    PortraitTime = Level.TimeSeconds + 3;
    PortraitPRI = PRI;
}

// seems like I'm the first who removed that bloody "final" mark  -- PooSH
simulated function DrawPortraitSE( Canvas C )
{
    local float PortraitWidth, PortraitHeight, Margin, XL, YL, X, Y;
    local int FontIdx;
    local ScrnCustomPRI PortraitScrnPRI;
    local Material M;

    PortraitWidth = 0.125 * C.ClipY;
    if ( bSpecialPortrait && Portrait != TraderPortrait )
        PortraitHeight = PortraitWidth * Portrait.MaterialVSize() / Portrait.MaterialUSize();
    else
        PortraitHeight = 1.5 * PortraitWidth;

    Margin = 0.025*PortraitWidth;
    X = -PortraitWidth * PortraitX + Margin;
    Y = (C.ClipY - PortraitHeight)/2 + Margin;

    // name
    if ( PortraitPRI != None )
    {
        if ( PortraitPRI.Team != None && PortraitPRI.Team.TeamIndex < 2 )
            C.DrawColor = TextColors[PortraitPRI.Team.TeamIndex];

        FontIdx = -2;
        do {
            C.Font = GetFontSizeIndex(C, FontIdx);
            ScrnScoreBoardClass.Static.TextSizeCountrySE(C,PortraitPRI,XL,YL);
        }until ( XL <= PortraitWidth || --FontIdx < -8 );

        // shift portrait up if it gets overlaped with console messages
        if ( Y + (1.07 * PortraitHeight + YL) > MsgTopY )
            Y = MsgTopY - 1.07 * PortraitHeight - YL;

        if ( XL > PortraitWidth )
            ScrnScoreBoardClass.Static.DrawCountryNameSE(C,PortraitPRI, C.ClipY/256 - PortraitWidth*PortraitX, Y + 1.06 * PortraitHeight); // align left
        else
            ScrnScoreBoardClass.Static.DrawCountryNameSE(C,PortraitPRI,C.ClipY/256 - PortraitWidth*PortraitX + (PortraitWidth - XL)/2, Y + 1.06 * PortraitHeight); // align center
    }
    else if ( Portrait == TraderPortrait )
    {
        C.DrawColor = WhiteColor;
        C.Font = GetFontSizeIndex(C, -2);
        C.TextSize(TraderString, XL, YL);
        // shift portrait up if it gets overlaped with console messages
        if ( ConsoleMessagePosY < 0.5 && (Y + 1.07 * PortraitHeight + YL) > MsgTopY )
            Y = MsgTopY - 1.07 * PortraitHeight - YL;
        C.SetPos(C.ClipY / 256 - PortraitWidth * PortraitX + 0.5 * (PortraitWidth - XL), Y + 1.06 * PortraitHeight);
        C.DrawTextClipped(TraderString,true);
    }

    // black background prevents alpha/mask flickering on portraits
    C.SetPos(X, Y);
    C.DrawColor = BlackColor;
    C.DrawTileStretched(WhiteMaterial, PortraitWidth, PortraitHeight);
    C.DrawColor = WhiteColor;
    C.SetPos(X, Y);
    C.DrawTile(Portrait, PortraitWidth, PortraitHeight, 0, 0, Portrait.MaterialUSize(), Portrait.MaterialVSize());

    if ( !bSpecialPortrait ) {
        PortraitScrnPRI = class'ScrnCustomPRI'.static.FindMe(PortraitPRI);
        if ( PortraitScrnPRI != none )
            M = PortraitScrnPRI.GetClanIcon();
        if ( M != none && M != Portrait ) {
            C.SetPos(X + PortraitWidth/2, Y + PortraitHeight - PortraitWidth/2);
            C.DrawColor.A = 160;
            C.DrawTile(M, PortraitWidth/2, PortraitWidth/2, 0, 0, M.MaterialUSize(), M.MaterialVSize());
            C.DrawColor.A = 255;
        }
    }


    C.DrawColor = C.static.MakeColor(160, 160, 160);
    C.SetPos(X, Y);
    C.DrawTile( Material'kf_fx_trip_t.Misc.KFModuNoise', PortraitWidth, PortraitHeight, 0.0, 0.0, 512, 512 );

    C.DrawColor = WhiteColor;
    C.SetPos(X - Margin, Y - Margin);
    C.DrawTileStretched(texture'InterfaceContent.Menu.BorderBoxA1', PortraitWidth + 2*Margin, PortraitHeight + 2*Margin);
}

simulated function DrawFirstPersonSpectatorHUD(Canvas C)
{
    local String S;
    local float TempSize, XL, YL;

    // player name
    C.SetDrawColor(200, 200, 200, KFHUDAlpha);
    C.Font = GetFontSizeIndex(C, -4);
    C.TextSize(strFollowing, XL, YL);
    c.SetPos((c.ClipX-XL)/2, 0);
    c.DrawText(strFollowing);

    if ( bSpectatingZED ) {
        s = KFMonster(PawnOwner).MenuName;
        C.Font = LoadWaitingFont(1);
        C.SetDrawColor(100, 0, 0, KFHUDAlpha);
        C.TextSize(s, XL, TempSize);
        c.SetPos((c.ClipX-XL)/2, YL);
        c.DrawText(s);
    }
    else {
        C.Font = GetFontSizeIndex(C, 0);
        C.DrawColor = WhiteAlphaColor;
        ScrnScoreBoardClass.Static.TextSizeCountrySE(C,PawnOwner.PlayerReplicationInfo,XL,TempSize);
        ScrnScoreBoardClass.Static.DrawCountryNameSE(C,PawnOwner.PlayerReplicationInfo,(c.ClipX-XL)/2,YL);

        C.DrawColor = WhiteAlphaColor;
        // weapon icon
        if ( OwnerWeaponClass != none && OwnerWeaponClass.default.TraderInfoTexture != none ) {
            TempSize = c.ClipY * 0.2;
            C.SetPos((c.ClipX-TempSize)/2, c.ClipY - TempSize);
            C.DrawTile(OwnerWeaponClass.default.TraderInfoTexture, TempSize, TempSize, 0, 0, OwnerWeaponClass.default.TraderInfoTexture.MaterialUSize(), OwnerWeaponClass.default.TraderInfoTexture.MaterialVSize());
        }
    }
}

simulated function DrawPlayerInfos(Canvas C)
{
    local KFPawn KFBuddy;
    local vector CamPos, ViewDir, ScreenPos;
    local rotator CamRot;

    // Grab our View Direction
    C.GetCameraLocation(CamPos,CamRot);
    ViewDir = vector(CamRot);

    // Draw the Name, Health, Armor, and Veterancy above other players (using this way to fix portal's beacon errors).
    foreach VisibleCollidingActors(class'KFPawn', KFBuddy, 1000.f, CamPos) {
        KFBuddy.bNoTeamBeacon = true;
        if ( KFBuddy.PlayerReplicationInfo != none && KFBuddy.Health > 0 && KFBuddy != PlayerOwner.Pawn
                && ((KFBuddy.Location - CamPos) Dot ViewDir) > 0.8 )
        {
            ScreenPos = C.WorldToScreen(KFBuddy.Location + vect(0,0,1) * KFBuddy.CollisionHeight * PlayerInfoOffset);
            if( ScreenPos.X>=0 && ScreenPos.Y>=0 && ScreenPos.X<=C.ClipX && ScreenPos.Y<=C.ClipY )
                DrawPlayerInfo(C, KFBuddy, ScreenPos.X, ScreenPos.Y);
        }
    }
}

simulated function DrawHud(Canvas C)
{
    if ( bDebugSpectatingHUD ) {
        DrawSpectatingHud(C);
        return;
    }

    RenderDelta = Level.TimeSeconds - LastHUDRenderTime;
    LastHUDRenderTime = Level.TimeSeconds;

    if ( FontsPrecached < 2 )
        PrecacheFonts(C);

    UpdateHud();

    PassStyle = STY_Modulated;
    DrawModOverlay(C);

    if ( bUseBloom )
        PlayerOwner.PostFX_SetActive(0, true);

    if ( bHideHud ) {
        // Draw fade effects even if the hud is hidden so poeple can't just turn off thier hud
        C.Style = ERenderStyle.STY_Alpha;
        DrawFadeEffect(C);
        return;
    }

    if ( KFPRI != none && KFPRI.bViewingMatineeCinematic ) {
        PassStyle = STY_Alpha;
        DrawCinematicHUD(C);
    }
    else {
        if ( bShowTargeting )
            DrawTargeting(C);

        DrawPlayerInfos(C);

        PassStyle = STY_Alpha;
        DrawDamageIndicators(C);
        DrawHudPassA(C);
        DrawHudPassC(C);

        if ( ScrnPC != none && ScrnPC.ActiveNote != none ) {
            if( PlayerOwner.Pawn == none )
                ScrnPC.ActiveNote = None;
            else
                ScrnPC.ActiveNote.RenderNote(C);
        }

        PassStyle = STY_None;
        DisplayLocalMessages(C);
        DrawWeaponName(C);
        DrawVehicleName(C);

        PassStyle = STY_Alpha;

        if ( KFGRI != none && KFGRI.EndGameType > 0 )
        {
            DrawEndGameHUD(C, KFGRI.EndGameType==2);
            return;
        }

        RenderFlash(C);
        C.Style = PassStyle;
        DrawKFHUDTextElements(C);
    }

    if ( bShowNotification )
        DrawPopupNotification(C);
}

// a lot of copy-paste job, because some devs are using "final" mark too much
simulated function DrawSpectatingHud(Canvas C)
{
    local bool bGameEnded, bSpecHUD;

    DrawModOverlay(C);

    if( bHideHud )
        return;

    bSpecHUD = bDebugSpectatingHUD || PlayerOwner.PlayerReplicationInfo == none
            || PlayerOwner.PlayerReplicationInfo.bOnlySpectator;

    PlayerOwner.PostFX_SetActive(0, false);

    DrawPlayerInfos(C);

    DrawFadeEffect(C);

    if ( ScrnPC != none && ScrnPC.ActiveNote != none )
        ScrnPC.ActiveNote = none;

    bGameEnded = KFGRI != none && KFGRI.EndGameType > 0;
    if( bGameEnded ) {
        if( KFGRI.EndGameType == 2 ) {
            DrawEndGameHUD(C, True);
            DrawStoryHUDInfo(C);
        }
        else {
            DrawEndGameHUD(C, False);
        }
    }

    if ( !bSpecHUD ) {
        DrawKFHUDTextElements(C);
    }
    DisplayLocalMessages(C);

    if ( bShowScoreBoard && ScoreBoard != None ) {
        ScoreBoard.DrawScoreboard(C);
    }
    else if ( bSpecHUD && !bGameEnded ) {
        DrawSpecialSpectatingHUD(C);
    }

    if ( bShowPortrait && Portrait != None )
        DrawPortraitSE(C);

    if ( bDrawHint )
        DrawHint(C);

    DrawStoryHUDInfo(C);

    if ( ShowDamages > 0 )
        DrawDamage(C);
}

simulated function DrawKFHUDTextElements(Canvas C)
{
    local float    XL, YL;
    local int      NumZombies, Counter;
    local string   S;
    local float    CircleSize;
    local float    ResScale;

    if ( PlayerOwner == none || KFGRI == none || !KFGRI.bMatchHasBegun || ScrnPC.bShopping )
        return;

    if( KF_StoryGRI(Level.GRI) != none )
        return; // DrawStoryHUDInfo is used instead

    ResScale =  C.SizeX / 1024.0;
    CircleSize = FMin(128 * ResScale,128);
    C.FontScaleX = FMin(ResScale,1.f);
    C.FontScaleY = FMin(ResScale,1.f);

    // Countdown Text
    if( !KFGRI.bWaveInProgress || (ScrnGRI != none && ScrnGRI.WaveEndRule == 2 /*RULE_Timeout*/ ) )
    {
        C.SetDrawColor(255, 255, 255, 255);
        C.SetPos(C.ClipX - CircleSize, 2);
        C.DrawTile(Material'KillingFloorHUD.HUD.Hud_Bio_Clock_Circle', CircleSize, CircleSize, 0, 0, 256, 256);

        Counter = KFGRI.TimeToNextWave / 60;
        NumZombies = KFGRI.TimeToNextWave - (Counter * 60);

        S = Eval((Counter >= 10), string(Counter), "0" $ Counter) $ ":" $ Eval((NumZombies >= 10), string(NumZombies), "0" $ NumZombies);
        C.Font = LoadFont(2);
        C.Strlen(S, XL, YL);
        C.SetDrawColor(255, 50, 50, KFHUDAlpha);
        C.SetPos(C.ClipX - CircleSize/2 - (XL / 2), CircleSize/2 - YL / 2);
        C.DrawText(S, False);
    }
    else {
        C.SetDrawColor(255, 255, 255, 255);
        C.SetPos(C.ClipX - CircleSize, 2);
        C.DrawTile(Material'KillingFloorHUD.HUD.Hud_Bio_Circle', CircleSize, CircleSize, 0, 0, 256, 256);

        Counter = KFGRI.MaxMonsters;
        if (ScrnGRI != none) {
            switch (ScrnGRI.WaveEndRule) {
                case 3:  // RULE_EarnDosh
                case 5:  // RULE_GrabDosh
                case 6:  // RULE_GrabDoshZed
                    C.SetPos(C.ClipX - CircleSize/2 - CircleSize/8, 8);
                    if ( KFPRI != none && KFPRI.Team != none ) {
                        C.DrawColor = TeamColors[KFPRI.Team.TeamIndex];
                        C.DrawColor.A = 255;
                    }
                    C.DrawTile(Texture'ScrnTex.HUD.Hud_Pound_Symbol_BW', CircleSize/4, CircleSize/4, 0, 0, 64, 64);
                    Counter = ScrnGRI.WaveCounter;
                    break;

                case 7:  // RULE_GrabAmmo
                    C.SetPos(C.ClipX - CircleSize/2 - CircleSize/8, 8);
                    C.SetDrawColor(255, 255, 255, 255);
                    C.DrawTile(ClipsIcon.WidgetTexture, CircleSize/4, CircleSize/4, 0, 0, ClipsIcon.TextureCoords.X2, ClipsIcon.TextureCoords.Y2);
                    Counter = ScrnGRI.WaveCounter;
                    break;

                case 8:  // RULE_KillSpecial
                    Counter = ScrnGRI.WaveCounter;
                    break;
            }
        }
        S = eval(Counter >= 0, string(Counter), "?");
        C.Font = LoadFont(1);
        C.Strlen(S, XL, YL);
        if (XL > CircleSize * 0.75) {
            C.Font = LoadFont(2);
            C.Strlen(S, XL, YL);
        }
        C.SetDrawColor(255, 50, 50, KFHUDAlpha);
        C.SetPos(C.ClipX - CircleSize/2 - (XL / 2), CircleSize/2 - (YL / 1.5));
        C.DrawText(S);
    }

    if( KFGRI.bWaveInProgress ) {
        // Show the number of waves
        S = WaveString @ string(KFGRI.WaveNumber + 1) $ "/" $ string(KFGRI.FinalWave);
        C.Font = LoadFont(5);
        C.Strlen(S, XL, YL);
        C.SetPos(C.ClipX - CircleSize/2 - (XL / 2), CircleSize/2 + (YL / 2.5));
        C.DrawText(S);
    }

    C.FontScaleX = 1;
    C.FontScaleY = 1;


    if ( KFPRI == none || KFPRI.Team == none || KFPRI.bOnlySpectator || PawnOwner == none )
    {
        return;
    }

    // Draw the shop pointer
    if ( KFGRI.CurrentShop != none && (ScrnGRI == none || ScrnGRI.bTraderArrow) ) {
        if ( ShopDirPointer == None ) {
            ShopDirPointer = Spawn(Class'KFShopDirectionPointer');
            ShopDirPointer.bHidden = true;
        }
        C.DrawColor = TextColors[TeamIndex];
        DrawDirPointer(C, ShopDirPointer,  KFGRI.CurrentShop.Location, 0, 0, false, strTrader);
    }
}


// C&P to add CriticalOverlayTimer
simulated function DrawModOverlay( Canvas C )
{
    local float MaxRBrighten, MaxGBrighten, MaxBBrighten;

    // We want the overlay to start black, and fade in, almost like the player opened their eyes
    // BrightFactor = 1.5;   // Not too bright.  Not too dark.  Livens things up just abit
    // Hook for Optional Vision overlay.  - Alex

    if( PawnOwner==None )
    {
        if( CurrentZone!=None || CurrentVolume!=None ) // Reset everything.
        {
            LastR = 0;
                LastG = 0;
                LastB = 0;
            CurrentZone = None;
            LastZone = None;
            CurrentVolume = None;
            LastVolume = None;
            bZoneChanged = false;
            SetTimer(0.f, false);
        }
        VisionOverlay = default.VisionOverlay;

        // Dead Players see Red
        if( !PlayerOwner.IsSpectating() && SpectatorOverlay != none )
        {
            C.SetDrawColor(255, 255, 255, GrainAlpha);
            C.DrawTile(SpectatorOverlay, C.SizeX, C.SizeY, 0, 0, 1024, 1024);
        }
        return;
    }

    C.SetPos(0, 0);

    // if critical, pulsate.  otherwise, dont.
    if ( CriticalOverlayTimer > Level.TimeSeconds )
        VisionOverlay = CriticalOverlay;
    else if ( (PlayerOwner.Pawn==PawnOwner || !PlayerOwner.bBehindView) && Vehicle(PawnOwner)==None
            && PawnOwner.Health>0 && PawnOwner.Health<(PawnOwner.HealthMax*0.25) )
        VisionOverlay = NearDeathOverlay;
    else
        VisionOverlay = default.VisionOverlay;

    // Players can choose to turn this feature off completely.
    // conversely, setting bDistanceFog = false in a Zone
    //will cause the code to ignore that zone for a shift in RGB tint
    if ( VisionOverlay == none || (KFLevelRule != none && !KFLevelRule.bUseVisionOverlay) )
        return;

    // here we determine the maximum "brighten" amounts for each value.  CANNOT exceed 255
    MaxRBrighten = Round(LastR* (1.0 - (LastR / 255)) - 2) ;
    MaxGBrighten = Round(LastG* (1.0 - (LastG / 255)) - 2) ;
    MaxBBrighten = Round(LastB* (1.0 - (LastB / 255)) - 2) ;

    C.SetDrawColor(LastR + MaxRBrighten, LastG + MaxGBrighten, LastB + MaxBBrighten, GrainAlpha);
    C.DrawTileScaled(VisionOverlay, C.SizeX, C.SizeY);  //,0,0,1024,1024);

    // Here we change over the Zone.
    // What happens of importance is
    // A.  Set Old Zone to current
    // B.  Set New Zone
    // C.  Set Color info up for use by Tick()

    // if we're in a new zone or volume without distance fog...just , dont touch anything.
    // the physicsvolume check is abit screwy because the player is always in a volume called "DefaultPhyicsVolume"
    // so we've gotta make sure that the return checks take this into consideration.

    // This block of code here just makes sure that if we've already got a tint, and we step into a zone/volume without
    // bDistanceFog, our current tint is not affected.
    // a.  If I'm in a zone and its not bDistanceFog. AND IM NOT IN A PHYSICSVOLUME. Just a zone.
    // b.  If I'm in a Volume
    if ( !PawnOwner.Region.Zone.bDistanceFog &&
         DefaultPhysicsVolume(PawnOwner.PhysicsVolume)==None && !PawnOwner.PhysicsVolume.bDistanceFog )
        return;

    if ( !bZoneChanged )
    {
        // Grab the most recent zone info from our PRI
        // Only update if it's different
        // EDIT:  AND HAS bDISTANCEFOG true
        if ( CurrentZone!=PawnOwner.Region.Zone || (DefaultPhysicsVolume(PawnOwner.PhysicsVolume) == None &&
             CurrentVolume != PawnOwner.PhysicsVolume) )
        {
            if ( CurrentZone != none )
                LastZone = CurrentZone;
            else if ( CurrentVolume != none )
                LastVolume = CurrentVolume;

            // This is for all occasions where we're either in a Levelinfo handled zone
            // Or a zoneinfo.
            // If we're in a LevelInfo / ZoneInfo  and NOT touching a Volume.  Set current Zone
            if ( PawnOwner.Region.Zone.bDistanceFog && DefaultPhysicsVolume(PawnOwner.PhysicsVolume)!= none && !PawnOwner.Region.Zone.bNoKFColorCorrection )
            {
                CurrentVolume = none;
                CurrentZone = PawnOwner.Region.Zone;
            }
            else if ( DefaultPhysicsVolume(PawnOwner.PhysicsVolume) == None && PawnOwner.PhysicsVolume.bDistanceFog && !PawnOwner.PhysicsVolume.bNoKFColorCorrection)
            {
                CurrentZone = none;
                CurrentVolume = PawnOwner.PhysicsVolume;
            }

            if ( CurrentVolume != none )
                LastZone = none;
            else if ( CurrentZone != none )
                LastVolume = none;

            if ( LastZone != none )
            {
                if( LastZone.bNewKFColorCorrection )
                {
                    LastR = LastZone.KFOverlayColor.R;
                        LastG = LastZone.KFOverlayColor.G;
                        LastB = LastZone.KFOverlayColor.B;
                }
                else
                {
                    LastR = LastZone.DistanceFogColor.R;
                        LastG = LastZone.DistanceFogColor.G;
                        LastB = LastZone.DistanceFogColor.B;
                }
            }
            else if ( LastVolume != none )
            {
                if( LastVolume.bNewKFColorCorrection )
                {
                    LastR = LastVolume.KFOverlayColor.R;
                        LastG = LastVolume.KFOverlayColor.G;
                        LastB = LastVolume.KFOverlayColor.B;
                }
                else
                {
                        LastR = LastVolume.DistanceFogColor.R;
                        LastG = LastVolume.DistanceFogColor.G;
                        LastB = LastVolume.DistanceFogColor.B;
                }
            }
            else if ( LastZone != none && LastVolume != none )
                return;

            if ( LastZone != CurrentZone || LastVolume != CurrentVolume )
            {
                bZoneChanged = true;
                SetTimer(OverlayFadeSpeed, false);
            }
        }
    }
    if ( !bTicksTurn && bZoneChanged )
    {
        // Pass it off to the tick now
        // valueCheckout signifies that none of the three values have been
        // altered by Tick() yet.

        // BOUNCE IT BACK! :D
        ValueCheckOut = 0;
        bTicksTurn = true;
        SetTimer(OverlayFadeSpeed, false);
    }
}


simulated function DrawSpecialSpectatingHUD(Canvas C)
{
    local float XL, YL;
    local string S;
    local int i, d;

    if ( KFGRI == none || !KFGRI.bMatchHasBegun )
        return;

    C.Font = LoadWaitingFont(SpecHeaderFont); // 0 - big, 1 - smaller
    C.DrawColor = WhiteColor;
    C.DrawColor.A = KFHUDAlpha;

    // draw time, if game is not finished yet
    if ( KFGRI.EndGameType == 0 && KFGRI.ElapsedTime > 0 ) {
        // total time
        C.SetPos(0, 0);
        C.DrawText(class'ScrnFunctions'.static.FormatTime(KFGRI.ElapsedTime));

        // wave num
        S = WaveString @ string(KFGRI.WaveNumber + 1);
        C.TextSize(S, XL, YL);
        C.SetPos((C.ClipX-XL)*0.5, 0);
        C.DrawText(S);

        // number of zeds
        if ( KFGRI.bWaveInProgress )
            S = string(KFGRI.MaxMonsters);
        else
            s = class'ScrnFunctions'.static.FormatTime(KFGRI.TimeToNextWave);
        C.TextSize(S, XL, YL);
        C.SetPos(C.ClipX-XL, 0);
        C.DrawText(S);
    }

    // deaths
    if ( bDrawSpecDeaths ) {
        d = 0;
        for ( i = 0; i < KFGRI.PRIArray.Length; i++) {
            if ( !KFGRI.PRIArray[i].bOnlySpectator )
                d += KFGRI.PRIArray[i].Deaths;
        }
        if ( d > 0 ) {
            S = string(d);
            C.TextSize(S, XL, YL);
            C.SetPos(c.ClipY*0.01, c.ClipY*0.99 - YL/2);
            C.DrawTile(ScrnScoreBoardClass.default.DeathIcon, YL/2, YL/2, 0, 0, ScrnScoreBoardClass.default.DeathIcon.MaterialUSize(), ScrnScoreBoardClass.default.DeathIcon.MaterialVSize());
            C.SetPos(c.ClipY*0.01 + YL/2, c.ClipY*0.99 - YL);
            C.DrawText(S);
        }
    }
}

// color tar support
simulated function LocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject, optional String CriticalString)
{
    local int i;
    local PlayerReplicationInfo HUDPRI;

    if( Message == None )
        return;

    if( bIsCinematic && !ClassIsChildOf(Message,class'ActionMessage') )
        return;

    if( CriticalString == "" )
    {
        if ( (PawnOwner != None) && (PawnOwner.PlayerReplicationInfo != None) )
            HUDPRI = PawnOwner.PlayerReplicationInfo;
        else
            HUDPRI = PlayerOwner.PlayerReplicationInfo;

        if ( HUDPRI == RelatedPRI_1 ) {
            CriticalString = class'ScrnFunctions'.static.ParseColorTags(
                    Message.static.GetRelatedString(Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject), HUDPRI);
        }
        else {
            CriticalString = class'ScrnFunctions'.static.ParseColorTags(
                    Message.static.GetString(Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject));
        }
    }

    if( bMessageBeep && Message.default.bBeep )
        PlayerOwner.PlayBeepSound();

    if( !Message.default.bIsSpecial )
    {
        if ( PlayerOwner.bDemoOwner )
        {
            for( i=0; i<ConsoleMessageCount; i++ )
                if ( i >= ArrayCount(TextMessages) || TextMessages[i].Text == "" )
                    break;

            if ( i > 0 && TextMessages[i-1].Text == CriticalString )
                return;
        }
        AddTextMessage( CriticalString, Message,RelatedPRI_1 );
        return;
    }

    i = ArrayCount(LocalMessages);
    if( Message.default.bIsUnique )
    {
        for( i = 0; i < ArrayCount(LocalMessages); i++ )
        {
            if( LocalMessages[i].Message == None )
                continue;

            if( LocalMessages[i].Message == Message )
                break;
        }
    }
    else if ( Message.default.bIsPartiallyUnique || PlayerOwner.bDemoOwner )
    {
        for( i = 0; i < ArrayCount(LocalMessages); i++ )
        {
            if( LocalMessages[i].Message == None )
                continue;

            if( ( LocalMessages[i].Message == Message ) && ( LocalMessages[i].Switch == Switch ) )
                break;
        }
    }

    if( i == ArrayCount(LocalMessages) )
    {
        for( i = 0; i < ArrayCount(LocalMessages); i++ )
        {
            if( LocalMessages[i].Message == None )
                break;
        }
    }

    if( i == ArrayCount(LocalMessages) )
    {
        for( i = 0; i < ArrayCount(LocalMessages) - 1; i++ )
            LocalMessages[i] = LocalMessages[i+1];
    }

    ClearMessage( LocalMessages[i] );

    LocalMessages[i].Message = Message;
    LocalMessages[i].Switch = Switch;
    LocalMessages[i].RelatedPRI = RelatedPRI_1;
    LocalMessages[i].RelatedPRI2 = RelatedPRI_2;
    LocalMessages[i].OptionalObject = OptionalObject;
    LocalMessages[i].EndOfLife = Message.static.GetLifetime(Switch) + Level.TimeSeconds;
    LocalMessages[i].StringMessage = CriticalString;
    LocalMessages[i].LifeTime = Message.static.GetLifetime(Switch);
}

simulated function DrawMessage( Canvas C, int i, float PosX, float PosY, out float DX, out float DY )
{
    // fix for cases when some mutators directly write LocalMessages instead of calling LocalizedMessage()
    // e.g., MutKillMessage
    LocalMessages[i].StringMessage = class'ScrnFunctions'.static.ParseColorTags(LocalMessages[i].StringMessage,
            LocalMessages[i].RelatedPRI);
    super.DrawMessage(C, i, PosX, PosY, DX, DY);
}

function AddTextMessage(string M, class<LocalMessage> MessageClass, PlayerReplicationInfo PRI)
{
    local int i;
    local bool bSetPRI;

    if ( class'ScrnBalance'.default.Mut != none ) {
        M = class'ScrnFunctions'.static.ParseColorTags(M, PRI);
        if ( MessageClass==class'SayMessagePlus' ) {
            MessageClass = class'ScrnSayMessagePlus';
            bSetPRI = true;
        }
        else if ( MessageClass==class'TeamSayMessagePlus' ) {
            MessageClass = class'ScrnTeamSayMessagePlus';
            bSetPRI = true;
        }
        else if ( MessageClass==class'xDeathMessage' )
            MessageClass = class'ScrnDeathMessage';
    }
    else {
        bSetPRI = MessageClass==class'SayMessagePlus' || MessageClass==class'TeamSayMessagePlus';
    }


    if( bMessageBeep && MessageClass.Default.bBeep )
        PlayerOwner.PlayBeepSound();

    for( i=0; i<ConsoleMessageCount; i++ )
    {
        if ( TextMessages[i].Text == "" )
            break;
    }
    if( i == ConsoleMessageCount )
    {
        for( i=0; i<ConsoleMessageCount-1; i++ )
            TextMessages[i] = TextMessages[i+1];
    }
    TextMessages[i].Text = M;
    TextMessages[i].MessageLife = Level.TimeSeconds + MessageClass.Default.LifeTime;
    TextMessages[i].TextColor = MessageClass.static.GetConsoleColor(PRI);
    if( bSetPRI )
        TextMessages[i].PRI = PRI;
    else
        TextMessages[i].PRI = None;
}


// added support of color messages
function DisplayMessages(Canvas C)
{
    local int i, j, XPos, YPos,MessageCount;
    local float XL, YL, XXL, YYL;

    for( i = 0; i < ConsoleMessageCount; i++ )
    {
        if ( TextMessages[i].Text == "" )
            break;
        else if( TextMessages[i].MessageLife < Level.TimeSeconds )
        {
            TextMessages[i].Text = "";

            if( i < ConsoleMessageCount - 1 )
            {
                for( j=i; j<ConsoleMessageCount-1; j++ )
                    TextMessages[j] = TextMessages[j+1];
            }
            TextMessages[j].Text = "";
            break;
        }
        else
            MessageCount++;
    }

    MsgTopY = (ConsoleMessagePosY * HudCanvasScale * C.SizeY) + (((1.0 - HudCanvasScale) / 2.0) * C.SizeY);
    if ( PlayerOwner == none || PlayerOwner.PlayerReplicationInfo == none || !PlayerOwner.PlayerReplicationInfo.bWaitingPlayer )
    {
        XPos = (ConsoleMessagePosX * HudCanvasScale * C.SizeX) + (((1.0 - HudCanvasScale) / 2.0) * C.SizeX);
    }
    else
    {
        XPos = (0.005 * HudCanvasScale * C.SizeX) + (((1.0 - HudCanvasScale) / 2.0) * C.SizeX);
    }

    C.Font = GetConsoleFont(C);
    C.DrawColor = LevelActionFontColor;

    C.TextSize ("A", XL, YL);

    MsgTopY -= YL * MessageCount+1; // DP_LowerLeft
    MsgTopY -= YL; // Room for typing prompt

    YPos = MsgTopY;
    for( i=0; i<MessageCount; i++ )
    {
        if ( TextMessages[i].Text == "" )
            break;

        C.SetPos( XPos, YPos );
        C.DrawColor = TextMessages[i].TextColor;
        YYL = 0;
        XXL = 0;
        if( TextMessages[i].PRI!=None )
        {
            XL = ScrnScoreBoardClass.Static.DrawCountryNameSE(C,TextMessages[i].PRI,XPos,YPos);
            C.SetPos( XPos+XL, YPos );
        }
        if( SmileyMsgs.Length!=0 )
            DrawSmileyText(TextMessages[i].Text,C,,YYL);
        else
            C.DrawText(TextMessages[i].Text,false);
        YPos += (YL+YYL);
    }
}

exec function DebugCrosshair(bool bEnable)
{
    if ( Level.NetMode == NM_Client && (PlayerOwner.PlayerReplicationInfo == none || !PlayerOwner.PlayerReplicationInfo.bOnlySpectator) )
        return;

    bCrosshairShow = bEnable;
    bShowKFDebugXHair = bEnable;
}

// copy-pated to remove RODebugMode()  -- PooSH
simulated function DrawCrosshair (Canvas C)
{
    local float NormalScale;
    local int i, CurrentCrosshair;
    local float OldScale,OldW, CurrentCrosshairScale;
    local color CurrentCrosshairColor;
    local SpriteWidget CHtexture;

    if ( !bCrosshairShow || !bShowKFDebugXHair )
        return;

    // one more check to prevent hacks
    if ( PlayerOwner.Level.NetMode != NM_Standalone && (PlayerOwner.PlayerReplicationInfo == none || !PlayerOwner.PlayerReplicationInfo.bOnlySpectator) ) {
        bCrosshairShow = false;
        return;
    }

    if ( (PawnOwner != None) && (PawnOwner.Weapon != None) && (PawnOwner.Weapon.CustomCrosshair >= 0) )
    {
        CurrentCrosshairColor = PawnOwner.Weapon.CustomCrosshairColor;
        CurrentCrosshair = PawnOwner.Weapon.CustomCrosshair;
        CurrentCrosshairScale = PawnOwner.Weapon.CustomCrosshairScale;
        if ( PawnOwner.Weapon.CustomCrosshairTextureName != "" )
        {
            if ( PawnOwner.Weapon.CustomCrosshairTexture == None )
            {
                PawnOwner.Weapon.CustomCrosshairTexture = Texture(DynamicLoadObject(PawnOwner.Weapon.CustomCrosshairTextureName,class'Texture'));
                if ( PawnOwner.Weapon.CustomCrosshairTexture == None )
                {
                    log(PawnOwner.Weapon$" custom crosshair texture not found!");
                    PawnOwner.Weapon.CustomCrosshairTextureName = "";
                }
            }
            CHTexture = Crosshairs[0];
            CHTexture.WidgetTexture = PawnOwner.Weapon.CustomCrosshairTexture;
        }
    }
    else
    {
        CurrentCrosshair = CrosshairStyle;
        CurrentCrosshairColor = CrosshairColor;
        CurrentCrosshairScale = CrosshairScale;
    }

    CurrentCrosshair = Clamp(CurrentCrosshair, 0, Crosshairs.Length - 1);

    NormalScale = Crosshairs[CurrentCrosshair].TextureScale;
    if ( CHTexture.WidgetTexture == None )
        CHTexture = Crosshairs[CurrentCrosshair];
    CHTexture.TextureScale *= CurrentCrosshairScale;

    for( i = 0; i < ArrayCount(CHTexture.Tints); i++ )
        CHTexture.Tints[i] = CurrentCrossHairColor;

    OldScale = HudScale;
    HudScale=1;
    OldW = C.ColorModulate.W;
    C.ColorModulate.W = 1;
    DrawSpriteWidget (C, CHTexture);
    C.ColorModulate.W = OldW;
    HudScale=OldScale;
    CHTexture.TextureScale = NormalScale;

    //DrawEnemyName(C);
}

exec function DebugZedHealth(bool bEnable)
{
    if ( Level.NetMode == NM_Client && (PlayerOwner.PlayerReplicationInfo == none || !PlayerOwner.PlayerReplicationInfo.bOnlySpectator) )
        return;

    bZedHealthShow = bEnable;
}

simulated function DrawZedHealth(Canvas C)
{
    local vector CameraLocation, CamDir, TargetLocation, HBScreenPos;
    local rotator CameraRotation;
    local float Dist;
    local float XL, YL;
    local KFMonster M;
    local color OldDrawColor;
    local string s;

    // rjp --  don't draw the health bar if menus are open
    // exception being, the Veterancy menu
    if ( PlayerOwner.Player.GUIController.bActive && GUIController(PlayerOwner.Player.GUIController).ActivePage.Name != 'GUIVeterancyBinder' )
        return;

    OldDrawColor = C.DrawColor;
    C.Font = GetFontSizeIndex(C, -4);

    C.GetCameraLocation(CameraLocation, CameraRotation);
    CamDir = vector(CameraRotation);

    foreach C.ViewPort.Actor.VisibleCollidingActors(class'KFMonster', M, 1000, C.ViewPort.Actor.CalcViewLocation) {
        if ( M.Health <= 0 )
            continue;

        TargetLocation = M.Location;
        if ( M.bUseExtendedCollision )
            TargetLocation.Z += M.ColHeight + M.ColOffset.Z;
        else
            TargetLocation.Z += M.CollisionHeight;
        Dist = VSize(TargetLocation - CameraLocation);

        // Check behind camera cut off
        if ( (Normal(TargetLocation - CameraLocation) dot CamDir) < 0 )
            continue;

        HBScreenPos = C.WorldToScreen(TargetLocation);
        if ( HBScreenPos.X <= 0 || HBScreenPos.X >= C.SizeX || HBScreenPos.Y <= 0 || HBScreenPos.Y >= C.SizeY)
            continue;

        s = M.Health $ " / " $ int(M.HealthMax + 0.01);
        C.SetDrawColor(0, 206, 0, 255);
        C.TextSize(s, XL, YL);
        C.SetPos(HBScreenPos.X - XL/2, HBScreenPos.Y - YL);
        C.DrawText(s);

        if ( M.HeadHealth > 0 ) {
            s = string(int(M.HeadHealth + 0.01));
            C.SetDrawColor(0, 100, 255, 255);
            C.TextSize(s, XL, YL);
            C.SetPos(HBScreenPos.X - XL/2, HBScreenPos.Y - YL * 2);
            C.DrawText(s);
        }
    }

    C.DrawColor = OldDrawColor;
}

exec function DisableHudHacks()
{
    bCrosshairShow = false;
    bShowKFDebugXHair = false;
    bZedHealthShow = false;
}

exec function SpecHeaderSize(byte size)
{
    if ( size == 0 || size == 1) {
        SpecHeaderFont = 1 - size;
        SaveConfig();
    }
    else
        PlayerOwner.ClientMessage("Header size must 0 (small) or 1 (big)");
}

final static function color PerkColor(int PerkLevel)
{
    if ( PerkLevel <= 0 )
        return default.PerkColors[0];

    PerkLevel--;
    if ( class'ScrnBalance'.default.Mut.b10Stars )
        PerkLevel /= 10;
    else
        PerkLevel /= 5;

    return default.PerkColors[min(PerkLevel, default.PerkColors.length-1)];
}

final static function string ColoredPerkLevel(int PerkLevel)
{
    return class'ScrnFunctions'.static.ColorStringC(string(PerkLevel), PerkColor(PerkLevel));
}

function static Font GetStaticFontSizeIndex(Canvas C, int FontSize)
{
    if ( C.ClipY >= 384 )
        FontSize++;
    if ( C.ClipY >= 480 )
        FontSize++;
    if ( C.ClipY >= 600 )
        FontSize++;
    if ( C.ClipY >= 768 )
        FontSize++;
    if ( C.ClipY >= 900 )
        FontSize++;
    if ( C.ClipY >= 1024 )
        FontSize++;

    return LoadFontStatic(Clamp( 8-FontSize, 0, 8));
}

simulated function SetHUDAlpha()
{
    super.SetHUDAlpha();

    CoolCashIcon.Tints[0].A = KFHUDAlpha;
    CoolCashIcon.Tints[1].A = KFHUDAlpha;
    CoolCashDigits.Tints[0].A = KFHUDAlpha;
    CoolCashDigits.Tints[1].A = KFHUDAlpha;
    LeftGunAmmoBG.Tints[0].A = KFHUDAlpha;
    LeftGunAmmoBG.Tints[1].A = KFHUDAlpha;
    LeftGunAmmoDigits.Tints[0].A = KFHUDAlpha;
    LeftGunAmmoDigits.Tints[1].A = KFHUDAlpha;
    LeftGunAmmoIcon.Tints[0].A = KFHUDAlpha;
    LeftGunAmmoIcon.Tints[1].A = KFHUDAlpha;
    CoolHudAmmoColor.A = KFHUDAlpha;
    WhiteAlphaColor.A = KFHUDAlpha;
    default.WhiteAlphaColor.A = KFHUDAlpha;
}

simulated function LayoutMessage( out HudLocalizedMessage Message, Canvas C )
{
    local int FontSize;

    super.LayoutMessage(Message, C);

    FontSize = Message.Message.static.GetFontSize(Message.Switch, Message.RelatedPRI, Message.RelatedPRI2, PlayerOwner.PlayerReplicationInfo);
    if (class<WaitingMessage>(Message.Message) != none
            && (Message.Switch <= 3 || Message.Switch == 5))
    {
        Message.StringFont = GetWaitingFontSizeIndex(C, FontSize);
    }
}

function SelectWeapon()
{
    if ( ScrnHumanPawn(PawnOwner) != none && ScrnHumanPawn(PawnOwner).bQuickMeleeInProgress )
        return;  // no weapon selection during quick melee
    super.SelectWeapon();
}

exec function LeftGunAmmo(bool b)
{
    bShowLeftGunAmmo = b;
}


defaultproperties
{
    MinMagCapacity=5
    LowAmmoPercent=0.250000
    texCowboy=Texture'ScrnTex.HUD.CowboyMode'
    CowboyTileY=0.02
    CowboyTileWidth=0.250000
    ShowDamages=1
    DamagePopupFont=4
    DamagePopupFadeOutTime=3.000000
    bShowSpeed=true
    SpeedometerX=0.85
    SpeedometerY=0.00
    SpeedometerFont=5
    ChatIcon=Texture'ScrnTex.HUD.ChatIcon'
    CriticalOverlay=Shader'KFX.NearDeathShader'

    BlamedIcon=(WidgetTexture=Texture'ScrnTex.HUD.Crap64',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.500000,PosX=0.95,PosY=0.5,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    BlamedIconSize=32
    BlameCountdown=120
    BlameDrawDistance=800

    SingleNadeIcon=(WidgetTexture=Texture'KillingFloor2HUD.HUD.Hud_M79',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.220000,PosX=0.781000,PosY=0.943000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))

    // used in ScrnBuyMenuSaleList. Brought here to allow user config
    TraderGroupColor=(R=128,G=128,B=128,A=255)
    TraderActiveGroupColor=(R=192,G=192,B=255,A=255)
    TraderSelectedGroupColor=(R=192,G=192,B=255,A=255)
    TraderPriceButtonColor=(R=160,G=160,B=160,A=255)
    TraderPriceButtonDisabledColor=(R=255,G=255,B=255,A=255)
    TraderPriceButtonSelectedColor=(R=255,G=128,B=160,A=255)

    bDrawSpecDeaths=True

    strFollowing="FOLLOWING:"
    strTrader="Trader: "
    strPendingItems="Waiting for shop items from server: "

    DigitsSmall=(DigitTexture=Texture'KillingFloorHUD.Generic.HUD',TextureCoords[0]=(X1=8,Y1=6,X2=32,Y2=38),TextureCoords[1]=(X1=50,Y1=6,X2=68,Y2=38),TextureCoords[2]=(X1=83,Y1=6,X2=113,Y2=38),TextureCoords[3]=(X1=129,Y1=6,X2=157,Y2=38),TextureCoords[4]=(X1=169,Y1=6,X2=197,Y2=38),TextureCoords[5]=(X1=206,Y1=6,X2=235,Y2=38),TextureCoords[6]=(X1=241,Y1=6,X2=269,Y2=38),TextureCoords[7]=(X1=285,Y1=6,X2=315,Y2=38),TextureCoords[8]=(X1=318,Y1=6,X2=348,Y2=38),TextureCoords[9]=(X1=357,Y1=6,X2=388,Y2=38),TextureCoords[10]=(X1=390,Y1=6,X2=428,Y2=38))
    WeightDigits=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.195000,PosY=0.942000,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    LeftGunAmmoBG=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_128x64',RenderStyle=STY_Alpha,TextureCoords=(X2=128,Y2=64),TextureScale=0.35,PosX=0.260,PosY=0.935,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    LeftGunAmmoIcon=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Bullets',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.20,PosX=0.266,PosY=0.945,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    LeftGunAmmoDigits=(RenderStyle=STY_Alpha,TextureScale=0.300,PosX=0.292,PosY=0.950,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    HealthBarCutoffDist=1000
    HealthBarFullVisDist=350 // also max distance for enemy drawing

    WhiteAlphaColor=(R=255,G=255,B=255,A=255)

    TeamColors(0)=(R=255,G=64,B=64,A=255)
    TeamColors(1)=(R=90,G=153,B=198,A=255)
    TextColors(0)=(R=255,G=50,B=50,A=255)
    TextColors(1)=(R=75,G=139,B=198,A=255)
    PerkColors(0)=(R=200,G=200,B=200,A=255)
    PerkColors(1)=(R=255,G=255,B=127,A=255)
    PerkColors(2)=(R=0,G=225,B=0,A=255)
    PerkColors(3)=(R=0,G=125,B=255,A=255)
    PerkColors(4)=(R=178,G=0,B=255,A=255)
    PerkColors(5)=(R=255,G=128,B=0,A=255)
    PerkColors(6)=(R=160,G=0,B=0,A=255)


    HudStyles(0)="Classic HUD, old icons"
    HudStyles(1)="Classic HUD, new icons"
    HudStyles(2)="Cool HUD (center)"
    HudStyles(3)="Cool HUD (left)"
    HUDSTL_CLASSIC=0
    HUDSTL_MODERN=1
    HUDSTL_COOL=2
    HUDSTL_COOL_LEFT=3
    HudStyle=1

    BarStyles(0)="Classic Bars"
    BarStyles(1)="Modern Bars"
    BarStyles(2)="Modern Extended"
    BarStyles(3)="Cool Bars"
    BARSTL_CLASSIC=0
    BARSTL_MODERN=1
    BARSTL_MODERN_EX=2
    BARSTL_COOL=3
    BarStyle=1
    PlayerInfoScale=1.0
    PlayerInfoOffset=1.0

    CoolHudScale=2.0
    CoolHudAmmoOffsetX = 0.995
    CoolHudAmmoOffsetY = 0.95
    CoolHudAmmoScale=0.75
    CoolHealthFadeOutTime=10
    PerkStarsMax=30
    ScrnDrawPlayerInfoBase=ScrnDrawPlayerInfoClassic
    CoolBarBase=Texture'ScrnTex.HUD.BarBase'
    CoolBarOverlay=Texture'ScrnTex.HUD.BarOverlay'
    CoolBarSize=512
    CoolHealthBarTop=30
    CoolHealthBarHeight=350
    CoolPerkToBarSize=0.75
    CoolIconToBarSize=0.75
    CoolStarToBarSize=0.125
    CoolStarAngleRad=0.261799 // 15 degrees
    CoolPerkOffsetY=0.0
    CoolPerkLevelOffsetY=0.87
    HealthBarColor=(R=192,G=0,B=0,A=200)
    HealingBarColor=(R=255,G=128,B=128,A=200)
    OverchargeHealthColor=(R=0,G=255,B=255,A=200)
    FullHealthColor=(R=0,G=192,B=0,A=200)
    LowHealthColor=(R=210,G=50,B=0,A=200)
    ArmorBarColor=(R=0,G=0,B=200,A=200)
    BigArmorColor=(R=0,G=255,B=255,A=200)
    CoolHudColor=(R=255,G=255,B=255,A=255)
    CoolHudAmmoColor=(R=160,G=160,B=160,A=200)
    LowAmmoColor=(R=192,G=160,B=0,A=200)
    NoAmmoColor=(R=192,G=0,B=0,A=200)

    strBonusLevel="^Bonus Level^"
    XPLevelShowTime=30
    BonusLevelShowTime=2
    XPBonusFadeRate=500

    CoolPerkLevelDigits=(RenderStyle=STY_Alpha,DrawPivot=DP_MiddleMiddle,OffsetX=5,OffsetY=-2)
    CoolCashIcon=(WidgetTexture=Texture'ScrnTex.HUD.Hud_Pound_Symbol_BW',RenderStyle=STY_Alpha,DrawPivot=DP_UpperLeft,TextureCoords=(X2=64,Y2=64),TextureScale=0.25,PosX=0.00,PosY=0.004,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=200),Tints[1]=(B=255,G=255,R=255,A=200))
    CoolCashDigits=(RenderStyle=STY_Alpha,DrawPivot=DP_UpperLeft,TextureScale=0.5,PosX=0.03,PosY=0.005,Tints[0]=(B=160,G=160,R=160,A=200),Tints[1]=(B=160,G=160,R=160,A=200))

    PulseRate=450
    BlinkRate=512
}
