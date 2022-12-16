class TSCHUD extends ScrnHUD;

#exec OBJ LOAD FILE=TSC_T.utx

var Texture Boxes[2];

// 0 - red win
// 1 - blue win
// 2 - both survived
// 3 - wiped
var Material EndGameMaterials[4];
var Material WaveGB[4];

var TSCGameReplicationInfo   TSCGRI;
var TSCTeam TSCTeams[2];
var TSCTeam MyTeam, EnemyTeam;

var     KFShopDirectionPointer  BaseDirPointer, EnemyBaseDirPointer, EnemyShopDirPointer;
var Color OutOfTheBaseColor;
var ConstantColor OutOfTheBaseMaterial;
var ConstantColor OwnBaseMaterial;

var localized string strBase;
var localized string strOurBase;
var localized string strGnome;
var localized string strCarrier;
var localized string strEnemyBase;
var localized string strStunned;


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
var()   SpriteWidget            SpecWaveKillsIcon[2];
var()   NumericWidget           SpecWaveKillsDigits[2];
// not used
var()   SpriteWidget            SpecMinKillsBG[2];
var()   NumericWidget           SpecMinKillsDigits[2];

var()   SpriteWidget            SpecDeathsBG[2];
var()   SpriteWidget            SpecDeathsIcon[2];
var()   NumericWidget           SpecDeathsDigits[2];

var()   SpriteWidget            SpecInvDoshBG[2];
var()   SpriteWidget            SpecInvDoshIcon[2];
var()   NumericWidget           SpecInvDoshDigits[2];

var()   SpriteWidget            SpecDoshBG[2];
var()   SpriteWidget            SpecDoshIcon[2];
var()   NumericWidget           SpecDoshDigits[2];

var     config bool             bDrawSpecBar;
var     material                SpecBarBG, SpecBarRed, SpecBarBlue;
var     config float            SpecBarY, SpecBarWidth, SpecBarHeight;

var     config bool             bSpecDrawClan;
var     config float            SpecClanNameX, SpecClanNameY;
var     config float            SpecClanBannerX, SpecClanBannerY, SpecClanBannerHeight;

var protected transient int TeamDosh[2], TeamHealth[2], TeamWaveKills[2];
var protected transient float RedTeamHealthRatio, RedTeamDoshRatio, RedTeamWaveKillRatio;
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
    if (TSCGRI == none)
        return;

    TSCTeams[0] = TSCTeam(TSCGRI.Teams[0]);
    TSCTeams[1] = TSCTeam(TSCGRI.Teams[1]);
    if (TeamIndex >= 0 && TeamIndex <= 1) {
        MyTeam = TSCTeams[TeamIndex];
        EnemyTeam = TSCTeams[1-TeamIndex];
    }
    else {
        MyTeam = none;
        EnemyTeam = none;
    }
}


simulated function UpdateHud()
{
    if ( KFPRI != none && KFPRI.Team != none && KFPRI.Team.TeamIndex != TeamIndex ) {
        UpdateTeamHud();
    }

    super.UpdateHud();
}

simulated function UpdateTeamHud()
{
    TeamIndex = KFPRI.Team.TeamIndex;
    LinkActors();

    HealthDigits.Tints[0] = TeamColors[TeamIndex];
    HealthDigits.Tints[1] = TeamColors[TeamIndex];
    ArmorDigits.Tints[0] = TeamColors[TeamIndex];
    ArmorDigits.Tints[1] = TeamColors[TeamIndex];
    WeightDigits.Tints[0] = TeamColors[TeamIndex];
    WeightDigits.Tints[1] = TeamColors[TeamIndex];
    LeftGunAmmoDigits.Tints[0] = TeamColors[TeamIndex];
    LeftGunAmmoDigits.Tints[1] = TeamColors[TeamIndex];
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
    LeftGunAmmoBG.WidgetTexture = Boxes[TeamIndex];
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
    LeftGunAmmoIcon.WidgetTexture = BulletsInClipIcon.WidgetTexture;

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

        if ( MyTeam != none && MyTeam.GetCurWaveKills() < TSCGRI.WaveKillReq ) {
            NumZombies = TSCGRI.WaveKillReq - MyTeam.GetCurWaveKills();
            S = NumZombies $ "/" $ KFGRI.MaxMonsters;
            C.Font = LoadFont(2);
            C.DrawColor = LowAmmoColor;
            PulseColorIf(C.DrawColor, KFGRI.MaxMonsters < NumZombies*2);
        }
        else {
            S = string(KFGRI.MaxMonsters);
            C.Font = LoadFont(1);
            C.DrawColor = TextColors[TeamIndex];
        }
        C.Strlen(S, XL, YL);
        C.SetPos(C.ClipX - CircleSize/2 - (XL / 2), CircleSize/2 - (YL / 1.5));
        C.DrawText(S);
    }

    C.DrawColor = TextColors[TeamIndex];
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
    local EScrnEffect Effect;

    // enemy base
    TeamBase = TSCTeamBase(KFGRI.Teams[1-TeamIndex].HomeBase);
    if ( TeamBase != none && (TeamBase.bActive || TeamBase.bStunned) ) {
        bAtEnemyBase = TSCGRI.AtBase(PawnOwner.Location, TeamBase);
        if ( EnemyBaseDirPointer == None ) {
            EnemyBaseDirPointer = Spawn(Class'KFShopDirectionPointer');
        }
        // apply enemy team color
        if ( TeamIndex == 0)
            EnemyBaseDirPointer.UV2Texture = ConstantColor'TSC_T.HUD.BlueCol';
        else
            EnemyBaseDirPointer.UV2Texture = none;

        if (TeamBase.bStunned) {
            s = strStunned;
            C.DrawColor = LowAmmoColor;
            Effect = EFF_NONE;
        }
        else if ( bAtEnemyBase ) {
            s = strEnemyBase;
            C.SetDrawColor(200, 128, 0, KFHUDAlpha);
            Effect = EFF_PULSE;
        }
        else {
            s = strEnemyBase;
            C.DrawColor = TextColors[1-TeamIndex];
            Effect = EFF_NONE;
        }
        DrawDirPointer(C, EnemyBaseDirPointer, TeamBase.Location, 2, 0, false, s, false, Effect);
    }

    // own base
    TeamBase = TSCTeamBase(KFPRI.Team.HomeBase);
    if ( TeamBase == none )
        return; // just in case

    if ( !TeamBase.bHidden && !(TeamBase.bHeld && TeamBase.HolderPRI == KFPRI) ) {
        Effect = EFF_NONE;
        if ( BaseDirPointer == None ) {
            BaseDirPointer = Spawn(Class'KFShopDirectionPointer');
            OutOfTheBaseMaterial = new class'ConstantColor';
            OutOfTheBaseMaterial.Color = OutOfTheBaseColor;
        }

        bAtOwnBase = TSCGRI.AtBase(PawnOwner.Location, TeamBase);
        if ( TeamBase.bStunned ) {
            s = strStunned;
            C.SetDrawColor(200, 0, 0, KFHUDAlpha);
            Effect = EFF_BLINK;
        }
        else if ( TeamBase.bActive ) {
            s = strOurBase;
            if ( bAtOwnBase) {
                C.SetDrawColor(32, 255, 32, KFHUDAlpha);
            }
            else {
                C.SetDrawColor(200, 128, 0, KFHUDAlpha);
                if( TSCGRI.bWaveInProgress && TSCGRI.MaxMonsters >= 10 ) {
                    Effect = EFF_PULSE;
                }
            }
        }
        else if ( TeamBase.bHeld ) {
            s = strCarrier;
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        else {
            s = strGnome;
            C.SetDrawColor(200, 0, 0, KFHUDAlpha); // dropped somewhere
        }

        if (Effect == EFF_Pulse) {
            BaseDirPointer.UV2Texture = OutOfTheBaseMaterial;
        }
        else {
            BaseDirPointer.UV2Texture = OwnBaseMaterial;
        }
        DrawDirPointer(C, BaseDirPointer, TeamBase.GetLocation(), 1, 0, false, s, false, Effect);
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
            if ( TeamBase.bStunned ) {
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
        else if ( TeamBase.bActive || TeamBase.bStunned ) {
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
                    s = PlayerOwner.ConsoleCommand("BINDINGTOKEY Duck");
                if ( s == "" )
                    s = PlayerOwner.ConsoleCommand("BINDINGTOKEY ToggleDuck");
                if ( s == "" )
                    s = PlayerOwner.ConsoleCommand("BINDINGTOKEY Crouch");
                if ( s == "" )
                    s = "SetupBase";
                aHint = Repl(aHint, "%KEY%", s, true);
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

simulated function float CalcTeamRatio(float RedTeamStat, float BlueTeamStat)
{
    if (RedTeamStat + BlueTeamStat < 0.0001)
        return 0.5;  // avoid div by 0
    return RedTeamStat / (RedTeamStat + BlueTeamStat);
}

simulated function CalsTeamStats()
{
    local int i;
    local KFPlayerReplicationInfo OtherPRI;

    TeamDosh[0] = 0;
    TeamDosh[1] = 0;
    TeamHealth[0] = 0;
    TeamHealth[1] = 0;
    TeamWaveKills[0] = TSCTeams[0].GetCurWaveKills();
    TeamWaveKills[1] = TSCTeams[1].GetCurWaveKills();

    for ( i = 0; i < KFGRI.PRIArray.Length; i++) {
        OtherPRI = KFPlayerReplicationInfo(KFGRI.PRIArray[i]);
        if ( OtherPRI != none && OtherPRI.Team != none && OtherPRI.Team.TeamIndex < 2 ) {
            TeamDosh[OtherPRI.Team.TeamIndex] += OtherPRI.Score;
            TeamHealth[OtherPRI.Team.TeamIndex] += OtherPRI.PlayerHealth;
        }
    }

    SpecKillsDigits[0].Value = TSCTeams[0].ZedKills;
    SpecKillsDigits[1].Value = TSCTeams[1].ZedKills;
    SpecDeathsDigits[0].Value = TSCTeams[0].Deaths;
    SpecDeathsDigits[1].Value = TSCTeams[1].Deaths;
    SpecDoshDigits[0].Value = TeamDosh[0] + KFGRI.Teams[0].Score;
    SpecDoshDigits[1].Value = TeamDosh[1] + KFGRI.Teams[1].Score;
    SpecInvDoshDigits[0].Value = TSCTeams[0].InventorySellValue;
    SpecInvDoshDigits[1].Value = TSCTeams[1].InventorySellValue;
    SpecWaveKillsDigits[0].Value = TeamWaveKills[0];
    SpecWaveKillsDigits[1].Value = TeamWaveKills[1];
    // SpecMinKillsDigits[0].Value = TSCTeams[0].GetPrevMinuteKills();
    // SpecMinKillsDigits[1].Value = TSCTeams[1].GetPrevMinuteKills();

    RedTeamDoshRatio = CalcTeamRatio(SpecDoshDigits[0].Value + SpecInvDoshDigits[0].Value,
            SpecDoshDigits[1].Value + SpecInvDoshDigits[1].Value);
    RedTeamHealthRatio = CalcTeamRatio(TeamHealth[0], TeamHealth[1]);
    RedTeamWaveKillRatio = CalcTeamRatio(TeamWaveKills[0], TeamWaveKills[1]);

    if ( SpecWaveKillsDigits[0].Value < TSCGRI.WaveKillReq ) {
        SpecWaveKillsDigits[0].Tints[0] = LowAmmoColor;
        PulseColorIf(SpecWaveKillsDigits[0].Tints[0], SpecWaveKillsDigits[1].Value >= TSCGRI.WaveKillReq);
    }
    else {
        SpecWaveKillsDigits[0].Tints[0] = default.SpecWaveKillsDigits[0].Tints[0];
    }

    if ( SpecWaveKillsDigits[1].Value < TSCGRI.WaveKillReq ) {
        SpecWaveKillsDigits[1].Tints[0] = LowAmmoColor;
        PulseColorIf(SpecWaveKillsDigits[1].Tints[0], SpecWaveKillsDigits[0].Value >= TSCGRI.WaveKillReq);
    }
    else {
        SpecWaveKillsDigits[1].Tints[0] = default.SpecWaveKillsDigits[1].Tints[0];
    }

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
    SpecWaveKillsIcon[0].Tints[0].A = KFHUDAlpha;
    SpecWaveKillsIcon[0].Tints[1].A = KFHUDAlpha;
    SpecWaveKillsDigits[0].Tints[0].A = KFHUDAlpha;
    SpecWaveKillsDigits[0].Tints[1].A = KFHUDAlpha;

    // SpecMinKillsBG[0].Tints[0].A = KFHUDAlpha;
    // SpecMinKillsBG[0].Tints[1].A = KFHUDAlpha;
    // SpecMinKillsDigits[0].Tints[0].A = KFHUDAlpha;
    // SpecMinKillsDigits[0].Tints[1].A = KFHUDAlpha;

    SpecKillsBG[1].Tints[0].A = KFHUDAlpha;
    SpecKillsBG[1].Tints[1].A = KFHUDAlpha;
    SpecKillsIcon[1].Tints[0].A = KFHUDAlpha;
    SpecKillsIcon[1].Tints[1].A = KFHUDAlpha;
    SpecKillsDigits[1].Tints[0].A = KFHUDAlpha;
    SpecKillsDigits[1].Tints[1].A = KFHUDAlpha;
    SpecWaveKillsBG[1].Tints[0].A = KFHUDAlpha;
    SpecWaveKillsBG[1].Tints[1].A = KFHUDAlpha;
    SpecWaveKillsIcon[1].Tints[0].A = KFHUDAlpha;
    SpecWaveKillsIcon[1].Tints[1].A = KFHUDAlpha;
    SpecWaveKillsDigits[1].Tints[0].A = KFHUDAlpha;
    SpecWaveKillsDigits[1].Tints[1].A = KFHUDAlpha;

    // SpecMinKillsBG[1].Tints[0].A = KFHUDAlpha;
    // SpecMinKillsBG[1].Tints[1].A = KFHUDAlpha;
    // SpecMinKillsDigits[1].Tints[0].A = KFHUDAlpha;
    // SpecMinKillsDigits[1].Tints[1].A = KFHUDAlpha;

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

    SpecInvDoshBG[0].Tints[0].A = KFHUDAlpha;
    SpecInvDoshBG[0].Tints[1].A = KFHUDAlpha;
    SpecInvDoshIcon[0].Tints[0].A = KFHUDAlpha;
    SpecInvDoshIcon[0].Tints[1].A = KFHUDAlpha;
    SpecInvDoshDigits[0].Tints[0].A = KFHUDAlpha;
    SpecInvDoshDigits[0].Tints[1].A = KFHUDAlpha;
    SpecInvDoshBG[1].Tints[0].A = KFHUDAlpha;
    SpecInvDoshBG[1].Tints[1].A = KFHUDAlpha;
    SpecInvDoshIcon[1].Tints[0].A = KFHUDAlpha;
    SpecInvDoshIcon[1].Tints[1].A = KFHUDAlpha;
    SpecInvDoshDigits[1].Tints[0].A = KFHUDAlpha;
    SpecInvDoshDigits[1].Tints[1].A = KFHUDAlpha;
}

simulated function DrawSpecBar(Canvas C, float Ratio, float x, float y, float w, float h,
    optional Texture RedIcon, optional Texture BlueIcon,
    optional Texture CenterIcon, optional Color CenterIconColor)
{
    local float redw;
    local float IconSize, IconSizeX;
    local Color OldColor;

    if (Ratio < 0)
        return;

    OldColor = C.DrawColor;
    SetAlphaColor(C.DrawColor, WhiteColor);

    IconSize = C.ClipY * h * 0.70;
    IconSizeX = IconSize / C.ClipX;
    if (RedIcon != none) {
        x += IconSizeX;
        w -= IconSizeX;
    }
    if (BlueIcon != none) {
        w -= IconSizeX;
    }

    redw = w * fclamp(Ratio, 0.025, 0.975);
    C.SetPos(C.ClipX * x, C.ClipY * y);
    C.DrawTileStretched(SpecBarRed, C.ClipX * redw, C.ClipY * h);

    C.SetPos(C.ClipX * (x + redw), C.ClipY * y);
    redw = w - redw;
    C.DrawTileStretched(SpecBarBlue, C.ClipX * redw + 1, C.ClipY * h);

    C.SetPos(C.ClipX * x, C.ClipY * y);
    C.DrawTileStretched(SpecBarBG, C.ClipX * w, C.ClipY * h);

    if (RedIcon != none) {
        C.SetPos(C.ClipX * x - IconSize, (C.ClipY * (y + h/2)) - IconSize/2);
        C.DrawIcon(RedIcon, IconSize / RedIcon.VSize);
    }
    if (BlueIcon != none) {
        C.SetPos(C.ClipX * (x + w), (C.ClipY * (y + h/2)) - IconSize/2);
        C.DrawIcon(BlueIcon, IconSize / BlueIcon.VSize);
    }

    if (CenterIcon != none) {
        SetAlphaColor(C.DrawColor, CenterIconColor);
        C.SetPos(C.ClipX * (x + w/2) - IconSize/2, (C.ClipY * (y + h/2)) - IconSize/2);
        C.DrawIcon(CenterIcon, IconSize / CenterIcon.VSize);
    }

    C.DrawColor = OldColor;
}

simulated function DrawClan(Canvas C, byte TeamIndex, float x, float y, float h)
{
    local TSCClanReplicationInfo ClanRep;
    local array<string> Lines;
    local float w, XL, YL, XLMax, YLMax;
    local int i, j;

    if (TeamIndex > 1 || TSCTeams[TeamIndex] == none)
        return;
    ClanRep = TSCTeams[TeamIndex].ClanRep;
    if (ClanRep == none)
        return;

    SetAlphaColor(C.DrawColor, WhiteColor);
    w = 2*h;

    if (!bLightHud) {
        C.SetPos(x, y);
        C.DrawTileStretched(Boxes[TeamIndex], w, h);
    }

    if (ClanRep.Banner != none) {
        C.SetPos(x, y);
        C.DrawTile(ClanRep.Banner, w, h,  0, 0, ClanRep.Banner.MaterialUSize(), ClanRep.Banner.MaterialVSize());
        return;
    }

    if (ClanRep.DecoName != "") {
        Split(ClanRep.DecoName, "|", Lines);
    }
    else {
        Lines[0] = ClanRep.ClanName;
    }

    // find the biggest font of the clan name that fits into the banner
    for (i = 1; i < 9; ++i) {
        C.Font = LoadFont(i);
        for (j = 0; j < Lines.Length; ++j) {
            C.TextSize(Lines[j], XL, YL);
            XLMax = fmax(XLMax, XL);
            YLMax = fmax(YLMax, YL);
        }
        if (XLMax < w && YLMax * Lines.Length < h)
            break;
    }
    SetAlphaColor(C.DrawColor, TextColors[TeamIndex]);
    XL = x + h;
    YL = y + (h - YLMax*Lines.Length)/2 + YLMax/2;  // V middle of the first line
    XL /= C.SizeX;
    YL /= C.SizeY; // line height
    YLMax /= C.SizeY; // line height

    for (j = 0; j < Lines.Length; ++j) {
        C.DrawScreenText(Lines[j], XL, YL + j * YLMax, DP_MiddleMiddle);
    }
}

simulated function DrawSpecialSpectatingHUD(Canvas C)
{
    local string s;
    local TSCTeamBase TeamBase;
    local EScrnEffect Effect;

    if ( KFGRI == none || !KFGRI.bMatchHasBegun)
        return;

    bDrawSpecDeaths = false;
    super.DrawSpecialSpectatingHUD(C);

    // player stats
    if ( Level.TimeSeconds > NextStatUpdateTime ) {
        NextStatUpdateTime = Level.TimeSeconds + 0.5;
        CalsTeamStats();
    }

    if (bSpecDrawClan) {
        DrawClan(C, 0, SpecClanBannerX * C.ClipX, SpecClanBannerY * C.ClipY, SpecClanBannerHeight * C.ClipY);
        DrawClan(C, 1, (1.0 - SpecClanBannerX) * C.ClipX - (2 * SpecClanBannerHeight * C.ClipY),
                SpecClanBannerY * C.ClipY, SpecClanBannerHeight * C.ClipY);

        // clan names
        C.Font = GetStaticFontSizeIndex(C, 2);
        if (TSCTeams[0] != none && TSCTeams[0].ClanRep != none) {
            SetAlphaColor(C.DrawColor, TextColors[0]);
            C.DrawScreenText(TSCTeams[0].ClanRep.Acronym, SpecClanNameX,  SpecClanNameY,
                    DP_UpperLeft);
        }
        if (TSCTeams[1] != none && TSCTeams[1].ClanRep != none) {
            SetAlphaColor(C.DrawColor, TextColors[1]);
            C.DrawScreenText(TSCTeams[1].ClanRep.Acronym, 1.0 - SpecClanNameX,  SpecClanNameY,
                    DP_UpperRight);
        }
        SetAlphaColor(C.DrawColor, WhiteColor);
    }

    if (bDrawSpecBar) {
        DrawSpecBar(C, RedTeamDoshRatio, (1.0 - SpecBarWidth) * 0.5, SpecBarY, SpecBarWidth, SpecBarHeight,
                texture'KillingFloorHUD.HUD.Hud_Pound_Symbol', texture'TSC_T.HUD.Hud_Pound_Symbol');
        DrawSpecBar(C, RedTeamHealthRatio, (1.0 - SpecBarWidth) * 0.5, SpecBarY + SpecBarHeight + 0.0005,
                SpecBarWidth, SpecBarHeight,
                texture'KillingFloorHUD.HUD.Hud_Medical_Cross', texture'TSC_T.HUD.Hud_Medical_Cross');
        DrawSpecBar(C, RedTeamWaveKillRatio, (1.0 - SpecBarWidth) * 0.5, SpecBarY + 2*(SpecBarHeight + 0.0005),
                SpecBarWidth, SpecBarHeight,
                texture'TSC_T.SpecHUD.ClotEmoRed', texture'TSC_T.SpecHUD.ClotEmoBlue');
    }

    if ( !bLightHud ) {
        DrawSpriteWidget(C, SpecKillsBG[0]);
        DrawSpriteWidget(C, SpecWaveKillsBG[0]);
        // DrawSpriteWidget(C, SpecMinKillsBG[0]);
        DrawSpriteWidget(C, SpecDeathsBG[0]);
        DrawSpriteWidget(C, SpecDoshBG[0]);
        DrawSpriteWidget(C, SpecInvDoshBG[0]);

        DrawSpriteWidget(C, SpecKillsBG[1]);
        DrawSpriteWidget(C, SpecWaveKillsBG[1]);
        // DrawSpriteWidget(C, SpecMinKillsBG[1]);
        DrawSpriteWidget(C, SpecDeathsBG[1]);
        DrawSpriteWidget(C, SpecDoshBG[1]);
        DrawSpriteWidget(C, SpecInvDoshBG[1]);
    }
    DrawSpriteWidget(C, SpecInvDoshIcon[0]);
    DrawNumericWidget(C, SpecInvDoshDigits[0], DigitsSmall);
    DrawSpriteWidget(C, SpecDoshIcon[0]);
    DrawNumericWidget(C, SpecDoshDigits[0], DigitsSmall);
    DrawSpriteWidget(C, SpecDeathsIcon[0]);
    DrawNumericWidget(C, SpecDeathsDigits[0], DigitsSmall);
    DrawSpriteWidget(C, SpecKillsIcon[0]);
    DrawNumericWidget(C, SpecKillsDigits[0], DigitsSmall);
    DrawSpriteWidget(C, SpecWaveKillsIcon[0]);
    DrawNumericWidget(C, SpecWaveKillsDigits[0], DigitsSmall);
    // DrawNumericWidget(C, SpecMinKillsDigits[0], DigitsSmall);

    DrawSpriteWidget(C, SpecInvDoshIcon[1]);
    DrawNumericWidget(C, SpecInvDoshDigits[1], DigitsSmall);
    DrawSpriteWidget(C, SpecDoshIcon[1]);
    DrawNumericWidget(C, SpecDoshDigits[1], DigitsSmall);
    DrawSpriteWidget(C, SpecDeathsIcon[1]);
    DrawNumericWidget(C, SpecDeathsDigits[1], DigitsSmall);
    DrawSpriteWidget(C, SpecKillsIcon[1]);
    DrawNumericWidget(C, SpecKillsDigits[1], DigitsSmall);
    DrawSpriteWidget(C, SpecWaveKillsIcon[1]);
    DrawNumericWidget(C, SpecWaveKillsDigits[1], DigitsSmall);
    // DrawNumericWidget(C, SpecMinKillsDigits[1], DigitsSmall);

    // ARROWS
    if ( TSCGRI == none || KFGRI.ElapsedTime < 15 )
        return;

    // Red Base
    TeamBase = TSCTeamBase(TSCGRI.Teams[0].HomeBase);
    if ( TeamBase != none && !TeamBase.bHidden ) {
        if ( BaseDirPointer == None )
            BaseDirPointer = Spawn(Class'KFShopDirectionPointer');

        Effect = EFF_NONE;
        BaseDirPointer.UV2Texture = none;
        if ( TeamBase.bStunned ) {
            s = strStunned;
            C.DrawColor = LowAmmoColor;
            Effect = EFF_BLINK;
        }
        else if ( TeamBase.bActive ) {
            s = strBase;
            SetAlphaColor(C.DrawColor, TextColors[0]);
        }
        else if ( TeamBase.bHeld ) {
            s = strCarrier;
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        else {
            s = strGnome;
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        DrawDirPointer(C, BaseDirPointer, TeamBase.GetLocation(), 0, 0, false, s, false, Effect);
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

        Effect = EFF_NONE;
        EnemyBaseDirPointer.UV2Texture = ConstantColor'TSC_T.HUD.BlueCol';
        if ( TeamBase.bStunned ) {
            s = strStunned;
            C.DrawColor = LowAmmoColor;
            Effect = EFF_BLINK;
        }
        else if ( TeamBase.bActive ) {
            s = strBase;
            SetAlphaColor(C.DrawColor, TextColors[1]);
        }
        else if ( TeamBase.bHeld ) {
            s = strCarrier;
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        else {
            s = strGnome;
            C.SetDrawColor(196, 206, 0, KFHUDAlpha);
        }
        DrawDirPointer(C, EnemyBaseDirPointer, TeamBase.GetLocation(), 0, 0, false, s, true, Effect);
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
        SetAlphaColor(C.DrawColor, TextColors[0]);
        DrawDirPointer(C, ShopDirPointer, TSCGRI.CurrentShop.Location, 0, 1, false, strTrader, false);

        // blue shop
        if ( EnemyShopDirPointer == None )
             EnemyShopDirPointer = Spawn(Class'KFShopDirectionPointer');
        EnemyShopDirPointer.UV2Texture = ConstantColor'TSC_T.HUD.BlueCol';
        SetAlphaColor(C.DrawColor, TextColors[1]);
        DrawDirPointer(C, EnemyShopDirPointer, TSCGRI.BlueShop.Location, 0, 1, false, strTrader, true);
    }
}

exec function ToggleSpecBar()
{
    bDrawSpecBar = !bDrawSpecBar;
}

exec function SpecBar(bool bEnabled)
{
    bDrawSpecBar = bEnabled;
}

exec function ToggleSpecClanBanner()
{
    bSpecDrawClan = !bSpecDrawClan;
}

exec function SpecClanBanner(bool bEnabled)
{
    bSpecDrawClan = bEnabled;
}

exec function HudSpecBarY(float y)
{
    SpecBarY = y;
    SaveConfig();
}

exec function HudSpecBarW(float w)
{
    SpecBarWidth = w;
    SaveConfig();
}

exec function HudSpecBarH(float h)
{
    SpecBarHeight = h;
    SaveConfig();
}

exec function HudSpecClanX(float x)
{
    SpecClanBannerX = x;
    SaveConfig();
}

exec function HudSpecClanY(float y)
{
    SpecClanBannerY = y;
    SaveConfig();
}

exec function HudSpecClanH(float h)
{
    SpecClanBannerHeight = h;
    SaveConfig();
}

exec function HudSpecClanNameX(float x)
{
    SpecClanNameX = x;
    SaveConfig();
}

exec function HudSpecClanNameY(float y)
{
    SpecClanNameY = y;
    SaveConfig();
}

exec function TeamStats()
{
    local byte t;

    for (t = 0; t < 2; ++t) {
        PlayerOwner.ClientMessage(TSCTeams[t].GetHumanReadableName() $ ": Kills={"
            $ " Total=" $ TSCTeams[t].ZedKills
            $ " Wave=" $ TSCTeams[t].GetCurWaveKills()
            $ " KPM=" $ TSCTeams[t].GetPrevMinuteKills()
            $ " ThisMinute=" $ TSCTeams[t].GetCurMinuteKills()
            $ "} Deaths=" $ TSCTeams[t].Deaths
            $ " Dosh=" $ int(TSCTeams[t].Score)
            , 'log');
    }
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
    strStunned="STUNNED: "

    titleWelcome="TEAM SURVIVAL COMPETITION"
    titleSuddenDeath="SUDDEN DEATH"
    titleSetupBase="SET UP BASE"
    titleBaseLost="BASE LOST"
    titlePvP="PLAYER-VS-PLAYER"
    titleStunned="GUARDIAN STUNNED"

    hintWelcome=" Welcome to TSC! Watch this place for useful hints. "
    hintFirstWave="You cannot hurt other players during the first wave. Focus on zeds!"
    hintPrepareToFight="Get ready for ZED invasion!"
    hintSuddenDeath="A single death wipes your squad"
    hintSuddenDeathTrader="Nobody of your team can die, or you will get wiped"
    hintGotoBase="Get to your Base for protection from Friendly Fire"
    hintEnemyBase="Get out from the Enemy Base before the Guardian kills you!"
    hintShopping="You can buy weapons and stuff from the Trader"
    hintFollowCarrier="Follow your Guardian Carrier to the new Base"
    hintGetGnome="Take the Guardian from your Trader to set up the Base"
    hintSetupBase="Get to the place where you want to set up the Base and press %KEY%"
    hintSetupEnemyBase="Cannot use Guardian on the Enemy Base!"
    hintBaseLostTrader="You left your Guardian alone for too long, and he went away. Now you have to survive the wave without the Base"
    hintPvP="Enemy team can hurt you even at your Base!"
    hintStunned="Base Guardian is stunned and cannot protect you from Human Damage"

    // RED
    SpecInvDoshBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.350,PosX=-0.04,PosY=0.785,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecInvDoshIcon(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Weight',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.160,PosX=0.001,PosY=0.797,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecInvDoshDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.0225,PosY=0.80,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    SpecDoshBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.350,PosX=-0.04,PosY=0.835,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecDoshIcon(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Pound_Symbol',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.160,PosX=0.001,PosY=0.847,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecDoshDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.0225,PosY=0.850,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    SpecDeathsBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.350,PosX=-0.04,PosY=0.885,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecDeathsIcon(0)=(WidgetTexture=Texture'TSC_T.SpecHUD.Skull64',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.16,PosX=0.001,PosY=0.897,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=64,G=64,R=200,A=255),Tints[1]=(B=64,G=64,R=2,A=255))
    SpecDeathsDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.0225,PosY=0.9,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    SpecKillsBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.35,PosX=-0.040,PosY=0.935,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecKillsIcon(0)=(WidgetTexture=Texture'TSC_T.SpecHUD.ClotEmoRed',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.16,PosX=0.001,PosY=0.947,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecKillsDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.0225,PosY=0.950,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    SpecWaveKillsBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_128x64',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=128,Y2=64),TextureScale=0.35,PosX=0.102,PosY=0.935,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecWaveKillsIcon(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Bio_Circle',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=256),TextureScale=0.04,PosX=0.104,PosY=0.947,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecWaveKillsDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.123,PosY=0.950,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    // SpecMinKillsBG(0)=(WidgetTexture=Texture'KillingFloorHUD.HUD.Hud_Box_128x64',RenderStyle=STY_Alpha,TextureCoords=(X1=32,Y1=0,X2=128,Y2=64),TextureScale=0.35,PosX=0.1525,PosY=0.935,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    // SpecMinKillsDigits(0)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.158,PosY=0.95,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))

    // BLUE
    SpecInvDoshBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.350,PosX=0.895,PosY=0.785,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecInvDoshIcon(1)=(WidgetTexture=Texture'TSC_T.SpecHUD.Hud_Weight',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.160,PosX=0.901,PosY=0.797,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecInvDoshDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.9225,PosY=0.8,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))

    SpecDoshBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.350,PosX=0.895,PosY=0.835,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecDoshIcon(1)=(WidgetTexture=Texture'TSC_T.SpecHUD.Hud_Pound_Symbol',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.160,PosX=0.901,PosY=0.847,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecDoshDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.9225,PosY=0.850,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))

    SpecDeathsBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.350,PosX=0.895,PosY=0.885,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecDeathsIcon(1)=(WidgetTexture=Texture'TSC_T.SpecHUD.Skull64',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.16,PosX=0.901,PosY=0.897,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))
    SpecDeathsDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.9225,PosY=0.9,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))

    SpecKillsBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_256x64',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=64),TextureScale=0.35,PosX=0.895,PosY=0.935,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecKillsIcon(1)=(WidgetTexture=Texture'TSC_T.SpecHUD.ClotEmoBlue',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.16,PosX=0.901,PosY=0.947,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecKillsDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.9225,PosY=0.950,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))

    SpecWaveKillsBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_128x64',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=128,Y2=64),TextureScale=0.35,PosX=0.823,PosY=0.935,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    SpecWaveKillsIcon(1)=(WidgetTexture=Texture'TSC_T.SpecHUD.Hud_Bio_Circle',RenderStyle=STY_Alpha,TextureCoords=(X2=256,Y2=256),TextureScale=0.04,PosX=0.828,PosY=0.947,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    SpecWaveKillsDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.848,PosY=0.950,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))

    // SpecMinKillsBG(1)=(WidgetTexture=Texture'TSC_T.HUD.Hud_Box_128x64',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=96,Y2=64),TextureScale=0.35,PosX=0.789,PosY=0.935,ScaleMode=SM_Right,Scale=1.0,Tints[0]=(B=255,G=255,R=255,A=128),Tints[1]=(B=255,G=255,R=255,A=128))
    // SpecMinKillsDigits(1)=(RenderStyle=STY_Alpha,TextureScale=0.3,PosX=0.796,PosY=0.950,Tints[0]=(B=198,G=153,R=90,A=255),Tints[1]=(B=198,G=153,R=90,A=255))

    SpecBarBG=texture'TSC_T.SpecHUD.Battery_BG'
    SpecBarRed=texture'TSC_T.SpecHUD.BarFill_Red'
    SpecBarBlue=texture'TSC_T.SpecHUD.BarFill_Blue'
    bDrawSpecBar=true
    SpecBarY=0.06
    SpecBarWidth=0.30
    SpecBarHeight=0.03

    bSpecDrawClan=true
    SpecClanNameX=0.005
    SpecClanNameY=0.750
    SpecClanBannerX=0.195
    SpecClanBannerY=0.046
    SpecClanBannerHeight=0.120

    bDrawSpecDeaths=False
    bDrawShopDirPointer=True

    bCoolHud=False
    bCoolHudTeamColor=True

    OutOfTheBaseColor=(R=200,G=200,B=32)
    OwnBaseMaterial=ConstantColor'TSC_T.HUD.GreenCol'
}
