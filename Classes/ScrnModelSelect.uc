class ScrnModelSelect extends SRModelSelect;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local ClientPerkRepLink S;
    local int i,j;
    local string C,G;
    local xUtil.PlayerRecord PR;

    super(LockedFloatingWindow).Initcomponent(MyController, MyOwner);

    co_Race.MyComboBox.List.bInitializeList = True;
    co_Race.ReadOnly(True);
    co_Race.AddItem(AllText);

    sb_Main.SetPosition(0.040000,0.075000,0.680742,0.555859);
    sb_Main.RightPadding = 0.5;
    sb_Main.ManageComponent(CharList);

    S = Class'ClientPerkRepLink'.Static.FindStats(PlayerOwner());
    if ( S==None || !S.bNoStandardChars )
    {
        class'xUtil'.static.GetPlayerList(PlayerList);
        co_Race.AddItem(StockText);
        CategoryNames.Length = 1;
        CategoryNames[0] = StockText;
    }
    CustomOffset = 0;
    CharCategories.Length = PlayerList.Length;

    // Add in custom mod chars.
    if( S!=None )
    {
        for( i=0; i<S.CustomChars.Length; ++i )
        {
            C = S.CustomChars[i];
            j = InStr(C,":");
            if( j==-1 )
                G = CustomText;
            else
            {
                G = Left(C,j);
                C = Mid(C,j+1);
            }
            PR = Class'xUtil'.Static.FindPlayerRecord(C);
            if( PR.DefaultName~=C )
            {
                ++CustomOffset;
                PlayerList.Insert(0,1);
                PlayerList[0] = PR;
                for( j=0; j<CategoryNames.Length; ++j )
                {
                    if( CategoryNames[j]~=G )
                        break;
                }
                if( j==CategoryNames.Length )
                {
                    CategoryNames.Length = j+1;
                    CategoryNames[j] = G;
                    co_Race.AddItem(G);
                }
                CharCategories.Insert(0,1);
                CharCategories[0] = j;
            }
        }
    }

    co_Race.OnChange=RaceChange;

    for (i = PlayerList.Length -1; i >= 0; --i) {
        if (!IsUnLocked(PlayerList[i])) {
            PlayerList.Remove(i,1);
        }
    }

    RefreshCharacterList("");

    // Spawn spinning character actor
    if ( SpinnyDude == None )
        SpinnyDude = PlayerOwner().spawn(class'XInterface.SpinnyWeap');

    SpinnyDude.SetDrawType(DT_Mesh);
    SpinnyDude.SetDrawScale(0.9);
    SpinnyDude.SpinRate = 0;
}

function bool IsUnlocked(xUtil.PlayerRecord Test)
{
    local ScrnPlayerController PC;

    PC = ScrnPlayerController(PlayerOwner());
    if ( PC == none )
        return true;

    // dunno why but Mrs.Foster dosn't pass super.IsUnlocked()
    return PC.IsTeamCharacter(Test.DefaultName) &&
        (Test.DefaultName ~= "Mrs_Foster"
            || Test.DefaultName ~= "Ms_Clamley"
            || super.IsUnlocked(Test));
}


