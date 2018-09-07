class FtgHUD extends TSCHUD;

var localized string titleStinkyClot;
var localized string hintStinkyClot;

var transient float StinkyTime;
var transient bool bFoundStinkyClot;


simulated function bool CheckForStinkyClot()
{
    local StinkyClot SC;

    if ( PawnOwner != none ) {
        foreach PawnOwner.VisibleCollidingActors(class'StinkyClot', SC, 1000, PawnOwner.Location) {
            StinkyTime = Level.TimeSeconds + 60; // show stinky hint for the next minute
            return true;
        }
    }
    StinkyTime = Level.TimeSeconds + 3; // look again in 3s
    return false;
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
    local int       row;

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
        DrawDirPointer(C, EnemyBaseDirPointer, TeamBase.Location, 1, 0, false, strEnemyBase);
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

        bDrawShopDirPointer = !KFGRI.bWaveInProgress && (ScrnGRI == none || ScrnGRI.bTraderArrow); // always draw Trader Arrow during the Trader Time
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
        if ( bDrawShopDirPointer )
            row = 1; // shift team base arrow to fit trader pointer
        DrawDirPointer(C, BaseDirPointer, TeamBase.GetLocation(), row, 0, false, s);
    }
    else
        bDrawShopDirPointer = (ScrnGRI == none || ScrnGRI.bTraderArrow); // no gnome = draw shop arrow

    // hints
    if ( bHideTSCHints || KFGRI.EndGameType > 0 )
        return;


    if ( TSCGRI.ElapsedTime <= 10 ) {
        aTitle = titleWelcome;
        aHint = hintWelcome;
        bCriticalHint = true;
    }
    else if ( TSCGRI.bWaveInProgress ) {
        bFoundStinkyClot = bFoundStinkyClot || ( StinkyTime < Level.TimeSeconds && CheckForStinkyClot() );
        if ( TSCGRI.WaveNumber == 0 )
            aHint = hintFirstWave;
        else if ( TSCGRI.bSuddenDeath ) {
            aHint = hintSuddenDeath;
            aTitle = titleSuddenDeath;
        }
        else if ( bAtEnemyBase ) {
            aHint = hintEnemyBase;
            bCriticalHint = true;
        }
        else if ( TSCGRI.MaxMonsters >= 10 && !bAtOwnBase && TeamBase.bActive ) {
                aHint = hintGotoBase;
        }
        else if ( bFoundStinkyClot && StinkyTime > Level.TimeSeconds ) {
            aHint = hintStinkyClot;
            aTitle = titleStinkyClot;
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


defaultproperties
{
    titleWelcome="FOLLOW THE GUARDIAN"
    titleBaseLost="FAILED TO FOLLOW THE GUARDIAN"
    titleStinkyClot="STINKY CLOT"

    hintWelcome=" Welcome to FTG! Watch this place for useful hints. "
    hintFirstWave="First wave is a usual KF wave. Kill all zeds and dont die :)"
    hintGotoBase="Get to your Base and protect The Guardian!"
    hintGetGnome="Take the Guardian from your trader to set up a Base"
    hintBaseLostTrader="You lost your Guardian and now you are dead!"
    hintStinkyClot="OMG it is a Stinky Clot! You cannot kill them but those things are really nasty."
}
