class ScrnScoreBoard extends SRScoreBoard;

var     localized   string      AssHeaderText;
var     localized   string      KillsAssSeparator;
var     localized   string      strPingMax;
var     localized   string      SpectatorsText;
var     localized   string      SuicideTimeText;


var     material                 AdminIcon, BlameIcon, BigBlameIcon;
var     material                DeathIcon;


var        Material                WhiteMaterial;

var()     color                    AssColor, DoshColor;

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
        S = class'ScrnBalance'.default.Mut.StripColorTags(PRI.PlayerName);
    else
        S = class'ScrnBalance'.default.Mut.ColoredPlayerName(PRI);

    if( MaxLen>0 )
        S = class'ScrnBalance'.static.LeftCol(S, MaxLen);

    C.DrawColor = Class'HudBase'.Default.WhiteColor;
    C.DrawColor.A = OriginalColor.A;
    C.TextSize(S,NameWidth,IconSize);
    Offset = DrawNamePrefixIcons(C, PRI, ScrnPRI, S, X, Y, IconSize);
    C.TextSize(class'ScrnUtility'.static.StripColor(S),NameWidth,IconSize);

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

simulated static function TextSizeCountrySE( Canvas C, PlayerReplicationInfo PRI, out float XL, out float YL )
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

simulated event UpdateScoreBoard(Canvas Canvas)
{
    local PlayerReplicationInfo PRI, OwnerPRI;
    local KFPlayerReplicationInfo KFPRI;
    local KF_StoryPRI StoryPRI;
    local ScrnGameReplicationInfo ScrnGRI;
    local int i, fi, FontReduction, NetXPos, PlayerCount, SpecCount, AliveCount, HeaderOffsetY,
        HeadFoot, MessageFoot,
        PlayerBoxSizeY, BoxSpaceY, NameXPos, BoxTextOffsetY, HealthXPos, BoxXPos,
        KillsXPos, TitleYPos, BoxWidth, VetXPos, NotShownCount,
        StoryIconXPos;
    local float XL,YL, y;
    local float deathsXL, KillsXL, NetXL, HealthXL, MaxNamePos, DeathsXPos, KillWidthX, CashXPos, TimeXPos, PProgressXS;
    local Material VeterancyBox,StarBox;
    local string S;
    local byte Stars;
    local KF_StoryObjective CurrentObj;
    local array<PlayerReplicationInfo> TeamPRIArray;
    local bool bStoryMode;
    local float StoryIconS;
    local material StoryIcon;
    local String Spectators;

    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
    bStoryMode = KF_StoryPRI(OwnerPRI) != none;
    ScrnGRI = ScrnGameReplicationInfo(GRI);

    for ( i = 0; i < GRI.PRIArray.Length; i++) {
        PRI = GRI.PRIArray[i];
        KFPRI = KFPlayerReplicationInfo(PRI);
        if ( !PRI.bOnlySpectator ) {
            if( !PRI.bOutOfLives && KFPRI != none && KFPRI.PlayerHealth > 0 )
                ++AliveCount;
            PlayerCount++;
            TeamPRIArray[ TeamPRIArray.Length ] = PRI;
        }
        else if ( PRI.PlayerID != 0 || PRI.PlayerName != "WebAdmin" ) {
            ++SpecCount;
            Spectators @= class'ScrnBalance'.default.Mut.StripColorTags(PRI.PlayerName) $ " |";
        }
    }

    Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);
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
        if ( ScrnGRI.WaveTitle != "" )
            S $= " | " $ ScrnGRI.WaveTitle;
        if ( ScrnGRI.WaveMessage != "" )
            S $= " | " $ ScrnGRI.WaveMessage;
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
        S = " " $ class'ScrnUnicode'.default.Dosh $ int(OwnerPRI.Team.Score);
        Canvas.SetPos(0.5 * (Canvas.ClipX + XL), HeaderOffsetY);
        Canvas.DrawTextClipped(S);
    }
    HeaderOffsetY+=(YL*3.f);

    // Select best font size and box size to fit as many players as possible on screen
    if ( Canvas.ClipX < 600 )
        fi = 4;
    else if ( Canvas.ClipX < 800 )
        fi = 3;
    else if ( Canvas.ClipX < 1000 )
        fi = 2;
    else if ( Canvas.ClipX < 1200 )
        fi = 1;
    else
        fi = 0;

    Canvas.Font = class'ROHud'.static.LoadMenuFontStatic(fi);
    Canvas.TextSize("Test", XL, YL);
    PlayerBoxSizeY = 1.2 * YL;
    BoxSpaceY = 0.25 * YL;

    while( ((PlayerBoxSizeY+BoxSpaceY)*PlayerCount)>(Canvas.ClipY-HeaderOffsetY) )
    {
        if( ++fi>=5 || ++FontReduction>=3 ) // Shrink font, if too small then break loop.
        {
            // We need to remove some player names here to make it fit.
            NotShownCount = PlayerCount-int((Canvas.ClipY-HeaderOffsetY)/(PlayerBoxSizeY+BoxSpaceY))+1;
            PlayerCount-=NotShownCount;
            break;
        }
        Canvas.Font = class'ROHud'.static.LoadMenuFontStatic(fi);
        Canvas.TextSize("Test", XL, YL);
        PlayerBoxSizeY = 1.2 * YL;
        BoxSpaceY = 0.25 * YL;
    }

    HeadFoot = 7 * YL;
    MessageFoot = 1.5 * HeadFoot;

    BoxWidth = 0.9 * Canvas.ClipX;
    BoxXPos = 0.5 * (Canvas.ClipX - BoxWidth);

    BoxWidth = Canvas.ClipX - 2 * BoxXPos;
    VetXPos = BoxXPos + 0.0001 * BoxWidth;
    NameXPos = VetXPos + PlayerBoxSizeY*1.75f;
    KillsXPos = BoxXPos + 0.50 * BoxWidth;
    DeathsXPos = BoxXPos + 0.57 * BoxWidth;
    CashXPos = BoxXPos + 0.65 * BoxWidth;
    HealthXpos = BoxXPos + 0.75 * BoxWidth;
    TimeXPos = BoxXPos + 0.87 * BoxWidth;
    NetXPos = BoxXPos + 0.996 * BoxWidth;
    if ( bStoryMode ) {
        StoryIconS = PlayerBoxSizeY - 2;
    }
    StoryIconXPos = 0.45 * BoxWidth - StoryIconS * 0.5;
    PProgressXS = BoxWidth * 0.1f;

    // draw background boxes
    Canvas.Style = ERenderStyle.STY_Alpha;
    for ( i = 0; i < PlayerCount; i++ )
    {
        Canvas.DrawColor = HUDClass.default.WhiteColor;
        Canvas.DrawColor.A = 128;
        Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY) * i);
        Canvas.DrawTileStretched( BoxMaterial, BoxWidth, PlayerBoxSizeY);

        // highlight myself
        if ( TeamPRIArray[i] == OwnerPRI ) {
            Canvas.SetDrawColor(0, 255, 0, 48);
            Canvas.SetPos(BoxXPos + 1, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY) * i + 1);
            Canvas.DrawTileStretched( WhiteMaterial, BoxWidth-2, PlayerBoxSizeY-2);
        }
    }
    if( NotShownCount>0 ) // Add box for not shown players.
    {
        Canvas.DrawColor = HUDClass.default.RedColor;
        Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY) * PlayerCount);
        Canvas.DrawTileStretched( BoxMaterial, BoxWidth, PlayerBoxSizeY);
    }

    // Draw headers
    TitleYPos = HeaderOffsetY - 1.1 * YL;
    Canvas.TextSize(HealthText, HealthXL, YL);
    Canvas.TextSize(DeathsText, DeathsXL, YL);
    Canvas.TextSize(KillsText, KillsXL, YL);
    Canvas.TextSize(NetText, NetXL, YL);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(NameXPos, TitleYPos);
    Canvas.DrawTextClipped(PlayerText);

    Canvas.SetPos(KillsXPos - KillsXL, TitleYPos);
    Canvas.DrawTextClipped(KillsText);
    Canvas.SetPos(KillsXPos, TitleYPos);
    Canvas.DrawColor = AssColor;
    Canvas.DrawTextClipped(KillsAssSeparator $ AssHeaderText);

    // death icon
    Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(DeathsXPos - PlayerBoxSizeY/2, TitleYPos);
    Canvas.DrawTile(DeathIcon, PlayerBoxSizeY, PlayerBoxSizeY, 0, 0, DeathIcon.MaterialUSize(), DeathIcon.MaterialVSize());
    Canvas.Style = ERenderStyle.STY_Normal;


    Canvas.TextSize(PointsText, XL, YL);
    Canvas.SetPos(CashXPos - 0.5 * XL, TitleYPos);
    Canvas.DrawTextClipped(PointsText);

    Canvas.TextSize(TimeText, XL, YL);
    Canvas.SetPos(TimeXPos - 0.5 * XL, TitleYPos);
    Canvas.DrawTextClipped(TimeText);

    Canvas.SetPos(HealthXPos - 0.5 * HealthXL, TitleYPos);
    Canvas.DrawTextClipped(HealthText);

    Canvas.Style = ERenderStyle.STY_Normal;
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(0.5 * Canvas.ClipX, HeaderOffsetY + 4);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(NetXPos - NetXL, TitleYPos);
    Canvas.DrawTextClipped(NetText);

    BoxTextOffsetY = HeaderOffsetY + 0.5 * (PlayerBoxSizeY - YL);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    MaxNamePos = Canvas.ClipX;
    Canvas.ClipX = KillsXPos - 4.f;

    for ( i = 0; i < PlayerCount; i++ )
    {
        PRI = TeamPRIArray[i]; // For some reasons, GRI.PRIArray[i] has WebAdmin in Story Mode
        // draw myself in green, admins - red, others - white  -- PooSH
        if ( PRI.bAdmin )
            Canvas.DrawColor = Class'HudBase'.Default.RedColor;
        else
            Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
        DrawCountryNameSE(Canvas,PRI,NameXPos,(PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
    }

    Canvas.ClipX = MaxNamePos;
    Canvas.DrawColor = HUDClass.default.WhiteColor;

    Canvas.Style = ERenderStyle.STY_Normal;

    // Draw the player informations.
    for ( i = 0; i < PlayerCount; i++ )
    {
        //PRI = GRI.PRIArray[i];
        PRI = TeamPRIArray[i]; // For some reasons, GRI.PRIArray[i] has WebAdmin in Story Mode
        KFPRI = KFPlayerReplicationInfo(PRI);
        StoryPRI = KF_StoryPRI(PRI);

        Canvas.DrawColor = HUDClass.default.WhiteColor;
        y = (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY;

        // Display admin. - moved to DrawNamePostfixIcons()
        // if( PRI.bAdmin )
        // {
            // Canvas.SetPos(BoxXPos - PlayerBoxSizeY, y + PlayerBoxSizeY*0.25);
            // XL = PlayerBoxSizeY*0.5;
            // Canvas.DrawTile(AdminIcon, XL, XL, 0, 0, AdminIcon.MaterialUSize(), AdminIcon.MaterialVSize());
        // }

        // display Story Icon
        if ( StoryPRI != none ){
            StoryIcon = StoryPRI.GetFloatingIconMat();
            if ( StoryIcon != none ) {
                Canvas.SetPos(StoryIconXPos - StoryIconS * 0.5, y + 1 );
                Canvas.DrawTile(StoryIcon, StoryIconS, StoryIconS, 0, 0, StoryIcon.MaterialUSize(), StoryIcon.MaterialVSize());
            }
        }

        // Display perks.
        if ( KFPRI!=None && Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill)!=none )
        {
            Stars = Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill).Static.PreDrawPerk(Canvas
                ,KFPRI.ClientVeteranSkillLevel,VeterancyBox,StarBox);

            if ( VeterancyBox != None )
                DrawPerkWithStars(Canvas,VetXPos,HeaderOffsetY+(PlayerBoxSizeY+BoxSpaceY)*i,PlayerBoxSizeY,min(Stars,25),VeterancyBox,StarBox);
            Canvas.DrawColor = HUDClass.default.WhiteColor;

            // Draw perk progress
            /*
            if( !PRI.bBot && KFPRI.ThreeSecondScore>=0 )
            {
                YL = float(KFPRI.ThreeSecondScore) / 10000.f;
                DrawProgressBar(Canvas,StoryIconXPos-PProgressXS*1.5,HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY) * i + PlayerBoxSizeY*0.4,PProgressXS,PlayerBoxSizeY*0.2,FClamp(YL,0.f,1.f));
                Canvas.DrawColor.A = 255;
            }
            */
        }

        // draw kills
        Canvas.TextSize(KFPRI.Kills, KillWidthX, YL);
        Canvas.SetPos(KillsXPos - KillWidthX, y);
        Canvas.DrawTextClipped(KFPRI.Kills);
        // draw Assists  -- PooSH
        if ( KFPRI.KillAssists > 0) {
            Canvas.DrawColor = AssColor;
            Canvas.SetPos(KillsXPos, y);
            Canvas.DrawTextClipped(KillsAssSeparator $ KFPRI.KillAssists);
            Canvas.DrawColor = HUDClass.default.WhiteColor;
        }

        // deaths
        if ( PRI.Deaths > 0 ) {
            S = string(int(PRI.Deaths));
            Canvas.TextSize(S, XL, YL);
            Canvas.SetPos(DeathsXPos - XL/2, y);
            Canvas.DrawTextClipped(S);
        }

        // draw cash
        S = class'ScrnUnicode'.default.Dosh $ int(PRI.Score);
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(CashXPos-XL*0.5f, y);
        Canvas.DrawColor = DoshColor;
        Canvas.DrawText(S,true);
        Canvas.DrawColor = HUDClass.default.WhiteColor;

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
            S = KFPRI.PlayerHealth@HealthyString;
        }
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(HealthXpos - 0.5 * XL, y);
        Canvas.DrawTextClipped(S);
    }

    Canvas.Font = class'ROHud'.static.LoadMenuFontStatic( min(8, fi+3) );
    if( NotShownCount>0 ) // Draw not shown info
    {
        Canvas.DrawColor.G = 255;
        Canvas.DrawColor.B = 0;
        Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*PlayerCount + BoxTextOffsetY);
        Canvas.DrawText(NotShownCount@NotShownInfo,true);
    }
    else if ( Spectators != "" )
    {
        Canvas.DrawColor = Class'HudBase'.Default.GrayColor;
        Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*PlayerCount + BoxTextOffsetY);
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
    HealthText="Health"
    PointsText="Do$h"
    TimeText="Time"
    strPingMax="N/A"
    DeathIcon=Texture'InterfaceArt_tex.deathicons.mine'
    BlameIcon=Texture'ScrnTex.HUD.Crap64'
    BigBlameIcon=Texture'ScrnAch_T.Achievements.PoopTrain'
    AdminIcon=Texture'I_AdminShield'
    WhiteMaterial=Texture'KillingFloorHUD.HUD.WhiteTexture'
    AssColor=(B=160,G=160,R=160,A=255)
    DoshColor=(B=125,G=255,R=255,A=255)
}
