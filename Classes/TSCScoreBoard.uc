class TSCScoreBoard extends ScrnScoreBoard;

#exec OBJ LOAD FILE=TSC_T.utx

var color RedBG[2], BlueBG[2];
var color GuestColor;
var material GameLogo;
var material CptIcon, CptAssIcon;

var array<localized string> HDmgNames;

// Blue team rows. The red team uses the the original Cache.
var transient array<SScoreRow> BlueCache;

// Cached per-team layout.
// Recalculated only if on resolution change or the local player switch teams
struct STeamLayout
{
    var int  Left, Width;
    var int  VetXPos, NameXPos, KillsXPos, DeathsXPos, CashXPos, HealthXPos, TimeXPos, NetXPos;
    var bool bExtraInfo;        // false for the opposing team: hides its dosh and health columns
    var Color OddBG, EvenBG;
    var int  TotalKills, TotalDeaths, TotalCash;
    var string WaveKillsText, WaveKillsReqText;
    var Color  WaveKillsColor, TotalColor;
    var bool bHasTeam;
};
var transient STeamLayout TeamLayout[2];

var transient int MyTeamIndex, OldMyTeamIndex;
var transient int RedCount, BlueCount;   // alive players per team, for the header line
var transient int DisplayedCount;
var transient int RedBoxXPos, RedBoxWidth, BlueBoxXPos, BlueBoxWidth;
var transient int PlayerBoxSizeY;
var transient float LogoSize;
var transient int TeamFontIndex;    // "fi" in the original code
var transient material TeamLogo[2];


// ============================================================================
//                      NAME CELL
// ============================================================================

// Adds the TSC captain / carrier icon.
// The admin icon is drawn separately by DrawTeam(), on the right edge of the name column,
// so it is suppressed in the name cell itself.
static function ResolveNameCell(PlayerReplicationInfo PRI, ScrnCustomPRI ScrnPRI, out SNameCell Cell,
    optional byte MaxLen, optional bool bNoColorTags)
{
    local TSCGameReplicationInfo TSCGRI;

    super.ResolveNameCell(PRI, ScrnPRI, Cell, MaxLen, bNoColorTags);

    if ( PRI == none )
        return;

    Cell.bAdmin = false;

    TSCGRI = TSCGameReplicationInfo(PRI.Level.GRI);
    if ( PRI.Team != none && PRI.Team.TeamIndex < 2 && TSCGRI != none ) {
        if ( PRI == TSCGRI.TeamCaptain[PRI.Team.TeamIndex] )
            Cell.TeamIcon = default.CptIcon;
        else if ( PRI == TSCGRI.TeamCarrier[PRI.Team.TeamIndex] )
            Cell.TeamIcon = default.CptAssIcon;
    }
}

function string GetSpectatorNameFast(PlayerReplicationInfo PRI, ScrnCustomPRI ScrnPRI)
{
    local string s;
    local Color CustomColor;

    if (PRI.bAdmin) {
        CustomColor = AdminColor;
    }
    else if (ScrnPRI != none) {
        if (ScrnPRI.IsReferee()) {
            CustomColor = AdminColor;
        }
        else if (ScrnPRI.IsGuest()) {
            CustomColor = GuestColor;
        }
        else if (ScrnPRI.GetSpecTeam() < 2) {
            CustomColor = class'ScrnHUD'.default.TextColors[ScrnPRI.GetSpecTeam()];
        }
    }

    s = class'ScrnCustomPRI'.static.GetPlainName(PRI, ScrnPRI);
    if (CustomColor.A != 0) {
        s = class'ScrnF'.static.ColorStringC(s, CustomColor)
                $ class'ScrnF'.static.ColorStringC("", SpecColor);
    }
    return s;
}


// ============================================================================
//                      CACHE UPDATE
// ============================================================================

// TSC splits players by team instead of collecting them into a single list,
// so we use ScanTeams() instead of ScanPlayers().
function ScanTeams(out array<PlayerReplicationInfo> Red, out array<PlayerReplicationInfo> Blue)
{
    local int i;
    local PlayerReplicationInfo PRI;
    local KFPlayerReplicationInfo KFPRI;

    Red.Length = 0;
    Blue.Length = 0;
    PlayerCount = 0;
    SpecCount = 0;
    AliveCount = 0;
    SpectatorLine = "";
    NewcomerLine = "";

    for ( i = 0; i < GRI.PRIArray.Length; i++) {
        PRI = GRI.PRIArray[i];
        if ( PRI == none )
            continue;

        KFPRI = KFPlayerReplicationInfo(PRI);
        if ( !PRI.bOnlySpectator && PRI.Team != none ) {
            if( !PRI.bOutOfLives && KFPRI != none && KFPRI.PlayerHealth>0 )
                ++AliveCount;

            if ( PRI.Team.TeamIndex == 0 )
                Red[Red.Length] = PRI;
            else if ( PRI.Team.TeamIndex == 1 )
                Blue[Blue.Length] = PRI;
        }
        else if ( PRI.PlayerID != 0 || PRI.PlayerName != "WebAdmin" ) {
            ++SpecCount;
            SpectatorLine @= GetSpectatorName(PRI) $ " |";
        }
    }
    RedCount = Red.Length;
    BlueCount = Blue.Length;
    PlayerCount = RedCount + BlueCount;
}

function UpdateGameplayRow(Canvas Canvas, out SScoreRow Row, bool bStoryMode)
{
    local PlayerReplicationInfo PRI;
    local KFPlayerReplicationInfo KFPRI;
    local ScrnCustomPRI ScrnPRI;
    local Material VeterancyBox, StarBox;
    local float YL;

    PRI = Row.PRI;
    if ( PRI == none )
        return; // a quitter: keep whatever was resolved before they left

    KFPRI = KFPlayerReplicationInfo(PRI);
    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PRI);
    Row.KFPRI = KFPRI;
    Row.ScrnPRI = ScrnPRI;
    Row.bAdmin = PRI.bAdmin;

    // name
    ResolveNameCell(PRI, ScrnPRI, Row.NameCell);
    MeasureNameCell(Canvas, Row.NameCell);
    if (PRI.bAdmin)
        Row.NameColor = Class'HudBase'.Default.RedColor;
    else
        Row.NameColor = Class'HudBase'.Default.WhiteColor;

    // perk
    Row.PerkIcon = none;
    Row.StarIcon = none;
    Row.PerkStars = 0;
    if ( KFPRI != None && Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill) != none ) {
        Row.PerkStars = Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill).Static.PreDrawPerk(Canvas,
                KFPRI.ClientVeteranSkillLevel, VeterancyBox, StarBox);
        Row.PerkIcon = VeterancyBox;
        Row.StarIcon = StarBox;
    }

    // kills and assists
    Row.KillsText = "";
    Row.AssistsText = "";
    Row.KillsColor = HUDClass.default.WhiteColor;
    if ( KFPRI != none ) {
        Row.KillsText = string(KFPRI.Kills);
        Canvas.TextSize(Row.KillsText, Row.KillsW, YL);
        if ( KFPRI.KillAssists > 0 ) {
            Row.AssistsText = KillsAssSeparator $ KFPRI.KillAssists;
            Canvas.TextSize(Row.AssistsText, Row.AssistsW, YL);
            Row.AssistsColor = AssColor;
        }
    }

    // deaths
    Row.DeathsText = "";
    Row.DeathsColor = HUDClass.default.WhiteColor;
    if ( PRI.Deaths > 0 ) {
        Row.DeathsText = string(int(PRI.Deaths));
        Canvas.TextSize(Row.DeathsText, Row.DeathsW, YL);
    }

    // dosh
    Row.CashText = class'ScrnUnicode'.default.Dosh $ int(PRI.Score);
    Canvas.TextSize(Row.CashText, Row.CashW, YL);

    // health
    if ( KFPRI == none || PRI.bOutOfLives || KFPRI.PlayerHealth <= 0 ) {
        Row.StatusColor = HUDClass.default.RedColor;
        Row.StatusText = OutText;
    }
    else {
        if( KFPRI.PlayerHealth >= 90 )
            Row.StatusColor = HUDClass.default.GreenColor;
        else if( KFPRI.PlayerHealth >= 50 )
            Row.StatusColor = HUDClass.default.GoldColor;
        else
            Row.StatusColor = HUDClass.default.RedColor;
        Row.StatusText = KFPRI.PlayerHealth $ HealthyString;
    }
    Canvas.TextSize(Row.StatusText, Row.StatusW, YL);

    // time
    if( GRI.ElapsedTime < PRI.StartTime ) // Login timer error, fix it.
        GRI.ElapsedTime = PRI.StartTime;
    Row.TimeText = FormatTime(GRI.ElapsedTime - PRI.StartTime);
    Canvas.TextSize(Row.TimeText, Row.TimeW, YL);

}

// ScrnScoreboard shows READY status is the health columnn.
// Since the players don't see the enemy health,
// TSC moves READY status to the PING.
function GetPingText(Canvas Canvas, PlayerReplicationInfo PRI, out String NetText, out Color NetColor)
{
    if (!GRI.bMatchHasBegun) {
        if ( PRI.bReadyToPlay ) {
            NetColor = Class'HudBase'.Default.WhiteColor;
            NetText = ReadyText;
        }
        else {
            NetColor = Class'HudBase'.Default.RedColor;
            NetText = NotReadyText;
        }
        return;
    }

    super.GetPingText(Canvas, PRI, NetText, NetColor);
}

function UpdateHeader(Canvas Canvas)
{
    local TSCGameReplicationInfo TSCGRRI;
    local TSCTeam TSCTeams[2];
    local PlayerReplicationInfo OwnerPRI;
    local byte HumanDamageMode;
    local string S;
    local float YL;

    TSCGRRI = TSCGameReplicationInfo(GRI);
    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
    TSCTeams[0] = TSCTeam(GRI.Teams[0]);
    TSCTeams[1] = TSCTeam(GRI.Teams[1]);

    if ( TSCGRRI != none )
        HumanDamageMode = TSCGRRI.HumanDamageMode;
    else
        HumanDamageMode = 3; // Normal, just in case

    Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);

    // "Zeroth", Draw game name
    if (TSCGRRI != none && TSCGRRI.GameTitle != "") {
        S = TSCGRRI.GameTitle;
        if ( TSCGRRI.GameVersion > 0 ) {
            S @= class'ScrnF'.static.VersionStr(TSCGRRI.GameVersion);
        }
    }
    else {
        S = GRI.GameName;
    }
    if (TSCTeams[0] != none && TSCTeams[0].ClanRep != none && TSCTeams[1] != none && TSCTeams[1].ClanRep != none) {
        S = TSCTeams[0].ClanRep.ClanName $ " vs. " $ TSCTeams[1].ClanRep.ClanName $ " | " $ S;
    }
    HeaderLine1 = S;
    Canvas.TextSize(S, HeaderLine1W, YL);

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
    HeaderLine2 = S;
    Canvas.TextSize(S, HeaderLine2W, YL);

    // Second title line
    S = PlayerCountText @ RedCount;
    if ( HumanDamageMode == 0 )
        S $= "+";
    else if ( HumanDamageMode <= 3 )
        S $= "x";
    else
        S $= "vs";
    S $= BlueCount;
    if ( SpecCount > 0 ) {
        S @= SpectatorCountText @ SpecCount;
    }
    S @= AliveCountText @ AliveCount;
    if ( OwnerPRI != none && OwnerPRI.Team != none )
        S @= "|" @ TeamScoreString;
    HeaderLine3 = S;
    Canvas.TextSize(S, HeaderLine3W, YL);

    TeamDoshText = "";
    if ( OwnerPRI != none && OwnerPRI.Team != none )
        TeamDoshText = " " $ class'ScrnUnicode'.default.Dosh $ int(OwnerPRI.Team.Score);

    HeaderYL = YL;
    LogoSize = Canvas.ClipY * 0.11 + YL + YL;
    HeaderOffsetY = Canvas.ClipY * 0.11 + YL + YL*3.f;
}

// Font size, box sizes and both column sets. The original recomputed all of this every frame.
function TeamResolutionChanged(Canvas Canvas)
{
    local float XL, YL;
    local int i;

    if ( Canvas.ClipX < 800 )
        TeamFontIndex = 4;
    else if ( Canvas.ClipX < 1000 )
        TeamFontIndex = 3;
    else if ( Canvas.ClipX < 1300 )
        TeamFontIndex = 2;
    else
        TeamFontIndex = 1;

    FontReduction = 0;
    Canvas.Font = class'ROHud'.static.LoadMenuFontStatic(TeamFontIndex);
    Canvas.TextSize("Test", XL, YL);
    PlayerBoxSizeY = 1.4 * YL;

    DisplayedCount = max(RowCount, 6);
    while( (PlayerBoxSizeY*DisplayedCount)>(Canvas.ClipY-HeaderOffsetY) )
    {
        if( ++TeamFontIndex>=5 || ++FontReduction>=3 ) // Shrink font, if too small then break loop.
        {
            // We need to remove some player names here to make it fit.
            DisplayedCount = int((Canvas.ClipY-HeaderOffsetY)/PlayerBoxSizeY)+1;
            break;
        }
        Canvas.Font = class'ROHud'.static.LoadMenuFontStatic(TeamFontIndex);
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

    TeamLayout[0].Left = RedBoxXPos;
    TeamLayout[0].Width = RedBoxWidth;
    TeamLayout[0].bExtraInfo = MyTeamIndex == 0;
    TeamLayout[0].OddBG = RedBG[0];
    TeamLayout[0].EvenBG = RedBG[1];

    TeamLayout[1].Left = BlueBoxXPos;
    TeamLayout[1].Width = BlueBoxWidth;
    TeamLayout[1].bExtraInfo = MyTeamIndex == 1;
    TeamLayout[1].OddBG = BlueBG[0];
    TeamLayout[1].EvenBG = BlueBG[1];

    Canvas.TextSize(KillsAssSeparator $ AssHeaderText, XL, YL);
    for ( i = 0; i < 2; ++i ) {
        TeamLayout[i].VetXPos = TeamLayout[i].Left + 0.0001 * TeamLayout[i].Width;
        TeamLayout[i].NameXPos = TeamLayout[i].VetXPos + PlayerBoxSizeY*1.75;
        if ( TeamLayout[i].bExtraInfo ) {
            TeamLayout[i].KillsXPos = TeamLayout[i].Left + 0.50 * TeamLayout[i].Width;
            TeamLayout[i].CashXPos = TeamLayout[i].Left + 0.67 * TeamLayout[i].Width;
            TeamLayout[i].HealthXPos = TeamLayout[i].Left + 0.75 * TeamLayout[i].Width;
            TeamLayout[i].TimeXPos = TeamLayout[i].Left + 0.85 * TeamLayout[i].Width;
            TeamLayout[i].NetXPos = TeamLayout[i].Left + 0.996 * TeamLayout[i].Width;
        }
        else {
            TeamLayout[i].KillsXPos = TeamLayout[i].Left + 0.55 * TeamLayout[i].Width;
            TeamLayout[i].TimeXPos = TeamLayout[i].Left + 0.80 * TeamLayout[i].Width;
            TeamLayout[i].NetXPos = TeamLayout[i].Left + 0.996 * TeamLayout[i].Width;
        }
        TeamLayout[i].DeathsXPos = TeamLayout[i].KillsXPos + XL + PlayerBoxSizeY;
    }
}

function UpdateTeamTotals(Canvas Canvas, int TeamIndex, out array<SScoreRow> Rows)
{
    local int i;
    local TSCTeam TSCTeam;
    local TSCGameReplicationInfo TSCGRI;
    local int WaveKills;

    TSCGRI = TSCGameReplicationInfo(GRI);
    TSCTeam = TSCTeam(GRI.Teams[TeamIndex]);

    TeamLayout[TeamIndex].TotalKills = 0;
    TeamLayout[TeamIndex].TotalDeaths = 0;
    TeamLayout[TeamIndex].TotalCash = 0;
    TeamLayout[TeamIndex].WaveKillsText = "";
    TeamLayout[TeamIndex].WaveKillsReqText = "";
    TeamLayout[TeamIndex].bHasTeam = TSCTeam != none;
    TeamLayout[TeamIndex].TotalColor = HUDClass.default.WhiteColor;

    for ( i = 0; i < Rows.Length; ++i ) {
        if ( Rows[i].KFPRI != none )
            TeamLayout[TeamIndex].TotalKills += Rows[i].KFPRI.Kills;
        if ( Rows[i].PRI != none ) {
            TeamLayout[TeamIndex].TotalDeaths += Rows[i].PRI.Deaths;
            if ( TeamLayout[TeamIndex].bExtraInfo )
                TeamLayout[TeamIndex].TotalCash += Rows[i].PRI.Score;
        }
    }

    if ( TSCTeam != none ) {
        TeamLayout[TeamIndex].TotalColor = TSCTeam.TeamColor;
        TeamLayout[TeamIndex].TotalCash += TSCTeam.Score;

        if ( TeamLayout[TeamIndex].TotalKills > 0 ) {
            WaveKills = TSCTeam.GetCurWaveKills();
            TeamLayout[TeamIndex].WaveKillsText = WaveString @ KillsText $ ": " $ WaveKills;
            if ( TSCGRI != none && WaveKills < TSCGRI.WaveKillReq ) {
                TeamLayout[TeamIndex].WaveKillsColor = class'ScrnHUD'.default.LowAmmoColor;
                TeamLayout[TeamIndex].WaveKillsReqText = " / " $ TSCGRI.WaveKillReq;
            }
            else {
                TeamLayout[TeamIndex].WaveKillsColor = TSCTeam.TeamColor;
            }
        }
    }

    TeamLogo[TeamIndex] = none;
    if ( TSCTeam != none )
        TeamLogo[TeamIndex] = TSCTeam.GetLogo();
}

function HighlightBest(out array<SScoreRow> Rows)
{
    local int i, MaxTeamKills;

    if (Rows.Length < 2)
        return;

    for (i = 0; i < Rows.Length; ++i) {
        if (Rows[i].KFPRI != none)
            MaxTeamKills = max(MaxTeamKills, Rows[i].KFPRI.Kills);
    }
    if (MaxTeamKills <= 0)
        return;

    for (i = 0; i < Rows.Length; ++i) {
        if (Rows[i].KFPRI != none && Rows[i].KFPRI.Kills == MaxTeamKills)
            Rows[i].KillsColor = BestColor;
    }
}

function UpdateCache(Canvas Canvas)
{
    local array<PlayerReplicationInfo> Red, Blue;
    local PlayerReplicationInfo OwnerPRI;
    local bool bResolutionChanged;
    local int i;

    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
    if ( OwnerPRI != none && OwnerPRI.Team != none )
        MyTeamIndex = OwnerPRI.Team.TeamIndex;
    else
        MyTeamIndex = -1;

    ScanTeams(Red, Blue);

    if ( bFrozen ) {
        // The game is over, so which team a newcomer landed on is irrelevant - they only joined to
        // vote for the next map. One shared line for both teams.
        AddNewcomers(Cache, Red);
        AddNewcomers(BlueCache, Blue);
    }
    else {
        SyncRows(Cache, Red, OwnerPRI);
        SyncRows(BlueCache, Blue, OwnerPRI);
    }
    RowCount = max(Cache.Length, BlueCache.Length);

    UpdateHeader(Canvas);

    bResolutionChanged = OldClipX != Canvas.ClipX || OldClipY != Canvas.ClipY
            || OldMyTeamIndex != MyTeamIndex;
    if (LastDrawnPlayerCount != RowCount || bResolutionChanged) {
        LastDrawnPlayerCount = RowCount;
        OldClipX = Canvas.ClipX;
        OldClipY = Canvas.ClipY;
        OldMyTeamIndex = MyTeamIndex;
    }
    // cheap enough, and it depends on RowCount anyway
    TeamResolutionChanged(Canvas); // leaves Canvas.Font set to the row font

    if ( bFrozen ) {
        for ( i = 0; i < Cache.Length; ++i ) {
            if ( bResolutionChanged )
                RemeasureGameplayRow(Canvas, Cache[i]);
            UpdateTelemetryRow(Canvas, Cache[i]);
        }
        for ( i = 0; i < BlueCache.Length; ++i ) {
            if ( bResolutionChanged )
                RemeasureGameplayRow(Canvas, BlueCache[i]);
            UpdateTelemetryRow(Canvas, BlueCache[i]);
        }
        return;
    }

    for ( i = 0; i < Cache.Length; ++i ) {
        UpdateGameplayRow(Canvas, Cache[i], false);
        UpdateTelemetryRow(Canvas, Cache[i]);
    }
    for ( i = 0; i < BlueCache.Length; ++i ) {
        UpdateGameplayRow(Canvas, BlueCache[i], false);
        UpdateTelemetryRow(Canvas, BlueCache[i]);
    }

    HighlightBest(Cache);
    HighlightBest(BlueCache);

    UpdateTeamTotals(Canvas, 0, Cache);
    UpdateTeamTotals(Canvas, 1, BlueCache);
}

function Unfreeze()
{
    super.Unfreeze();
    BlueCache.Length = 0;
}


// ============================================================================
//                      DRAWING
// ============================================================================

function DrawCache(Canvas Canvas)
{
    local float XL, YL, y;
    local Material M;

    // ---- header ----
    Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);
    if ( MyTeamIndex >= 0 && GRI.Teams[MyTeamIndex] != none )
        Canvas.DrawColor = GRI.Teams[MyTeamIndex].TeamColor;
    else
        Canvas.DrawColor = HUDClass.default.RedColor;
    Canvas.Style = ERenderStyle.STY_Normal;

    Canvas.SetPos( (Canvas.ClipX - HeaderLine1W)/2, Canvas.ClipY * 0.11 - HeaderYL);
    Canvas.DrawTextClipped(HeaderLine1);

    Canvas.SetPos(0.5 * (Canvas.ClipX - HeaderLine2W), Canvas.ClipY * 0.11);
    Canvas.DrawTextClipped(HeaderLine2);

    Canvas.SetPos(0.5 * (Canvas.ClipX - HeaderLine3W), Canvas.ClipY * 0.11 + HeaderYL);
    Canvas.DrawTextClipped(HeaderLine3);
    if ( TeamDoshText != "" ) {
        Canvas.DrawColor = DoshColor;
        Canvas.SetPos(0.5 * (Canvas.ClipX + HeaderLine3W), Canvas.ClipY * 0.11 + HeaderYL);
        Canvas.DrawTextClipped(TeamDoshText);
    }

    // ---- logos ----
    Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
    Canvas.DrawColor.A = 160;
    Canvas.Style = ERenderStyle.STY_Alpha;
    // TSC LOGO (1024x64)
    XL = Canvas.ClipX*0.5;
    YL = XL/16;
    Canvas.SetPos((Canvas.ClipX-XL)/2, 0);
    Canvas.DrawTile(GameLogo, XL, YL, 0, 0, GameLogo.MaterialUSize(), GameLogo.MaterialVSize());

    if (TeamLogo[0] != none) {
        M = TeamLogo[0];
        Canvas.SetPos(0, 0);
        Canvas.DrawTile(M, LogoSize, LogoSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
    }
    if (TeamLogo[1] != none) {
        M = TeamLogo[1];
        Canvas.SetPos(Canvas.ClipX - LogoSize, 0);
        Canvas.DrawTile(M, LogoSize, LogoSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
    }

    Canvas.Font = class'ROHud'.static.LoadMenuFontStatic(TeamFontIndex);
    y = DrawTeam(Canvas, 0, Cache);
    y = fmax(y, DrawTeam(Canvas, 1, BlueCache));
    y += PlayerBoxSizeY;

    Canvas.Font = class'ROHud'.static.LoadMenuFontStatic( min(8, TeamFontIndex+2) );
    Canvas.TextSize("0", XL, YL);
    if (SpectatorLine != "") {
        Canvas.DrawColor = SpecColor;
        Canvas.SetPos(RedBoxXPos, y);
        Canvas.DrawText(SpectatorsText $ ": |" $ SpectatorLine, true);
        y += YL;
    }
    if (NewcomerLine != "") {
        Canvas.DrawColor = HUDClass.default.GreenColor;
        Canvas.SetPos(RedBoxXPos, y);
        Canvas.DrawText(NewcomersText $ ": |" $ NewcomerLine, true);
    }
}

function float DrawTeam(Canvas Canvas, int TeamIndex, out array<SScoreRow> Rows)
{
    local bool bEven;
    local int i, BoxTextOffsetY;
    local int Left, Width, LineHeight, LineCount;
    local float tmpClipX, XL, YL, y;
    local string S;
    local PlayerReplicationInfo OwnerPRI;

    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
    Left = TeamLayout[TeamIndex].Left;
    Width = TeamLayout[TeamIndex].Width;
    LineHeight = PlayerBoxSizeY;
    LineCount = DisplayedCount;

    Canvas.Style = ERenderStyle.STY_Alpha;

    // lines
    y = HeaderOffsetY;
    for ( i = 0; i < LineCount; i++) {
        bEven = !bEven;
        if ( i < Rows.length && Rows[i].PRI != none && Rows[i].PRI == OwnerPRI)
            Canvas.SetDrawColor(0, 255, 0, 48); // highlight myself
        else if ( bEven )
            Canvas.DrawColor = TeamLayout[TeamIndex].EvenBG;
        else
            Canvas.DrawColor = TeamLayout[TeamIndex].OddBG;
        Canvas.SetPos(Left, y);
        Canvas.DrawTileStretched( WhiteMaterial, Width, LineHeight);
        y += LineHeight;
    }
    // draw box around
    Canvas.DrawColor = HUDClass.default.RedColor;
    Canvas.SetPos(Left, HeaderOffsetY);
    Canvas.DrawTileStretched(BoxMaterial, Width, LineHeight * LineCount);

    //headers
    y = HeaderOffsetY - LineHeight;
    Canvas.Style = ERenderStyle.STY_Normal;
    Canvas.DrawColor = HUDClass.default.WhiteColor;

    Canvas.SetPos(TeamLayout[TeamIndex].NameXPos, y);
    Canvas.DrawTextClipped(PlayerText);

    Canvas.TextSize(KillsText, XL, YL);
    Canvas.SetPos(TeamLayout[TeamIndex].KillsXPos - XL, y);
    Canvas.DrawTextClipped(KillsText);
    Canvas.SetPos(TeamLayout[TeamIndex].KillsXPos, y);
    Canvas.DrawColor = AssColor;
    Canvas.DrawTextClipped(KillsAssSeparator $ AssHeaderText);
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    // death icon
    Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.SetPos(TeamLayout[TeamIndex].DeathsXPos - LineHeight/2, y);
    Canvas.DrawTile(DeathIcon, LineHeight, LineHeight, 0, 0, DeathIcon.MaterialUSize(), DeathIcon.MaterialVSize());
    Canvas.Style = ERenderStyle.STY_Normal;

    Canvas.TextSize(TimeText, XL, YL);
    Canvas.SetPos(TeamLayout[TeamIndex].TimeXPos - 0.5 * XL, y);
    Canvas.DrawTextClipped(TimeText);

    if ( TeamLayout[TeamIndex].bExtraInfo ) {
        Canvas.TextSize(PointsText, XL, YL);
        Canvas.SetPos(TeamLayout[TeamIndex].CashXPos - 0.5 * XL, y);
        Canvas.DrawTextClipped(PointsText);

        Canvas.TextSize(HealthText, XL, YL);
        Canvas.SetPos(TeamLayout[TeamIndex].HealthXPos - 0.5 * XL, y);
        Canvas.DrawTextClipped(HealthText);
    }

    Canvas.TextSize(NetText, XL, YL);
    Canvas.SetPos(TeamLayout[TeamIndex].NetXPos - XL, y);
    Canvas.DrawTextClipped(NetText);

    // ---- player names ----
    BoxTextOffsetY = (LineHeight - YL)/2;
    y = HeaderOffsetY + BoxTextOffsetY;
    tmpClipX = Canvas.ClipX;
    Canvas.TextSize("     ", XL, YL);
    Canvas.ClipX = TeamLayout[TeamIndex].KillsXPos - XL;
    for ( i = 0; i < LineCount && i < Rows.length; i++ ) {
        // draw admins in red, others in white
        if ( Rows[i].bAdmin ) {
            Canvas.SetPos(Canvas.ClipX - LineHeight, y - BoxTextOffsetY + 1);
            XL = LineHeight-2;
            Canvas.DrawTile(AdminIcon, XL, XL, 0, 0, AdminIcon.MaterialUSize(), AdminIcon.MaterialVSize());
        }
        Canvas.DrawColor = Rows[i].NameColor;
        DrawNameCell(Canvas, Rows[i].NameCell, TeamLayout[TeamIndex].NameXPos, y);
        Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
        y += LineHeight;
    }
    // Draw not shown info
    if( Rows.length > LineCount ) {
        Canvas.DrawColor.G = 255;
        Canvas.DrawColor.B = 0;
        Canvas.SetPos(TeamLayout[TeamIndex].NameXPos, y);
        Canvas.DrawText(string(Rows.length - LineCount) @ NotShownInfo,true);
    }
    // restore canvas properties
    Canvas.ClipX = tmpClipX;
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.Style = ERenderStyle.STY_Normal;

    // ---- player informations ----
    y = HeaderOffsetY + BoxTextOffsetY;
    for ( i = 0; i < LineCount && i < Rows.length; i++ )
        y = DrawTeamRow(Canvas, Rows[i], TeamIndex, y, BoxTextOffsetY, LineHeight);

    // ---- totals ----
    y = HeaderOffsetY + LineCount*LineHeight;

    Canvas.DrawColor = TeamLayout[TeamIndex].TotalColor;
    Canvas.SetPos(TeamLayout[TeamIndex].NameXPos, y);
    Canvas.DrawTextClipped(TotalText);
    if (TeamLayout[TeamIndex].bExtraInfo && TeamLayout[TeamIndex].TotalCash > 0) {
        S = class'ScrnUnicode'.default.Dosh $ TeamLayout[TeamIndex].TotalCash;
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(TeamLayout[TeamIndex].CashXPos - XL/2, y);
        Canvas.DrawTextClipped(S);
    }
    if ( TeamLayout[TeamIndex].TotalDeaths > 0) {
        S = string(TeamLayout[TeamIndex].TotalDeaths);
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(TeamLayout[TeamIndex].DeathsXPos - XL/2, y);
        Canvas.DrawTextClipped(S);
    }
    if ( TeamLayout[TeamIndex].TotalKills > 0 ) {
        S = string(TeamLayout[TeamIndex].TotalKills);
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(TeamLayout[TeamIndex].KillsXPos - XL, y);
        Canvas.DrawTextClipped(S);
        Canvas.DrawColor = HUDClass.default.WhiteColor;
    }

    y += YL;
    if ( TeamLayout[TeamIndex].WaveKillsText != "" ) {
        S = TeamLayout[TeamIndex].WaveKillsText;
        Canvas.TextSize(S, XL, YL);
        Canvas.SetPos(TeamLayout[TeamIndex].KillsXPos - XL, y);
        Canvas.DrawColor = TeamLayout[TeamIndex].WaveKillsColor;
        Canvas.DrawTextClipped(S);

        if ( TeamLayout[TeamIndex].WaveKillsReqText != "" ) {
            Canvas.SetPos(TeamLayout[TeamIndex].KillsXPos, y);
            Canvas.DrawTextClipped(TeamLayout[TeamIndex].WaveKillsReqText);
        }
        y += YL;
    }

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    return y;
}

function float DrawTeamRow(Canvas Canvas, out SScoreRow Row, int TeamIndex, float y,
        float BoxTextOffsetY, float LineHeight)
{
    Canvas.DrawColor = HUDClass.default.WhiteColor;

    // Display perks.
    if ( Row.PerkIcon != None ) {
        DrawPerkWithStars(Canvas, TeamLayout[TeamIndex].VetXPos, y - BoxTextOffsetY, LineHeight,
                Row.PerkStars, Row.PerkIcon, Row.StarIcon);
        Canvas.DrawColor = HUDClass.default.WhiteColor;
    }

    // kills
    if (Row.KillsText != "") {
        Canvas.DrawColor = Row.KillsColor;
        Canvas.SetPos(TeamLayout[TeamIndex].KillsXPos - Row.KillsW, y);
        Canvas.DrawTextClipped(Row.KillsText);
        Canvas.DrawColor = HUDClass.default.WhiteColor;
    }
    // assists
    if ( Row.AssistsText != "" ) {
        Canvas.DrawColor = Row.AssistsColor;
        Canvas.SetPos(TeamLayout[TeamIndex].KillsXPos, y);
        Canvas.DrawTextClipped(Row.AssistsText);
        Canvas.DrawColor = HUDClass.default.WhiteColor;
    }
    // deaths
    if ( Row.DeathsText != "" ) {
        Canvas.SetPos(TeamLayout[TeamIndex].DeathsXPos - Row.DeathsW/2, y);
        Canvas.DrawTextClipped(Row.DeathsText);
    }

    if ( TeamLayout[TeamIndex].bExtraInfo ) {
        // dosh
        if ( Row.CashText != "" ) {
            Canvas.DrawColor = DoshColor;
            Canvas.SetPos(TeamLayout[TeamIndex].CashXPos - Row.CashW*0.5f, y);
            Canvas.DrawText(Row.CashText, true);
            Canvas.DrawColor = HUDClass.default.WhiteColor;
        }
        // health
        if ( Row.StatusText != "" ) {
            Canvas.DrawColor = Row.StatusColor;
            Canvas.SetPos(TeamLayout[TeamIndex].HealthXPos - 0.5 * Row.StatusW, y);
            Canvas.DrawTextClipped(Row.StatusText);
            Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
        }
    }

    // time
    if ( Row.TimeText != "" ) {
        Canvas.SetPos(TeamLayout[TeamIndex].TimeXPos - Row.TimeW*0.5f, y);
        Canvas.DrawText(Row.TimeText, true);
    }

    // ping / status / QUIT
    if ( Row.NetText != "" ) {
        Canvas.DrawColor = Row.NetColor;
        Canvas.SetPos(TeamLayout[TeamIndex].NetXPos - Row.NetW, y);
        Canvas.DrawTextClipped(Row.NetText);
        Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
    }

    return y + LineHeight;
}

defaultproperties
{
    RedBG(0)=(R=128,G=64,B=64,A=200)
    RedBG(1)=(R=160,G=64,B=64,A=200)
    BlueBG(0)=(R=64,G=64,B=128,A=200)
    BlueBG(1)=(R=64,G=64,B=160,A=200)

    GuestColor=(R=1,G=255,B=1,A=255)


    KillsAssSeparator="+"
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
