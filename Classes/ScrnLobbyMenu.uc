class ScrnLobbyMenu extends SRLobbyMenu;

function AddPlayer( KFPlayerReplicationInfo PRI, int Index, Canvas C )
{
    local float Top;
    local Material M;
    local ScrnBalance Mut;
    local String PlayerName;

    if( Index>=PlayerBoxes.Length )
    {
        Top = Index*0.045;
        PlayerBoxes.Length = Index+1;
        PlayerBoxes[Index].ReadyBox = new (None) Class'moCheckBox';
        PlayerBoxes[Index].ReadyBox.bValueReadOnly = true;
        PlayerBoxes[Index].ReadyBox.ComponentJustification = TXTA_Left;
        PlayerBoxes[Index].ReadyBox.CaptionWidth = 0.82;
        PlayerBoxes[Index].ReadyBox.LabelColor.B = 0;
        PlayerBoxes[Index].ReadyBox.WinTop = 0.0475+Top;
        PlayerBoxes[Index].ReadyBox.WinLeft = 0.075;
        PlayerBoxes[Index].ReadyBox.WinWidth = 0.4;
        PlayerBoxes[Index].ReadyBox.WinHeight = 0.045;
        PlayerBoxes[Index].ReadyBox.RenderWeight = 0.55;
        PlayerBoxes[Index].ReadyBox.bAcceptsInput = False;
        PlayerBoxes[Index].PlayerBox = new (None) Class'KFPlayerReadyBar';
        PlayerBoxes[Index].PlayerBox.WinTop = 0.04+Top;
        PlayerBoxes[Index].PlayerBox.WinLeft = 0.04;
        PlayerBoxes[Index].PlayerBox.WinWidth = 0.35;
        PlayerBoxes[Index].PlayerBox.WinHeight = 0.045;
        PlayerBoxes[Index].PlayerBox.RenderWeight = 0.35;
        PlayerBoxes[Index].PlayerPerk = new (None) Class'GUIImage';
        PlayerBoxes[Index].PlayerPerk.ImageStyle = ISTY_Justified;
        PlayerBoxes[Index].PlayerPerk.WinTop = 0.043+Top;
        PlayerBoxes[Index].PlayerPerk.WinLeft = 0.0418;
        PlayerBoxes[Index].PlayerPerk.WinWidth = 0.039;
        PlayerBoxes[Index].PlayerPerk.WinHeight = 0.039;
        PlayerBoxes[Index].PlayerPerk.RenderWeight = 0.56;
        PlayerBoxes[Index].PlayerVetLabel = new (None) Class'GUILabel';
        PlayerBoxes[Index].PlayerVetLabel.TextAlign = TXTA_Right;
        PlayerBoxes[Index].PlayerVetLabel.TextColor = Class'Canvas'.Static.MakeColor(19,19,19);
        PlayerBoxes[Index].PlayerVetLabel.TextFont = "UT2SmallFont";
        PlayerBoxes[Index].PlayerVetLabel.WinTop = 0.04+Top;
        PlayerBoxes[Index].PlayerVetLabel.WinLeft = 0.22907;
        PlayerBoxes[Index].PlayerVetLabel.WinWidth = 0.151172;
        PlayerBoxes[Index].PlayerVetLabel.WinHeight = 0.045;
        PlayerBoxes[Index].PlayerVetLabel.RenderWeight = 0.5;
        AppendComponent(PlayerBoxes[Index].ReadyBox, true);
        AppendComponent(PlayerBoxes[Index].PlayerBox, true);
        AppendComponent(PlayerBoxes[Index].PlayerPerk, true);
        AppendComponent(PlayerBoxes[Index].PlayerVetLabel, true);

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
        PlayerBoxes[Index].PlayerVetLabel.Caption = "Lv" @ PRI.ClientVeteranSkillLevel @ PRI.ClientVeteranSkill.default.VeterancyName;
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


// copy-pasted to add Hell On Earth difdiculty  -- PooSH
function bool InternalOnPreDraw(Canvas C)
{
    local int i, j;
    local string StoryString;
    local String SkillString;
    local String s;
    local KFGameReplicationInfo KFGRI;
    local ScrnGameReplicationInfo ScrnGRI;
    local PlayerController PC;

    PC = PlayerOwner();

    if ( PC == none || PC.Level == none ) // Error?
    {
        return false;
    }

    if ( (PC.PlayerReplicationInfo != none && (!PC.PlayerReplicationInfo.bWaitingPlayer || PC.PlayerReplicationInfo.bOnlySpectator)) || PC.Outer.Name=='Entry' )
    {
        bAllowClose = true;
        PC.ClientCloseMenu(True,False);
        return false;
    }

    t_Footer.InternalOnPreDraw(C);

    KFGRI = KFGameReplicationInfo(PC.GameReplicationInfo);
    ScrnGRI = ScrnGameReplicationInfo(PC.GameReplicationInfo);

    if ( KFGRI != none )
        WaveLabel.Caption = string(KFGRI.WaveNumber + 1) $ "/" $ string(KFGRI.FinalWave);
    else
    {
        WaveLabel.Caption = "?/?";
        return false;
    }
    C.DrawColor.A = 255;

    // First fill in non-ready players.
    for ( i = 0; i<KFGRI.PRIArray.Length; i++ )
    {
        if ( KFGRI.PRIArray[i] == none || KFGRI.PRIArray[i].bOnlySpectator || KFGRI.PRIArray[i].bReadyToPlay || KFPlayerReplicationInfo(KFGRI.PRIArray[i])==None )
            continue;

        AddPlayer(KFPlayerReplicationInfo(KFGRI.PRIArray[i]),j,C);
        if( ++j>=MaxPlayersOnList )
            GoTo'DoneIt';
    }

    // Then comes rest.
    for ( i = 0; i < KFGRI.PRIArray.Length; i++ )
    {
        if ( KFGRI.PRIArray[i]==none || KFGRI.PRIArray[i].bOnlySpectator || !KFGRI.PRIArray[i].bReadyToPlay || KFPlayerReplicationInfo(KFGRI.PRIArray[i])==None )
            continue;

        if ( KFGRI.PRIArray[i].bReadyToPlay )
        {
            if ( !bTimeoutTimeLogged )
            {
                ActivateTimeoutTime = PC.Level.TimeSeconds;
                bTimeoutTimeLogged = true;
            }
        }
        AddPlayer(KFPlayerReplicationInfo(KFGRI.PRIArray[i]),j,C);
        if( ++j>=MaxPlayersOnList )
            GoTo'DoneIt';
    }

    if( j<MaxPlayersOnList )
        EmptyPlayers(j);

DoneIt:
    StoryString = PC.Level.Description;

    if ( !bStoryBoxFilled )
    {
        l_StoryBox.LoadStoryText();
        bStoryBoxFilled = true;
    }

    CheckBotButtonAccess();

    if ( KFGRI.BaseDifficulty <= 1 )
        SkillString = BeginnerString;
    else if ( KFGRI.BaseDifficulty <= 2 )
        SkillString = NormalString;
    else if ( KFGRI.BaseDifficulty <= 4 )
        SkillString = HardString;
    else if ( KFGRI.BaseDifficulty <= 5 )
        SkillString = SuicidalString;
    else
        SkillString = HellOnEarthString;

    if ( ScrnGRI != none ) {
        s = ScrnGRI.GameName;
        if ( ScrnGRI.GameTitle != "" )
            s $= ": " $ ScrnGRI.GameTitle;
        s $= " @ " $  PC.Level.Title;
    }
    else {
        s = CurrentMapString @ PC.Level.Title;
    }
    CurrentMapLabel.Caption = s;

    DifficultyLabel.Caption = DifficultyString @ SkillString;

    return false;
}

function bool ShowPerkMenu(GUIComponent Sender)
{
    if ( PlayerOwner() != none) {
        if (ScrnPlayerController(PlayerOwner()) != none )
            PlayerOwner().ClientOpenMenu(ScrnPlayerController(PlayerOwner()).ProfilePageClassString, false);
        else
            PlayerOwner().ClientOpenMenu(string(Class'ScrnProfilePage'), false);
    }
    return true;
}

defaultproperties
{
     Begin Object Class=ScrnLobbyFooter Name=BuyFooter
         RenderWeight=0.300000
         TabOrder=8
         bBoundToParent=False
         bScaleToParent=False
         OnPreDraw=BuyFooter.InternalOnPreDraw
     End Object
     t_Footer=ScrnLobbyFooter'ScrnBalanceSrv.ScrnLobbyMenu.BuyFooter'
}
