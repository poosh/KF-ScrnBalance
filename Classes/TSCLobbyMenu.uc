class TSCLobbyMenu extends ScrnLobbyMenu
    dependson(TSCLobbyFooter);

#exec OBJ LOAD FILE=TSC_T.utx

var automated   GUIImage            TSCLogo;

var    automated    GUIButton            TeamButtons[2];
var automated   GUIImage            TeamLogos[2];
var automated   GUIImage            TeamTitles[2];

var automated   GUILabel            l_PlayerTeam;
var automated   GUILabel            l_HDmgCaption;
var automated   GUILabel            l_HDmgInfo;

var    localized string    ReadyString, UnreadyString;
var    localized string    strJoin, strJoined;
var    localized string    strCurrentWave, strWaves;
var    localized string    strTeam;
var    localized string    strNotTeamMember;

var    localized string    WaitingForMorePlayers;
var    localized string    TeamNames[2];

var    localized string    strHDmg;
var array<localized string> HDmgNames, HDmgInfo;


var array<FPlayerBoxEntry>        BluePlayerBoxes;


var TeamInfo MyTeam;

// stats
var int RedPlayers, BluePlayers;


event Timer()
{
    local TSCGameReplicationInfo GRI;
    local PlayerReplicationInfo PRI;


    PRI = PlayerOwner().PlayerReplicationInfo;
    if ( PRI != none ) {
        if ( PRI.bOnlySpectator ) {
            label_TimeOutCounter.Caption = "You are a spectator.";
            Return;
        }
    }



    GRI = TSCGameReplicationInfo(PlayerOwner().GameReplicationInfo);
    if ( GRI==None )
        label_TimeOutCounter.Caption = WaitingForServerStatus;
    else if ( GRI.Level.NetMode != NM_Standalone && (RedPlayers == 0 || BluePlayers == 0
                || RedPlayers+BluePlayers < GRI.MinNetPlayers) )
        label_TimeOutCounter.Caption = WaitingForMorePlayers;
    else if ( GRI.LobbyTimeout <= 0 )
        label_TimeOutCounter.Caption = WaitingForOtherPlayers;
    else
        label_TimeOutCounter.Caption = AutoCommence$":" @ GRI.LobbyTimeout;

    if ( GRI != None ) {
        l_HDmgCaption.Caption = strHDmg $ HdmgNames[GRI.HumanDamageMode];
        l_HDmgInfo.Caption = HdmgInfo[GRI.HumanDamageMode];
    }

    UpdateButtonCaptions();
}

function TeamChanged()
{
    local ScrnPlayerController PC;
    local string CN;

    PC = ScrnPlayerController(PlayerOwner());
    if ( PC == none )
        return;

    CN = PC.PlayerReplicationInfo.CharacterName;
    if ( !PC.ValidateCharacter(CN) )
        PC.ChangeCharacter(CN);
}

function bool OnTeamButtonClick(GUIComponent Sender)
{
    local KFPlayerController PC;
    local int TeamIndex;

    PC = KFPlayerController(PlayerOwner());
    if ( PC == none )
        return true;

    if ( Sender == TeamButtons[1] )
        TeamIndex = 1;
    else
        TeamIndex = 0;

    if ( PC.PlayerReplicationInfo == none || PC.PlayerReplicationInfo.Team == none
            || PC.PlayerReplicationInfo.Team.TeamIndex != TeamIndex )
    {
        if ( PC.PlayerReplicationInfo.bReadyToPlay ) {
            PC.ServerUnreadyPlayer();
            PC.PlayerReplicationInfo.bReadyToPlay = False;
        }
        PC.ServerChangeTeam(TeamIndex);
    }
    else {
        // if already in this team, then do ready/unready
        if ( PC.Level.NetMode == NM_Standalone || !PC.PlayerReplicationInfo.bReadyToPlay ) {
            PC.SendSelectedVeterancyToServer(true);

            //Set Ready
            PC.ServerRestartPlayer();
            PC.PlayerReplicationInfo.bReadyToPlay = True;
            if ( PC.Level.GRI.bMatchHasBegun )
                PC.ClientCloseMenu(true, false);
        }
        else {
            PC.ServerUnreadyPlayer();
            PC.PlayerReplicationInfo.bReadyToPlay = False;
        }
    }

    UpdateButtonCaptions();

    return true;
}

function UpdateButtonCaptions()
{
    local KFPlayerController PC;
    local int TeamIndex;

    PC = KFPlayerController(PlayerOwner());
    if ( PC == none )
        return;

    if ( PC.PlayerReplicationInfo == none || PC.PlayerReplicationInfo.Team == none ) {
        TeamButtons[0].Caption = strJoin;
        TeamButtons[1].Caption = strJoin;
    }
    else {
        TeamIndex = PC.PlayerReplicationInfo.Team.TeamIndex;
        TeamButtons[1-TeamIndex].Caption = strJoin;
        if ( PC.PlayerReplicationInfo.bReadyToPlay )
            TeamButtons[TeamIndex].Caption = UnreadyString;
        else
            TeamButtons[TeamIndex].Caption = ReadyString;
    }
}

function AddPlayer( KFPlayerReplicationInfo PRI, int Index, Canvas C )
{
    local float Top;
    local Material M;
    local ScrnBalance Mut;
    local String PlayerName;

    if( Index>=PlayerBoxes.Length )
    {
        Top = 0.025 + Index*0.045;
        PlayerBoxes.Length = Index+1;
        PlayerBoxes[Index].ReadyBox = new (None) Class'moCheckBox';
        PlayerBoxes[Index].ReadyBox.bValueReadOnly = true;
        PlayerBoxes[Index].ReadyBox.ComponentJustification = TXTA_Left;
        PlayerBoxes[Index].ReadyBox.CaptionWidth = 0.82;
        PlayerBoxes[Index].ReadyBox.LabelColor.B = 0;
        PlayerBoxes[Index].ReadyBox.WinTop = 0.0475+Top;
        PlayerBoxes[Index].ReadyBox.WinLeft = 0.125;
        PlayerBoxes[Index].ReadyBox.WinWidth = 0.40;
        PlayerBoxes[Index].ReadyBox.WinHeight = 0.045;
        PlayerBoxes[Index].ReadyBox.RenderWeight = 0.55;
        PlayerBoxes[Index].ReadyBox.bAcceptsInput = False;

        PlayerBoxes[Index].PlayerBox = new (None) Class'KFPlayerReadyBar';
        PlayerBoxes[Index].PlayerBox.WinTop = 0.04+Top;
        PlayerBoxes[Index].PlayerBox.WinLeft = 0.09;
        PlayerBoxes[Index].PlayerBox.WinWidth = 0.35;
        PlayerBoxes[Index].PlayerBox.WinHeight = 0.045;
        PlayerBoxes[Index].PlayerBox.RenderWeight = 0.35;

        PlayerBoxes[Index].PlayerPerk = new (None) Class'GUIImage';
        PlayerBoxes[Index].PlayerPerk.ImageStyle = ISTY_Justified;
        PlayerBoxes[Index].PlayerPerk.WinTop = 0.043+Top;
        PlayerBoxes[Index].PlayerPerk.WinLeft = 0.0918;
        PlayerBoxes[Index].PlayerPerk.WinWidth = 0.039;
        PlayerBoxes[Index].PlayerPerk.WinHeight = 0.039;
        PlayerBoxes[Index].PlayerPerk.RenderWeight = 0.56;

        PlayerBoxes[Index].PlayerVetLabel = new (None) Class'GUILabel';
        PlayerBoxes[Index].PlayerVetLabel.TextAlign = TXTA_Right;
        PlayerBoxes[Index].PlayerVetLabel.TextColor = Class'Canvas'.Static.MakeColor(19,19,19);
        PlayerBoxes[Index].PlayerVetLabel.TextFont = "UT2SmallFont";
        PlayerBoxes[Index].PlayerVetLabel.WinTop = 0.04+Top;
        PlayerBoxes[Index].PlayerVetLabel.WinLeft = 0.27907;
        PlayerBoxes[Index].PlayerVetLabel.WinWidth = 0.151172;
        PlayerBoxes[Index].PlayerVetLabel.WinHeight = 0.045;
        PlayerBoxes[Index].PlayerVetLabel.RenderWeight = 0.5;

        AppendComponent(PlayerBoxes[Index].ReadyBox, true);
        AppendComponent(PlayerBoxes[Index].PlayerBox, true);
        AppendComponent(PlayerBoxes[Index].PlayerPerk, true);
        AppendComponent(PlayerBoxes[Index].PlayerVetLabel, true);

        /*
        Top = (PlayerBoxes[Index].PlayerBox.WinTop+PlayerBoxes[Index].PlayerBox.WinHeight);
        if( !bMOTDHidden && Top>=ADBackground.WinTop )
        {
            ADBackground.WinTop = Top+0.01;
            if( (ADBackground.WinTop+ADBackground.WinHeight)>t_ChatBox.WinTop )
            {
                ADBackground.WinHeight = t_ChatBox.WinTop-ADBackground.WinTop;
                if( ADBackground.WinHeight<0.15 )
                {
                    RemoveComponent(ADBackground);
                    RemoveComponent(tb_ServerMOTD);
                    bMOTDHidden = true;
                }
            }
        }
        */
    }
    PlayerBoxes[Index].ReadyBox.Checked(PRI.bReadyToPlay);

    Mut = class'ScrnBalance'.default.Mut;
    if ( Mut != none ) {
        PlayerName = Mut.LeftCol(Mut.ColoredPlayerName(PRI), 20);
    }
    else {
        PlayerName = Left(PRI.PlayerName, 20);
    }
    PlayerBoxes[Index].ReadyBox.SetCaption(" "$PlayerName);

    if ( PRI.ClientVeteranSkill != none )
    {
        PlayerBoxes[Index].PlayerVetLabel.Caption = LvAbbrString @ PRI.ClientVeteranSkillLevel @ PRI.ClientVeteranSkill.default.VeterancyName;
        if( Class<SRVeterancyTypes>(PRI.ClientVeteranSkill)!=None )
        {
            Class<SRVeterancyTypes>(PRI.ClientVeteranSkill).Static.PreDrawPerk(C,PRI.ClientVeteranSkillLevel,PlayerBoxes[Index].PlayerPerk.Image,M);
            PlayerBoxes[Index].PlayerPerk.ImageColor = C.DrawColor;
        }
        else
        {
            PlayerBoxes[Index].PlayerPerk.Image = PRI.ClientVeteranSkill.default.OnHUDIcon;
            PlayerBoxes[Index].PlayerPerk.ImageColor = Class'Canvas'.Static.MakeColor(255,255,255);
        }
    }
    else
    {
        PlayerBoxes[Index].PlayerPerk.Image = None;
        PlayerBoxes[Index].PlayerVetLabel.Caption = "";
    }
    PlayerBoxes[Index].bIsEmpty = false;
}

function AddBluePlayer( KFPlayerReplicationInfo PRI, int Index, Canvas C )
{
    local float Top;
    local Material M;
    local ScrnBalance Mut;
    local String PlayerName;

    if( Index>=BluePlayerBoxes.Length )
    {
        Top = 0.025 + Index*0.045;
        BluePlayerBoxes.Length = Index+1;
        BluePlayerBoxes[Index].ReadyBox = new (None) Class'moCheckBox';
        BluePlayerBoxes[Index].ReadyBox.bValueReadOnly = true;
        BluePlayerBoxes[Index].ReadyBox.ComponentJustification = TXTA_Left;
        BluePlayerBoxes[Index].ReadyBox.CaptionWidth = 0.82;
        BluePlayerBoxes[Index].ReadyBox.LabelColor.B = 0;
        BluePlayerBoxes[Index].ReadyBox.WinTop = 0.0475+Top;
        BluePlayerBoxes[Index].ReadyBox.WinLeft = 0.545;
        BluePlayerBoxes[Index].ReadyBox.WinWidth = 0.4;
        BluePlayerBoxes[Index].ReadyBox.WinHeight = 0.045;
        BluePlayerBoxes[Index].ReadyBox.RenderWeight = 0.55;
        BluePlayerBoxes[Index].ReadyBox.bAcceptsInput = False;

        BluePlayerBoxes[Index].PlayerBox = new (None) Class'KFPlayerReadyBar';
        BluePlayerBoxes[Index].PlayerBox.WinTop = 0.04+Top;
        BluePlayerBoxes[Index].PlayerBox.WinLeft = 0.51;
        BluePlayerBoxes[Index].PlayerBox.WinWidth = 0.35;
        BluePlayerBoxes[Index].PlayerBox.WinHeight = 0.045;
        BluePlayerBoxes[Index].PlayerBox.RenderWeight = 0.35;

        BluePlayerBoxes[Index].PlayerPerk = new (None) Class'GUIImage';
        BluePlayerBoxes[Index].PlayerPerk.ImageStyle = ISTY_Justified;
        BluePlayerBoxes[Index].PlayerPerk.WinTop = 0.043+Top;
        BluePlayerBoxes[Index].PlayerPerk.WinLeft = 0.5118;
        BluePlayerBoxes[Index].PlayerPerk.WinWidth = 0.039;
        BluePlayerBoxes[Index].PlayerPerk.WinHeight = 0.039;
        BluePlayerBoxes[Index].PlayerPerk.RenderWeight = 0.56;

        BluePlayerBoxes[Index].PlayerVetLabel = new (None) Class'GUILabel';
        BluePlayerBoxes[Index].PlayerVetLabel.TextAlign = TXTA_Right;
        BluePlayerBoxes[Index].PlayerVetLabel.TextColor = Class'Canvas'.Static.MakeColor(19,19,19);
        BluePlayerBoxes[Index].PlayerVetLabel.TextFont = "UT2SmallFont";
        BluePlayerBoxes[Index].PlayerVetLabel.WinTop = 0.04+Top;
        BluePlayerBoxes[Index].PlayerVetLabel.WinLeft = 0.69907;
        BluePlayerBoxes[Index].PlayerVetLabel.WinWidth = 0.151172;
        BluePlayerBoxes[Index].PlayerVetLabel.WinHeight = 0.045;
        BluePlayerBoxes[Index].PlayerVetLabel.RenderWeight = 0.5;

        AppendComponent(BluePlayerBoxes[Index].ReadyBox, true);
        AppendComponent(BluePlayerBoxes[Index].PlayerBox, true);
        AppendComponent(BluePlayerBoxes[Index].PlayerPerk, true);
        AppendComponent(BluePlayerBoxes[Index].PlayerVetLabel, true);

        /*
        Top = (BluePlayerBoxes[Index].PlayerBox.WinTop+BluePlayerBoxes[Index].PlayerBox.WinHeight);
        if( !bMOTDHidden && Top>=ADBackground.WinTop )
        {
            ADBackground.WinTop = Top+0.01;
            if( (ADBackground.WinTop+ADBackground.WinHeight)>t_ChatBox.WinTop )
            {
                ADBackground.WinHeight = t_ChatBox.WinTop-ADBackground.WinTop;
                if( ADBackground.WinHeight<0.15 )
                {
                    RemoveComponent(ADBackground);
                    RemoveComponent(tb_ServerMOTD);
                    bMOTDHidden = true;
                }
            }
        }
        */
    }
    BluePlayerBoxes[Index].ReadyBox.Checked(PRI.bReadyToPlay);

    Mut = class'ScrnBalance'.default.Mut;
    if ( Mut != none ) {
        PlayerName = Mut.LeftCol(Mut.ColoredPlayerName(PRI), 20);
    }
    else {
        PlayerName = Left(PRI.PlayerName, 20);
    }
    BluePlayerBoxes[Index].ReadyBox.SetCaption(" "$PlayerName);

    if ( PRI.ClientVeteranSkill != none )
    {
        BluePlayerBoxes[Index].PlayerVetLabel.Caption = LvAbbrString @ PRI.ClientVeteranSkillLevel @ PRI.ClientVeteranSkill.default.VeterancyName;
        if( Class<SRVeterancyTypes>(PRI.ClientVeteranSkill)!=None )
        {
            Class<SRVeterancyTypes>(PRI.ClientVeteranSkill).Static.PreDrawPerk(C,PRI.ClientVeteranSkillLevel,BluePlayerBoxes[Index].PlayerPerk.Image,M);
            BluePlayerBoxes[Index].PlayerPerk.ImageColor = C.DrawColor;
        }
        else
        {
            BluePlayerBoxes[Index].PlayerPerk.Image = PRI.ClientVeteranSkill.default.OnHUDIcon;
            BluePlayerBoxes[Index].PlayerPerk.ImageColor = Class'Canvas'.Static.MakeColor(255,255,255);
        }
    }
    else
    {
        BluePlayerBoxes[Index].PlayerPerk.Image = None;
        BluePlayerBoxes[Index].PlayerVetLabel.Caption = "";
    }
    BluePlayerBoxes[Index].bIsEmpty = false;
}


function EmptyBluePlayers( int Index )
{
    while( Index<BluePlayerBoxes.Length && !BluePlayerBoxes[Index].bIsEmpty )
    {
        BluePlayerBoxes[Index].ReadyBox.Checked(False);
        BluePlayerBoxes[Index].PlayerPerk.Image = None;
        BluePlayerBoxes[Index].PlayerVetLabel.Caption = "";
        BluePlayerBoxes[Index].ReadyBox.SetCaption("");
        BluePlayerBoxes[Index].bIsEmpty = true;
        ++Index;
    }
}

function bool InternalOnPreDraw(Canvas C)
{
    local int i, r, b;
    //local string StoryString;
    local String SkillString;
    local TSCGameReplicationInfo GRI;
    local KFPlayerReplicationInfo KFPRI;
    local PlayerController PC;

    PC = PlayerOwner();

    if ( PC == none || PC.Level == none ) // Error?
        return false;

    if ( (PC.PlayerReplicationInfo != none && (!PC.PlayerReplicationInfo.bWaitingPlayer || PC.PlayerReplicationInfo.bOnlySpectator)) || PC.Outer.Name=='Entry' )
    {
        bAllowClose = true;
        PC.ClientCloseMenu(True,False);
        return false;
    }

    if (  PC.PlayerReplicationInfo != none && PC.PlayerReplicationInfo.Team != MyTeam ) {
        MyTeam = PC.PlayerReplicationInfo.Team;
        TeamChanged();
    }

    t_Footer.InternalOnPreDraw(C);

    GRI = TSCGameReplicationInfo(PC.GameReplicationInfo);

    if ( GRI != none ) {
        if ( GRI.bMatchHasBegun )
            WaveLabel.Caption = strCurrentWave @ string(GRI.WaveNumber + 1) $ "/" $ string(GRI.FinalWave)$"+"$ string(GRI.OvertimeWaves) $"OT+"$ string(GRI.SudDeathWaves)$"SD";
        else
            WaveLabel.Caption = string(GRI.FinalWave) @ strWaves @ "+" @ string(GRI.OvertimeWaves)$"OT"
                @ "+" @ string(GRI.SudDeathWaves)$"SD";
    }
    else {
        WaveLabel.Caption = "Wrong Game Type!"; // shouldn't happen
        return false;
    }
    C.DrawColor.A = 255;

    // First fill in non-ready players.
    RedPlayers = 0;
    BluePlayers = 0;
    for ( i = 0; i<GRI.PRIArray.Length; i++ ) {
        KFPRI = KFPlayerReplicationInfo(GRI.PRIArray[i]);
        if ( KFPRI == none || KFPRI.bOnlySpectator || KFPRI.bReadyToPlay || KFPRI.Team == none)
            continue;

        if ( KFPRI.Team.TeamIndex == 0 ) {
            RedPlayers++;
            if ( r < MaxPlayersOnList ) {
                AddPlayer(KFPRI, r++, C);
            }
        }
        else if ( KFPRI.Team.TeamIndex == 1 ) {
            BluePlayers++;
            if ( b < MaxPlayersOnList )
                AddBluePlayer(KFPRI, b++, C);
        }
    }

    // Then comes rest.
    for ( i = 0; i < GRI.PRIArray.Length; i++ ) {
        KFPRI = KFPlayerReplicationInfo(GRI.PRIArray[i]);
        if ( KFPRI == none || KFPRI.bOnlySpectator || !KFPRI.bReadyToPlay || KFPRI.Team == none)
            continue;

        if ( KFPRI.bReadyToPlay ) {
            if ( !bTimeoutTimeLogged ) {
                ActivateTimeoutTime = PC.Level.TimeSeconds;
                bTimeoutTimeLogged = true;
            }
        }

        if ( KFPRI.Team.TeamIndex == 0 ) {
            RedPlayers++;
            if ( r < MaxPlayersOnList )
                AddPlayer(KFPRI, r++, C);
        }
        else if ( KFPRI.Team.TeamIndex == 1 ) {
            BluePlayers++;
            if ( b < MaxPlayersOnList )
                AddBluePlayer(KFPRI, b++, C);
        }
    }

    if( r < MaxPlayersOnList )
        EmptyPlayers(r);
    if( b < MaxPlayersOnList )
        EmptyBluePlayers(b);

DoneIt:
    //StoryString = PC.Level.Description;

    if ( !bStoryBoxFilled )
    {
        l_StoryBox.LoadStoryText();
        bStoryBoxFilled = true;
    }

    CheckBotButtonAccess();

    if ( GRI.BaseDifficulty <= 1 )
        SkillString = BeginnerString;
    else if ( GRI.BaseDifficulty <= 2 )
        SkillString = NormalString;
    else if ( GRI.BaseDifficulty <= 4 )
        SkillString = HardString;
    else if ( GRI.BaseDifficulty <= 5 )
        SkillString = SuicidalString;
    else
        SkillString = HellOnEarthString;

    CurrentMapLabel.Caption = PC.Level.Title;
    DifficultyLabel.Caption = SkillString;

    if ( MyTeam != none ) {
        l_PlayerTeam.Caption = strTeam @ TeamNames[MyTeam.TeamIndex];
        l_PlayerTeam.TextColor = MyTeam.TeamColor;
    }
    else {
        l_PlayerTeam.Caption = strNotTeamMember;
        l_PlayerTeam.TextColor = class'Canvas'.static.MakeColor(192, 192, 192, 255);
    }

    return false;
}





defaultproperties
{
    TeamNames[0]="British"
    TeamNames[1]="Steampunk"
    WaitingForMorePlayers="Waiting for more players to join in..."
    strJoin="Join"
    strJoined="Joined"
    ReadyString="Ready"
    UnreadyString="Unready"
    strCurrentWave="Current Wave:"
    strWaves="waves"
    DifficultyString="Difficulty:"
    strTeam="Team:"
    strNotTeamMember="Select team..."
    MaxPlayersOnList=11

    Begin Object Class=TSCLobbyFooter Name=BuyFooter
        RenderWeight=0.300000
        TabOrder=8
        bBoundToParent=False
        bScaleToParent=False
        OnPreDraw=BuyFooter.InternalOnPreDraw
    End Object
    t_Footer=ScrnLobbyFooter'ScrnBalanceSrv.TSCLobbyMenu.BuyFooter'

    label_TimeOutCounter=GUILabel'ScrnBalanceSrv.TSCLobbyFooter.TimeOutCounter'

     Begin Object Class=GUIImage Name=TSCLogoLeft
         Image=Texture'TSC_T.Team.TSC_Left'
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         IniOption="@Internal"
         WinTop=0.16
         WinLeft=0.00
         WinWidth=0.07565
         WinHeight=0.68
         RenderWeight=0.10
     End Object
     TSCLogo=GUIImage'ScrnBalanceSrv.TSCLobbyMenu.TSCLogoLeft'

     Begin Object Class=GUIImage Name=RedLogo
         Image=Texture'TSC_T.Team.BritishLogo'
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         IniOption="@Internal"
         WinTop=0.00
         WinLeft=0.00
         WinWidth=0.09
         WinHeight=0.16
         RenderWeight=0.10
     End Object
     TeamLogos[0]=GUIImage'ScrnBalanceSrv.TSCLobbyMenu.RedLogo'

     Begin Object Class=GUIImage Name=BlueLogo
         Image=Texture'TSC_T.Team.SteampunkLogo'
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         IniOption="@Internal"
         WinTop=0.00
         WinLeft=0.90
         WinWidth=0.09
         WinHeight=0.16
         RenderWeight=0.10
     End Object
     TeamLogos[1]=GUIImage'ScrnBalanceSrv.TSCLobbyMenu.BlueLogo'

     Begin Object Class=GUIImage Name=RedTitle
         Image=Texture'TSC_T.Team.BritishSquad'
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         IniOption="@Internal"
         WinTop=0.00
         WinLeft=0.10
         WinWidth=0.24
         WinHeight=0.06
         RenderWeight=0.15
     End Object
     TeamTitles[0]=GUIImage'ScrnBalanceSrv.TSCLobbyMenu.RedTitle'

     Begin Object Class=GUIImage Name=BlueTitle
         Image=Texture'TSC_T.Team.SteampunkSquad'
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         IniOption="@Internal"
         WinTop=0.00
         WinLeft=0.5118
         WinWidth=0.24
         WinHeight=0.06
         RenderWeight=0.15
     End Object
     TeamTitles[1]=GUIImage'ScrnBalanceSrv.TSCLobbyMenu.BlueTitle'

    Begin Object Class=GUIButton Name=RedButton
        Caption="Join"
        Hint="Click to join the British Squad, or Ready/Unredy, if already joined"
        WinTop=0.025
        WinLeft=0.37
        WinWidth=0.10
        WinHeight=0.04
        RenderWeight=2.000000
        TabOrder=0
        bBoundToParent=True
        ToolTip=None
        OnClick=TSCLobbyMenu.OnTeamButtonClick
        OnKeyEvent=ReadyButton.InternalOnKeyEvent
    End Object
    TeamButtons[0]=GUIButton'ScrnBalanceSrv.TSCLobbyMenu.RedButton'

    Begin Object Class=GUIButton Name=BlueButton
        Caption="Join"
        Hint="Click to join the Steampunk Squad, or Ready/Unredy, if already joined"
        WinTop=0.025
        WinLeft=0.79
        WinWidth=0.10
        WinHeight=0.04
        RenderWeight=2.000000
        TabOrder=1
        bBoundToParent=True
        ToolTip=None
        OnClick=TSCLobbyMenu.OnTeamButtonClick
        OnKeyEvent=ReadyButton.InternalOnKeyEvent
    End Object
    TeamButtons[1]=GUIButton'ScrnBalanceSrv.TSCLobbyMenu.BlueButton'


     Begin Object Class=SRLobbyChat Name=ChatBox
         OnCreateComponent=ChatBox.InternalOnCreateComponent
         WinTop=0.807600
         WinLeft=0.016090
         WinWidth=0.971410
         WinHeight=0.100000
         RenderWeight=1.000000
         TabOrder=1
         OnPreDraw=ChatBox.FloatingPreDraw
         OnRendered=ChatBox.FloatingRendered
         OnHover=ChatBox.FloatingHover
         OnMousePressed=ChatBox.FloatingMousePressed
         OnMouseRelease=ChatBox.FloatingMouseRelease
     End Object
     t_ChatBox=SRLobbyChat'ScrnBalanceSrv.TSCLobbyMenu.ChatBox'

     Begin Object Class=GUISectionBackground Name=ADBG
        Caption="Server Info"
         WinTop=0.567412
         WinLeft=0.09
         WinWidth=0.38
         WinHeight=0.25
         RenderWeight=0.300000
         OnPreDraw=ADBG.InternalPreDraw
     End Object
     ADBackground=GUISectionBackground'ScrnBalanceSrv.TSCLobbyMenu.ADBG'


     Begin Object Class=GUILabel Name=PerkClickArea
         WinTop=0.567412
         WinLeft=0.5118
         WinWidth=0.122478
         WinHeight=0.332588
         bAcceptsInput=True
         OnClickSound=CS_Click
         OnClick=LobbyMenu.ShowPerkMenu
     End Object
     PerkClickLabel=GUILabel'ScrnBalanceSrv.TSCLobbyMenu.PerkClickArea'

     Begin Object Class=GUISectionBackground Name=PlayerPortraitB
         WinTop=0.567412
         WinLeft=0.5118
         WinWidth=0.122478
         WinHeight=0.332588
         OnPreDraw=PlayerPortraitB.InternalPreDraw
     End Object
     PlayerPortraitBG=GUISectionBackground'ScrnBalanceSrv.TSCLobbyMenu.PlayerPortraitB'

     Begin Object Class=GUIImage Name=PlayerPortrait
         Image=Texture'InterfaceArt_tex.Menu.changeme_texture'
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         IniOption="@Internal"
         WinTop=0.607517
         WinLeft=0.51526
         WinWidth=0.115541
         WinHeight=0.286159
         RenderWeight=0.300000
     End Object
     i_Portrait=GUIImage'ScrnBalanceSrv.TSCLobbyMenu.PlayerPortrait'

     Begin Object Class=GUISectionBackground Name=BGPerk
         bFillClient=True
         Caption="Player Info"
         WinTop=0.567412
         WinLeft=0.634278
         WinWidth=0.355722
         WinHeight=0.14
         OnPreDraw=BGPerk.InternalPreDraw
     End Object
     i_BGPerk=GUISectionBackground'ScrnBalanceSrv.TSCLobbyMenu.BGPerk'

     Begin Object Class=GUILabel Name=PlayerTeam
         Caption="Select a team"
         TextAlign=TXTA_Left
         TextColor=(B=192,G=192,R=192)
         VertAlign=TXTA_Center
         FontScale=FNS_Small
         WinTop=0.66
         WinLeft=0.703
         WinWidth=0.23
         WinHeight=0.035
         RenderWeight=0.95
     End Object
     l_PlayerTeam=GUILabel'ScrnBalanceSrv.TSCLobbyMenu.PlayerTeam'

     Begin Object Class=GUISectionBackground Name=BGPerkEffects
         bFillClient=True
         Caption="Game Info"
         WinTop=0.707412
         WinLeft=0.634278
         WinWidth=0.355722
         WinHeight=0.192588
         OnPreDraw=BGPerkEffects.InternalPreDraw
     End Object
     i_BGPerkEffects=GUISectionBackground'ScrnBalanceSrv.TSCLobbyMenu.BGPerkEffects'

     Begin Object Class=GUILabel Name=CurrentMapL
         Caption="LAlalala Map"
         TextColor=(B=158,G=176,R=175)
         VertAlign=TXTA_Top
         WinTop=0.75
         WinLeft=0.655
         WinWidth=0.33
         WinHeight=0.035
         RenderWeight=0.900000
     End Object
     CurrentMapLabel=GUILabel'ScrnBalanceSrv.TSCLobbyMenu.CurrentMapL'

     Begin Object Class=GUILabel Name=DifficultyL
         Caption="Difficulty"
         TextColor=(B=158,G=176,R=175)
         VertAlign=TXTA_Top
         WinTop=0.775
         WinLeft=0.655
         WinWidth=0.33
         WinHeight=0.035
         RenderWeight=0.900000
     End Object
     DifficultyLabel=GUILabel'ScrnBalanceSrv.TSCLobbyMenu.DifficultyL'

     Begin Object Class=GUILabel Name=WaveL
         Caption="1/4"
         TextAlign=TXTA_Left
         TextColor=(B=158,G=176,R=175)
         VertAlign=TXTA_Top
         FontScale=FNS_Small
         WinTop=0.80
         WinLeft=0.655
         WinWidth=0.33
         WinHeight=0.035
         RenderWeight=0.95
     End Object
     WaveLabel=GUILabel'ScrnBalanceSrv.TSCLobbyMenu.WaveL'

     Begin Object Class=GUILabel Name=HumanDamageL
         Caption="Human Damage: Normal"
         TextAlign=TXTA_Left
         TextColor=(B=158,G=176,R=175)
         VertAlign=TXTA_Top
         FontScale=FNS_Small
         WinTop=0.825
         WinLeft=0.655
         WinWidth=0.33
         WinHeight=0.035
         RenderWeight=0.95
     End Object
     l_HDmgCaption=GUILabel'ScrnBalanceSrv.TSCLobbyMenu.HumanDamageL'

     Begin Object Class=GUILabel Name=HumanDamageInfoL
         Caption="Full protection within own Base."
         TextAlign=TXTA_Left
         TextColor=(B=90,G=115,R=115)
         VertAlign=TXTA_Top
         bMultiLine=True
         FontScale=FNS_Small
         WinTop=0.850
         WinLeft=0.655
         WinWidth=0.33
         WinHeight=0.070
         RenderWeight=0.95
     End Object
     l_HDmgInfo=GUILabel'ScrnBalanceSrv.TSCLobbyMenu.HumanDamageInfoL'

    strHDmg="Human Damage: "

    HDmgNames(0)="OFF"
    HDmgNames(1)="No Friendly Fire"
    HDmgNames(2)="PvP, No Friendly Fire."
    HDmgNames(3)="Normal"
    HDmgNames(4)="PvP"
    HDmgNames(5)="Always"

    HDmgInfo(0)="Players can't hurt each other at all."
    HDmgInfo(1)="Teammates can't hurt each other."
    HDmgInfo(2)="Players can hurt enemies only."
    HDmgInfo(3)="Full protection within own Base."
    HDmgInfo(4)="Base protects from Friendly Fire only."
    HDmgInfo(5)="Base does not protect from Human Damage."



    // hide
     Begin Object Class=GUIImage Name=WaveB
        bVisible=False
     End Object
     WaveBG=GUIImage'ScrnBalanceSrv.TSCLobbyMenu.WaveB'

     Begin Object Class=KFMapStoryLabel Name=LobbyMapStoryBox
         bVisible=False
    End Object
    l_StoryBox=KFMapStoryLabel'ScrnBalanceSrv.TSCLobbyMenu.LobbyMapStoryBox'

     Begin Object Class=AltSectionBackground Name=StoryBoxBackground
        bVisible=False
     End Object
     StoryBoxBG=AltSectionBackground'ScrnBalanceSrv.TSCLobbyMenu.StoryBoxBackground'

     Begin Object Class=AltSectionBackground Name=GameInfoB
        bVisible=False
     End Object
     GameInfoBG=AltSectionBackground'ScrnBalanceSrv.TSCLobbyMenu.GameInfoB'

      Begin Object Class=GUIScrollTextBox Name=PerkEffectsScroll
         bVisible=False
     End Object
     lb_PerkEffects=GUIScrollTextBox'ScrnBalanceSrv.TSCLobbyMenu.PerkEffectsScroll'
}