class TSCScoreBoard extends ScrnScoreBoard;

#exec OBJ LOAD FILE=TSC_T.utx

var     color                   RedBG[2], BlueBG[2];

var     material                RedLogo, BlueLogo;
var     material                GameLogo;

var     material                CptIcon, CptAssIcon;

var array<localized string> HDmgNames;


static function float DrawNamePrefixIcons(Canvas C, PlayerReplicationInfo PRI, ScrnCustomPRI ScrnPRI, out String PlayerName,
    float X, float Y, float IconSize)
{
    local float XL;
    local TSCGameReplicationInfo TSCGRI;
    local Material M;

    XL = super.DrawNamePrefixIcons(C, PRI, ScrnPRI, PlayerName, X, Y, IconSize);

    TSCGRI = TSCGameReplicationInfo(PRI.Level.GRI);
    if ( PRI.Team != none && PRI.Team.TeamIndex < 2 && TSCGRI != none ) {
        if ( PRI == TSCGRI.TeamCaptain[PRI.Team.TeamIndex] )
            M = default.CptIcon;
        else if ( PRI == TSCGRI.TeamCarrier[PRI.Team.TeamIndex] )
            M = default.CptAssIcon;

        if ( M != none) {
            C.SetPos(X + XL, Y);
            C.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
            XL += IconSize * 1.2;
        }
    }

    return XL;
}


simulated function DrawTeam(Canvas Canvas, array<PlayerReplicationInfo> TeamPRIArray, int Left, int Top, int Width, int LineHeight, int LineCount,
    bool bExtraInfo, color OddBGColor, color EvenBGColor)
{
    local PlayerReplicationInfo PRI, OwnerPRI;
    local KFPlayerReplicationInfo KFPRI;
    local bool bEven;
    local int i, y, BoxTextOffsetY;
    local int VetXPos, NameXPos, DeathsXPos, KillsXPos, CashXPos, HealthXpos, TimeXPos, NetXPos;
    local float tmpClipX, XL,YL;
    local Material VeterancyBox,StarBox;
    local string S;
    local byte Stars;
    local int TotalKills, TotalAss, TotalDeaths;

    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;

    Canvas.Style = ERenderStyle.STY_Alpha;

    // lines
    Y = Top;
    for ( i = 0; i < LineCount; i++) {
        bEven = !bEven;
        if ( i < TeamPRIArray.length && TeamPRIArray[i] == OwnerPRI)
            Canvas.SetDrawColor(0, 255, 0, 48); // highlight myself
        else if ( bEven )
            Canvas.DrawColor = EvenBGColor;
        else
            Canvas.DrawColor = OddBGColor;
        Canvas.SetPos(Left, Y);
        Canvas.DrawTileStretched( WhiteMaterial, Width, LineHeight);
        y += LineHeight;
    }
    // draw box around
    Canvas.DrawColor = HUDClass.default.RedColor;
    Canvas.SetPos(Left, Top);
    Canvas.DrawTileStretched(BoxMaterial, Width, LineHeight * LineCount);

    // set columns
    VetXPos = Left + 0.0001 * Width;
    NameXPos = VetXPos + LineHeight*1.75;
    if ( bExtraInfo ) {
        KillsXPos = Left + 0.50 * Width;
        CashXPos = Left + 0.67 * Width;
        HealthXpos = Left + 0.75 * Width;
        TimeXPos = Left + 0.85 * Width;
        NetXPos = Left + 0.996 * Width;
    }
    else {
        KillsXPos = Left + 0.55 * Width;
        TimeXPos = Left + 0.80 * Width;
        NetXPos = Left + 0.996 * Width;
    }

    Canvas.TextSize(KillsAssSeparator $ AssHeaderText, XL, YL);
    DeathsXPos = KillsXPos + XL + LineHeight;

    //headers
    y = Top - LineHeight;
    Canvas.Style = ERenderStyle.STY_Normal;

    Canvas.SetPos(NameXPos, y);
    Canvas.DrawTextClipped(PlayerText);

    Canvas.TextSize(KillsText, XL, YL);
    Canvas.SetPos(KillsXPos - XL, y);
    Canvas.DrawTextClipped(KillsText);
    Canvas.SetPos(KillsXPos, y);
    Canvas.DrawColor = AssColor;
    Canvas.DrawTextClipped(KillsAssSeparator $ AssHeaderText);
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    // death icon
    Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.SetPos(DeathsXPos - LineHeight/2, y);
    Canvas.DrawTile(DeathIcon, LineHeight, LineHeight, 0, 0, DeathIcon.MaterialUSize(), DeathIcon.MaterialVSize());
    Canvas.Style = ERenderStyle.STY_Normal;

    Canvas.TextSize(TimeText, XL, YL);
    Canvas.SetPos(TimeXPos - 0.5 * XL, y);
    Canvas.DrawTextClipped(TimeText);

    if ( bExtraInfo ) {
        Canvas.TextSize(PointsText, XL, YL);
        Canvas.SetPos(CashXPos - 0.5 * XL, y);
        Canvas.DrawTextClipped(PointsText);

        Canvas.TextSize(HealthText, XL, YL);
        Canvas.SetPos(HealthXPos - 0.5 * XL, y);
        Canvas.DrawTextClipped(HealthText);
    }

    Canvas.TextSize(NetText, XL, YL);
    Canvas.SetPos(NetXPos - XL, y);
    Canvas.DrawTextClipped(NetText);


    // player names
    BoxTextOffsetY = (LineHeight - YL)/2;
    y = Top + BoxTextOffsetY;
    tmpClipX = Canvas.ClipX;
    Canvas.TextSize("     ", XL, YL);
    Canvas.ClipX = KillsXPos - XL;
    for ( i = 0; i < LineCount && i < TeamPRIArray.length; i++ ) {
        PRI = TeamPRIArray[i];
        // draw admins in red, others in white
        if ( PRI.bAdmin ) {
            Canvas.SetPos(Canvas.ClipX - LineHeight, y - BoxTextOffsetY + 1);
            XL = LineHeight-2;
            Canvas.DrawTile(AdminIcon, XL, XL, 0, 0, AdminIcon.MaterialUSize(), AdminIcon.MaterialVSize());
            Canvas.DrawColor = Class'HudBase'.Default.RedColor;
        }
        DrawCountryNameSE(Canvas, PRI, NameXPos, y);
        //restore
        Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
        y += LineHeight;
    }
    // Draw not shown info
    if( TeamPRIArray.length > LineCount ) {
        Canvas.DrawColor.G = 255;
        Canvas.DrawColor.B = 0;
        Canvas.SetPos(NameXPos, y);
        Canvas.DrawText(string(TeamPRIArray.length - LineCount) @ NotShownInfo,true);
    }
    // restore canvas properties
    Canvas.ClipX = tmpClipX;
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.Style = ERenderStyle.STY_Normal;

    y = Top + BoxTextOffsetY;
    // Draw the player informations.
    for ( i = 0; i < LineCount && i < TeamPRIArray.length; i++ ) {
        PRI = TeamPRIArray[i];
        KFPRI = KFPlayerReplicationInfo(PRI);

        Canvas.DrawColor = HUDClass.default.WhiteColor;

        // Display perks.
        if ( KFPRI!=None && Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill)!=none )
        {
            Stars = Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill).Static.PreDrawPerk(Canvas
                ,KFPRI.ClientVeteranSkillLevel,VeterancyBox,StarBox);

            if ( VeterancyBox != None )
                DrawPerkWithStars(Canvas, VetXPos, y - BoxTextOffsetY, LineHeight, Stars, VeterancyBox, StarBox);
            Canvas.DrawColor = HUDClass.default.WhiteColor;
        }

        // draw kills
        TotalKills += KFPRI.Kills;
        Canvas.TextSize(PRI.Kills, XL, YL);
        Canvas.SetPos(KillsXPos - XL, y);
        Canvas.DrawTextClipped(KFPRI.Kills);
        // draw Assists  -- PooSH
        if ( KFPRI != none && KFPRI.KillAssists > 0) {
            TotalAss += KFPRI.KillAssists;
            Canvas.DrawColor = AssColor;
            Canvas.SetPos(KillsXPos, y);
            Canvas.DrawTextClipped(KillsAssSeparator $ KFPRI.KillAssists);
            Canvas.DrawColor = HUDClass.default.WhiteColor;
        }
        // deaths
        if ( PRI.Deaths > 0 ) {
            TotalDeaths += PRI.Deaths;
            S = string(int(PRI.Deaths));
            Canvas.TextSize(S, XL, YL);
            Canvas.SetPos(DeathsXPos - XL/2, y);
            Canvas.DrawTextClipped(S);
        }

        if ( bExtraInfo && KFPRI != none ) {
            // draw cash
            S = class'ScrnUnicode'.default.Dosh $ int(PRI.Score);
            Canvas.TextSize(S, XL, YL);
            Canvas.SetPos(CashXPos-XL*0.5f, y);
            Canvas.DrawColor = DoshColor;
            Canvas.DrawText(S,true);
            Canvas.DrawColor = HUDClass.default.WhiteColor;

            // draw healths
            if ( PRI.bOutOfLives || KFPRI.PlayerHealth<=0 )
            {
                Canvas.DrawColor = HUDClass.default.RedColor;
                S = OutText;
            }
            else
            {
                if( KFPRI.PlayerHealth>=90 )
                    Canvas.DrawColor = HUDClass.default.GreenColor;
                else if( KFPRI.PlayerHealth>=50 )
                    Canvas.DrawColor = HUDClass.default.GoldColor;
                else Canvas.DrawColor = HUDClass.default.RedColor;
                S = KFPRI.PlayerHealth$HealthyString;
            }
            Canvas.TextSize(S, XL, YL);
            Canvas.SetPos(HealthXpos - 0.5 * XL, y);
            Canvas.DrawTextClipped(S);
            Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
        }

        // draw time
        if( GRI.ElapsedTime<PRI.StartTime ) // Login timer error, fix it.
            GRI.ElapsedTime = PRI.StartTime;
        S = FormatTime(GRI.ElapsedTime-PRI.StartTime);
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(TimeXPos-XL*0.5f, y);
        Canvas.DrawText(S,true);

        // Draw ping
        Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
        if ( !GRI.bMatchHasBegun ) {
            if ( PRI.bReadyToPlay )
                S = ReadyText;
            else {
                Canvas.DrawColor = Class'HudBase'.Default.RedColor;
                S = NotReadyText;
            }
        }
        else if( PRI.bBot )
            S = BotText;
        else if ( PRI.Ping == 255 ) {
            Canvas.DrawColor = HUDClass.default.RedColor;
            S = strPingMax;
        }
        else {
            S = string(PRI.Ping*4);
            if ( PRI.Ping >= 50 ) // *4 = 200
                Canvas.DrawColor = HUDClass.default.RedColor;
            else if ( PRI.Ping >= 25 ) // *4 = 100
                Canvas.DrawColor = HUDClass.default.GoldColor;
        }
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(NetXPos-XL, y);
        Canvas.DrawTextClipped(S);
        Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;

        y+=LineHeight;
    }

    // totals
    y = Top + LineCount*LineHeight; // + BoxTextOffsetY;

    if ( TeamPRIArray.length > 0 && TeamPRIArray[0].Team != none )
        Canvas.DrawColor = TeamPRIArray[0].Team.TeamColor;

    if ( TotalDeaths > 0) {
        S = string(TotalDeaths);
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(DeathsXPos - XL/2, y);
        Canvas.DrawTextClipped(S);
    }
    if ( TotalKills > 0 ) {
        Canvas.TextSize(TotalKills, XL, YL);
        Canvas.SetPos(KillsXPos - XL, y);
        Canvas.DrawTextClipped(TotalKills);
        Canvas.DrawColor = HUDClass.default.WhiteColor;
    }
    if ( TotalAss > 0) {
        Canvas.DrawColor = AssColor;
        Canvas.SetPos(KillsXPos, y);
        Canvas.DrawTextClipped(KillsAssSeparator $ TotalAss);
        Canvas.DrawColor = HUDClass.default.WhiteColor;
    }

    Canvas.DrawColor = HUDClass.default.WhiteColor;
}

simulated event UpdateScoreBoard(Canvas Canvas)
{
    local TSCGameReplicationInfo TSCGRRI;
    local PlayerReplicationInfo PRI, OwnerPRI;
    local KFPlayerReplicationInfo KFPRI;
    local int i, fi, FontReduction, HeaderOffsetY, PlayerBoxSizeY;
    local int RedBoxXPos, RedBoxWidth, BlueBoxXpos, BlueBoxWidth;
    local float XL,YL;
    local int MyTeamIndex;
    local int AliveCount, SpecCount, DisplayedCount;
    local array<PlayerReplicationInfo> RedTeamPRIArray, BlueTeamPRIArray;
    local String S;
    local byte HumanDamageMode;
    local String Spectators;

    TSCGRRI = TSCGameReplicationInfo(GRI);
    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
    if ( OwnerPRI != none && OwnerPRI.Team != none )
        MyTeamIndex = OwnerPRI.Team.TeamIndex;
    else
        MyTeamIndex = -1;

    for ( i = 0; i < GRI.PRIArray.Length; i++)
    {
        PRI = GRI.PRIArray[i];
        KFPRI = KFPlayerReplicationInfo(PRI);
        if ( PRI != none ) {
            if ( !PRI.bOnlySpectator && PRI.Team != none )
            {
                if( !PRI.bOutOfLives && KFPRI != none && KFPRI.PlayerHealth>0 )
                    ++AliveCount;

                if ( PRI.Team.TeamIndex == 0 )
                    RedTeamPRIArray[RedTeamPRIArray.Length] = PRI;
                else if ( PRI.Team.TeamIndex == 1 )
                    BlueTeamPRIArray[BlueTeamPRIArray.Length] = PRI;
            }
            else if ( PRI.PlayerID != 0 || PRI.PlayerName != "WebAdmin" ) {
                ++SpecCount;
                Spectators @= class'ScrnBalance'.default.Mut.StripColorTags(PRI.PlayerName) $ " |";
            }
        }
    }
    DisplayedCount = max(RedTeamPRIArray.Length, BlueTeamPRIArray.Length);

    if ( TSCGRRI != none )
        HumanDamageMode = TSCGRRI.HumanDamageMode;
    else
        HumanDamageMode = 3; // Normal, just in case

    Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);
    if ( OwnerPRI.Team != none )
        Canvas.DrawColor = OwnerPRI.Team.TeamColor;
    else
        Canvas.DrawColor = HUDClass.default.RedColor;
    Canvas.Style = ERenderStyle.STY_Normal;
    HeaderOffsetY = Canvas.ClipY * 0.11;

    // "Zeroth", Draw game name :)
    S = GRI.GameName;
    Canvas.TextSize(S, XL,YL);
    Canvas.SetPos( (Canvas.ClipX - XL)/2, HeaderOffsetY - YL);
    Canvas.DrawTextClipped(S);

    // First, draw title.
    if ( HumanDamageMode != 3 )
        S = HDmgNames[HumanDamageMode] $ " | ";
    else
        S = "";
    S $= SkillLevel[Clamp(InvasionGameReplicationInfo(GRI).BaseDifficulty, 0, 7)]  $ " | HL="$string(class'ScrnBalance'.default.Mut.HardcoreLevel)
            $ " | " $ WaveString @ string(InvasionGameReplicationInfo(GRI).WaveNumber + 1)$"/"$string(InvasionGameReplicationInfo(GRI).FinalWave)
            $ " | " $ Level.Title $ " | " $ FormatTime(GRI.ElapsedTime);
    if ( TSCGRRI != none && !TSCGRRI.bStopCountDown ) {
        S $= " | " $ SuicideTimeText @ FormatTime(TSCGRRI.RemainingTime);
    }
    Canvas.TextSize(S, XL,YL);
    Canvas.SetPos(0.5 * (Canvas.ClipX - XL), HeaderOffsetY);
    Canvas.DrawTextClipped(S);

    // Second title line
    S = PlayerCountText@RedTeamPRIArray.Length;
    if ( HumanDamageMode == 0 )
        S $= "+";
    else if ( HumanDamageMode <= 3 )
        S $= "x";
    else
        S $= "vs";
    S $= BlueTeamPRIArray.Length;
    if ( SpecCount > 0 ) {
        S @= SpectatorCountText @ SpecCount;
    }
    S @= AliveCountText @ AliveCount;
    if ( OwnerPRI != none && OwnerPRI.Team != none )
        S @= "|" @ TeamScoreString;
    Canvas.TextSize(S, XL,YL);
    HeaderOffsetY+=YL;
    Canvas.SetPos(0.5 * (Canvas.ClipX - XL), HeaderOffsetY);
    Canvas.DrawTextClipped(S);
    if ( OwnerPRI != none && OwnerPRI.Team != none ) {
        Canvas.DrawColor = DoshColor;
        S = " " $ class'ScrnUnicode'.default.Dosh $ int(OwnerPRI.Team.Score);
        Canvas.SetPos(0.5 * (Canvas.ClipX + XL), HeaderOffsetY);
        Canvas.DrawTextClipped(S);
    }


    HeaderOffsetY+=(YL*3.f);

    // Select best font size and box size to fit as many players as possible on screen
    if ( Canvas.ClipX < 800 )
        fi = 4;
    else if ( Canvas.ClipX < 1000 )
        fi = 3;
    else if ( Canvas.ClipX < 1300 )
        fi = 2;
    else
        fi = 1;

    Canvas.Font = class'ROHud'.static.LoadMenuFontStatic(fi);
    Canvas.TextSize("Test", XL, YL);
    PlayerBoxSizeY = 1.4 * YL;

    DisplayedCount = max(DisplayedCount, 6);
    while( (PlayerBoxSizeY*DisplayedCount)>(Canvas.ClipY-HeaderOffsetY) )
    {
        if( ++fi>=5 || ++FontReduction>=3 ) // Shrink font, if too small then break loop.
        {
            // We need to remove some player names here to make it fit.
            DisplayedCount = int((Canvas.ClipY-HeaderOffsetY)/PlayerBoxSizeY)+1;
            break;
        }
        Canvas.Font = class'ROHud'.static.LoadMenuFontStatic(fi);
        Canvas.TextSize("Test", XL, YL);
        PlayerBoxSizeY = 1.2 * YL;
    }

    RedBoxWidth = 0.98 * Canvas.ClipX;
    RedBoxXPos = (Canvas.ClipX - RedBoxWidth)/2;
    if ( MyTeamIndex == 0 )
        BlueBoxWidth = RedBoxWidth * 0.40;
    else if ( MyTeamIndex == 1 )
        BlueBoxWidth = RedBoxWidth * 0.60;
    else
        BlueBoxWidth = RedBoxWidth/2;
    RedBoxWidth -= BlueBoxWidth;
    BlueBoxXPos = RedBoxXPos + RedBoxWidth;

    Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
    Canvas.DrawColor.A = 160;
    Canvas.Style = ERenderStyle.STY_Alpha;
    // TSC LOGO (1024x64)
    XL = Canvas.ClipX*0.5;
    YL = XL/16;
    Canvas.SetPos((Canvas.ClipX-XL)/2, 0);
    Canvas.DrawTile(GameLogo, XL, YL, 0, 0, GameLogo.MaterialUSize(), GameLogo.MaterialVSize());

    // Team Logos
    Canvas.DrawColor.A = 100;
    XL = fmin(Canvas.ClipX * 0.25, PlayerBoxSizeY*DisplayedCount - 4);
    YL = fmax((PlayerBoxSizeY*DisplayedCount-XL)/2, 2);
    Canvas.SetPos(RedBoxXPos+(RedBoxWidth-XL)/2, HeaderOffsetY + YL);
    Canvas.DrawTile(RedLogo, XL, XL, 0, 0, RedLogo.MaterialUSize(), RedLogo.MaterialVSize());

    Canvas.SetPos(BlueBoxXPos + (BlueBoxWidth-XL)/2, HeaderOffsetY + YL);
    Canvas.DrawTile(BlueLogo, XL, XL, 0, 0, BlueLogo.MaterialUSize(), BlueLogo.MaterialVSize());

    DrawTeam(canvas, RedTeamPRIArray, RedBoxXPos, HeaderOffsetY, RedBoxWidth, PlayerBoxSizeY, DisplayedCount, MyTeamIndex == 0, RedBG[0], RedBG[1]);
    DrawTeam(canvas, BlueTeamPRIArray, BlueBoxXPos, HeaderOffsetY, BlueBoxWidth, PlayerBoxSizeY, DisplayedCount, MyTeamIndex == 1, BlueBG[0], BlueBG[1]);

    if ( Spectators != "" )
    {
        Canvas.Font = class'ROHud'.static.LoadMenuFontStatic( min(8, fi+2) );
        Canvas.DrawColor = Class'HudBase'.Default.GrayColor;
        Canvas.SetPos(RedBoxXPos, HeaderOffsetY + PlayerBoxSizeY*DisplayedCount + PlayerBoxSizeY*0.5 );
        Canvas.DrawText(SpectatorsText $ ": |" $ Spectators, true);
    }
}

defaultproperties
{
    RedBG(0)=(R=128,G=64,B=64,A=200)
    RedBG(1)=(R=160,G=64,B=64,A=200)
    BlueBG(0)=(R=64,G=64,B=128,A=200)
    BlueBG(1)=(R=64,G=64,B=160,A=200)

    KillsAssSeparator="+"
    RedLogo=Texture'TSC_T.Team.BritishLogo'
    BlueLogo=Texture'TSC_T.Team.SteampunkLogo'
    GameLogo=Texture'TSC_T.Team.TSC'
    DeathIcon=Texture'TSC_T.SpecHUD.Skull64'

    BoxMaterial=Texture'TSC_T.HUD.TransparentBox'

    CptIcon=Texture'TSC_T.Team.IconC'
    CptAssIcon=Texture'TSC_T.Team.IconA'

    OutText="DEAD"
    ReadyText="READY"
    NotReadyText="N/RDY"
    HealthyString="hp"

    HDmgNames(0)="No Human Damage"
    HDmgNames(1)="No Friendly Fire"
    HDmgNames(2)="PvP+NoFF"
    HDmgNames(3)="Normal"
    HDmgNames(4)="PvP Mode"
    HDmgNames(5)="Full Human Damage"
}
