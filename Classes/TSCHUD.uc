class TSCHUD extends ScrnHUD;

#exec OBJ LOAD FILE=TSC_T.utx

var Texture Boxes[2];

// 0 - red win
// 1 - blue win
// 2 - both survived
// 3 - wiped
var Material EndGameMaterials[4];
var Material WaveGB[4];

var     TSCGameReplicationInfo   TSCGRI;

var     KFShopDirectionPointer  BaseDirPointer, EnemyBaseDirPointer, EnemyShopDirPointer;

var localized string strBase;
var localized string strOurBase;
var localized string strGnome;
var localized string strCarrier;
var localized string strEnemyBase;


// TSC hints
var config bool bHideTSCHints;
var transient float CriticalHintBG;
var transient float LastCriticalHintTime;

var localized string titleWelcome;
var localized string titleSuddenDeath;
var localized string titleSetupBase;
var localized string titleBaseLost;
var localized string titlePvP;
var localized string titleStunned;

var localized string hintWelcome;
var localized string hintFirstWave;
var localized string hintPrepareToFight;
var localized string hintSuddenDeath;
var localized string hintSuddenDeathTrader;
var localized string hintGotoBase;
var localized string hintEnemyBase;
var localized string hintShopping;
var localized string hintFollowCarrier;
var localized string hintGetGnome;
var localized string hintSetupBase;
var localized string hintSetupEnemyBase;
var localized string hintBaseLostTrader;
var localized string hintPvP;
var localized string hintStunned;


var()   SpriteWidget            SpecKillsBG[2];
var()   SpriteWidget            SpecKillsIcon[2];
var()   NumericWidget           SpecKillsDigits[2];
var()   SpriteWidget            SpecWaveKillsBG[2];
var()   NumericWidget           SpecWaveKillsDigits[2];
var()   SpriteWidget            SpecMinKillsBG[2];
var()   NumericWidget           SpecMinKillsDigits[2];

var()   SpriteWidget            SpecDeathsBG[2];
var()   SpriteWidget            SpecDeathsIcon[2];
var()   NumericWidget           SpecDeathsDigits[2];

var()   SpriteWidget            SpecDoshBG[2];
var()   SpriteWidget            SpecDoshIcon[2];
var()   NumericWidget           SpecDoshDigits[2];

var     material                SpecBarBG;
var     config float            SpecBarY, SpecBarWidth, SpecBarHeight;

var protected transient int TeamDosh[2], TeamHealth[2];
var protected transient float RedTeamHealthRatio;
var protected transient float NextStatUpdateTime;

var bool bDrawShopDirPointer;

simulated function DestroyDirPointers()
{
    if ( ShopDirPointer!=None )
        ShopDirPointer.Destroy();
    if ( EnemyShopDirPointer!=None )
        EnemyShopDirPointer.Destroy();
    if ( BaseDirPointer!=None )
        BaseDirPointer.Destroy();
    if ( EnemyBaseDirPointer!=None )
        EnemyBaseDirPointer.Destroy();
}

simulated function Destroyed()
{
    DestroyDirPointers();
    super.Destroyed();
}

simulated function LinkActors()
{
    super.LinkActors();

    TSCGRI = TSCGameReplicationInfo(PlayerOwner.GameReplicationInfo);
}


simulated function UpdateHud()
{
    TeamColors[0].A = KFHUDAlpha;
    TeamColors[1].A = KFHUDAlpha;
    TextColors[0].A = KFHUDAlpha;
    TextColors[1].A = KFHUDAlpha;

    if ( KFPRI != none && KFPRI.Team != none && KFPRI.Team.TeamIndex != TeamIndex )
        UpdateTeamHud();

    super.UpdateHud();

    if ( TeamIndex == 1 ) {
        // override hardcoded values in HUDKillingFloor.UpdateHud()
        if ( HealthDigits.Tints[0].G <= 64 ) {
            HealthDigits.Tints[0] = TeamColors[TeamIndex];
            HealthDigits.Tints[1] = TeamColors[TeamIndex];
        }
        if ( SyringeDigits.Tints[0].R == 255 ) {
            SyringeDigits.Tints[0] = TeamColors[TeamIndex];
            SyringeDigits.Tints[1] = TeamColors[TeamIndex];
        }
        if ( QuickSyringeDigits.Tints[0].R == 255 ) {
            QuickSyringeDigits.Tints[0] = TeamColors[TeamIndex];
            QuickSyringeDigits.Tints[1] = TeamColors[TeamIndex];
        }
        if ( BulletsInClipDigits.Tints[0].R == 255 ) {
            BulletsInClipDigits.Tints[0] = TeamColors[TeamIndex];
            BulletsInClipDigits.Tints[1] = TeamColors[TeamIndex];
        }
        if ( ClipsDigits.Tints[0].R == 255 ) {
            ClipsDigits.Tints[0] = TeamColors[TeamIndex];
            ClipsDigits.Tints[1] = TeamColors[TeamIndex];
        }
    }
}

simulated function UpdateTeamHud()
{
    TeamIndex = KFPRI.Team.TeamIndex;

    HealthDigits.Tints[0] = TeamColors[TeamIndex];
    HealthDigits.Tints[1] = TeamColors[TeamIndex];
    ArmorDigits.Tints[0] = TeamColors[TeamIndex];
    ArmorDigits.Tints[1] = TeamColors[TeamIndex];
    WeightDigits.Tints[0] = TeamColors[TeamIndex];
    WeightDigits.Tints[1] = TeamColors[TeamIndex];
    GrenadeDigits.Tints[0] = TeamColors[TeamIndex];
    GrenadeDigits.Tints[1] = TeamColors[TeamIndex];
    ClipsDigits.Tints[0] = TeamColors[TeamIndex];
    ClipsDigits.Tints[1] = TeamColors[TeamIndex];
    SecondaryClipsDigits.Tints[0] = TeamColors[TeamIndex];
    SecondaryClipsDigits.Tints[1] = TeamColors[TeamIndex];
    BulletsInClipDigits.Tints[0] = TeamColors[TeamIndex];
    BulletsInClipDigits.Tints[1] = TeamColors[TeamIndex];
    FlashlightDigits.Tints[0] = TeamColors[TeamIndex];
    FlashlightDigits.Tints[1] = TeamColors[TeamIndex];
    WelderDigits.Tints[0] = TeamColors[TeamIndex];
    WelderDigits.Tints[1] = TeamColors[TeamIndex];
    SyringeDigits.Tints[0] = TeamColors[TeamIndex];
    SyringeDigits.Tints[1] = TeamColors[TeamIndex];
    MedicGunDigits.Tints[0] = TeamColors[TeamIndex];
    MedicGunDigits.Tints[1] = TeamColors[TeamIndex];
    QuickSyringeDigits.Tints[0] = TeamColors[TeamIndex];
    QuickSyringeDigits.Tints[1] = TeamColors[TeamIndex];
    CashDigits.Tints[0] = TeamColors[TeamIndex];
    CashDigits.Tints[1] = TeamColors[TeamIndex];

    HealthBG.WidgetTexture = Boxes[TeamIndex];
    ArmorBG.WidgetTexture = Boxes[TeamIndex];
    WeightBG.WidgetTexture = Boxes[TeamIndex];
    GrenadeBG.WidgetTexture = Boxes[TeamIndex];
    ClipsBG.WidgetTexture = Boxes[TeamIndex];
    SecondaryClipsBG.WidgetTexture = Boxes[TeamIndex];
    BulletsInClipBG.WidgetTexture = Boxes[TeamIndex];
    FlashlightBG.WidgetTexture = Boxes[TeamIndex];
    WelderBG.WidgetTexture = Boxes[TeamIndex];
    SyringeBG.WidgetTexture = Boxes[TeamIndex];
    MedicGunBG.WidgetTexture = Boxes[TeamIndex];
    QuickSyringeBG.WidgetTexture = Boxes[TeamIndex];

    DoorWelderBG = Boxes[TeamIndex];

    // Cool HUD
    CoolHudAmmoColor = TeamColors[TeamIndex];
    CoolCashDigits.Tints[0] = TeamColors[TeamIndex];
    CoolCashDigits.Tints[1] = TeamColors[TeamIndex];
    CoolCashIcon.Tints[0] = TeamColors[TeamIndex];
    CoolCashIcon.Tints[1] = TeamColors[TeamIndex];


    if ( TeamIndex == 1 ) {
        HealthIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Medical_Cross';
        ArmorIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Shield';
        WeightIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Weight';
        GrenadeIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Grenade';
        ClipsIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Ammo_Clip';
        SecondaryClipsIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_M79';
        BulletsInClipIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Bullets';
        M79Icon.WidgetTexture=Texture'TSC_T.HUD.Hud_M79';
        SingleNadeIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_M79';
        PipeBombIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Pipebomb';
        LawRocketIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Law_Rocket';
        ArrowheadIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Arrowhead';
        SingleBulletIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Single_Bullet';
        FlameIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Flame';
        FlameTankIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Flame_Tank';
        HuskAmmoIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Flame';
        SawAmmoIcon.WidgetTexture=Texture'TSC_T.HUD.Texture_Hud_Sawblade';
        ZEDAmmoIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Lightning_Bolt';
        FlashlightIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Flashlight';
        FlashlightOffIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Flashlight_Off';
        WelderIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Lightning_Bolt';
        SyringeIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Syringe';
        MedicGunIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Syringe';
        QuickSyringeIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Syringe';
        CashIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Pound_Symbol';

        // Cool HUD
        //CoolCashIcon.WidgetTexture=Texture'TSC_T.HUD.Hud_Pound_Symbol';
    }
    else {
        HealthIcon.WidgetTexture = default.HealthIcon.WidgetTexture;
        ArmorIcon.WidgetTexture = default.ArmorIcon.WidgetTexture;
        WeightIcon.WidgetTexture = default.WeightIcon.WidgetTexture;
        GrenadeIcon.WidgetTexture = default.GrenadeIcon.WidgetTexture;
        ClipsIcon.WidgetTexture = default.ClipsIcon.WidgetTexture;
        SecondaryClipsIcon.WidgetTexture = default.SecondaryClipsIcon.WidgetTexture;
        BulletsInClipIcon.WidgetTexture = default.BulletsInClipIcon.WidgetTexture;
        M79Icon.WidgetTexture = default.M79Icon.WidgetTexture;
        SingleNadeIcon.WidgetTexture = default.SingleNadeIcon.WidgetTexture;
        PipeBombIcon.WidgetTexture = default.PipeBombIcon.WidgetTexture;
        LawRocketIcon.WidgetTexture = default.LawRocketIcon.WidgetTexture;
        ArrowheadIcon.WidgetTexture = default.ArrowheadIcon.WidgetTexture;
        SingleBulletIcon.WidgetTexture = default.SingleBulletIcon.WidgetTexture;
        FlameIcon.WidgetTexture = default.FlameIcon.WidgetTexture;
        FlameTankIcon.WidgetTexture = default.FlameTankIcon.WidgetTexture;
        HuskAmmoIcon.WidgetTexture = default.HuskAmmoIcon.WidgetTexture;
        SawAmmoIcon.WidgetTexture = default.SawAmmoIcon.WidgetTexture;
        ZEDAmmoIcon.WidgetTexture = default.ZEDAmmoIcon.WidgetTexture;
        FlashlightIcon.WidgetTexture = default.FlashlightIcon.WidgetTexture;
        FlashlightOffIcon.WidgetTexture = default.FlashlightOffIcon.WidgetTexture;
        WelderIcon.WidgetTexture = default.WelderIcon.WidgetTexture;
        SyringeIcon.WidgetTexture = default.SyringeIcon.WidgetTexture;
        MedicGunIcon.WidgetTexture = default.MedicGunIcon.WidgetTexture;
        QuickSyringeIcon.WidgetTexture = default.QuickSyringeIcon.WidgetTexture;
        CashIcon.WidgetTexture = default.CashIcon.WidgetTexture;

        // Cool HUD
        //CoolCashIcon.WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Pound_Symbol';
    }

    SetHUDAlpha();
}

simulated function DrawKFHUDTextElements(Canvas C)
{
    local float    XL, YL;
    local int      NumZombies, Min;
    local string   S;
    local float    CircleSize;
    local float    ResScale;
    local ShopVolume shop;

    if ( PlayerOwner == none || PlayerOwner.Player == none || PlayerOwner.Player.bShowWindowsMouse
        || KFGRI == none || !KFGRI.bMatchHasBegun )
    {
        return;
    }

    ResScale =  C.SizeX / 1024.0;
    CircleSize = FMin(128 * ResScale,128);
    C.FontScaleX = FMin(ResScale,1.f);
    C.FontScaleY = FMin(ResScale,1.f);

    // Countdown Text
    if( !KFGRI.bWaveInProgress || TSCGRI.WaveEndRule == 2 /*RULE_Timeout*/ )
    {
        C.SetDrawColor(255, 255, 255, 255);
        C.SetPos(C.ClipX - CircleSize, 2);

        C.DrawTile(WaveGB[TeamIndex], CircleSize, CircleSize, 0, 0, 256, 256);

        Min = KFGRI.TimeToNextWave / 60;
        NumZombies = KFGRI.TimeToNextWave - (Min * 60);

        S = Eval((Min >= 10), string(Min), "0" $ Min) $ ":" $ Eval((NumZombies >= 10), string(NumZombies), "0" $ NumZombies);
        C.Font = LoadFont(2);
        C.Strlen(S, XL, YL);
        C.DrawColor = TextColors[TeamIndex];
        C.SetPos(C.ClipX - CircleSize/2 - (XL / 2), CircleSize/2 - YL / 2);
        C.DrawText(S, False);
    }
    else
    {
        C.SetDrawColor(255, 255, 255, 255);
        C.SetPos(C.ClipX - CircleSize, 2);
        C.DrawTile(WaveGB[2+TeamIndex], CircleSize, CircleSize, 0, 0, 256, 256);

        // TODO: Add support for ScrnGRI.WaveEndRule

        S = string(KFGRI.MaxMonsters);
        C.Font = LoadFont(1);
        C.Strlen(S, XL, YL);
        C.DrawColor = TextColors[TeamIndex];
        C.SetPos(C.ClipX - CircleSize/2 - (XL / 2), CircleSize/2 - (YL / 1.5));
        C.DrawText(S);
    }

    if ( KFGRI.bWaveInProgress ) {
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
    if ( bDrawShopDirPointer )
    {
        if ( ShopDirPointer == None )
        {
            ShopDirPointer = Spawn(Class'KFShopDirectionPointer');
            //ShopDirPointer.bHidden = bHideHud;
        }

        // apply team color
        if ( TSCGRI != none && TeamIndex == 1) {
            shop = TSCGRI.BlueShop;
            ShopDirPointer.UV2Texture = ConstantColor'TSC_T.HUD.BlueCol';
        }
        else {
            shop = KFGRI.CurrentShop;
            ShopDirPointer.UV2Texture = none;
        }

        if ( shop != none ) {
            C.DrawColor = TextColors[TeamIndex];
            DrawDirPointer(C, ShopDirPointer, shop.Location, 0, 0, false, strTrader);
        }
        else {
            ShopDirPointer.bHidden = true;
        }
    }

    if ( TSCGRI != none )
        DrawTSCHUDTextElements(C);
}


simulated function DrawTSCHUDTextElements(Canvas C)
{
    local TSCTeamBase TeamBase;
    local bool      bAtOwnBase, bAtEnemyBase;
    local int       FontSize;
    local float     XL, YL, BottomY;
    local string    aHint, aTitle;
    local bool      bCriticalHint;
    local string    s;

    // enemy base
    TeamBase = TSCTeamBase(KFGRI.Teams[1-TeamIndex].HomeBase);
    if ( TeamBase != none && TeamBase.bActive ) {
        bAtEnemyBase = TSCGRI.AtBase(PawnOwner.Location, TeamBase);
        if ( EnemyBaseDirPointer == None ) {
            EnemyBaseDirPointer = Spawn(Class'KFShopDirectionPointer');
        }
        // apply enemy team color
        if ( TeamIndex == 0)
            EnemyBaseDirPointer.UV2Texture = ConstantColor'TSC_T.HUD.BlueCol';
        else
            EnemyBaseDirPointer.UV2Texture = none;

        if ( bAtEnemyBase )
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        else
            C.DrawColor = TextColors[1-TeamIndex];
        DrawDirPointer(C, EnemyBaseDirPointer, TeamBase.Location, 2, 0, false, strEnemyBase);
    }

    // own base
    TeamBase = TSCTeamBase(KFPRI.Team.HomeBase);
    if ( TeamBase == none )
        return; // just in case

    if ( !TeamBase.bHidden && !(TeamBase.bHeld && TeamBase.HolderPRI == KFPRI) ) {
        if ( BaseDirPointer == None ) {
            BaseDirPointer = Spawn(Class'KFShopDirectionPointer');
            BaseDirPointer.UV2Texture = ConstantColor'TSC_T.HUD.GreenCol';
        }

        bAtOwnBase = TSCGRI.AtBase(PawnOwner.Location, TeamBase);
        if ( TeamBase.bActive ) {
            s = strOurBase;
            if ( bAtOwnBase)
                C.SetDrawColor(32, 255, 32, KFHUDAlpha);
            else
                C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        else if ( TeamBase.bHeld ) {
            s = strCarrier;
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        else {
            s = strGnome;
            C.SetDrawColor(200, 0, 0, KFHUDAlpha); // dropped somewhere
        }
        DrawDirPointer(C, BaseDirPointer, TeamBase.GetLocation(), 1, 0, false, s);
    }

    // hints
    if ( bHideTSCHints || KFGRI.EndGameType > 0 )
        return;

    if ( TSCGRI.ElapsedTime <= 10 ) {
        aTitle = titleWelcome;
        aHint = hintWelcome;
        bCriticalHint = true;
    }
    else if ( TSCGRI.bWaveInProgress ) {
        if ( TSCGRI.WaveNumber == 0 )
            aHint = hintFirstWave;
        else if ( bAtEnemyBase ) {
            aHint = hintEnemyBase;
            bCriticalHint = true;
        }
        else if ( TSCGRI.bSuddenDeath ) {
            aHint = hintSuddenDeath;
            aTitle = titleSuddenDeath;
        }
        else if ( TSCGRI.MaxMonsters >= 10 ) {
            if ( !TeamBase.bActive && !TeamBase.bHidden ) {
                aTitle = titleStunned;
                aHint = hintStunned;
                bCriticalHint = true;
            }
            else if ( !bAtOwnBase && TeamBase.bActive )
                aHint = hintGotoBase;
            else if ( TSCGRI.HumanDamageMode == 2 || TSCGRI.HumanDamageMode >= 4 ) {
                aTitle = titlePvP;
                aHint = hintPvP;
            }
        }
    }
    else {
        if ( TSCGRI.bSuddenDeath ) {
            aHint = hintSuddenDeathTrader;
            aTitle = titleSuddenDeath;
            bCriticalHint = true;
        }
        else if ( bAtEnemyBase ) {
            if ( TeamBase.bHeld && TeamBase.HolderPRI == KFPRI )
                aHint = hintSetupEnemyBase;
            else
                aHint = hintEnemyBase;
            bCriticalHint = true;
        }
        else if ( TeamBase.bActive ) {
            if ( TSCGRI.TimeToNextWave < 30 && !bAtOwnBase )
                aHint = hintGotoBase;
            else if ( TSCGRI.TimeToNextWave < 10 )
                aHint = hintPrepareToFight;
            else
                aHint = hintShopping;
        }
        else if ( TeamBase.bHeld ) {
            if ( TeamBase.HolderPRI == KFPRI ) {
                aTitle = titleSetupBase;
                aHint = hintSetupBase;
                s = PlayerOwner.ConsoleCommand("BINDINGTOKEY SetupBase");
                if ( s == "" )
                    s = PlayerOwner.ConsoleCommand("BINDINGTOKEY AltFire");
                ReplaceText(aHint, "%KEY%", s);
            }
            else if ( TSCGRI.TimeToNextWave < 30 )
                aHint = hintFollowCarrier; // enough shopping, time to get to the base
            else
                aHint = hintShopping; // others can do shopping while somebody sets up the base
        }
        else if ( TeamBase.bHome ) {
            aTitle = titleBaseLost;
            if ( TSCGRI.TimeToNextWave < 30 )
                aHint = hintBaseLostTrader;
            else
                aHint = hintShopping;
        }
        else if ( TSCGRI.TeamCarrier[TeamIndex] == none || TSCGRI.TeamCarrier[TeamIndex] == KFPRI ) {
                aTitle = titleSetupBase;
                aHint = hintGetGnome;
        }
        else
            aHint = hintShopping;
    }

    if ( C.ClipX <= 1024 )
        FontSize = 7;
    else if ( C.ClipX < 1400 )
        FontSize = 6;
    else
        FontSize = 5;

    BottomY = C.ClipY;
    if ( aHint != "" ) {
        C.Font = LoadFont(FontSize);
        C.StrLen(aHint, XL, YL);
        if ( bCoolHud && !bCoolHudLeftAlign ) {
            C.SetPos((c.ClipX-XL)/2, 0); // top center
            BottomY = YL;
        }
        else {
            BottomY -= YL;
            C.SetPos((c.ClipX-XL)/2, BottomY); // bottom center
        }
        if ( bCriticalHint ) {
            CriticalHintBG -= fmax(1.0, (Level.TimeSeconds - LastCriticalHintTime) * 200.0);
            LastCriticalHintTime = Level.TimeSeconds;
            if ( CriticalHintBG < 32 )
                CriticalHintBG = 232;
            C.SetDrawColor(CriticalHintBG, CriticalHintBG, 0, 128);
        }
        else
            C.SetDrawColor(32, 32, 32, 80);
        C.DrawTileStretched(WhiteMaterial, XL, YL);
        C.DrawColor = TextColors[TeamIndex];
        C.DrawText(aHint);
    }
    if ( aTitle != "" ) {
        C.Font = LoadFont(FontSize-1);
        C.StrLen(aTitle, XL, YL);
        if ( bCoolHud && !bCoolHudLeftAlign )
            CowboyTileY = fmax(CowboyTileY, (BottomY + YL) / C.ClipY); // shift down cowboy mode to properly display hints
        else
            BottomY -= YL;
        C.SetPos((c.ClipX-XL)/2, BottomY);
        C.SetDrawColor(32, 32, 32, 80);
        C.DrawTileStretched(WhiteMaterial, XL, YL);
        C.DrawColor = TextColors[TeamIndex];
        C.DrawText(aTitle);
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
    else if ( PlayerOwner.Pawn != PawnOwner && ScrnHumanPawn(PawnOwner) != none
            && ScrnHumanPawn(PawnOwner).SpecWeapon != none )
        CurWeaponName = ScrnHumanPawn(PawnOwner).SpecWeapon.default.ItemName;

    if ( CurWeaponName == "" )
        return;


    C.Font  = GetFontSizeIndex(C, -1);
    C.DrawColor = TextColors[TeamIndex];
    C.Strlen(CurWeaponName, XL, YL);

    // Diet Hud needs to move the weapon name a little bit or it looks weird
    if ( !bLightHud )
        C.SetPos((C.ClipX * 0.983) - XL, C.ClipY * 0.90);
    else
        C.SetPos((C.ClipX * 0.97) - XL, C.ClipY * 0.915);

    C.DrawText(CurWeaponName);
}



simulated function DrawEndGameHUD(Canvas C, bool bVictory)
{
    local float Scalar;
    local TeamInfo Team;

    DestroyDirPointers();

    C.DrawColor.A = 255;
    C.DrawColor.R = 255;
    C.DrawColor.G = 255;
    C.DrawColor.B = 255;
    Scalar = FClamp(C.ClipY, 320, 1024);
    C.CurX = C.ClipX / 2 - Scalar / 2;
    C.CurY = C.ClipY / 2 - Scalar / 2;
    C.Style = ERenderStyle.STY_Alpha;

    if ( bVictory )
    {
        Team = TeamInfo(KFGRI.Winner);
        if ( Team != none && Team.TeamIndex < 2 )
            MyColorMod.Material = EndGameMaterials[Team.TeamIndex];
        else if ( !TSCGRI.bSingleTeamGame )
            MyColorMod.Material = EndGameMaterials[2]; // both teams win
        else
            MyColorMod.Material = EndGameMaterials[1]; // in non-team game players are in blue team
    }
    else if ( TSCGRI.bSingleTeamGame )
        MyColorMod.Material = Combiner'DefeatCombiner';
    else
        MyColorMod.Material =  EndGameMaterials[3];

    if ( EndGameHUDTime >= 1 )
        MyColorMod.Color.A = 255;
    else
        MyColorMod.Color.A = EndGameHUDTime * 255.f;

    C.DrawTile(MyColorMod, Scalar, Scalar, 0, 0, 1024, 1024);

    if ( bShowScoreBoard && ScoreBoard != None )
    {
        ScoreBoard.DrawScoreboard(C);
    }

    //display end-game achievements
    C.Reset();
    DisplayLocalMessages(C);
}

simulated function CalsTeamStats()
{
    local int i;
    local KFPlayerReplicationInfo OtherPRI;

    TeamDosh[0] = 0;
    TeamDosh[1] = 0;
    TeamHealth[0] = 0;
    TeamHealth[1] = 0;

    for ( i = 0; i < KFGRI.PRIArray.Length; i++) {
        OtherPRI = KFPlayerReplicationInfo(KFGRI.PRIArray[i]);
        if ( OtherPRI != none && OtherPRI.Team != none && OtherPRI.Team.TeamIndex < 2 ) {
            TeamDosh[OtherPRI.Team.TeamIndex] += OtherPRI.Score;
            TeamHealth[OtherPRI.Team.TeamIndex] += OtherPRI.PlayerHealth;
        }
    }

    SpecKillsDigits[0].Value = TSCTeam(KFGRI.Teams[0]).ZedKills;
    SpecKillsDigits[1].Value = TSCTeam(KFGRI.Teams[1]).ZedKills;
    SpecDeathsDigits[0].Value = TSCTeam(KFGRI.Teams[0]).Deaths;
    SpecDeathsDigits[1].Value = TSCTeam(KFGRI.Teams[1]).Deaths;
    SpecDoshDigits[0].Value = TeamDosh[0] + KFGRI.Teams[0].Score;
    SpecDoshDigits[1].Value = TeamDosh[1] + KFGRI.Teams[1].Score;
    RedTeamHealthRatio = float(TeamHealth[0]) / (TeamHealth[0]+TeamHealth[1]);

    // v2.00
    SpecWaveKillsDigits[0].Value = max(TSCTeam(KFGRI.Teams[0]).ZedKills - TSCTeam(KFGRI.Teams[0]).WaveKills, 0);
    SpecWaveKillsDigits[1].Value = max(TSCTeam(KFGRI.Teams[1]).ZedKills - TSCTeam(KFGRI.Teams[1]).WaveKills, 0);
    SpecMinKillsDigits[0].Value = max(TSCTeam(KFGRI.Teams[0]).ZedKills - TSCTeam(KFGRI.Teams[0]).PrevMinKills, 0);
    SpecMinKillsDigits[1].Value = max(TSCTeam(KFGRI.Teams[1]).ZedKills - TSCTeam(KFGRI.Teams[1]).PrevMinKills, 0);

    if ( SpecMinKillsDigits[0].Value < 15 ) {
        SpecWaveKillsDigits[0].Tints[0].R = 196;
        SpecWaveKillsDigits[0].Tints[0].G = 206;
        SpecWaveKillsDigits[0].Tints[0].B = 0;
    }
    else
        SpecWaveKillsDigits[0].Tints[0] = default.SpecWaveKillsDigits[0].Tints[0];

    if ( SpecMinKillsDigits[1].Value < 15 ) {
        SpecWaveKillsDigits[1].Tints[0].R = 196;
        SpecWaveKillsDigits[1].Tints[0].G = 206;
        SpecWaveKillsDigits[1].Tints[0].B = 0;
    }
    else
        SpecWaveKillsDigits[1].Tints[0] = default.SpecWaveKillsDigits[1].Tints[0];

    SpecWaveKillsDigits[0].Tints[1] = SpecWaveKillsDigits[0].Tints[0];
    SpecWaveKillsDigits[1].Tints[1] = SpecWaveKillsDigits[1].Tints[0];

    SpecKillsBG[0].Tints[0].A = KFHUDAlpha;
    SpecKillsBG[0].Tints[1].A = KFHUDAlpha;
    SpecKillsIcon[0].Tints[0].A = KFHUDAlpha;
    SpecKillsIcon[0].Tints[1].A = KFHUDAlpha;
    SpecKillsDigits[0].Tints[0].A = KFHUDAlpha;
    SpecKillsDigits[0].Tints[1].A = KFHUDAlpha;
    SpecWaveKillsBG[0].Tints[0].A = KFHUDAlpha;
    SpecWaveKillsBG[0].Tints[1].A = KFHUDAlpha;
    SpecWaveKillsDigits[0].Tints[0].A = KFHUDAlpha;
    SpecWaveKillsDigits[0].Tints[1].A = KFHUDAlpha;
    SpecMinKillsBG[0].Tints[0].A = KFHUDAlpha;
    SpecMinKillsBG[0].Tints[1].A = KFHUDAlpha;
    SpecMinKillsDigits[0].Tints[0].A = KFHUDAlpha;
    SpecMinKillsDigits[0].Tints[1].A = KFHUDAlpha;

    SpecKillsBG[1].Tints[0].A = KFHUDAlpha;
    SpecKillsBG[1].Tints[1].A = KFHUDAlpha;
    SpecKillsIcon[1].Tints[0].A = KFHUDAlpha;
    SpecKillsIcon[1].Tints[1].A = KFHUDAlpha;
    SpecKillsDigits[1].Tints[0].A = KFHUDAlpha;
    SpecKillsDigits[1].Tints[1].A = KFHUDAlpha;
    SpecWaveKillsBG[1].Tints[0].A = KFHUDAlpha;
    SpecWaveKillsBG[1].Tints[1].A = KFHUDAlpha;
    SpecWaveKillsDigits[1].Tints[0].A = KFHUDAlpha;
    SpecWaveKillsDigits[1].Tints[1].A = KFHUDAlpha;
    SpecMinKillsBG[1].Tints[0].A = KFHUDAlpha;
    SpecMinKillsBG[1].Tints[1].A = KFHUDAlpha;
    SpecMinKillsDigits[1].Tints[0].A = KFHUDAlpha;
    SpecMinKillsDigits[1].Tints[1].A = KFHUDAlpha;

    SpecDeathsBG[0].Tints[0].A = KFHUDAlpha;
    SpecDeathsBG[0].Tints[1].A = KFHUDAlpha;
    SpecDeathsIcon[0].Tints[0].A = KFHUDAlpha;
    SpecDeathsIcon[0].Tints[1].A = KFHUDAlpha;
    SpecDeathsDigits[0].Tints[0].A = KFHUDAlpha;
    SpecDeathsDigits[0].Tints[1].A = KFHUDAlpha;
    SpecDeathsBG[1].Tints[0].A = KFHUDAlpha;
    SpecDeathsBG[1].Tints[1].A = KFHUDAlpha;
    SpecDeathsIcon[1].Tints[0].A = KFHUDAlpha;
    SpecDeathsIcon[1].Tints[1].A = KFHUDAlpha;
    SpecDeathsDigits[1].Tints[0].A = KFHUDAlpha;
    SpecDeathsDigits[1].Tints[1].A = KFHUDAlpha;

    SpecDoshBG[0].Tints[0].A = KFHUDAlpha;
    SpecDoshBG[0].Tints[1].A = KFHUDAlpha;
    SpecDoshIcon[0].Tints[0].A = KFHUDAlpha;
    SpecDoshIcon[0].Tints[1].A = KFHUDAlpha;
    SpecDoshDigits[0].Tints[0].A = KFHUDAlpha;
    SpecDoshDigits[0].Tints[1].A = KFHUDAlpha;
    SpecDoshBG[1].Tints[0].A = KFHUDAlpha;
    SpecDoshBG[1].Tints[1].A = KFHUDAlpha;
    SpecDoshIcon[1].Tints[0].A = KFHUDAlpha;
    SpecDoshIcon[1].Tints[1].A = KFHUDAlpha;
    SpecDoshDigits[1].Tints[0].A = KFHUDAlpha;
    SpecDoshDigits[1].Tints[1].A = KFHUDAlpha;
}


simulated function DrawSpecialSpectatingHUD(Canvas C)
{
    local float x, w;
    local string s;
    local TSCTeamBase TeamBase;

    if ( KFGRI == none || !KFGRI.bMatchHasBegun)
        return;

    bDrawSpecDeaths = false;
    super.DrawSpecialSpectatingHUD(C);

    // player stats
    if ( Level.TimeSeconds > NextStatUpdateTime ) {
        NextStatUpdateTime = Level.TimeSeconds + 0.5;
        CalsTeamStats();
    }

    if ( !bLightHud ) {
        DrawSpriteWidget(C, SpecKillsBG[0]);
        DrawSpriteWidget(C, SpecWaveKillsBG[0]);
        //DrawSpriteWidget(C, SpecMinKillsBG[0]);
        DrawSpriteWidget(C, SpecDeathsBG[0]);
        DrawSpriteWidget(C, SpecDoshBG[0]);

        DrawSpriteWidget(C, SpecKillsBG[1]);
        DrawSpriteWidget(C, SpecWaveKillsBG[1]);
        //DrawSpriteWidget(C, SpecMinKillsBG[1]);
        DrawSpriteWidget(C, SpecDeathsBG[1]);
        DrawSpriteWidget(C, SpecDoshBG[1]);
    }
    DrawSpriteWidget(C, SpecDoshIcon[0]);
    DrawNumericWidget(C, SpecDoshDigits[0], DigitsSmall);
    DrawSpriteWidget(C, SpecDeathsIcon[0]);
    DrawNumericWidget(C, SpecDeathsDigits[0], DigitsSmall);
    DrawSpriteWidget(C, SpecKillsIcon[0]);
    DrawNumericWidget(C, SpecKillsDigits[0], DigitsSmall);
    DrawNumericWidget(C, SpecWaveKillsDigits[0], DigitsSmall);
    //DrawNumericWidget(C, SpecMinKillsDigits[0], DigitsSmall);

    DrawSpriteWidget(C, SpecDoshIcon[1]);
    DrawNumericWidget(C, SpecDoshDigits[1], DigitsSmall);
    DrawSpriteWidget(C, SpecDeathsIcon[1]);
    DrawNumericWidget(C, SpecDeathsDigits[1], DigitsSmall);
    DrawSpriteWidget(C, SpecKillsIcon[1]);
    DrawNumericWidget(C, SpecKillsDigits[1], DigitsSmall);
    DrawNumericWidget(C, SpecWaveKillsDigits[1], DigitsSmall);
    //DrawNumericWidget(C, SpecMinKillsDigits[1], DigitsSmall);

    C.DrawColor = WhiteColor;
    C.DrawColor.A = KFHUDAlpha;

    // manpower
    if ( TeamHealth[0]+TeamHealth[1] > 0 ) {
        w = SpecBarWidth * fclamp(RedTeamHealthRatio, 0.025, 0.975);
        x = (1.0 - SpecBarWidth) * 0.5;
        C.SetPos(C.ClipX * x, C.ClipY * SpecBarY);
        C.DrawTileStretched(texture'TSC_T.SpecHUD.BarFill_Red', C.ClipX * w, C.ClipY*SpecBarHeight);
        C.SetPos(C.ClipX * (x + w), C.ClipY * SpecBarY);
        w = SpecBarWidth - w;
        C.DrawTileStretched(texture'TSC_T.SpecHUD.BarFill_Blue', C.ClipX*w + 1, C.ClipY*SpecBarHeight);
        C.SetPos(C.ClipX * x, C.ClipY * SpecBarY);
        C.DrawTileStretched(SpecBarBG, C.ClipX*SpecBarWidth, C.ClipY*SpecBarHeight);
    }

    // ARROWS
    if ( TSCGRI == none || KFGRI.ElapsedTime < 15 )
        return;

    // Red Base
    TeamBase = TSCTeamBase(TSCGRI.Teams[0].HomeBase);
    if ( TeamBase != none && !TeamBase.bHidden ) {
        if ( BaseDirPointer == None )
            BaseDirPointer = Spawn(Class'KFShopDirectionPointer');

        BaseDirPointer.UV2Texture = none;
        if ( TeamBase.bActive ) {
            s = strBase;
            C.DrawColor = TextColors[0];
            C.DrawColor.A = KFHUDAlpha;
        }
        else if ( TeamBase.bHeld ) {
            s = strCarrier;
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        else {
            s = strGnome;
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        DrawDirPointer(C, BaseDirPointer, TeamBase.GetLocation(), 0, 0, false, s, false);
    }
    else {
        if ( BaseDirPointer != none )
            BaseDirPointer.bHidden = true;
    }

    // Blue Base
    TeamBase = TSCTeamBase(TSCGRI.Teams[1].HomeBase);
    if ( TeamBase != none && !TeamBase.bHidden ) {
        if ( EnemyBaseDirPointer == None )
            EnemyBaseDirPointer = Spawn(Class'KFShopDirectionPointer');

        EnemyBaseDirPointer.UV2Texture = ConstantColor'TSC_T.HUD.BlueCol';
        if ( TeamBase.bActive ) {
            s = strBase;
            C.DrawColor = TextColors[1];
            C.DrawColor.A = KFHUDAlpha;
        }
        else if ( TeamBase.bHeld ) {
            s = strCarrier;
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        else {
            s = strGnome;
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        DrawDirPointer(C, EnemyBaseDirPointer, TeamBase.GetLocation(), 0, 0, false, s, true);
    }
    else {
        if ( EnemyBaseDirPointer != none )
            EnemyBaseDirPointer.bHidden = true;
    }


    // trader arrows should be show only during trader time to prevent exploits, when stream viewers
    // tell players location of the next enemy trader
    if ( TSCGRI.bWaveInProgress ) {
        if ( ShopDirPointer != none )
            ShopDirPointer.bHidden = true;
        if ( EnemyShopDirPointer != none )
            EnemyShopDirPointer.bHidden = true;
    }
    else {
        // red shop
        if ( ShopDirPointer == None )
             ShopDirPointer = Spawn(Class'KFShopDirectionPointer');
        ShopDirPointer.UV2Texture = none;
        C.DrawColor = TextColors[0];
        DrawDirPointer(C, ShopDirPointer, TSCGRI.CurrentShop.Location, 0, 1, false, strTrader, false);

        // blue shop
        if ( EnemyShopDirPointer == None )
             EnemyShopDirPointer = Spawn(Class'KFShopDirectionPointer');
        EnemyShopDirPointer.UV2Texture = ConstantColor'TSC_T.HUD.BlueCol';
        C.DrawColor = TextColors[1];
        DrawDirPointer(C, EnemyShopDirPointer, TSCGRI.BlueShop.Location, 0, 1, false, strTrader, true);
    }
}

exec function SpecHPBarY(float value)
{
    SpecBarY = value;
    SaveConfig();
}

exec function SpecHPBarW(float value)
{
    if ( value < 0 || value > 1) {
        PlayerOwner.ClientMessage("Value must be between 0 and 1, where 1 - full screen, 0.5 - half screen etc.");
        return;
    }
    SpecBarWidth = value;
    SaveConfig();
}

exec function SpecHPBarH(float value)
{
    if ( value < 0 || value > 1) {
        PlayerOwner.ClientMessage("Value must be between 0 and 1, where 1 - full screen, 0.5 - half screen etc.");
        return;
    }
    SpecBarHeight = value;
    SaveConfig();
}




defaultproperties
{
    Boxes(0)=Texture'KillingFloorHUD.HUD.Hud_Box_128x64'
    Boxes(1)=Texture'TSC_T.HUD.Hud_Box_128x64'
    EndGameMaterials(0)=Texture'TSC_T.End.RedWin'
    EndGameMaterials(1)=Texture'TSC_T.End.BlueWin'
    EndGameMaterials(2)=Texture'TSC_T.End.Win'
    EndGameMaterials(3)=Shader'TSC_T.End.WipedShader'
    WaveGB[0]=Material'KillingFloorHUD.HUD.Hud_Bio_Clock_Circle'
    WaveGB[1]=Material'TSC_T.HUD.Hud_Bio_Clock_Circle'
    WaveGB[2]=Material'KillingFloorHUD.HUD.Hud_Bio_Circle'
    WaveGB[3]=Material'TSC_T.HUD.Hud_Bio_Circle'

    strBase="Base: "
    strOurBase="Our Base: "
    strGnome="Guardian: "
    strCarrier="Carrier: "
    strEnemyBase="Enemy Base: "

    titleWelcome="TEAM SURVIVAL COMPETITION"
    titleSuddenDeath="SUDDEN DEATH"
    titleSetupBase="SET UP BASE"
    titleBaseLost="BASE LOST"
    titlePvP="PLAYER-VS-PLAYER"
    titleStunned="GUARDIAN STUNNED"

    hintWelcome=" Welcome to TSC! Watch this place for useful hints. "
    hintFirstWave="You cannot hurt other players during first wave. So focus on zeds!"
    hintPrepareToFight="Get ready for ZED invasion!"
    hintSuddenDeath="A single death wipes your squad"
    hintSuddenDeathTrader="Nobody of your team can die, or you will get wiped"
    hintGotoBase="Get to your Base for protection from Friendly Fire"
    hintEnemyBase="Get out from Enemy Base before the Gnome kills you!"
    hintShopping="You can buy weapons and stuff from the Trader"
    hintFollowCarrier="Follow your Gnome Carrier to the new Base"
    hintGetGnome="Take the Gnome from your trader to set up a Base"
    hintSetupBase="Get to the place where you want to set up a base and press %KEY%"
    hintSetupEnemyBase="Can not use Gnome on the Enemy Base!"
    hintBaseLostTrader="You left your Gnome alone for too long, and he went away. Now you'll have to survive a wave without a Base"
    hintPvP="Enemy team can hurt you even at your Base!"
    hintStunned="Base Guardian is stunned and cannot protect you from Human Damage"

    // RED
    SpecDoshBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.350000,PosX=-0.04,PosY=0.835000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecDoshIcon(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Pound_Symbol',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.160000,PosX=0.001000,PosY=0.847000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecDoshDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.022500,PosY=0.850000,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    SpecKillsBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.35,PosX=-0.04,PosY=0.935000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecKillsIcon(0)=(WidgetTexture=Texture'TSC_T.SpecHUD.ClotEmoRed',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.16,PosX=0.001000,PosY=0.947000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecKillsDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.022500,PosY=0.950000,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))
    SpecWaveKillsBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_128x64',RenderStyle=STY_Alpha,TextureCoords=(X1=32,Y1=0,X2=128,Y2=64),TextureScale=0.35,PosX=0.10,PosY=0.935000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecWaveKillsDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.105,PosY=0.950000,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))
    SpecMinKillsBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_128x64',RenderStyle=STY_Alpha,TextureCoords=(X1=32,Y1=0,X2=128,Y2=64),TextureScale=0.35,PosX=0.1525,PosY=0.935000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecMinKillsDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.158,PosY=0.95,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    SpecDeathsBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.350000,PosX=-0.04,PosY=0.885000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecDeathsIcon(0)=(WidgetTexture=Texture'TSC_T.SpecHUD.Skull64',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.16,PosX=0.001000,PosY=0.897000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=64,G=64,R=200,A=255),Tints[1]=(B=64,G=64,R=200,A=255))
    SpecDeathsDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.022500,PosY=0.900000,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    // BLUE
    SpecDoshBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.350000,PosX=0.895000,PosY=0.835000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecDoshIcon(1)=(WidgetTexture=Texture'TSC_T.SpecHUD.Hud_Pound_Symbol',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.160000,PosX=0.901000,PosY=0.847000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecDoshDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.922500,PosY=0.850000,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))

    SpecDeathsBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.350000,PosX=0.895000,PosY=0.885000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecDeathsIcon(1)=(WidgetTexture=Texture'TSC_T.SpecHUD.Skull64',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.16,PosX=0.901000,PosY=0.897000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))
    SpecDeathsDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.922500,PosY=0.900000,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))

    SpecKillsBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.35,PosX=0.895000,PosY=0.935000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecKillsIcon(1)=(WidgetTexture=Texture'TSC_T.SpecHUD.ClotEmoBlue',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.16,PosX=0.901000,PosY=0.947000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecKillsDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.922500,PosY=0.950000,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))
    SpecWaveKillsBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_128x64',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=96,Y2=64),TextureScale=0.35,PosX=0.842000,PosY=0.935000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecWaveKillsDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.849,PosY=0.950000,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))
    SpecMinKillsBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_128x64',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=96,Y2=64),TextureScale=0.35,PosX=0.789,PosY=0.935000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecMinKillsDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.796,PosY=0.950000,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))

    SpecBarBG=texture'TSC_T.SpecHUD.Battery_BG'
    SpecBarY=0.08
    SpecBarWidth=0.4
    SpecBarHeight=0.04

    bDrawSpecDeaths=False
    bDrawShopDirPointer=True

    bCoolHud=False
    bCoolHudTeamColor=True
}
