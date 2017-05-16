class TSCLobbyFooter extends ScrnLobbyFooter;

defaultproperties
{
    // hide ready button
    Begin Object Class=GUIButton Name=ReadyButton
        bVisible=False
        MenuState=MSAT_Disabled
        Caption="Ready"
        Hint="Click to indicate you are ready to play"
        WinTop=0.966146
        WinLeft=0.280000
        WinWidth=0.120000
        WinHeight=0.033203
        RenderWeight=2.000000
        TabOrder=4
        bBoundToParent=True
        ToolTip=None
        OnClick=TSCLobbyFooter.OnFooterClick
        OnKeyEvent=ReadyButton.InternalOnKeyEvent
    End Object
    b_Ready=GUIButton'ScrnBalanceSrv.TSCLobbyFooter.ReadyButton'

     Begin Object Class=GUILabel Name=TimeOutCounter
         Caption="Game will auto-commence in: "
         TextAlign=TXTA_Left
         TextColor=(B=158,G=176,R=175)
         WinTop=0.96
         WinLeft=0.005
         WinWidth=0.995
         WinHeight=0.033203
         TabOrder=6
     End Object
}