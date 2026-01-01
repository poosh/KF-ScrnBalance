class ScrnScoreBoard extends SRScoreBoard;

var     localized   string      AssHeaderText;
var     localized   string      KillsAssSeparator;
var     localized   string      strPingMax;
var     localized   string      SpectatorsText;
var     localized   string      SuicideTimeText;
var     localized   string      TotalText;
var     localized   string      DamageText;
var     localized   string      HealText;

var Material AdminIcon, BlameIcon, BigBlameIcon, DeathIcon;
var Material WhiteMaterial;

var color AssColor, DoshColor, BestColor, DeadColor;

var transient float BoxWidth, BoxX;
var transient float VetX, NameX, KillsX, DamageX, HealX, DeathsX, CashX, HealthX, TimeX, NetX;
var transient float StoryIconXPos, StoryIconS;

var int PlayerFontIndex;

var transient float OldClipX, OldClipY;
var transient float BoxHeight, BoxSpaceY;

// SE - because DrawCountryName() is final :(
static function float DrawCountryNameSE( Canvas C, PlayerReplicationInfo PRI, float X, float Y,
    optional byte MaxLen, optional bool bNoColorTags )
{
    local float NameWidth,IconSize,Offset;
    local Color OriginalColor;
    local string S;
    local ScrnCustomPRI ScrnPRI;
    local Material M;

    OriginalColor = C.DrawColor;
    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PRI);
    if ( bNoColorTags )
        S = class'ScrnFunctions'.static.StripColorTags(PRI.PlayerName);
    else
        S = class'ScrnBalance'.default.Mut.ColoredPlayerName(PRI);

    if( MaxLen>0 )
        S = class'ScrnFunctions'.static.LeftCol(S, MaxLen);

    C.DrawColor = Class'HudBase'.Default.WhiteColor;
    C.DrawColor.A = OriginalColor.A;
    C.TextSize(S,NameWidth,IconSize);
    Offset = DrawNamePrefixIcons(C, PRI, ScrnPRI, S, X, Y, IconSize);
    C.TextSize(class'ScrnFunctions'.static.StripColor(S),NameWidth,IconSize);

    if ( ScrnPRI != none ) {

        M = ScrnPRI.GetPreNameIcon();
        if ( M != none ) {
            if ( ScrnPRI.PrefixIconColor.A == 0 && KFPlayerReplicationInfo(PRI) != none )
                C.DrawColor = class'ScrnHUD'.static.PerkColor(KFPlayerReplicationInfo(PRI).ClientVeteranSkillLevel);
            else if ( ScrnPRI.PrefixIconColor.A == 1 && PRI.Team != none && PRI.Team.TeamIndex < 2 )
                C.DrawColor = class'ScrnHUD'.default.TextColors[PRI.Team.TeamIndex];
            else
                C.DrawColor = ScrnPRI.PrefixIconColor;
            C.DrawColor.A = OriginalColor.A;

            C.SetPos(X+Offset, Y);
            C.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
            Offset += IconSize * 1.1;
        }
    }
    // name
    if ( C.Style != ERenderStyle.STY_None ) {
        C.DrawColor = OriginalColor;
        C.SetPos(X + Offset, Y);
        C.DrawTextClipped(S,false);
    }
    Offset += NameWidth;

    if ( ScrnPRI != none ) {
        M = ScrnPRI.GetPostNameIcon();
        if ( M != none ) {
            if ( ScrnPRI.PostfixIconColor.A == 0 && KFPlayerReplicationInfo(PRI) != none )
                C.DrawColor = class'ScrnHUD'.static.PerkColor(KFPlayerReplicationInfo(PRI).ClientVeteranSkillLevel);
            else if ( ScrnPRI.PostfixIconColor.A == 1 && PRI.Team != none && PRI.Team.TeamIndex < 2 )
                C.DrawColor = class'ScrnHUD'.default.TextColors[PRI.Team.TeamIndex];
            else
                C.DrawColor = ScrnPRI.PostfixIconColor;
            C.DrawColor.A = OriginalColor.A;

            Offset += IconSize * 0.1;
            C.SetPos(X+Offset, Y);
            C.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
            Offset += IconSize*1.2;
        }
    }
    C.DrawColor = Class'HudBase'.Default.WhiteColor;
    C.DrawColor.A = OriginalColor.A;
    Offset += DrawNamePostfixIcons(C, PRI, ScrnPRI, S, X + Offset, Y, IconSize);

    C.DrawColor = OriginalColor;
    return Offset;
}

static function TextSizeCountrySE( Canvas C, PlayerReplicationInfo PRI, out float XL, out float YL )
{
    local byte OriginalStyle;

    C.TextSize("ABC",XL,YL);
    OriginalStyle = C.Style;
    C.Style = ERenderStyle.STY_None;
    XL = DrawCountryNameSE(C, PRI, 0, 0, 0, true);
    C.Style = OriginalStyle;
}



/*
 * Draws additional Icons (materials) before player's name
 * @param [in/out]  PlayerName text of player name to be drawn
 * @param X, Y      coordinates of Top Left corner, where icons should be started to draw
 * @param IconSize  prefered size of the square icon.
 * @return Total witdh of the all drawn icons, i.e. X + return value = left coord of player's name
 */
static function float DrawNamePrefixIcons(Canvas C, PlayerReplicationInfo PRI, ScrnCustomPRI ScrnPRI, out String PlayerName,
    float X, float Y, float IconSize)
{
    local Material M;
    local int pos;
    local float OriginalX;

    OriginalX = X;
    // country tags
    if( Mid(PlayerName,0,1)=="[" ) {
        if ( Mid(PlayerName,3,1)=="]" )
            pos = 3;
        else if ( Mid(PlayerName,4,1)=="]" )
            pos = 4;

        if ( pos > 0 ) {
            if ( Mid(PlayerName,1,pos-1) == "EU" ) {
                M = Texture'ScrnTex.HUD.EU';
                PRI.Skins[0] = M;
            }
            else
                M = GetCountryFlag(PRI);
            if ( M != none || Mid(PlayerName,1,pos-1) == "???" ) {
                PlayerName = Mid(PlayerName,pos+1);
                if ( Mid(PlayerName,0,1) == " " || Mid(PlayerName,0,1) == "_")
                    PlayerName = Mid(PlayerName, 1); // remove leading space
            }
        }
    }
    if( M!=None ) {
        C.SetPos(X, Y + IconSize*0.2);
        C.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
        X += IconSize * 1.2;
    }

    // Display admin.
    if( PRI.bAdmin )
    {
        M = default.AdminIcon;
        C.SetPos(X, Y);
        C.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
        X += IconSize * 1.1;
    }

    return X-OriginalX;
}


// Function can be used to draw additional Icons at the end of player's name
// PlainPlayerName doesn't have
static function float DrawNamePostfixIcons(Canvas C, PlayerReplicationInfo PRI, ScrnCustomPRI ScrnPRI, String PlainPlayerName,
    float X, float Y, float IconSize)
{
    local int i, count;
    local float OriginalX;
    local Material M;

    OriginalX = X;
    if ( ScrnPRI != none ) {
        if ( ScrnPRI.GetPlayoffCount() > 0 ) {
            X += IconSize * 0.1;
            count = ScrnPRI.GetTourneyWinCount();
            for ( i = ScrnPRI.GetPlayoffCount(); i>0; --i ) {
                if ( count > 0 ) {
                    M = Texture'ScrnTex.Tourney.TSC_Name_IconW';
                    count--;
                }
                else
                    M = Texture'ScrnTex.Tourney.TSC_Name_Icon';
                C.SetPos(X, Y);
                C.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
                X += IconSize;
            }
            X += IconSize * 0.1;
        }
        if ( ScrnPRI.BlameCounter > 0 ) {
            count = ScrnPRI.BlameCounter;
            while ( count > 0 ) {
                if ( count >= 5 ) {
                    M = default.BigBlameIcon;
                    count -= 5;
                }
                else {
                    M = default.BlameIcon;
                    count--;
                }
                C.SetPos(X, Y);
                C.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
                X += IconSize;
            }
        }
    }
    return X-OriginalX;
}

simulated function ResolutionChanged(Canvas Canvas)
{
    local float XL, YL, X0, M;

    if ( Canvas.ClipX < 600 )
        PlayerFontIndex = 4;
    else if ( Canvas.ClipX < 800 )
        PlayerFontIndex = 3;
    else if ( Canvas.ClipX < 1300 )
        PlayerFontIndex = 2;
    else if ( Canvas.ClipX < 1900 )
        PlayerFontIndex = 1;
    else
        PlayerFontIndex = 0;

    if (Canvas.ClipX < 1200)
        BoxWidth = 0.99;
    else if (Canvas.ClipX < 1900)
        BoxWidth = 0.90;
    else if (Canvas.ClipX < 2500)
        BoxWidth = 0.80;
    else if (Canvas.ClipX < 3800)
        BoxWidth = 0.65;
    else
        BoxWidth = 0.50;
    BoxWidth *= Canvas.ClipX;
    BoxX = (Canvas.ClipX - BoxWidth) / 2;

    Canvas.Font = class'ScrnHUD'.static.LoadMenuFontStatic(PlayerFontIndex);
    Canvas.TextSize("0", X0, YL);
    BoxHeight = 1.2 * YL;
    BoxSpaceY = 0.25 * YL;

    if (Canvas.ClipX > 3000)
        M = X0 * 4.0;
    else if (Canvas.ClipX > 2000)
        M = X0 * 2.0;
    else
        M = X0;

    HealthX = BoxX + M;
    VetX = HealthX + M + 6*X0;
    NameX = VetX + BoxHeight * 1.75;

    NetX = BoxX + BoxWidth - M;
    Canvas.TextSize("00:00:00", XL, YL);
    TimeX = NetX - 4*X0 - M - XL/2;

    DeathsX = TimeX - XL/2 - M - X0;
    HealX = DeathsX - M - X0; // right align
    DamageX = HealX - M - 4*X0;

    Canvas.TextSize(KillsAssSeparator $ "9999", XL, YL);
    KillsX = DamageX - M - 6*X0 - XL;

    CashX = KillsX - M - 9*X0;

    StoryIconS = BoxHeight - 2;
    StoryIconXPos = CashX - M - 3*X0 - StoryIconS;
}

simulated event UpdateScoreBoard(Canvas Canvas)
{
    local PlayerReplicationInfo PRI, OwnerPRI;
    local KFPlayerReplicationInfo KFPRI;
    local ScrnCustomPRI ScrnPRI;
    local KF_StoryPRI StoryPRI;
    local ScrnGameReplicationInfo ScrnGRI;
    local int i, FontReduction, PlayerCount, SpecCount, AliveCount, HeaderOffsetY, HeadFoot, MessageFoot,BoxTextOffsetY,
            TitleYPos, NotShownCount;
    local float XL,YL, y;
    local float deathsXL, KillsXL, NetXL, MaxNamePos, KillWidthX;
    local Material VeterancyBox,StarBox;
    local string S;
    local byte Stars;
    local KF_StoryObjective CurrentObj;
    local array<PlayerReplicationInfo> TeamPRIArray;
    local bool bStoryMode;
    local material StoryIcon;
    local String Spectators;
    local int TotalKills, TotalDeaths, TotalCash;
    local int LineHeight;
    local int MaxKills, MaxAss, MaxDamage, MaxHeals, MaxDeaths;

    if (OldClipX != Canvas.ClipX || OldClipY != Canvas.ClipY) {
        ResolutionChanged(Canvas);
        OldClipX = Canvas.ClipX;
        OldClipY = Canvas.ClipY;
    }

    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
    bStoryMode = KF_StoryPRI(OwnerPRI) != none;
    ScrnGRI = ScrnGameReplicationInfo(GRI);

    for ( i = 0; i < GRI.PRIArray.Length; i++) {
        PRI = GRI.PRIArray[i];
        KFPRI = KFPlayerReplicationInfo(PRI);
        ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PRI);
        if (!PRI.bOnlySpectator) {
            if( !PRI.bOutOfLives && KFPRI != none && KFPRI.PlayerHealth > 0 )
                ++AliveCount;
            PlayerCount++;
            TeamPRIArray[TeamPRIArray.Length] = PRI;
            MaxKills = max(MaxKills, KFPRI.Kills);
            MaxAss =  max(MaxAss, KFPRI.KillAssists);
            MaxDeaths =  max(MaxDeaths, KFPRI.Deaths);
            if (ScrnPRI != none) {
                MaxDamage = max(MaxDamage, ScrnPRI.TotalDamageK);
                MaxHeals = max(MaxHeals, ScrnPRI.TotalHeal);
            }
        }
        else if ( PRI.PlayerID != 0 || PRI.PlayerName != "WebAdmin" ) {
            ++SpecCount;
            Spectators @= class'ScrnFunctions'.static.StripColorTags(PRI.PlayerName) $ " |";
        }
    }

    Canvas.Font = class'ScrnHUD'.static.GetSmallMenuFont(Canvas);
    Canvas.DrawColor = HUDClass.default.RedColor;
    Canvas.Style = ERenderStyle.STY_Normal;
    HeaderOffsetY = Canvas.ClipY * 0.11;

    // "Zeroth", Draw game name :)
    S = GRI.GameName;
    if ( ScrnGRI != none ) {
        if ( ScrnGRI.GameTitle != "" ) {
            S $= ": " $ ScrnGRI.GameTitle;
            if ( ScrnGRI.GameVersion > 0 ) {
                s @= class'ScrnF'.static.VersionStr(ScrnGRI.GameVersion);
            }
        }
        if (ScrnGRI.WaveTitle != "" && ScrnGRI.WaveTitle != " ")
            S $= " | " $ class'ScrnF'.static.StripColor(ScrnGRI.WaveTitle);
        if (ScrnGRI.WaveMessage != "" && ScrnGRI.WaveMessage != " ")
            S $= " | " $ class'ScrnF'.static.StripColor(ScrnGRI.WaveMessage);
    }
    Canvas.TextSize(S, XL,YL);
    Canvas.SetPos( (Canvas.ClipX - XL)/2, HeaderOffsetY - YL);
    Canvas.DrawTextClipped(S);

    // First, draw title.
    if(KF_StoryGRI(GRI) != none) {
        CurrentObj = KF_StoryGRI(GRI).GetCurrentObjective();
        if(CurrentObj != none)
            S = CurrentObj.HUD_Header.Header_Text;
    }
    else {
        S = WaveString @ (InvasionGameReplicationInfo(GRI).WaveNumber + 1)$"/"$string(InvasionGameReplicationInfo(GRI).FinalWave);
    }
    S = SkillLevel[Clamp(InvasionGameReplicationInfo(GRI).BaseDifficulty, 0, 7)]
        $ " | HL="$string(class'ScrnBalance'.default.Mut.HardcoreLevel)
        $ " | " $ S $ " | " $ Level.Title $ " | " $ FormatTime(GRI.ElapsedTime);
    if ( ScrnGRI != none && !ScrnGRI.bStopCountDown ) {
        S $= " | " $ SuicideTimeText @ FormatTime(ScrnGRI.RemainingTime);
    }

    Canvas.TextSize(S, XL,YL);
    Canvas.SetPos( (Canvas.ClipX - XL)/2, HeaderOffsetY );
    Canvas.DrawTextClipped(S);

    // Second title line
    S = PlayerCountText @ PlayerCount;
    if ( SpecCount > 0 ) {
        S @= SpectatorCountText @ SpecCount;
    }
    S @= AliveCountText @ AliveCount;
    if ( ScrnGRI != none && ScrnGRI.FakedAlivePlayers > AliveCount ) {
        S $= " ("$ScrnGRI.FakedAlivePlayers$")";
    }
    if ( OwnerPRI != none && OwnerPRI.Team != none )
        S @= "|" @ TeamScoreString;
    Canvas.TextSize(S, XL,YL);
    HeaderOffsetY+=YL;
    Canvas.SetPos(0.5 * (Canvas.ClipX - XL), HeaderOffsetY);
    Canvas.DrawTextClipped(S);
    if ( OwnerPRI != none && OwnerPRI.Team != none ) {
        Canvas.DrawColor = DoshColor;
        TotalCash = OwnerPRI.Team.Score;
        S = " " $ class'ScrnUnicode'.default.Dosh $ TotalCash;
        Canvas.SetPos(0.5 * (Canvas.ClipX + XL), HeaderOffsetY);
        Canvas.DrawTextClipped(S);
    }
    HeaderOffsetY+=(YL*3.f);

    Canvas.Font = class'ScrnHUD'.static.LoadMenuFontStatic(PlayerFontIndex);
    while ((BoxHeight + BoxSpaceY) * PlayerCount > Canvas.ClipY - HeaderOffsetY) {
        // Shrink font, if too small then break loop.
        if (PlayerFontIndex + FontReduction >= 4) {
            // We need to remove some player names here to make it fit.
            NotShownCount = PlayerCount - int((Canvas.ClipY - HeaderOffsetY) / (BoxHeight + BoxSpaceY)) + 1;
            PlayerCount -= NotShownCount;
            break;
        }
        ++FontReduction;
        Canvas.Font = class'ScrnHUD'.static.LoadMenuFontStatic(PlayerFontIndex + FontReduction);
        Canvas.TextSize("Test", XL, YL);
        BoxHeight = 1.2 * YL;
        BoxSpaceY = 4;
    }

    HeadFoot = 7 * YL;
    MessageFoot = 1.5 * HeadFoot;

    // draw background boxes
    Canvas.Style = ERenderStyle.STY_Alpha;
    for (i = 0; i < PlayerCount; ++i) {
        Canvas.DrawColor = HUDClass.default.WhiteColor;
        Canvas.DrawColor.A = 128;
        Canvas.SetPos(BoxX, HeaderOffsetY + (BoxHeight + BoxSpaceY) * i);
        Canvas.DrawTileStretched( BoxMaterial, BoxWidth, BoxHeight);

        // highlight myself
        if ( TeamPRIArray[i] == OwnerPRI ) {
            Canvas.SetDrawColor(0, 255, 0, 48);
            Canvas.SetPos(BoxX + 1, HeaderOffsetY + (BoxHeight + BoxSpaceY) * i + 1);
            Canvas.DrawTileStretched( WhiteMaterial, BoxWidth-2, BoxHeight-2);
        }
    }

    if (NotShownCount > 0) {
        Canvas.DrawColor = HUDClass.default.RedColor;
        Canvas.SetPos(BoxX, HeaderOffsetY + (BoxHeight + BoxSpaceY) * PlayerCount);
        Canvas.DrawTileStretched( BoxMaterial, BoxWidth, BoxHeight);
    }

    // Draw headers
    TitleYPos = HeaderOffsetY - 1.1 * YL;
    Canvas.TextSize(DeathsText, DeathsXL, YL);
    Canvas.TextSize(KillsText, KillsXL, YL);
    Canvas.TextSize(NetText, NetXL, YL);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(NameX, TitleYPos);
    Canvas.DrawTextClipped(PlayerText);

    Canvas.SetPos(KillsX - KillsXL, TitleYPos);
    Canvas.DrawTextClipped(KillsText);
    Canvas.SetPos(KillsX, TitleYPos);
    Canvas.DrawColor = AssColor;
    Canvas.DrawTextClipped(KillsAssSeparator $ AssHeaderText);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.TextSize(DamageText, XL, YL);
    Canvas.SetPos(DamageX - XL, TitleYPos);
    Canvas.DrawTextClipped(DamageText);

    Canvas.TextSize(HealText, XL, YL);
    Canvas.SetPos(HealX - XL, TitleYPos);
    Canvas.DrawTextClipped(HealText);

    // death icon
    Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(DeathsX - BoxHeight/2, TitleYPos);
    Canvas.DrawTile(DeathIcon, BoxHeight, BoxHeight, 0, 0, DeathIcon.MaterialUSize(), DeathIcon.MaterialVSize());
    Canvas.Style = ERenderStyle.STY_Normal;


    Canvas.TextSize(PointsText, XL, YL);
    Canvas.SetPos(CashX - 0.5 * XL, TitleYPos);
    Canvas.DrawTextClipped(PointsText);

    Canvas.TextSize(TimeText, XL, YL);
    Canvas.SetPos(TimeX - 0.5 * XL, TitleYPos);
    Canvas.DrawTextClipped(TimeText);

    Canvas.SetPos(HealthX, TitleYPos);
    Canvas.DrawTextClipped(HealthText);

    Canvas.Style = ERenderStyle.STY_Normal;
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(0.5 * Canvas.ClipX, HeaderOffsetY + 4);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(NetX - NetXL, TitleYPos);
    Canvas.DrawTextClipped(NetText);

    BoxTextOffsetY = HeaderOffsetY + 0.5 * (BoxHeight - YL);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    MaxNamePos = Canvas.ClipX;
    Canvas.ClipX = StoryIconXPos - StoryIconS;
    for (i = 0; i < PlayerCount; ++i) {
        PRI = TeamPRIArray[i]; // For some reasons, GRI.PRIArray[i] has WebAdmin in Story Mode
        // draw myself in green, admins - red, others - white  -- PooSH
        if ( PRI.bAdmin )
            Canvas.DrawColor = Class'HudBase'.Default.RedColor;
        else
            Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
        DrawCountryNameSE(Canvas, PRI, NameX, (BoxHeight + BoxSpaceY)*i + BoxTextOffsetY);
    }
    Canvas.ClipX = MaxNamePos;
    Canvas.DrawColor = HUDClass.default.WhiteColor;

    Canvas.Style = ERenderStyle.STY_Normal;

    // Draw the player information
    LineHeight = BoxHeight + BoxSpaceY;
    y = BoxTextOffsetY;
    for (i = 0; i < PlayerCount; ++i) {
        //PRI = GRI.PRIArray[i];
        PRI = TeamPRIArray[i]; // For some reasons, GRI.PRIArray[i] has WebAdmin in Story Mode
        KFPRI = KFPlayerReplicationInfo(PRI);
        StoryPRI = KF_StoryPRI(PRI);
        ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PRI);

        Canvas.DrawColor = HUDClass.default.WhiteColor;
        // display Story Icon
        if ( StoryPRI != none ){
            StoryIcon = StoryPRI.GetFloatingIconMat();
            if ( StoryIcon != none ) {
                Canvas.SetPos(StoryIconXPos - StoryIconS * 0.5, y + 1 );
                Canvas.DrawTile(StoryIcon, StoryIconS, StoryIconS, 0, 0, StoryIcon.MaterialUSize(), StoryIcon.MaterialVSize());
            }
        }

        // Display perks.
        if (KFPRI!=None && Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill)!=none) {
            Stars = Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill).Static.PreDrawPerk(Canvas,
                    KFPRI.ClientVeteranSkillLevel, VeterancyBox, StarBox);

            if (VeterancyBox != None)
                DrawPerkWithStars(Canvas, VetX, HeaderOffsetY + (BoxHeight + BoxSpaceY) * i, BoxHeight,
                        min(Stars, 25), VeterancyBox, StarBox);
        }

        // draw kills
        if (KFPRI.Kills == MaxKills && MaxKills > 0 && PlayerCount > 1) {
            Canvas.DrawColor = BestColor;
        }
        else {
            Canvas.DrawColor = HUDClass.default.WhiteColor;
        }
        TotalKills += KFPRI.Kills;
        Canvas.TextSize(KFPRI.Kills, KillWidthX, YL);
        Canvas.SetPos(KillsX - KillWidthX, y);
        Canvas.DrawTextClipped(KFPRI.Kills);

        // draw Assists  -- PooSH
        if (KFPRI.KillAssists > 0) {
            Canvas.DrawColor = AssColor;
            Canvas.SetPos(KillsX, y);
            Canvas.TextSize(KillsAssSeparator, XL, YL);
            Canvas.DrawTextClipped(KillsAssSeparator);
            Canvas.SetPos(KillsX + XL, y);
            if (KFPRI.KillAssists == MaxAss && PlayerCount > 1) {
                Canvas.DrawColor = BestColor;
            }
            Canvas.DrawTextClipped(KFPRI.KillAssists);
        }

        if (ScrnPRI != none) {
            if (ScrnPRI.TotalDamageK > 0) {
                if (ScrnPRI.TotalDamageK == MaxDamage && PlayerCount > 1) {
                    Canvas.DrawColor = BestColor;
                }
                else {
                    Canvas.DrawColor = HUDClass.default.WhiteColor;
                }
                S = ScrnPRI.TotalDamageK $ "k";
                Canvas.TextSize(S, XL, YL);
                Canvas.SetPos(DamageX - XL, y);
                Canvas.DrawTextClipped(S);
            }
            if (ScrnPRI.TotalHeal > 0) {
                if (ScrnPRI.TotalHeal == MaxHeals  && PlayerCount > 1) {
                    Canvas.DrawColor = BestColor;
                }
                else {
                    Canvas.DrawColor = HUDClass.default.WhiteColor;
                }
                S = string(ScrnPRI.TotalHeal);
                Canvas.TextSize(S, XL, YL);
                Canvas.SetPos(HealX - XL, y);
                Canvas.DrawTextClipped(S);
            }
        }

        // deaths
        if (PRI.Deaths > 0) {
            if (PRI.Deaths == MaxDeaths) {
                Canvas.DrawColor = HUDClass.default.RedColor;
            }
            else {
                Canvas.DrawColor = HUDClass.default.WhiteColor;
            }
            TotalDeaths += PRI.Deaths;
            S = string(int(PRI.Deaths));
            Canvas.TextSize(S, XL, YL);
            Canvas.SetPos(DeathsX - XL/2, y);
            Canvas.DrawTextClipped(S);
        }

        // draw cash
        if (int(PRI.Score) != 0) {
            TotalCash += PRI.Score;
            S = class'ScrnUnicode'.default.Dosh $ int(PRI.Score);
            Canvas.TextSize(S, XL, YL);
            Canvas.SetPos(CashX-XL*0.5f, y);
            Canvas.DrawColor = DoshColor;
            Canvas.DrawText(S,true);
        }

        // draw play time
        Canvas.DrawColor = HUDClass.default.WhiteColor;
        if (GRI.ElapsedTime<PRI.StartTime) // Login timer error, fix it.
            GRI.ElapsedTime = PRI.StartTime;
        S = FormatTime(GRI.ElapsedTime-PRI.StartTime);
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(TimeX - XL*0.5f, y);
        Canvas.DrawText(S, true);

        // Draw ping
        Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
        if (PRI.bBot) {
            S = BotText;
        }
        else if (PRI.Ping == 255) {
            Canvas.DrawColor = HUDClass.default.RedColor;
            S = strPingMax;
        }
        else {
            S = string(PRI.Ping*4);
            if (PRI.Ping >= 50) // *4 = 200
                Canvas.DrawColor = HUDClass.default.RedColor;
            else if ( PRI.Ping >= 25 ) // *4 = 100
                Canvas.DrawColor = HUDClass.default.GoldColor;
        }
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(NetX-XL, y);
        Canvas.DrawTextClipped(S);
        Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;

        // draw health or ready status
        if (!GRI.bMatchHasBegun) {
            if (PRI.bReadyToPlay) {
                Canvas.DrawColor = HUDClass.default.WhiteColor;
                S = ReadyText;
            }
            else {
                Canvas.DrawColor = DeadColor;
                S = NotReadyText;
            }
        }
        else if (PRI.bOutOfLives || KFPRI.PlayerHealth<=0) {
            Canvas.DrawColor = DeadColor;
            S = OutText;
        }
        else {
            S = KFPRI.PlayerHealth @ HealthyString;
            if (KFPRI.PlayerHealth >= 90) {
                Canvas.DrawColor = HUDClass.default.GreenColor;
                if (KFPRI.PlayerHealth >= 1000) {
                    S = string(KFPRI.PlayerHealth); // WTF?
                }
            }
            else if (KFPRI.PlayerHealth >= 50) {
                Canvas.DrawColor = HUDClass.default.GoldColor;
            }
            else {
                Canvas.DrawColor = HUDClass.default.RedColor;
            }
        }
        Canvas.SetPos(HealthX, y);
        Canvas.DrawTextClipped(S);

        y += LineHeight;
    }

    y -= BoxSpaceY;
    // totals
    if (NotShownCount == 0) {
        Canvas.Font = class'ScrnHUD'.static.LoadMenuFontStatic(PlayerFontIndex + FontReduction + 1);
        Canvas.DrawColor = HUDClass.default.WhiteColor;

        Canvas.SetPos(NameX, y);
        Canvas.DrawTextClipped(TotalText);
        // DOSH
        S = class'ScrnUnicode'.default.Dosh $ TotalCash;
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(CashX - XL/2, y);
        Canvas.DrawTextClipped(S);
        if ( TotalDeaths > 0) {
            S = string(TotalDeaths);
            Canvas.TextSize(S, XL, YL);
            Canvas.SetPos(DeathsX - XL/2, y);
            Canvas.DrawTextClipped(S);
        }
        if ( TotalKills > 0 ) {
            Canvas.TextSize(TotalKills, XL, YL);
            Canvas.SetPos(KillsX - XL, y);
            Canvas.DrawTextClipped(TotalKills);
        }
        y += YL;
    }

    Canvas.Font = class'ScrnHUD'.static.LoadMenuFontStatic(PlayerFontIndex + FontReduction + 2);
    if (NotShownCount > 0) {
        Canvas.DrawColor = HUDClass.default.GreenColor;
        Canvas.SetPos(NameX, y);
        Canvas.DrawText(NotShownCount@NotShownInfo,true);
    }
    else if (Spectators != "") {
        Canvas.DrawColor = HUDClass.Default.GrayColor;
        Canvas.SetPos(NameX, y);
        Canvas.DrawText(SpectatorsText $ ": |" $ Spectators, true);
    }
}

defaultproperties
{
    TeamScoreString="Team Wallet:"
    AssHeaderText="Ass."
    KillsAssSeparator=" + "
    SpectatorsText="Spectators"
    SuicideTimeText="Suicide in"
    HealthText="Status"
    PointsText="Do$h"
    DamageText="Damage"
    HealText="Heal"
    TimeText="Time"
    strPingMax="N/A"
    TotalText="Total:"
    DeathIcon=Texture'InterfaceArt_tex.deathicons.mine'
    BlameIcon=Texture'ScrnTex.HUD.Crap64'
    BigBlameIcon=Texture'ScrnAch_T.Achievements.PoopTrain'
    AdminIcon=Texture'I_AdminShield'
    WhiteMaterial=Texture'KillingFloorHUD.HUD.WhiteTexture'
    AssColor=(R=160,G=160,B=160,A=255)
    DeadColor=(R=160,G=160,B=160,A=255)
    DoshColor=(R=255,G=255,B=125,A=255)
    BestColor=(R=255,G=0,B=255,A=255)
}
