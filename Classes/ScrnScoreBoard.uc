class ScrnScoreBoard extends SRScoreBoard;

var     localized   string      AssHeaderText;
var     localized   string      KillsAssSeparator;
var     localized   string      strPingMax;
var     localized   string      SpectatorsText;
var     localized   string      SuicideTimeText;
var     localized   string      TotalText;
var     localized   string      DamageText;
var     localized   string      HealText;
var     localized   string      QuitText;
var     localized   string      NewcomersText;

var Material AdminIcon, BlameIcon, BigBlameIcon, DeathIcon;
var Material WhiteMaterial;

var Material PlayerIconBackground;

var color AssColor, DoshColor, BestColor, DeadColor, AdminColor, SpecColor;

var transient float BoxWidth, BoxX;
var transient float VetX, NameX, KillsX, DamageX, HealX, DeathsX, CashX, HealthX, TimeX, NetX;
var transient float StoryIconXPos, StoryIconS;

var int PlayerFontIndex;

var transient float OldClipX, OldClipY;
var transient float BoxHeight, BoxSpaceY;
var transient float PlayerIconSize;
var float PlayerIconSpacing, PlayerIconMargin, PlayerPortraitVShift;
var transient float BaseBoxHeight, BaseBoxSpaceY, BasePlayerIconSize;

var transient int LastDrawnPlayerCount;

// debug
// var int FakedPlayers;

// ============================================================================
//                      CACHE
// ============================================================================
// UpdateScoreBoard() is called on every rendered frame - 120 times per second at 120 FPS.
// Almost nothing that it draws changes that often.
// Optimization:
// 1. Rebuild the cache every UpdateFrequency seconds.
// 2. Draw from the cache in between.

// Everything needed to draw a player name with all of its icons, resolved once per cache update.
struct SNameCell
{
    var string   Name;          // colored (or plain) player name without the country tag
    var string   MeasureName;   // Name without the color codes - used for measuring only
    var Material CountryIcon;
    var Material TeamIcon;      // TSC captain / carrier icon
    var Material PreIcon, PostIcon;
    var Color    PreIconColor, PostIconColor;
    var bool     bAdmin;
    var byte     PlayoffCount, TourneyWins, BlameCount;  // TSC Icons / Iceman's "PNG" / Poops
    var float    IconSize;      // font height
    var float    TextWidth;     // width of MeasureName
    var float    TotalWidth;    // name + all of the icons
};

struct SScoreRow
{
    var PlayerReplicationInfo   PRI;
    var KFPlayerReplicationInfo KFPRI;
    var ScrnCustomPRI           ScrnPRI;

    var bool bSeen;             // transient marker used while syncing the cache with GRI.PRIArray
    var bool bQuit;             // player left after the game had ended
    var bool bAdmin;            // TSC draws the admin icon separately from the name cell

    var SNameCell NameCell;
    var Color     NameColor;

    var Material Avatar, ClanIcon, StoryIcon, PerkIcon, StarIcon;
    var bool     bAvatarIsPortrait;
    var byte     PerkStars;

    var string KillsText, AssistsText, DamageText, HealText, DeathsText, CashText, TimeText,
               NetText, StatusText;
    var Color  KillsColor, AssistsColor, DamageColor, HealColor, DeathsColor, NetColor, StatusColor;
    var float  KillsW, AssistsW, SeparatorW, DamageW, HealW, DeathsW, CashW, TimeW, NetW, StatusW;
};

var transient array<SScoreRow> Cache;

var float UpdateFrequency;          // seconds between two cache updates
var transient float NextUpdateTime;
var transient bool bFrozen;         // game over: rows and totals are a frozen result snapshot

// header / footer data, rebuilt together with the rows
var transient string HeaderLine1, HeaderLine2, HeaderLine3, TeamDoshText, SpectatorLine;
// Players who joined after the game had ended - the frozen cache gets no rows for them
var transient string NewcomerLine;
var transient float  HeaderLine1W, HeaderLine2W, HeaderLine3W;
var transient int    PlayerCount, SpecCount, AliveCount, NotShownCount;
var transient int    RowCount;      // cached rows actually drawn (includes quitters)
var transient int    TotalKills, TotalDeaths, TotalCash;
var transient int    MaxKills, MaxAss, MaxDamage, MaxHeals, MaxDeaths;
var transient int    FontReduction;
var transient float  HeaderOffsetY, HeaderYL;
var transient float  ShrinkYL;


// ============================================================================
//                      NAME CELL
// ============================================================================

static function ResolveNameCell(PlayerReplicationInfo PRI, ScrnCustomPRI ScrnPRI, out SNameCell Cell,
    optional byte MaxLen, optional bool bNoColorTags)
{
    local string S;
    local int pos;
    local KFPlayerReplicationInfo KFPRI;

    Cell.CountryIcon = none;
    Cell.TeamIcon = none;
    Cell.PreIcon = none;
    Cell.PostIcon = none;
    Cell.PlayoffCount = 0;
    Cell.TourneyWins = 0;
    Cell.BlameCount = 0;
    Cell.Name = "";
    Cell.MeasureName = "";
    Cell.bAdmin = false;

    if ( PRI == none )
        return;

    Cell.bAdmin = PRI.bAdmin;
    KFPRI = KFPlayerReplicationInfo(PRI);

    if ( bNoColorTags )
        S = class'ScrnCustomPRI'.static.GetPlainName(PRI, ScrnPRI);
    else
        S = class'ScrnCustomPRI'.static.GetColoredName(PRI, ScrnPRI);

    if ( MaxLen > 0 )
        S = class'ScrnFunctions'.static.LeftCol(S, MaxLen);

    // country tags
    if ( Mid(S,0,1) == "[" ) {
        if ( Mid(S,3,1) == "]" )
            pos = 3;
        else if ( Mid(S,4,1) == "]" )
            pos = 4;

        if ( pos > 0 ) {
            if ( Mid(S,1,pos-1) == "EU" ) {
                Cell.CountryIcon = Texture'ScrnTex.HUD.EU';
                PRI.Skins[0] = Cell.CountryIcon;
            }
            else
                Cell.CountryIcon = GetCountryFlag(PRI);

            if ( Cell.CountryIcon != none || Mid(S,1,pos-1) == "???" ) {
                S = Mid(S, pos+1);
                if ( Mid(S,0,1) == " " || Mid(S,0,1) == "_" )
                    S = Mid(S, 1); // remove leading space
            }
        }
    }

    if ( ScrnPRI != none ) {
        Cell.PreIcon = ScrnPRI.GetPreNameIcon();
        if ( Cell.PreIcon != none ) {
            if ( ScrnPRI.PrefixIconColor.A == 0 && KFPRI != none )
                Cell.PreIconColor = class'ScrnHUD'.static.PerkColor(KFPRI.ClientVeteranSkillLevel);
            else if ( ScrnPRI.PrefixIconColor.A == 1 && PRI.Team != none && PRI.Team.TeamIndex < 2 )
                Cell.PreIconColor = class'ScrnHUD'.default.TextColors[PRI.Team.TeamIndex];
            else
                Cell.PreIconColor = ScrnPRI.PrefixIconColor;
        }

        Cell.PostIcon = ScrnPRI.GetPostNameIcon();
        if ( Cell.PostIcon != none ) {
            if ( ScrnPRI.PostfixIconColor.A == 0 && KFPRI != none )
                Cell.PostIconColor = class'ScrnHUD'.static.PerkColor(KFPRI.ClientVeteranSkillLevel);
            else if ( ScrnPRI.PostfixIconColor.A == 1 && PRI.Team != none && PRI.Team.TeamIndex < 2 )
                Cell.PostIconColor = class'ScrnHUD'.default.TextColors[PRI.Team.TeamIndex];
            else
                Cell.PostIconColor = ScrnPRI.PostfixIconColor;
        }

        Cell.PlayoffCount = ScrnPRI.GetPlayoffCount();
        Cell.TourneyWins = ScrnPRI.GetTourneyWinCount();
        Cell.BlameCount = ScrnPRI.BlameCounter;
    }

    Cell.Name = S;
    Cell.MeasureName = class'ScrnF'.static.StripColor(S);
}

static final function int BlameIconCount(byte BlameCount)
{
    return (BlameCount / 5) + (BlameCount % 5);
}

// Resolution-dependent par of the name cell.
// The client may change resolution while the scoreboard is open via setres command.
static function MeasureNameCell(Canvas C, out SNameCell Cell)
{
    local float XL, YL;

    C.TextSize(Cell.Name, XL, Cell.IconSize);
    C.TextSize(Cell.MeasureName, Cell.TextWidth, YL);

    Cell.TotalWidth = Cell.TextWidth;
    if ( Cell.CountryIcon != none )
        Cell.TotalWidth += Cell.IconSize * 1.2;
    if ( Cell.bAdmin )
        Cell.TotalWidth += Cell.IconSize * 1.1;
    if ( Cell.TeamIcon != none )
        Cell.TotalWidth += Cell.IconSize * 1.2;
    if ( Cell.PreIcon != none )
        Cell.TotalWidth += Cell.IconSize * 1.1;
    if ( Cell.PostIcon != none )
        Cell.TotalWidth += Cell.IconSize * 1.3;
    if ( Cell.PlayoffCount > 0 )
        Cell.TotalWidth += Cell.IconSize * (Cell.PlayoffCount + 0.2);
    Cell.TotalWidth += Cell.IconSize * BlameIconCount(Cell.BlameCount);
}

// @return total drawn width, i.e. X + return value = right edge of the name cell
static function float DrawNameCell(Canvas C, out SNameCell Cell, float X, float Y)
{
    local Color OriginalColor, IconColor;
    local float Offset, IconSize;
    local Material M;
    local int i, count;

    OriginalColor = C.DrawColor;
    IconSize = Cell.IconSize;

    C.DrawColor = Class'HudBase'.Default.WhiteColor;
    C.DrawColor.A = OriginalColor.A;

    if ( Cell.CountryIcon != none ) {
        C.SetPos(X + Offset, Y + IconSize*0.2);
        C.DrawTile(Cell.CountryIcon, IconSize, IconSize, 0, 0,
                Cell.CountryIcon.MaterialUSize(), Cell.CountryIcon.MaterialVSize());
        Offset += IconSize * 1.2;
    }

    // Display admin.
    if ( Cell.bAdmin ) {
        M = default.AdminIcon;
        C.SetPos(X + Offset, Y);
        C.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
        Offset += IconSize * 1.1;
    }

    if ( Cell.TeamIcon != none ) {
        C.SetPos(X + Offset, Y);
        C.DrawTile(Cell.TeamIcon, IconSize, IconSize, 0, 0,
                Cell.TeamIcon.MaterialUSize(), Cell.TeamIcon.MaterialVSize());
        Offset += IconSize * 1.2;
    }

    if ( Cell.PreIcon != none ) {
        IconColor = Cell.PreIconColor;
        IconColor.A = OriginalColor.A;
        C.DrawColor = IconColor;
        C.SetPos(X + Offset, Y);
        C.DrawTile(Cell.PreIcon, IconSize, IconSize, 0, 0,
                Cell.PreIcon.MaterialUSize(), Cell.PreIcon.MaterialVSize());
        Offset += IconSize * 1.1;
    }

    // name
    if ( C.Style != ERenderStyle.STY_None ) {
        C.DrawColor = OriginalColor;
        C.SetPos(X + Offset, Y);
        C.DrawTextClipped(Cell.Name, false);
    }
    Offset += Cell.TextWidth;

    if ( Cell.PostIcon != none ) {
        IconColor = Cell.PostIconColor;
        IconColor.A = OriginalColor.A;
        C.DrawColor = IconColor;
        Offset += IconSize * 0.1;
        C.SetPos(X + Offset, Y);
        C.DrawTile(Cell.PostIcon, IconSize, IconSize, 0, 0,
                Cell.PostIcon.MaterialUSize(), Cell.PostIcon.MaterialVSize());
        Offset += IconSize * 1.2;
    }

    C.DrawColor = Class'HudBase'.Default.WhiteColor;
    C.DrawColor.A = OriginalColor.A;

    // tournament icons
    if ( Cell.PlayoffCount > 0 ) {
        Offset += IconSize * 0.1;
        count = Cell.TourneyWins;
        for ( i = Cell.PlayoffCount; i > 0; --i ) {
            if ( count > 0 ) {
                M = Texture'ScrnTex.Tourney.TSC_Name_IconW';
                count--;
            }
            else
                M = Texture'ScrnTex.Tourney.TSC_Name_Icon';
            C.SetPos(X + Offset, Y);
            C.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
            Offset += IconSize;
        }
        Offset += IconSize * 0.1;
    }

    // blame icons
    count = Cell.BlameCount;
    while ( count > 0 ) {
        if ( count >= 5 ) {
            M = default.BigBlameIcon;
            count -= 5;
        }
        else {
            M = default.BlameIcon;
            count--;
        }
        C.SetPos(X + Offset, Y);
        C.DrawTile(M, IconSize, IconSize, 0, 0, M.MaterialUSize(), M.MaterialVSize());
        Offset += IconSize;
    }

    C.DrawColor = OriginalColor;
    return Offset;
}

// Resolve + measure + draw. Used by other callers like ScrnHUD that do not pre-cache.
static function float DrawCountryNameSE( Canvas C, PlayerReplicationInfo PRI, float X, float Y,
    optional byte MaxLen, optional bool bNoColorTags )
{
    local SNameCell Cell;

    if ( PRI == none )
        return 0;

    ResolveNameCell(PRI, class'ScrnCustomPRI'.static.FindMe(PRI), Cell, MaxLen, bNoColorTags);
    MeasureNameCell(C, Cell);
    return DrawNameCell(C, Cell, X, Y);
}

static function TextSizeCountrySE( Canvas C, PlayerReplicationInfo PRI, out float XL, out float YL )
{
    local SNameCell Cell;

    C.TextSize("ABC", XL, YL);
    if ( PRI == none )
        return;

    ResolveNameCell(PRI, class'ScrnCustomPRI'.static.FindMe(PRI), Cell, 0, true);
    MeasureNameCell(C, Cell);
    XL = Cell.TotalWidth;
}


// ============================================================================
//                      LAYOUT
// ============================================================================

// Removed sorting by kill counter.
function bool UpdateGRI()
{
    if (GRI == none) {
        InitGRI();
    }
    return GRI != none;
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

    PlayerIconSize = Canvas.ClipY * 0.05;
    PlayerIconSpacing = default.PlayerIconSpacing;

    if (Canvas.ClipX < 1200) {
        BoxWidth = 0.99;
        PlayerIconSize = 0;
        PlayerIconSpacing = 0;
    }
    else if (Canvas.ClipX < 1600)
        BoxWidth = 0.90;
    else if (Canvas.ClipX < 2500)
        BoxWidth = 0.80;
    else if (Canvas.ClipX < 3800)
        BoxWidth = 0.65;
    else
        BoxWidth = 0.50;
    BoxWidth *= Canvas.ClipX;
    BoxX = (Canvas.ClipX - BoxWidth) / 2;
    PlayerIconSize = fmin(PlayerIconSize, BoxX);

    Canvas.Font = class'ScrnHUD'.static.LoadMenuFontStatic(PlayerFontIndex);
    Canvas.TextSize("0", X0, YL);
    BoxHeight = 1.2 * YL;
    BoxSpaceY = fmax(0.25 * YL, PlayerIconSize - BoxHeight + PlayerIconSpacing);

    BaseBoxHeight = BoxHeight;
    BaseBoxSpaceY = BoxSpaceY;
    BasePlayerIconSize = PlayerIconSize;

    if (Canvas.ClipX > 3000)
        M = X0 * 4.0;
    else if (Canvas.ClipX > 2000)
        M = X0 * 2.0;
    else
        M = X0;

    HealthX = BoxX + M + 7*X0;
    VetX = HealthX + M;
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

// Shrinks the row font until all of the rows fit on the screen.
// @post Leaves Canvas.Font set to the final row font.
simulated function ShrinkFont(Canvas Canvas)
{
    local float XL, YL;

    FontReduction = 0;
    NotShownCount = 0;
    ShrinkYL = HeaderYL;
    BoxHeight = BaseBoxHeight;
    BoxSpaceY = BaseBoxSpaceY;
    PlayerIconSize = BasePlayerIconSize;

    Canvas.Font = class'ScrnHUD'.static.LoadMenuFontStatic(PlayerFontIndex);
    if ((BoxHeight + BoxSpaceY) * RowCount > Canvas.ClipY * 0.85 - HeaderOffsetY) {
        // in the first iteration, we don't reduce the font; just remove avatars
        FontReduction = -1;
        PlayerIconSize = 0;

        while ((BoxHeight + BoxSpaceY) * RowCount > Canvas.ClipY * 0.85 - HeaderOffsetY) {
            // Shrink font, if too small then break loop.
            if (PlayerFontIndex + FontReduction >= 4) {
                // We need to remove some player names here to make it fit.
                NotShownCount = RowCount - int((Canvas.ClipY - HeaderOffsetY) / (BoxHeight + BoxSpaceY)) + 1;
                RowCount -= NotShownCount;
                break;
            }
            ++FontReduction;
            Canvas.Font = class'ScrnHUD'.static.LoadMenuFontStatic(PlayerFontIndex + FontReduction);
            Canvas.TextSize("[Test]", XL, YL);
            ShrinkYL = YL;
            BoxHeight = 1.2 * YL;
            if (FontReduction < 2) {
                BoxSpaceY = 4;
            }
            else {
                BoxSpaceY = 0;
            }
        }
    }
}


// ============================================================================
//                      CACHE UPDATE
// ============================================================================

simulated function ScanPlayers(out array<PlayerReplicationInfo> Active)
{
    local int i;
    local PlayerReplicationInfo PRI;
    local KFPlayerReplicationInfo KFPRI;
    local ScrnCustomPRI ScrnPRI;

    Active.Length = 0;
    PlayerCount = 0;
    SpecCount = 0;
    AliveCount = 0;
    MaxKills = 0;
    MaxAss = 0;
    MaxDeaths = 0;
    MaxDamage = 0;
    MaxHeals = 0;
    SpectatorLine = "";
    NewcomerLine = "";

    for ( i = 0; i < GRI.PRIArray.Length; i++) {
        PRI = GRI.PRIArray[i];
        if ( PRI == none )
            continue;

        KFPRI = KFPlayerReplicationInfo(PRI);
        ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PRI);
        if (!PRI.bOnlySpectator) {
            if( !PRI.bOutOfLives && KFPRI != none && KFPRI.PlayerHealth > 0 )
                ++AliveCount;
            PlayerCount++;
            Active[Active.Length] = PRI;
            if ( KFPRI != none ) {
                MaxKills = max(MaxKills, KFPRI.Kills);
                MaxAss =  max(MaxAss, KFPRI.KillAssists);
                MaxDeaths =  max(MaxDeaths, KFPRI.Deaths);
            }
            if (ScrnPRI != none) {
                MaxDamage = max(MaxDamage, ScrnPRI.TotalDamageK);
                MaxHeals = max(MaxHeals, ScrnPRI.TotalHeal);
            }
        }
        else if ( PRI.PlayerID != 0 || PRI.PlayerName != "WebAdmin" ) {
            ++SpecCount;
            SpectatorLine @= GetSpectatorNameFast(PRI, ScrnPRI) $ " |";
        }
    }
}

simulated function string GetSpectatorNameFast(PlayerReplicationInfo PRI, ScrnCustomPRI ScrnPRI)
{
    return class'ScrnCustomPRI'.static.GetPlainName(PRI, ScrnPRI);
}

final simulated function string GetSpectatorName(PlayerReplicationInfo PRI)
{
    return GetSpectatorNameFast(PRI, class'ScrnCustomPRI'.static.FindMe(PRI));
}

simulated function int FindRow(out array<SScoreRow> Rows, PlayerReplicationInfo PRI)
{
    local int i;

    for ( i = 0; i < Rows.Length; ++i ) {
        if ( Rows[i].PRI == PRI )
            return i;
    }
    return -1;
}

// Synchronizes the cached rows with the actual player list without reordering the existing entries.
// The local player is always in row 0 unless spectating.
// Newcomers are put at the end of the list.
simulated function SyncRows(out array<SScoreRow> Rows, out array<PlayerReplicationInfo> Active,
        PlayerReplicationInfo OwnerPRI)
{
    local int i, j;
    local SScoreRow Row;

    for ( i = 0; i < Rows.Length; ++i )
        Rows[i].bSeen = false;

    for ( i = 0; i < Active.Length; ++i ) {
        j = FindRow(Rows, Active[i]);
        if ( j < 0 ) {
            // a new player: pin myself to the top, append everybody else to the bottom
            if ( Active[i] == OwnerPRI ) {
                Rows.Insert(0, 1);
                j = 0;
            }
            else {
                j = Rows.Length;
                Rows.Length = j + 1;
            }
            Rows[j].PRI = Active[i];
            Rows[j].bQuit = false;
        }
        Rows[j].bSeen = true;
    }

    for ( i = Rows.Length - 1; i >= 0; --i ) {
        if ( !Rows[i].bSeen )
            Rows.Remove(i, 1);
    }

    // If OwnerPRI got replicated later and got inserted to the back of the Cache (is it even possible?)
    if (OwnerPRI != none) {
        j = FindRow(Rows, OwnerPRI);
        if (j > 0) {
            Row = Rows[j];
            Rows.Remove(j, 1);
            Rows.Insert(0, 1);
            Rows[0] = Row;
        }
    }
}

// Those who joined after the game end are not displayed do not appear on the scoreboard.
// They are drawn on the special footer line - like spectators
simulated function AddNewcomers(out array<SScoreRow> Rows, out array<PlayerReplicationInfo> Active)
{
    local int i;

    for ( i = 0; i < Active.Length; ++i ) {
        if ( FindRow(Rows, Active[i]) < 0 )
            NewcomerLine @= GetSpectatorName(Active[i]) $ " |";
    }
}

simulated function UpdateGameplayRow(Canvas Canvas, out SScoreRow Row, bool bStoryMode)
{
    local PlayerReplicationInfo PRI;
    local KFPlayerReplicationInfo KFPRI;
    local ScrnCustomPRI ScrnPRI;
    local KF_StoryPRI StoryPRI;
    local Material VeterancyBox, StarBox;
    local float YL;

    PRI = Row.PRI;
    if ( PRI == none )
        return; // a quitter: keep whatever was resolved before they left

    KFPRI = KFPlayerReplicationInfo(PRI);
    ScrnPRI = class'ScrnCustomPRI'.static.FindMe(PRI);
    StoryPRI = KF_StoryPRI(PRI);
    Row.KFPRI = KFPRI;
    Row.ScrnPRI = ScrnPRI;
    Row.bAdmin = PRI.bAdmin;

    // avatar
    Row.Avatar = none;
    Row.ClanIcon = none;
    Row.bAvatarIsPortrait = false;
    if ( ScrnPRI != none ) {
        Row.Avatar = ScrnPRI.GetAvatar();
        Row.ClanIcon = ScrnPRI.GetClanIcon();
    }
    if ( Row.Avatar == none ) {
        Row.Avatar = PRI.GetPortrait();
        Row.bAvatarIsPortrait = true;
    }

    // name
    ResolveNameCell(PRI, ScrnPRI, Row.NameCell);
    MeasureNameCell(Canvas, Row.NameCell);
    if (PRI.bAdmin)
        Row.NameColor = Class'HudBase'.Default.RedColor;
    else
        Row.NameColor = Class'HudBase'.Default.WhiteColor;

    // story icon
    Row.StoryIcon = none;
    if ( bStoryMode && StoryPRI != none )
        Row.StoryIcon = StoryPRI.GetFloatingIconMat();

    // perk
    Row.PerkIcon = none;
    Row.StarIcon = none;
    Row.PerkStars = 0;
    if (KFPRI != None && Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill) != none) {
        Row.PerkStars = Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill).Static.PreDrawPerk(Canvas,
                KFPRI.ClientVeteranSkillLevel, VeterancyBox, StarBox);
        Row.PerkIcon = VeterancyBox;
        Row.StarIcon = StarBox;
        Row.PerkStars = min(Row.PerkStars, 25);
    }

    // kills
    Row.KillsText = "";
    Row.AssistsText = "";
    if ( KFPRI != none ) {
        if (KFPRI.Kills == MaxKills && MaxKills > 0 && PlayerCount > 1)
            Row.KillsColor = BestColor;
        else
            Row.KillsColor = HUDClass.default.WhiteColor;
        TotalKills += KFPRI.Kills;
        Row.KillsText = string(KFPRI.Kills);
        Canvas.TextSize(Row.KillsText, Row.KillsW, YL);

        if (KFPRI.KillAssists > 0) {
            Row.AssistsText = string(KFPRI.KillAssists);
            Canvas.TextSize(KillsAssSeparator, Row.SeparatorW, YL);
            Canvas.TextSize(Row.AssistsText, Row.AssistsW, YL);
            if (KFPRI.KillAssists == MaxAss && PlayerCount > 1)
                Row.AssistsColor = BestColor;
            else
                Row.AssistsColor = AssColor;
        }
    }

    // damage and heals
    Row.DamageText = "";
    Row.HealText = "";
    if (ScrnPRI != none) {
        if (ScrnPRI.TotalDamageK > 0) {
            if (ScrnPRI.TotalDamageK == MaxDamage && PlayerCount > 1)
                Row.DamageColor = BestColor;
            else
                Row.DamageColor = HUDClass.default.WhiteColor;
            Row.DamageText = ScrnPRI.TotalDamageK $ "k";
            Canvas.TextSize(Row.DamageText, Row.DamageW, YL);
        }
        if (ScrnPRI.TotalHeal > 0) {
            if (ScrnPRI.TotalHeal == MaxHeals && PlayerCount > 1)
                Row.HealColor = BestColor;
            else
                Row.HealColor = HUDClass.default.WhiteColor;
            Row.HealText = string(ScrnPRI.TotalHeal);
            Canvas.TextSize(Row.HealText, Row.HealW, YL);
        }
    }

    // deaths
    Row.DeathsText = "";
    if (PRI.Deaths > 0) {
        if (PRI.Deaths == MaxDeaths)
            Row.DeathsColor = HUDClass.default.RedColor;
        else
            Row.DeathsColor = HUDClass.default.WhiteColor;
        TotalDeaths += PRI.Deaths;
        Row.DeathsText = string(int(PRI.Deaths));
        Canvas.TextSize(Row.DeathsText, Row.DeathsW, YL);
    }

    // dosh
    Row.CashText = "";
    if (int(PRI.Score) != 0) {
        TotalCash += PRI.Score;
        Row.CashText = class'ScrnUnicode'.default.Dosh $ int(PRI.Score);
        Canvas.TextSize(Row.CashText, Row.CashW, YL);
    }

    // play time
    if (GRI.ElapsedTime < PRI.StartTime) // Login timer error, fix it.
        GRI.ElapsedTime = PRI.StartTime;
    Row.TimeText = FormatTime(GRI.ElapsedTime - PRI.StartTime);
    Canvas.TextSize(Row.TimeText, Row.TimeW, YL);

    // health or ready status
    if (!GRI.bMatchHasBegun) {
        if (PRI.bReadyToPlay) {
            Row.StatusColor = HUDClass.default.WhiteColor;
            Row.StatusText = ReadyText;
        }
        else {
            Row.StatusColor = HUDClass.default.RedColor;
            Row.StatusText = NotReadyText;
        }
    }
    else if (PRI.bOutOfLives || KFPRI == none || KFPRI.PlayerHealth <= 0) {
        Row.StatusColor = DeadColor;
        Row.StatusText = OutText;
    }
    else {
        Row.StatusText = KFPRI.PlayerHealth @ HealthyString;
        if (KFPRI.PlayerHealth >= 90)
            Row.StatusColor = HUDClass.default.GreenColor;
        else if (KFPRI.PlayerHealth >= 50)
            Row.StatusColor = HUDClass.default.GoldColor;
        else
            Row.StatusColor = HUDClass.default.RedColor;
    }
    Canvas.TextSize(Row.StatusText, Row.StatusW, YL);
}

// Update PING even after the game end (bFrozen=True)
// If the player disconnected after the game end, PING=QUIT
simulated function UpdateTelemetryRow(Canvas Canvas, out SScoreRow Row)
{
    local PlayerReplicationInfo PRI;
    local float YL;

    PRI = Row.PRI;
    if ( PRI == none ) {
        if ( !Row.bQuit )
            MarkQuitter(Canvas, Row);
        return;
    }

    GetPingText(Canvas, PRI, Row.NetText, Row.NetColor);
    Canvas.TextSize(Row.NetText, Row.NetW, YL);
}

simulated function GetPingText(Canvas Canvas, PlayerReplicationInfo PRI, out String NetText, out Color NetColor)
{
    NetColor = Class'HudBase'.Default.WhiteColor;
    if (PRI.bBot) {
        NetText = BotText;
    }
    else if (PRI.Ping == 255) {
        NetColor = HUDClass.default.RedColor;
        NetText = strPingMax;
    }
    else {
        NetText = string(PRI.Ping*4);
        if (PRI.PacketLoss > 0) {
            NetText $= "!";
            NetColor = HUDClass.default.RedColor;
        }
        if (PRI.Ping >= 50) { // *4 = 200
            NetColor = HUDClass.default.RedColor;
        }
        else if ( PRI.Ping >= 25 ) { // *4 = 100
            NetColor = HUDClass.default.GoldColor;
        }
    }
}

simulated function MarkQuitter(Canvas Canvas, out SScoreRow Row)
{
    local float YL;

    Row.bQuit = true;
    Row.PRI = none;
    Row.KFPRI = none;
    Row.ScrnPRI = none;
    Row.NetText = QuitText;
    Row.NetColor = HUDClass.default.RedColor;
    Canvas.TextSize(Row.NetText, Row.NetW, YL);
}

// Remeasures the frozen part of a row from its cached strings only to ensure a resolution change works
// correctly even for rows whose PRI is gone.
// The telemetry part remeasures itself.
simulated function RemeasureGameplayRow(Canvas Canvas, out SScoreRow Row)
{
    local float YL;

    MeasureNameCell(Canvas, Row.NameCell);
    Canvas.TextSize(Row.KillsText, Row.KillsW, YL);
    Canvas.TextSize(KillsAssSeparator, Row.SeparatorW, YL);
    Canvas.TextSize(Row.AssistsText, Row.AssistsW, YL);
    Canvas.TextSize(Row.DamageText, Row.DamageW, YL);
    Canvas.TextSize(Row.HealText, Row.HealW, YL);
    Canvas.TextSize(Row.DeathsText, Row.DeathsW, YL);
    Canvas.TextSize(Row.CashText, Row.CashW, YL);
    Canvas.TextSize(Row.TimeText, Row.TimeW, YL);
    Canvas.TextSize(Row.StatusText, Row.StatusW, YL);
}

simulated function UpdateHeader(Canvas Canvas)
{
    local ScrnGameReplicationInfo ScrnGRI;
    local PlayerReplicationInfo OwnerPRI;
    local KF_StoryObjective CurrentObj;
    local string S;
    local float YL;

    ScrnGRI = ScrnGameReplicationInfo(GRI);
    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;

    Canvas.Font = class'ScrnHUD'.static.GetSmallMenuFont(Canvas);

    // Title Line 1
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
    HeaderLine1 = S;
    Canvas.TextSize(S, HeaderLine1W, YL);

    // Title Line 2
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
    HeaderLine2 = S;
    Canvas.TextSize(S, HeaderLine2W, YL);

    // Title Line 3
    S = PlayerCountText @ PlayerCount;
    if ( ScrnGRI != none && ScrnGRI.FakedPlayers > PlayerCount ) {
        S $= " ("$ScrnGRI.FakedPlayers$")";
    }
    if ( SpecCount > 0 ) {
        S @= SpectatorCountText @ SpecCount;
    }
    S @= AliveCountText @ AliveCount;
    if ( ScrnGRI != none && ScrnGRI.FakedAlivePlayers > AliveCount ) {
        S $= " ("$ScrnGRI.FakedAlivePlayers$")";
    }
    if ( OwnerPRI != none && OwnerPRI.Team != none )
        S @= "|" @ TeamScoreString;
    HeaderLine3 = S;
    Canvas.TextSize(S, HeaderLine3W, YL);

    TeamDoshText = "";
    if ( OwnerPRI != none && OwnerPRI.Team != none )
        TeamDoshText = " " $ class'ScrnUnicode'.default.Dosh $ int(OwnerPRI.Team.Score);

    HeaderYL = YL;
    HeaderOffsetY = Canvas.ClipY * 0.11 + YL + YL*3.f;
}

// Rebuilds the whole cache. Called at most once per UpdateFrequency seconds.
// XXX: Zed Time slows down the update process. Does it really matter?
// Pro-Tip: Do not view the scoreboard during ZT ;)
simulated function UpdateCache(Canvas Canvas)
{
    local array<PlayerReplicationInfo> Active;
    local KFGameReplicationInfo KFGRI;
    local PlayerReplicationInfo OwnerPRI;
    local bool bStoryMode, bResolutionChanged;
    local int i;

    KFGRI = KFGameReplicationInfo(GRI);
    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
    bStoryMode = KF_StoryPRI(OwnerPRI) != none;

    if (bFrozen && KFGRI != none && KFGRI.EndGameType == 0) {
        // Current impossible. Reserved for future use, if ScrnGameType will support Reset()
        bFrozen = false;
        Cache.Length = 0;
    }

    ScanPlayers(Active);

    if ( bFrozen )
        AddNewcomers(Cache, Active);
    else
        SyncRows(Cache, Active, OwnerPRI);
    RowCount = Cache.Length;

    UpdateHeader(Canvas);

    bResolutionChanged = OldClipX != Canvas.ClipX || OldClipY != Canvas.ClipY;
    if (LastDrawnPlayerCount != RowCount || bResolutionChanged) {
        LastDrawnPlayerCount = RowCount;
        ResolutionChanged(Canvas);
        OldClipX = Canvas.ClipX;
        OldClipY = Canvas.ClipY;
    }
    ShrinkFont(Canvas); // leaves Canvas.Font set to the row font

    if ( bFrozen ) {
        for ( i = 0; i < Cache.Length; ++i ) {
            if ( bResolutionChanged )
                RemeasureGameplayRow(Canvas, Cache[i]);
            UpdateTelemetryRow(Canvas, Cache[i]);
        }
        return;
    }

    TotalKills = 0;
    TotalDeaths = 0;
    TotalCash = 0;
    for ( i = 0; i < Cache.Length; ++i ) {
        UpdateGameplayRow(Canvas, Cache[i], bStoryMode);
        UpdateTelemetryRow(Canvas, Cache[i]);
    }

    // We just did the final update after the game has ended.
    // Freeze the cache updates to display the snapshop of the end results.
    if ( KFGRI != none && KFGRI.EndGameType > 0 )
        bFrozen = true;
}


// ============================================================================
//                      DRAWING
// ============================================================================

simulated event UpdateScoreBoard(Canvas Canvas)
{
    if ( KFPlayerController(Owner) == none || GRI == none )
        return;

    if ( Level.TimeSeconds >= NextUpdateTime || OldClipX != Canvas.ClipX || OldClipY != Canvas.ClipY ) {
        NextUpdateTime = Level.TimeSeconds + UpdateFrequency;
        UpdateCache(Canvas);
    }

    DrawCache(Canvas);
}

simulated function DrawCache(Canvas Canvas)
{
    local PlayerReplicationInfo OwnerPRI;
    local int i, BoxTextOffsetY, TitleYPos;
    local float XL, YL, y, IconToBoxY, OriginalClipX;
    local float DeathsXL, KillsXL, NetXL;
    local int LineHeight;
    local string S;

    OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;

    // ---- header ----
    Canvas.Font = class'ScrnHUD'.static.GetSmallMenuFont(Canvas);
    Canvas.DrawColor = HUDClass.default.RedColor;
    Canvas.Style = ERenderStyle.STY_Normal;

    Canvas.SetPos( (Canvas.ClipX - HeaderLine1W)/2, Canvas.ClipY * 0.11 - HeaderYL);
    Canvas.DrawTextClipped(HeaderLine1);

    Canvas.SetPos( (Canvas.ClipX - HeaderLine2W)/2, Canvas.ClipY * 0.11 );
    Canvas.DrawTextClipped(HeaderLine2);

    Canvas.SetPos(0.5 * (Canvas.ClipX - HeaderLine3W), Canvas.ClipY * 0.11 + HeaderYL);
    Canvas.DrawTextClipped(HeaderLine3);
    if ( TeamDoshText != "" ) {
        Canvas.DrawColor = DoshColor;
        Canvas.SetPos(0.5 * (Canvas.ClipX + HeaderLine3W), Canvas.ClipY * 0.11 + HeaderYL);
        Canvas.DrawTextClipped(TeamDoshText);
    }

    Canvas.Font = class'ScrnHUD'.static.LoadMenuFontStatic(PlayerFontIndex + max(FontReduction, 0));
    Canvas.TextSize("0", XL, YL);

    IconToBoxY = fmax(0.0, (PlayerIconSize - BoxHeight)/2);
    LineHeight = BoxHeight + BoxSpaceY;

    // ---- background boxes ----
    y = HeaderOffsetY + IconToBoxY;
    Canvas.Style = ERenderStyle.STY_Alpha;
    for (i = 0; i < RowCount; ++i) {
        Canvas.DrawColor = HUDClass.default.WhiteColor;
        Canvas.DrawColor.A = 128;
        Canvas.SetPos(BoxX, y);
        Canvas.DrawTileStretched( BoxMaterial, BoxWidth, BoxHeight);

        // highlight myself
        if (Cache[i].PRI == OwnerPRI && OwnerPRI != none) {
            Canvas.SetDrawColor(0, 255, 0, 48);
            Canvas.SetPos(BoxX + 1, y + 1);
            Canvas.DrawTileStretched(WhiteMaterial, BoxWidth-2, BoxHeight-2);
        }

        y += LineHeight;
    }

    if (NotShownCount > 0) {
        Canvas.DrawColor = HUDClass.default.RedColor;
        Canvas.SetPos(BoxX, HeaderOffsetY + y);
        Canvas.DrawTileStretched( BoxMaterial, BoxWidth, BoxHeight);
    }

    // ---- column headers ----
    TitleYPos = HeaderOffsetY - 1.1 * ShrinkYL;
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

    Canvas.TextSize(HealthText, XL, YL);
    Canvas.SetPos(HealthX - XL, TitleYPos);
    Canvas.DrawTextClipped(HealthText);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(NetX - NetXL, TitleYPos);
    Canvas.DrawTextClipped(NetText);

    // ---- player rows ----
    OriginalClipX = Canvas.ClipX;
    BoxTextOffsetY = (BoxHeight - YL)/2;
    y = HeaderOffsetY + IconToBoxY + BoxTextOffsetY;
    for (i = 0; i < RowCount; ++i) {
        DrawRow(Canvas, Cache[i], y, IconToBoxY, BoxTextOffsetY, OriginalClipX);
        y += LineHeight;
    }

    y -= BoxSpaceY - IconToBoxY;

    // ---- totals ----
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
            S = string(TotalKills);
            Canvas.TextSize(S, XL, YL);
            Canvas.SetPos(KillsX - XL, y);
            Canvas.DrawTextClipped(S);
        }
        y += YL + BoxSpaceY - IconToBoxY;
    }

    // ---- footer ----
    Canvas.Font = class'ScrnHUD'.static.LoadMenuFontStatic(PlayerFontIndex + FontReduction + 2);
    Canvas.TextSize("0", XL, YL);
    if (NotShownCount > 0) {
        Canvas.DrawColor = HUDClass.default.GreenColor;
        Canvas.SetPos(NameX, y);
        Canvas.DrawText(NotShownCount@NotShownInfo,true);
        y += YL;
    }
    else if (SpectatorLine != "") {
        Canvas.DrawColor = SpecColor;
        Canvas.SetPos(BoxX, y);
        Canvas.DrawText(SpectatorsText $ ": |" $ SpectatorLine, true);
        y += YL;
    }
    if (NewcomerLine != "") {
        Canvas.DrawColor = HUDClass.default.GreenColor;
        Canvas.SetPos(BoxX, y);
        Canvas.DrawText(NewcomersText $ ": |" $ NewcomerLine, true);
    }
}

simulated function DrawRow(Canvas Canvas, out SScoreRow Row, float y, float IconToBoxY,
        float BoxTextOffsetY, float OriginalClipX)
{
    local Material M;

    // Avatar
    if (PlayerIconSize > 0) {
        Canvas.Style = ERenderStyle.STY_Alpha;
        Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
        Canvas.SetPos(BoxX - PlayerIconSize + PlayerIconMargin, y - IconToBoxY - BoxTextOffsetY + PlayerIconMargin);
        M = Row.Avatar;
        if ( M == none ) {
            // no avatar and no portrait - just the frame below
        }
        else if ( Row.bAvatarIsPortrait ) {
            // There is no typo - we use U size on both axis to cut down the bottom part of the
            // character portrait.
            Canvas.DrawTile(M, PlayerIconSize - 2*PlayerIconMargin, PlayerIconSize - 2*PlayerIconMargin,
                    0, M.MaterialVSize() * PlayerPortraitVShift, M.MaterialUSize(), M.MaterialUSize());
        }
        else {
            Canvas.DrawTile(M, PlayerIconSize - 2*PlayerIconMargin, PlayerIconSize - 2*PlayerIconMargin, 0, 0,
                    M.MaterialUSize(), M.MaterialVSize());
        }

        Canvas.SetPos(BoxX - PlayerIconSize, y - IconToBoxY - BoxTextOffsetY);
        Canvas.DrawTileStretched(PlayerIconBackground, PlayerIconSize, PlayerIconSize);

        if (Row.ClanIcon != none) {
            M = Row.ClanIcon;
            Canvas.SetPos(BoxX + BoxWidth + PlayerIconMargin, y - IconToBoxY - BoxTextOffsetY + PlayerIconMargin);
            Canvas.DrawTile(M, PlayerIconSize - 2*PlayerIconMargin, PlayerIconSize - 2*PlayerIconMargin, 0, 0,
                    M.MaterialUSize(), M.MaterialVSize());
            Canvas.SetPos(BoxX + BoxWidth, y - IconToBoxY - BoxTextOffsetY);
            Canvas.DrawTileStretched(PlayerIconBackground, PlayerIconSize, PlayerIconSize);
        }
        Canvas.Style = ERenderStyle.STY_Normal;
    }

    // Player Name
    Canvas.DrawColor = Row.NameColor;
    Canvas.ClipX = StoryIconXPos - StoryIconS;
    DrawNameCell(Canvas, Row.NameCell, NameX, y);
    Canvas.ClipX = OriginalClipX;

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    // display Story Icon
    if ( Row.StoryIcon != none ) {
        M = Row.StoryIcon;
        Canvas.SetPos(StoryIconXPos - StoryIconS * 0.5, y + 1 );
        Canvas.DrawTile(M, StoryIconS, StoryIconS, 0, 0, M.MaterialUSize(), M.MaterialVSize());
    }

    // Perk
    if (Row.PerkIcon != None) {
        DrawPerkWithStars(Canvas, VetX, y - BoxTextOffsetY, BoxHeight, Row.PerkStars, Row.PerkIcon, Row.StarIcon);
    }

    // Kills
    if (Row.KillsText != "") {
        Canvas.DrawColor = Row.KillsColor;
        Canvas.SetPos(KillsX - Row.KillsW, y);
        Canvas.DrawTextClipped(Row.KillsText);
    }

    // Assists
    if (Row.AssistsText != "") {
        Canvas.DrawColor = AssColor;
        Canvas.SetPos(KillsX, y);
        Canvas.DrawTextClipped(KillsAssSeparator);
        Canvas.SetPos(KillsX + Row.SeparatorW, y);
        Canvas.DrawColor = Row.AssistsColor;
        Canvas.DrawTextClipped(Row.AssistsText);
    }

    // Damage
    if (Row.DamageText != "") {
        Canvas.DrawColor = Row.DamageColor;
        Canvas.SetPos(DamageX - Row.DamageW, y);
        Canvas.DrawTextClipped(Row.DamageText);
    }

    // Heals
    if (Row.HealText != "") {
        Canvas.DrawColor = Row.HealColor;
        Canvas.SetPos(HealX - Row.HealW, y);
        Canvas.DrawTextClipped(Row.HealText);
    }

    // Deaths
    if (Row.DeathsText != "") {
        Canvas.DrawColor = Row.DeathsColor;
        Canvas.SetPos(DeathsX - Row.DeathsW/2, y);
        Canvas.DrawTextClipped(Row.DeathsText);
    }

    // Dosh
    if (Row.CashText != "") {
        Canvas.DrawColor = DoshColor;
        Canvas.SetPos(CashX - Row.CashW*0.5f, y);
        Canvas.DrawText(Row.CashText, true);
    }

    // play time
    if (Row.TimeText != "") {
        Canvas.DrawColor = HUDClass.default.WhiteColor;
        Canvas.SetPos(TimeX - Row.TimeW*0.5f, y);
        Canvas.DrawText(Row.TimeText, true);
    }

    // ping
    if (Row.NetText != "") {
        Canvas.DrawColor = Row.NetColor;
        Canvas.SetPos(NetX - Row.NetW, y);
        Canvas.DrawTextClipped(Row.NetText);
    }

    // health / status / QUIT
    if (Row.StatusText != "") {
        Canvas.DrawColor = Row.StatusColor;
        Canvas.SetPos(HealthX - Row.StatusW, y);
        Canvas.DrawTextClipped(Row.StatusText);
    }

    Canvas.DrawColor = Class'HudBase'.Default.WhiteColor;
}

defaultproperties
{
    UpdateFrequency=0.2
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
    QuitText="QUIT"
    NewcomersText="Joined"
    DeathIcon=Texture'InterfaceArt_tex.deathicons.mine'
    BlameIcon=Texture'ScrnTex.HUD.Crap64'
    BigBlameIcon=Texture'ScrnAch_T.Achievements.PoopTrain'
    AdminIcon=Texture'I_AdminShield'
    WhiteMaterial=Texture'KillingFloorHUD.HUD.WhiteTexture'
    AssColor=(R=160,G=160,B=160,A=255)
    DeadColor=(R=160,G=160,B=160,A=255)
    DoshColor=(R=255,G=255,B=125,A=255)
    BestColor=(R=255,G=0,B=255,A=255)
    AdminColor=(R=255,G=0,B=255,A=255)
    SpecColor=(R=200,G=200,B=200,A=255)
    PlayerIconBackground=Texture'InterfaceContent.Menu.BorderBoxA1'
    PlayerIconSpacing=4
    PlayerIconMargin=3
    PlayerPortraitVShift=0.1
}
