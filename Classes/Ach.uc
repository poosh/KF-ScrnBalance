Class Ach extends ScrnAchievements;

#exec OBJ LOAD FILE=ScrnAch_T.utx

// The engine limits the size of a localized string to 4096.
// That's why we need to do the copy-paste crap below to bypass the limitaion.
var localized string DisplayName0, Description0;
var localized string DisplayName1, Description1;
var localized string DisplayName2, Description2;
var localized string DisplayName3, Description3;
var localized string DisplayName4, Description4;
var localized string DisplayName5, Description5;
var localized string DisplayName6, Description6;
var localized string DisplayName7, Description7;
var localized string DisplayName8, Description8;
var localized string DisplayName9, Description9;
var localized string DisplayName10, Description10;
var localized string DisplayName11, Description11;
var localized string DisplayName12, Description12;
var localized string DisplayName13, Description13;
var localized string DisplayName14, Description14;
var localized string DisplayName15, Description15;
var localized string DisplayName16, Description16;
var localized string DisplayName17, Description17;
var localized string DisplayName18, Description18;
var localized string DisplayName19, Description19;
var localized string DisplayName20, Description20;
var localized string DisplayName21, Description21;
var localized string DisplayName22, Description22;
var localized string DisplayName23, Description23;
var localized string DisplayName24, Description24;
var localized string DisplayName25, Description25;
var localized string DisplayName26, Description26;
var localized string DisplayName27, Description27;
var localized string DisplayName28, Description28;
var localized string DisplayName29, Description29;
var localized string DisplayName30, Description30;
var localized string DisplayName31, Description31;
var localized string DisplayName32, Description32;
var localized string DisplayName33, Description33;
var localized string DisplayName34, Description34;
var localized string DisplayName35, Description35;
var localized string DisplayName36, Description36;
var localized string DisplayName37, Description37;
var localized string DisplayName38, Description38;
var localized string DisplayName39, Description39;
var localized string DisplayName40, Description40;
var localized string DisplayName41, Description41;
var localized string DisplayName42, Description42;
var localized string DisplayName43, Description43;
var localized string DisplayName44, Description44;
var localized string DisplayName45, Description45;
var localized string DisplayName46, Description46;
var localized string DisplayName47, Description47;
var localized string DisplayName48, Description48;
var localized string DisplayName49, Description49;
var localized string DisplayName50, Description50;
var localized string DisplayName51, Description51;
var localized string DisplayName52, Description52;
var localized string DisplayName53, Description53;
var localized string DisplayName54, Description54;
var localized string DisplayName55, Description55;
var localized string DisplayName56, Description56;
var localized string DisplayName57, Description57;
var localized string DisplayName58, Description58;
var localized string DisplayName59, Description59;
var localized string DisplayName60, Description60;
var localized string DisplayName61, Description61;
var localized string DisplayName62, Description62;
var localized string DisplayName63, Description63;
var localized string DisplayName64, Description64;
var localized string DisplayName65, Description65;
var localized string DisplayName66, Description66;
var localized string DisplayName67, Description67;
var localized string DisplayName68, Description68;
var localized string DisplayName69, Description69;
var localized string DisplayName70, Description70;
var localized string DisplayName71, Description71;
var localized string DisplayName72, Description72;
var localized string DisplayName73, Description73;
var localized string DisplayName74, Description74;
var localized string DisplayName75, Description75;
var localized string DisplayName76, Description76;
var localized string DisplayName77, Description77;
var localized string DisplayName78, Description78;
var localized string DisplayName79, Description79;
var localized string DisplayName80, Description80;
var localized string DisplayName81, Description81;
var localized string DisplayName82, Description82;
var localized string DisplayName83, Description83;
var localized string DisplayName84, Description84;
var localized string DisplayName85, Description85;
var localized string DisplayName86, Description86;
var localized string DisplayName87, Description87;
var localized string DisplayName88, Description88;
var localized string DisplayName89, Description89;
var localized string DisplayName90, Description90;
var localized string DisplayName91, Description91;
var localized string DisplayName92, Description92;
var localized string DisplayName93, Description93;
var localized string DisplayName94, Description94;
var localized string DisplayName95, Description95;
var localized string DisplayName96, Description96;
var localized string DisplayName97, Description97;
var localized string DisplayName98, Description98;
var localized string DisplayName99, Description99;
var localized string DisplayName100, Description100;
var localized string DisplayName101, Description101;
var localized string DisplayName102, Description102;
var localized string DisplayName103, Description103;
var localized string DisplayName104, Description104;
var localized string DisplayName105, Description105;
var localized string DisplayName106, Description106;
var localized string DisplayName107, Description107;
var localized string DisplayName108, Description108;
var localized string DisplayName109, Description109;
var localized string DisplayName110, Description110;
var localized string DisplayName111, Description111;
var localized string DisplayName112, Description112;
var localized string DisplayName113, Description113;
var localized string DisplayName114, Description114;
var localized string DisplayName115, Description115;
var localized string DisplayName116, Description116;
var localized string DisplayName117, Description117;
var localized string DisplayName118, Description118;
var localized string DisplayName119, Description119;
var localized string DisplayName120, Description120;
var localized string DisplayName121, Description121;
var localized string DisplayName122, Description122;
var localized string DisplayName123, Description123;
var localized string DisplayName124, Description124;
var localized string DisplayName125, Description125;
var localized string DisplayName126, Description126;
var localized string DisplayName127, Description127;
var localized string DisplayName128, Description128;
var localized string DisplayName129, Description129;
var localized string DisplayName130, Description130;
var localized string DisplayName131, Description131;
var localized string DisplayName132, Description132;
var localized string DisplayName133, Description133;
var localized string DisplayName134, Description134;
var localized string DisplayName135, Description135;
var localized string DisplayName136, Description136;
var localized string DisplayName137, Description137;
var localized string DisplayName138, Description138;
var localized string DisplayName139, Description139;
var localized string DisplayName140, Description140;
var localized string DisplayName141, Description141;
var localized string DisplayName142, Description142;
var localized string DisplayName143, Description143;
var localized string DisplayName144, Description144;


protected simulated function int ReadProgressFromData(int AchIndex)
{
    if ( AchIndex >= 19 && AchIndex <= 21 ) {
        //kill counter
        if ( RepLink != none )
            return min(RepLink.RKillsStat, AchDefs[AchIndex].MaxProgress);
        else
            return 0; // RepLink isn't set yet
    }
    return super.ReadProgressFromData(AchIndex);
}

simulated function Tick(float DeltaTime)
{
    if ( Role < ROLE_Authority ) {
        if ( GetRepLink() == none )
            return; // RepLink isn't set yet

        if ( RepLink.RKillsStat <= 0 )
            return; // initial replication data is not received yet

        ClientSetAchProgress(19, ReadProgressFromData(19), true);
        ClientSetAchProgress(20, ReadProgressFromData(20), true);
        ClientSetAchProgress(21, ReadProgressFromData(21), true);
    }
    Disable('Tick');
}

simulated function SetDefaultAchievementData()
{
    AchDefs[0].DisplayName = DisplayName0;
    AchDefs[1].DisplayName = DisplayName1;
    AchDefs[2].DisplayName = DisplayName2;
    AchDefs[3].DisplayName = DisplayName3;
    AchDefs[4].DisplayName = DisplayName4;
    AchDefs[5].DisplayName = DisplayName5;
    AchDefs[6].DisplayName = DisplayName6;
    AchDefs[7].DisplayName = DisplayName7;
    AchDefs[8].DisplayName = DisplayName8;
    AchDefs[9].DisplayName = DisplayName9;
    AchDefs[10].DisplayName = DisplayName10;
    AchDefs[11].DisplayName = DisplayName11;
    AchDefs[12].DisplayName = DisplayName12;
    AchDefs[13].DisplayName = DisplayName13;
    AchDefs[14].DisplayName = DisplayName14;
    AchDefs[15].DisplayName = DisplayName15;
    AchDefs[16].DisplayName = DisplayName16;
    AchDefs[17].DisplayName = DisplayName17;
    AchDefs[18].DisplayName = DisplayName18;
    AchDefs[19].DisplayName = DisplayName19;
    AchDefs[20].DisplayName = DisplayName20;
    AchDefs[21].DisplayName = DisplayName21;
    AchDefs[22].DisplayName = DisplayName22;
    AchDefs[23].DisplayName = DisplayName23;
    AchDefs[24].DisplayName = DisplayName24;
    AchDefs[25].DisplayName = DisplayName25;
    AchDefs[26].DisplayName = DisplayName26;
    AchDefs[27].DisplayName = DisplayName27;
    AchDefs[28].DisplayName = DisplayName28;
    AchDefs[29].DisplayName = DisplayName29;
    AchDefs[30].DisplayName = DisplayName30;
    AchDefs[31].DisplayName = DisplayName31;
    AchDefs[32].DisplayName = DisplayName32;
    AchDefs[33].DisplayName = DisplayName33;
    AchDefs[34].DisplayName = DisplayName34;
    AchDefs[35].DisplayName = DisplayName35;
    AchDefs[36].DisplayName = DisplayName36;
    AchDefs[37].DisplayName = DisplayName37;
    AchDefs[38].DisplayName = DisplayName38;
    AchDefs[39].DisplayName = DisplayName39;
    AchDefs[40].DisplayName = DisplayName40;
    AchDefs[41].DisplayName = DisplayName41;
    AchDefs[42].DisplayName = DisplayName42;
    AchDefs[43].DisplayName = DisplayName43;
    AchDefs[44].DisplayName = DisplayName44;
    AchDefs[45].DisplayName = DisplayName45;
    AchDefs[46].DisplayName = DisplayName46;
    AchDefs[47].DisplayName = DisplayName47;
    AchDefs[48].DisplayName = DisplayName48;
    AchDefs[49].DisplayName = DisplayName49;
    AchDefs[50].DisplayName = DisplayName50;
    AchDefs[51].DisplayName = DisplayName51;
    AchDefs[52].DisplayName = DisplayName52;
    AchDefs[53].DisplayName = DisplayName53;
    AchDefs[54].DisplayName = DisplayName54;
    AchDefs[55].DisplayName = DisplayName55;
    AchDefs[56].DisplayName = DisplayName56;
    AchDefs[57].DisplayName = DisplayName57;
    AchDefs[58].DisplayName = DisplayName58;
    AchDefs[59].DisplayName = DisplayName59;
    AchDefs[60].DisplayName = DisplayName60;
    AchDefs[61].DisplayName = DisplayName61;
    AchDefs[62].DisplayName = DisplayName62;
    AchDefs[63].DisplayName = DisplayName63;
    AchDefs[64].DisplayName = DisplayName64;
    AchDefs[65].DisplayName = DisplayName65;
    AchDefs[66].DisplayName = DisplayName66;
    AchDefs[67].DisplayName = DisplayName67;
    AchDefs[68].DisplayName = DisplayName68;
    AchDefs[69].DisplayName = DisplayName69;
    AchDefs[70].DisplayName = DisplayName70;
    AchDefs[71].DisplayName = DisplayName71;
    AchDefs[72].DisplayName = DisplayName72;
    AchDefs[73].DisplayName = DisplayName73;
    AchDefs[74].DisplayName = DisplayName74;
    AchDefs[75].DisplayName = DisplayName75;
    AchDefs[76].DisplayName = DisplayName76;
    AchDefs[77].DisplayName = DisplayName77;
    AchDefs[78].DisplayName = DisplayName78;
    AchDefs[79].DisplayName = DisplayName79;
    AchDefs[80].DisplayName = DisplayName80;
    AchDefs[81].DisplayName = DisplayName81;
    AchDefs[82].DisplayName = DisplayName82;
    AchDefs[83].DisplayName = DisplayName83;
    AchDefs[84].DisplayName = DisplayName84;
    AchDefs[85].DisplayName = DisplayName85;
    AchDefs[86].DisplayName = DisplayName86;
    AchDefs[87].DisplayName = DisplayName87;
    AchDefs[88].DisplayName = DisplayName88;
    AchDefs[89].DisplayName = DisplayName89;
    AchDefs[90].DisplayName = DisplayName90;
    AchDefs[91].DisplayName = DisplayName91;
    AchDefs[92].DisplayName = DisplayName92;
    AchDefs[93].DisplayName = DisplayName93;
    AchDefs[94].DisplayName = DisplayName94;
    AchDefs[95].DisplayName = DisplayName95;
    AchDefs[96].DisplayName = DisplayName96;
    AchDefs[97].DisplayName = DisplayName97;
    AchDefs[98].DisplayName = DisplayName98;
    AchDefs[99].DisplayName = DisplayName99;
    AchDefs[100].DisplayName = DisplayName100;
    AchDefs[101].DisplayName = DisplayName101;
    AchDefs[102].DisplayName = DisplayName102;
    AchDefs[103].DisplayName = DisplayName103;
    AchDefs[104].DisplayName = DisplayName104;
    AchDefs[105].DisplayName = DisplayName105;
    AchDefs[106].DisplayName = DisplayName106;
    AchDefs[107].DisplayName = DisplayName107;
    AchDefs[108].DisplayName = DisplayName108;
    AchDefs[109].DisplayName = DisplayName109;
    AchDefs[110].DisplayName = DisplayName110;
    AchDefs[111].DisplayName = DisplayName111;
    AchDefs[112].DisplayName = DisplayName112;
    AchDefs[113].DisplayName = DisplayName113;
    AchDefs[114].DisplayName = DisplayName114;
    AchDefs[115].DisplayName = DisplayName115;
    AchDefs[116].DisplayName = DisplayName116;
    AchDefs[117].DisplayName = DisplayName117;
    AchDefs[118].DisplayName = DisplayName118;
    AchDefs[119].DisplayName = DisplayName119;
    AchDefs[120].DisplayName = DisplayName120;
    AchDefs[121].DisplayName = DisplayName121;
    AchDefs[122].DisplayName = DisplayName122;
    AchDefs[123].DisplayName = DisplayName123;
    AchDefs[124].DisplayName = DisplayName124;
    AchDefs[125].DisplayName = DisplayName125;
    AchDefs[126].DisplayName = DisplayName126;
    AchDefs[127].DisplayName = DisplayName127;
    AchDefs[128].DisplayName = DisplayName128;
    AchDefs[129].DisplayName = DisplayName129;
    AchDefs[130].DisplayName = DisplayName130;
    AchDefs[131].DisplayName = DisplayName131;
    AchDefs[132].DisplayName = DisplayName132;
    AchDefs[133].DisplayName = DisplayName133;
    AchDefs[134].DisplayName = DisplayName134;
    AchDefs[135].DisplayName = DisplayName135;
    AchDefs[136].DisplayName = DisplayName136;
    AchDefs[137].DisplayName = DisplayName137;
    AchDefs[138].DisplayName = DisplayName138;
    AchDefs[139].DisplayName = DisplayName139;
    AchDefs[140].DisplayName = DisplayName140;
    AchDefs[141].DisplayName = DisplayName141;
    AchDefs[142].DisplayName = DisplayName142;
    AchDefs[143].DisplayName = DisplayName143;
    AchDefs[144].DisplayName = DisplayName144;

    AchDefs[0].Description = Description0;
    AchDefs[1].Description = Description1;
    AchDefs[2].Description = Description2;
    AchDefs[3].Description = Description3;
    AchDefs[4].Description = Description4;
    AchDefs[5].Description = Description5;
    AchDefs[6].Description = Description6;
    AchDefs[7].Description = Description7;
    AchDefs[8].Description = Description8;
    AchDefs[9].Description = Description9;
    AchDefs[10].Description = Description10;
    AchDefs[11].Description = Description11;
    AchDefs[12].Description = Description12;
    AchDefs[13].Description = Description13;
    AchDefs[14].Description = Description14;
    AchDefs[15].Description = Description15;
    AchDefs[16].Description = Description16;
    AchDefs[17].Description = Description17;
    AchDefs[18].Description = Description18;
    AchDefs[19].Description = Description19;
    AchDefs[20].Description = Description20;
    AchDefs[21].Description = Description21;
    AchDefs[22].Description = Description22;
    AchDefs[23].Description = Description23;
    AchDefs[24].Description = Description24;
    AchDefs[25].Description = Description25;
    AchDefs[26].Description = Description26;
    AchDefs[27].Description = Description27;
    AchDefs[28].Description = Description28;
    AchDefs[29].Description = Description29;
    AchDefs[30].Description = Description30;
    AchDefs[31].Description = Description31;
    AchDefs[32].Description = Description32;
    AchDefs[33].Description = Description33;
    AchDefs[34].Description = Description34;
    AchDefs[35].Description = Description35;
    AchDefs[36].Description = Description36;
    AchDefs[37].Description = Description37;
    AchDefs[38].Description = Description38;
    AchDefs[39].Description = Description39;
    AchDefs[40].Description = Description40;
    AchDefs[41].Description = Description41;
    AchDefs[42].Description = Description42;
    AchDefs[43].Description = Description43;
    AchDefs[44].Description = Description44;
    AchDefs[45].Description = Description45;
    AchDefs[46].Description = Description46;
    AchDefs[47].Description = Description47;
    AchDefs[48].Description = Description48;
    AchDefs[49].Description = Description49;
    AchDefs[50].Description = Description50;
    AchDefs[51].Description = Description51;
    AchDefs[52].Description = Description52;
    AchDefs[53].Description = Description53;
    AchDefs[54].Description = Description54;
    AchDefs[55].Description = Description55;
    AchDefs[56].Description = Description56;
    AchDefs[57].Description = Description57;
    AchDefs[58].Description = Description58;
    AchDefs[59].Description = Description59;
    AchDefs[60].Description = Description60;
    AchDefs[61].Description = Description61;
    AchDefs[62].Description = Description62;
    AchDefs[63].Description = Description63;
    AchDefs[64].Description = Description64;
    AchDefs[65].Description = Description65;
    AchDefs[66].Description = Description66;
    AchDefs[67].Description = Description67;
    AchDefs[68].Description = Description68;
    AchDefs[69].Description = Description69;
    AchDefs[70].Description = Description70;
    AchDefs[71].Description = Description71;
    AchDefs[72].Description = Description72;
    AchDefs[73].Description = Description73;
    AchDefs[74].Description = Description74;
    AchDefs[75].Description = Description75;
    AchDefs[76].Description = Description76;
    AchDefs[77].Description = Description77;
    AchDefs[78].Description = Description78;
    AchDefs[79].Description = Description79;
    AchDefs[80].Description = Description80;
    AchDefs[81].Description = Description81;
    AchDefs[82].Description = Description82;
    AchDefs[83].Description = Description83;
    AchDefs[84].Description = Description84;
    AchDefs[85].Description = Description85;
    AchDefs[86].Description = Description86;
    AchDefs[87].Description = Description87;
    AchDefs[88].Description = Description88;
    AchDefs[89].Description = Description89;
    AchDefs[90].Description = Description90;
    AchDefs[91].Description = Description91;
    AchDefs[92].Description = Description92;
    AchDefs[93].Description = Description93;
    AchDefs[94].Description = Description94;
    AchDefs[95].Description = Description95;
    AchDefs[96].Description = Description96;
    AchDefs[97].Description = Description97;
    AchDefs[98].Description = Description98;
    AchDefs[99].Description = Description99;
    AchDefs[100].Description = Description100;
    AchDefs[101].Description = Description101;
    AchDefs[102].Description = Description102;
    AchDefs[103].Description = Description103;
    AchDefs[104].Description = Description104;
    AchDefs[105].Description = Description105;
    AchDefs[106].Description = Description106;
    AchDefs[107].Description = Description107;
    AchDefs[108].Description = Description108;
    AchDefs[109].Description = Description109;
    AchDefs[110].Description = Description110;
    AchDefs[111].Description = Description111;
    AchDefs[112].Description = Description112;
    AchDefs[113].Description = Description113;
    AchDefs[114].Description = Description114;
    AchDefs[115].Description = Description115;
    AchDefs[116].Description = Description116;
    AchDefs[117].Description = Description117;
    AchDefs[118].Description = Description118;
    AchDefs[119].Description = Description119;
    AchDefs[120].Description = Description120;
    AchDefs[121].Description = Description121;
    AchDefs[122].Description = Description122;
    AchDefs[123].Description = Description123;
    AchDefs[124].Description = Description124;
    AchDefs[125].Description = Description125;
    AchDefs[126].Description = Description126;
    AchDefs[127].Description = Description127;
    AchDefs[128].Description = Description128;
    AchDefs[129].Description = Description129;
    AchDefs[130].Description = Description130;
    AchDefs[131].Description = Description131;
    AchDefs[132].Description = Description132;
    AchDefs[133].Description = Description133;
    AchDefs[134].Description = Description134;
    AchDefs[135].Description = Description135;
    AchDefs[136].Description = Description136;
    AchDefs[137].Description = Description137;
    AchDefs[138].Description = Description138;
    AchDefs[139].Description = Description139;
    AchDefs[140].Description = Description140;
    AchDefs[141].Description = Description141;
    AchDefs[142].Description = Description142;
    AchDefs[143].Description = Description143;
    AchDefs[144].Description = Description144;

    super.SetDefaultAchievementData();
}


defaultproperties
{
    ProgressName="Achievements"
    DefaultAchGroup="MISC"
    GroupInfo(1)=(Group="MAP",Caption="Maps")
    GroupInfo(2)=(Group="EXP",Caption="Basic Experience")
    GroupInfo(3)=(Group="MASTER",Caption="Master Skills")
    GroupInfo(4)=(Group="TW",Caption="Teamwork")
    GroupInfo(5)=(Group="MISC",Caption="Miscellaneous")

    AchDefs(0)=(id="WinCustomMaps",DisplayName="Curious",Description="Survive on %c community-made maps",Icon=Texture'KillingFloorHUD.Achievements.Achievement_5',MaxProgress=10,DataSize=6,Group="MAP")
    AchDefs(1)=(id="WinCustomMaps1",DisplayName="Wanderer",Description="Survive on %c community-made maps",Icon=Texture'KillingFloorHUD.Achievements.Achievement_11',MaxProgress=20,DataSize=-1,Group="MAP")
    AchDefs(2)=(id="WinCustomMaps2",DisplayName="Explorer",Description="Survive on %c community-made maps",Icon=Texture'KillingFloorHUD.Achievements.Achievement_17',MaxProgress=30,DataSize=-1,Group="MAP")
    AchDefs(3)=(id="WinCustomMapsNormal",DisplayName="Piece of Cake",Description="Survive on %c community-made maps in any ScrN Balance game",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_109',MaxProgress=7,DataSize=3,Group="MAP")
    AchDefs(4)=(id="WinCustomMapsHard",DisplayName="Pound Cake",Description="Survive on %c community-made maps against Super/Custom specimens and Hardcore Level 5+",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_110',MaxProgress=5,DataSize=3,Group="MAP",FilterMaskAll=2)
    AchDefs(5)=(id="WinCustomMapsSui",DisplayName="Cyanide Cake",Description="Survive on %c community-made maps in Turbo/Nightmare/SocIso/Custom game and HL 10+",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_111',MaxProgress=5,DataSize=3,Group="MAP",FilterMaskAll=4)
    AchDefs(6)=(id="WinCustomMapsHoE",DisplayName="Devil Cake",Description="Survive on %c community-made maps in FTG/XCM/Nightmare/Doom3 game and HL 15+",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_112',MaxProgress=3,DataSize=3,Group="MAP",FilterMaskAll=8)
    AchDefs(7)=(id="KillSuperPat",DisplayName="Death to the Super Scientist",Description="Defeat the Hard or Super Patriarch",Icon=Texture'KillingFloorHUD.Achievements.Achievement_42',MaxProgress=1,DataSize=1,FilterMaskAll=68)
    AchDefs(8)=(id="MerryMen",DisplayName="Merry Men",Description="Kill the Patriarch when everyone is ONLY using Crossbows",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_58',MaxProgress=1,DataSize=1,Group="TW",bForceShow=True)
    AchDefs(9)=(id="MerryMen50cal",DisplayName="Merry Men .50",Description="Kill the Patriarch when everyone is ONLY using M99",Icon=Texture'ScrnAch_T.Achievements.MerryMen50',MaxProgress=1,DataSize=1,Group="TW",bForceShow=True)
    AchDefs(10)=(id="ThinIcePirouette",DisplayName="Thin-Ice Pirouette",Description="Complete %c waves when the rest of your team has died (3+ players)",Icon=Texture'KillingFloorHUD.Achievements.Achievement_36',MaxProgress=10,DataSize=4)
    AchDefs(11)=(id="Kenny",DisplayName="OMG, We Have Kenny!",Description="Having one of you dying almost every wave (5+ waves)",Icon=Texture'ScrnAch_T.Achievements.Kenny',MaxProgress=1,DataSize=1)
    AchDefs(12)=(id="PerkFavorite",DisplayName="Favorite Perk",Description="Survive a game from beginning till the end without changing your perk",Icon=Texture'ScrnAch_T.Achievements.PerkFavorite',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(13)=(id="PerfectBalance",DisplayName="Perfect Balance",Description="Survive 6+ player game having 1 player per perk",Icon=Texture'ScrnAch_T.Achievements.PerfectBalance',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(14)=(id="MrPerky",DisplayName="Mr. Golden Perky",Description="Unlock Gold Medal for ALL perks",Icon=Texture'KillingFloorHUD.Achievements.Achievement_39',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(15)=(id="PerkGreen",DisplayName="Wow, a Green Medal!",Description="Unlock Green Perk Medal",Icon=Texture'ScrnAch_T.Achievements.PerkGreen',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(16)=(id="PerkBlue",DisplayName="Blue Gold",Description="Unlock Blue Perk Medal",Icon=Texture'ScrnAch_T.Achievements.PerkBlue',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(17)=(id="PerkPurple",DisplayName="Purple Reign",Description="Unlock Purple Perk Medal",Icon=Texture'ScrnAch_T.Achievements.PerkPurple',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(18)=(id="PerkOrange",DisplayName="Nothing Rhymes with Orange",Description="Unlock Orange Perk Medal",Icon=Texture'ScrnAch_T.Achievements.PerkOrange',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(19)=(id="Kill1000Zeds",DisplayName="Junior Zed Exterminator",Description="Kill 1,000 Specimens",Icon=Texture'KillingFloorHUD.Achievements.Achievement_18',MaxProgress=1000,DataSize=-2,Group="EXP")
    AchDefs(20)=(id="Kill10000Zeds",DisplayName="Zed Slayer",Description="Kill 10,000 Specimens",Icon=Texture'KillingFloorHUD.Achievements.Achievement_19',MaxProgress=10000,DataSize=-1,Group="EXP")
    AchDefs(21)=(id="Kill100000Zeds",DisplayName="Killing Machine",Description="Kill 100,000 Specimens",Icon=Texture'KillingFloorHUD.Achievements.Achievement_20',MaxProgress=100000,DataSize=-1,Group="EXP")
    AchDefs(22)=(id="OldSchoolKiting",DisplayName="Old-School Kiting",Description="Kill 15 Fleshpounds with an Axe",Icon=Texture'KillingFloorHUD.Achievements.Achievement_31',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(23)=(id="SuicideBomber",DisplayName="Suicide Bomber",Description="Detonate grenade in your hands, killing at least 5 zeds with it",Icon=Texture'ScrnAch_T.Achievements.Ahmed',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(24)=(id="Snipe250SC",DisplayName="Sharpening Scrakes",Description="Kill %c Scrakes with Sharpshooter's weapons",Icon=Texture'ScrnAch_T.Achievements.ScrakeSniper250',MaxProgress=250,DataSize=8,Group="EXP")
    AchDefs(25)=(id="BringingLAW",DisplayName="Bringing the LAW",Description="Kill 100 Big Zeds with L.A.W.",Icon=Texture'KillingFloorHUD.Achievements.Achievement_41',MaxProgress=100,DataSize=8,Group="EXP")
    AchDefs(26)=(id="FastShot",DisplayName="Fast Shot",Description="Stun&Kill 100 Husks before they hurt anyone",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_148',MaxProgress=100,DataSize=8,Group="EXP")
    AchDefs(27)=(id="NapalmStrike",DisplayName="Napalm Strike",Description="Kill 20 specimens with a single napalm blow",Icon=Texture'KillingFloorHUD.Achievements.Achievement_23',MaxProgress=1,bForceShow=True,DataSize=1,Group="MASTER")
    AchDefs(28)=(id="HC4Kills",DisplayName="One Bloody Handsome",Description="Kill 4 specimens with a single shot of a Handcannon",Icon=Texture'KillingFloorHUD.Achievements.Achievement_29',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(29)=(id="Magnum12Kills",DisplayName="Double Penetration",Description="Kill 12 specimens with Magnum .44 without reloading",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_169',MaxProgress=1,bForceShow=True,DataSize=1,Group="MASTER")
    AchDefs(30)=(id="MK23_12Kills",DisplayName="Penetration is for Pussies",Description="Kills 12 specimens with headshots from MK23 without reloading",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_176',MaxProgress=1,bForceShow=True,DataSize=1,Group="MASTER")
    AchDefs(31)=(id="BruteXbow",DisplayName="Brutal Men",Description="Kill %c Brutes with Crossbow or M99 without taking a damage",Icon=Texture'ScrnAch_T.Achievements.BruteSniper',MaxProgress=30,FilterMaskAll=32,DataSize=5,Group="MASTER")
    AchDefs(32)=(id="BruteM14",DisplayName="Brutal Dot",Description="Kill %c Brutes with M14 without taking a damage",Icon=Texture'ScrnAch_T.Achievements.BruteM14',MaxProgress=50,FilterMaskAll=32,DataSize=6,Group="MASTER")
    AchDefs(33)=(id="BruteScar",DisplayName="Brutally SCAR'd",Description="Kill %c Brutes with SCAR/FNFAL without taking a damage",Icon=Texture'ScrnAch_T.Achievements.BruteScar',MaxProgress=15,FilterMaskAll=32,DataSize=4,Group="MASTER")
    AchDefs(34)=(id="Kill100FPExplosives",DisplayName="Pound This",Description="Kill %c Fleshpounds with explosives",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_64',MaxProgress=100,DataSize=7,Group="EXP")
    AchDefs(35)=(id="Nail250Zeds",DisplayName="Nail'd",Description="Nail %c alive zeds to walls",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_186',MaxProgress=250,DataSize=8,Group="EXP")
    AchDefs(36)=(id="NailPush100m",DisplayName="Fly High",Description="Push %c zeds at least 100m away with Nailgun",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_61',MaxProgress=10,DataSize=4,Group="EXP")
    AchDefs(37)=(id="NailPushShiver",DisplayName="Teleported Back",Description="Push back headless Shiver with Nailgun",Icon=Texture'ScrnAch_T.Achievements.Teleport',MaxProgress=1,FilterMaskAll=32,DataSize=1)
    AchDefs(38)=(id="TrueCowboy",DisplayName="True Cowboy",Description="Spend an entire wave in Cowboy Mode",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_170',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(39)=(id="MadCowboy",DisplayName="Mad Cowboy",Description="Kill 8 zeds with Machine Pistols without releasing a trigger",Icon=Texture'ScrnAch_T.Achievements.CrazyCowboy',MaxProgress=1,DataSize=1,Group="MISC",bForceShow=True)
    AchDefs(40)=(id="M4203Kill50Zeds",DisplayName="#1 In Trash Cleaning",Description="Kill 40 zeds in one wave with M4-203 SE",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_165',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(41)=(id="M99Kill3SC",DisplayName="Ain't Looking For Easy Ways",Description="Kill %c Raged Scrakes with M99 headshots (Sui+)",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_180',MaxProgress=3,DataSize=2)
    AchDefs(42)=(id="ExplosionLove",DisplayName="Explosion of Love",Description="Heal 4 players with one medic grenade",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_187',MaxProgress=1,DataSize=1)
    AchDefs(43)=(id="iDoT",DisplayName="Power of iDoT",Description="Reach 300dps incremental Damage over Time (iDoT) with flares",Icon=Texture'ScrnAch_T.Achievements.iDoT',MaxProgress=1,DataSize=1)
    AchDefs(44)=(id="Unassisted",DisplayName="Unassisted",Description="Solo-kill 6p HoE Fleshpound",Icon=Texture'ScrnAch_T.Achievements.Unassisted',MaxProgress=1,bForceShow=True,DataSize=1,Group="MASTER")
    AchDefs(45)=(id="TW_SC_LAWHSG",DisplayName="TeamWork: When Size Matters",Description="Finish %c LAW-stunned Scrakes with Hunting or Combat Shotgun",Icon=Texture'ScrnAch_T.Teamwork.SC_LAWHSG',MaxProgress=30,DataSize=5,Group="TW")
    AchDefs(46)=(id="TW_SC_Instant",DisplayName="TeamWork: Instant Kill",Description="Kill %c Scrakes with two simultaneous Crossbow/M99 headshots",Icon=Texture'ScrnAch_T.Teamwork.SC_InstantKill',MaxProgress=30,bForceShow=True,DataSize=5,Group="TW")
    AchDefs(47)=(id="TW_Siren",DisplayName="TeamWork: No Big Guns on Skinny Bitches",Description="Kill %c Sirens with Pistols + Assault Rifles",Icon=Texture'ScrnAch_T.Teamwork.siren',MaxProgress=100,DataSize=7,Group="TW")
    AchDefs(48)=(id="TW_Shiver",DisplayName="TeamWork: Grilled Shiver Brains",Description="Decapitate %c burning Shivers with Assault Rifles",Icon=Texture'ScrnAch_T.Teamwork.Shiver',MaxProgress=50,FilterMaskAll=32,DataSize=8,Group="TW")
    AchDefs(49)=(id="TW_Husk_Stun",DisplayName="TeamWork: Stunning Shot, Mate!",Description="Finish %c stunned Husks with Shotguns",Icon=Texture'ScrnAch_T.Teamwork.Husk_Stun',MaxProgress=30,DataSize=6,Group="TW")
    AchDefs(50)=(id="TW_FP_Snipe",DisplayName="TeamWork: Sharpened Flesh",Description="Headshot-kill %c Fleshpounds by 2+ Sharpshooters",Icon=Texture'ScrnAch_T.Teamwork.FP_XBOWM14',MaxProgress=15,DataSize=4,Group="TW")
    AchDefs(51)=(id="TW_FP_Pipe",DisplayName="TeamWork: Sniper Blow",Description="Rage %c Fleshpounds directly on a pipebomb with Crossbow/M99",Icon=Texture'ScrnAch_T.Teamwork.FP_M99Pipe',MaxProgress=15,DataSize=4,Group="TW")
    AchDefs(52)=(id="ScrakeNader",DisplayName="Scrake Nader",Description="Rage %c stunned Scrakes with hand grenades",Icon=Texture'ScrnAch_T.Achievements.ScrakeNaders',MaxProgress=50,DataSize=8)
    AchDefs(53)=(id="ScrakeUnnader",DisplayName="Why the Hell Are You Nading Scrakes?!",Description="Kill %c naded Scrakes with sniper weapons, before they do any damage to your retarded teammates.",Icon=Texture'ScrnAch_T.Achievements.ScrakeUnnader',MaxProgress=50,DataSize=8)
    AchDefs(54)=(id="TouchOfSavior",DisplayName="Touch of Savior",Description="Make %c heals, saving player from a death",Icon=Texture'ScrnAch_T.Achievements.TouchOfSavior',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(55)=(id="OnlyHealer",DisplayName="I Heal, You - Shoot!",Description="Be the only healing person in 3+player team for %c waves (200+hp)",Icon=Texture'KillingFloorHUD.Achievements.Achievement_35',MaxProgress=10,DataSize=4,Group="EXP")
    AchDefs(56)=(id="CombatMedic",DisplayName="Combat Medic",Description="Heal %c players and kill their enemies too",Icon=Texture'ScrnAch_T.Achievements.CombatMedic',MaxProgress=100,DataSize=8,Group="EXP")
    AchDefs(57)=(id="MeleeKillCrawlers",DisplayName="My Kung Fu is Better",Description="Melee-kill %c Crawlers without taking a damage",Icon=Texture'ScrnAch_T.Achievements.MeleeCrawler',MaxProgress=250,DataSize=8,Group="MASTER")
    AchDefs(58)=(id="MeleeHitBehind",DisplayName="My Kung Fu is Stronger",Description="Melee-hit %c zeds from behind",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_120',MaxProgress=250,DataSize=8,Group="MASTER")
    AchDefs(59)=(id="MeleeDecapBloats",DisplayName="My Kung Fu Doesn't Make You Puke",Description="Decapitate %c Bloats with melee weapons without getting puked",Icon=Texture'KillingFloorHUD.Achievements.Achievement_30',MaxProgress=50,DataSize=6,Group="MASTER")
    AchDefs(60)=(id="Ash",DisplayName="Tribute to Ash Williams",Description="Kill 40 zeds in a wave with Boomstick and Chainsaw (10+ kills each). Do not use any other weapons!",Icon=Texture'ScrnAch_T.Achievements.Ash',MaxProgress=1,bForceShow=True,DataSize=1)
    AchDefs(61)=(id="Overkill",DisplayName="Overkill",Description="Shoot a Crawler in the head with M99",Icon=Texture'ScrnAch_T.Achievements.Overkill',MaxProgress=1,DataSize=1)
    AchDefs(62)=(id="BruteExplosive",DisplayName="Block THIS!",Description="Kill %c Brutes with explosive damage",Icon=Texture'ScrnAch_T.Achievements.BruteExplosive',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(63)=(id="KillHuskHuskGun",DisplayName="Burning Irony",Description="Kill %c Husks with Husk Cannon",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_57',MaxProgress=30,DataSize=5,Group="EXP")
    AchDefs(64)=(id="HFC",DisplayName="Horzine Fried Crawler",Description="Recipe: Burn %c Crawlers at temp. below 80C until they die.",Icon=Texture'ScrnAch_T.Achievements.HFC',MaxProgress=999,DataSize=10,Group="EXP")
    AchDefs(65)=(id="CarveRoast",DisplayName="Let Me Carve a Roast",Description="Kill %c crispified zeds with melee weapons.",Icon=Texture'ScrnAch_T.Achievements.CarveRoast',MaxProgress=30,DataSize=6)
    AchDefs(66)=(id="DotOfDoom",DisplayName="Dot of Doom",Description="Get 25 headshots in a row with the M14EBR.",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_59',MaxProgress=1,bForceShow=True,DataSize=1,Group="MASTER")
    AchDefs(67)=(id="Money10k",DisplayName="I Need DOSH!",Description="Start a wave having 10,000 pounds of cash",Icon=Texture'KillingFloorHUD.Achievements.Achievement_37',MaxProgress=1,DataSize=1)
    AchDefs(68)=(id="Welcome",DisplayName="Welcome to ScrN Balance!",Description="Welcome to the ScrN Total Game Balance Community! Enjoy the best modification for Killing Floor!",Icon=Texture'ScrnAch_T.Achievements.PerfectBalance',MaxProgress=1,DataSize=1)
    AchDefs(69)=(id="MedicOfDoom",DisplayName="Medic of Doom",Description="Kill 15 zeds with M4-203M Medic Rifle without reloading.",Icon=Texture'ScrnAch_T.Master.MedicOfDoom',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(70)=(id="Plus25Clots",DisplayName="+25 Clot kills",Description="Kill 25 clots having less than 4 seconds between subsequent kills.",Icon=Texture'ScrnAch_T.Master.Plus25Clots',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(71)=(id="GetOffMyLawn",DisplayName="I said get off my Lawn!",Description="Kill %c Fleshpounds with the Boomstick or Combat Shotgun.",Icon=Texture'ScrnAch_T.Master.GetOffMyLawn',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(72)=(id="Accuracy",DisplayName="Accuracy",Description="Finish %c waves with 75% headshot accuracy. At least 30 decapitations required per wave.",Icon=Texture'ScrnAch_T.Master.Accuracy',MaxProgress=10,DataSize=4,Group="MASTER")
    AchDefs(73)=(id="SteampunkSniper",DisplayName="Steampunk Sniper",Description="Score 10 headshots in a row with Musket. Do it %c times.",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_223',MaxProgress=4,DataSize=3,Group="MASTER")
    AchDefs(74)=(id="MeleeGod",DisplayName="Melee God",Description="Kill %c Scrakes with only head-hits from melee weapons. Buzzsaw Bow excluding.",Icon=Texture'ScrnAch_T.Master.Gauntlet',MaxProgress=30,DataSize=5,Group="MASTER")
    AchDefs(75)=(id="HuskGunSC",DisplayName="Weird but usefull",Description="Kill %c Scrakes with the Husk Gun.",Icon=Texture'ScrnAch_T.Exp.HuskGunSC',MaxProgress=30,DataSize=5,Group="EXP")
    AchDefs(76)=(id="Impressive",DisplayName="Impressive",Description="Score 5 headshots in a row %c times.",Icon=Texture'ScrnAch_T.Exp.Impressive',MaxProgress=250,DataSize=8,Group="EXP")
    AchDefs(77)=(id="GrimReaper",DisplayName="Grim Reaper",Description="Kill %c zeds with Scythe.",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_193',MaxProgress=250,DataSize=8,Group="EXP")
    AchDefs(78)=(id="MindBlowingSacrifice",DisplayName="Mind-Blowing Sacrifice",Description="Kill %c Fleshpounds by blocking them on own pipes.",Icon=Texture'ScrnAch_T.Exp.MindBlowingSacrifice',MaxProgress=7,DataSize=3,Group="EXP")
    AchDefs(79)=(id="PrematureDetonation",DisplayName="Premature Detonation",Description="Kill %c zeds with undetonated grenades or rockets.",Icon=Texture'ScrnAch_T.Exp.PrematureDetonation',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(80)=(id="NoHeadshots",DisplayName="Hitboxes Are Overrated",Description="Kill %c big zeds without landing any headshot and taking damage.",Icon=Texture'ScrnAch_T.Exp.NoHeadshots',MaxProgress=62,DataSize=6,Group="EXP")
    AchDefs(81)=(id="BitterIrony",DisplayName="Bitter Irony",Description="Kill %c Scrakes with a Chainsaw.",Icon=Texture'KillingFloorHUD.Achievements.Achievement_25',MaxProgress=62,DataSize=6,Group="EXP")
    AchDefs(82)=(id="BallsOfSteel",DisplayName="Balls of Steel",Description="Survive an entire game without wearing heavy armor, damage resistance and dying.",Icon=Texture'ScrnAch_T.Exp.BallsOfSteel',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(83)=(id="OutOfTheGum",DisplayName="Out of the Gum",Description="Kill 30 specimens with bullets, having less than 5 seconds between subsequent kills.",Icon=Texture'ScrnAch_T.Exp.OutOfTheGum',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(84)=(id="HorzineArmor",DisplayName="Good Defence Is NOT a Good Offence",Description="Survive %c times after taking a heavy damage, thanks to wearing a Horzine Armor.",Icon=Texture'ScrnAch_T.Exp.HorzineArmor',MaxProgress=7,DataSize=3,Group="EXP")
    AchDefs(85)=(id="RocketBlow",DisplayName="I Love Rocket Blow",Description="Kill 10 specimens with a single rocket blow. Liked it? Then do it %c times.",Icon=Texture'ScrnAch_T.Exp.RocketBlow',MaxProgress=30,DataSize=5,Group="EXP")
    AchDefs(86)=(id="SavingResources",DisplayName="Saving Resources",Description="Save %c pipebombs from Bloats or Sirens.",Icon=Texture'ScrnAch_T.Exp.SavingResources',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(87)=(id="Gunslingophobia",DisplayName="Gunslingophobia",Description="One-shot kill %c Crawlers with pistols.",Icon=Texture'ScrnAch_T.Exp.Gunslingophobia',MaxProgress=1001,DataSize=10,Group="EXP")
    AchDefs(88)=(id="OldGangster",DisplayName="Old Gangster",Description="Kill 5 zeds without releasing the trigger of your Tommy Gun (drum mag.)",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_227',MaxProgress=55,DataSize=6,Group="EXP")
    AchDefs(89)=(id="TW_PipeBlock",DisplayName="TeamWork: Hold On, The Big One! Take a Present.",Description="Block %c  big zeds on pipebombs without taking significant damage.",Icon=Texture'ScrnAch_T.Teamwork.PipeBlock',MaxProgress=30,DataSize=5,Group="TW")
    AchDefs(90)=(id="TW_BackstabSC",DisplayName="TeamWork: Taking From Behind",Description="Attract %c Scrakes on yourself, allowing teammate to backstab him.",Icon=Texture'ScrnAch_T.Teamwork.BackstabScrakes',MaxProgress=30,DataSize=5,Group="TW")
    AchDefs(91)=(id="NoI",DisplayName="There is no I in the TEAM",Description="Finish the wave, where all (3+) players have almost the same kill count (+/-10%).",Icon=Texture'ScrnAch_T.Teamwork.NoI',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(92)=(id="PatMelee",DisplayName="We Don't Give a **** About The Radial Attack",Description="Kill Patriarch with melee weapons only.",Icon=Texture'ScrnAch_T.Teamwork.PatMelee',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(93)=(id="Pat9mm",DisplayName="Peashooters",Description="Kill End Game Boss with 9mm pistols only.",Icon=Texture'ScrnAch_T.Teamwork.Peashooters',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(94)=(id="PatPrey",DisplayName="Hunting the Prey",Description="Hunt the Patriarch during his heal-runs and kill him in 2:00 without focusing on other specimens.",Icon=Texture'ScrnAch_T.Teamwork.PatPrey',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(95)=(id="PerfectWave",DisplayName="Perfect Wave",Description="Survive %c waves without anybody taking a damage. Wave 1 excluding.",Icon=Texture'ScrnAch_T.Teamwork.PerfectWave',MaxProgress=15,DataSize=4,Group="TW")
    AchDefs(96)=(id="PerfectGame",DisplayName="Perfect Game",Description="Survive 2+ player game without a single player death.",Icon=Texture'ScrnAch_T.Teamwork.PerfectGame',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(97)=(id="SpeedrunBronze",DisplayName="Speedrun Bronze",Description="Win a long game in 45 minutes. Map should have at least 3 traders.",Icon=Texture'ScrnAch_T.Teamwork.SpeedrunBronze',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(98)=(id="SpeedrunSilver",DisplayName="Speedrun Silver",Description="Win a long game in 40 minutes. Map should have at least 3 traders.",Icon=Texture'ScrnAch_T.Teamwork.SpeedrunSilver',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(99)=(id="SpeedrunGold",DisplayName="Speedrun Gold",Description="Win a long game in 33 minutes. Map should have at least 3 traders.",Icon=Texture'ScrnAch_T.Teamwork.SpeedrunGold',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(100)=(id="Blame55p",DisplayName="Acute Case of Fecalphilia",Description="Blame 55 things. Make a good reason for doing that.",Icon=Texture'ScrnAch_T.Achievements.Blame55p',MaxProgress=55,DataSize=6)
    AchDefs(101)=(id="BlameMe",DisplayName="Self-Criticism Approved",Description="Blame yourself. Make a good reason for doing that.",Icon=Texture'ScrnAch_T.Achievements.BlameMe',MaxProgress=1,DataSize=1)
    AchDefs(102)=(id="BlameTeam",DisplayName="You Guys Suck",Description="Blame your team. Make a good reason for doing that.",Icon=Texture'ScrnAch_T.Achievements.BlameTeam',MaxProgress=1,DataSize=1)
    AchDefs(103)=(id="MaxBlame",DisplayName="Conductor of the Poop Train",Description="Get blamed 5 times in one game.",Icon=Texture'ScrnAch_T.Achievements.PoopTrain',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(104)=(id="KillWhore",DisplayName="KillWhore",Description="Get 2.5x more kills than any other player in your team (3+p).",Icon=Texture'ScrnAch_T.Achievements.KillWhore',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(105)=(id="ComeatMe",DisplayName="Come at Me, Bro!",Description="Kill a Jason with a Machete.",Icon=Texture'ScrnAch_T.Achievements.ComeatMe',MaxProgress=1,DataSize=1,FilterMaskAll=32)
    AchDefs(106)=(id="Friday13",DisplayName="Friday the 13th",Description="Survive the wave after 2 of your teammates got killed by Jason Voorhees.",Icon=Texture'ScrnAch_T.Achievements.Friday13',MaxProgress=1,DataSize=1,FilterMaskAll=32)
    AchDefs(107)=(id="ClotHater",DisplayName="Clot Hater",Description="Kill 15 Clots in a row. Do it %c times. Cuz you really hate them.",Icon=Texture'ScrnAch_T.Achievements.ClotHater',MaxProgress=15,DataSize=4)
    AchDefs(108)=(id="MadeinChina",DisplayName="Made in China",Description="Get blown up by your own Pipebomb.",Icon=Texture'ScrnAch_T.Achievements.MadeinChina',MaxProgress=1,DataSize=1)
    AchDefs(109)=(id="FastVengeance",DisplayName="Fast Vengeance",Description="Kill a zed within 5 seconds of it killed a teammate.",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_198',MaxProgress=1,DataSize=1)
    AchDefs(110)=(id="Overkill1",DisplayName="Overkill vol.1",Description="Kill a Crawler with a headshot from fully-charged Husk Gun.",Icon=Texture'ScrnAch_T.Achievements.Overkill1',MaxProgress=1,DataSize=1)
    AchDefs(111)=(id="Overkill2",DisplayName="Overkill vol.2",Description="Kill a Crawler with a headshot from undetonated rocket.",Icon=Texture'ScrnAch_T.Achievements.Overkill2',MaxProgress=1,DataSize=1)
    AchDefs(112)=(id="Overkill3",DisplayName="Overkill vol.3",Description="Blow up your own pipe, which kills only a single Crawler.",Icon=Texture'ScrnAch_T.Achievements.Overkill3',MaxProgress=1,DataSize=1)
    AchDefs(113)=(id="LuxuryFuneral",DisplayName="Savings For a Luxury Funeral",Description="Your teammate was greedy. He had a lot of money to share but he'd choosen to save... for the own funeral.",Icon=Texture'KillingFloorHUD.Achievements.Achievement_27',MaxProgress=1,DataSize=1)
    AchDefs(114)=(id="Cookies",DisplayName="All Your Cookies Belong To Me",Description="Kill %c zeds with weapons picked up from dead player corpses.",Icon=Texture'ScrnAch_T.Achievements.Cookies',MaxProgress=13,DataSize=4)
    AchDefs(115)=(id="EyeForAnEye",DisplayName="Eye for an Eye",Description="Kill a specimen, who killed your teamate, with a weapon, picked up from his body.",Icon=Texture'ScrnAch_T.Achievements.EyeForAnEye',MaxProgress=1,DataSize=1)
    AchDefs(116)=(id="MilkingCow",DisplayName="Milking Cow",Description="Spare $2000 cash with your teammates without receiving it back.",Icon=Texture'ScrnAch_T.Achievements.Cow',MaxProgress=1,DataSize=1)
    AchDefs(117)=(id="SpareChange",DisplayName="Spare Change for Homeless",Description="Spare $1 with your poor teammate, who has at least 10x less money than you (including donations).",Icon=Texture'ScrnAch_T.Achievements.SpareChange',MaxProgress=1,DataSize=1)
    AchDefs(118)=(id="SellCrap",DisplayName="Want Dosh? Sell THIS!",Description="Blame a player who is begging for money.",Icon=Texture'ScrnAch_T.Achievements.SellCrap',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(119)=(id="GhostSmell",DisplayName="I Can Smell Ghosts",Description="Decapitate %c Ghosts with Sharpshooter's weapons from 20+ meters",Icon=Texture'ScrnAch_T.ScrnZeds.GhostSmell',MaxProgress=15,DataSize=4,FilterMaskAll=16,Group="EXP")
    AchDefs(120)=(id="Ghostbuster",DisplayName="Ghostbuster",Description="As Commando, kill %c Stalkers or Ghosts within detection range without taking a damage.",Icon=Texture'ScrnAch_T.ScrnZeds.Ghostbuster',MaxProgress=100,DataSize=7,FilterMaskAll=16,Group="EXP")
    AchDefs(121)=(id="TeslaBomber",DisplayName="Tesla Bomber",Description="Kill %c ZEDs with Tesla Husks's self-destruct explosion.",Icon=Texture'ScrnAch_T.ScrnZeds.TeslaBomber',MaxProgress=30,DataSize=5,FilterMaskAll=16,Group="MASTER")
    AchDefs(122)=(id="NikolaTesla",DisplayName="Nikola Tesla and You",Description="Kill %c Tesla Husks with close-combat weapons (melee or shotguns). But take some electrical damage before!",Icon=Texture'ScrnAch_T.ScrnZeds.NikolaTesla',MaxProgress=15,DataSize=4,FilterMaskAll=16)
    AchDefs(123)=(id="TeslaChain",DisplayName="Chain Reaction",Description="Get connected to 2 other players with Tesla Beams",Icon=Texture'ScrnAch_T.ScrnZeds.TeslaChain',MaxProgress=1,DataSize=1,FilterMaskAll=16)
    AchDefs(124)=(id="TSCT",DisplayName="TSC Tournament Member",Description="Participate in TSC Tournement and get into the Playoffs",Icon=Texture'ScrnTex.Tourney.TourneyMember64',MaxProgress=1,DataSize=1,Group="Hidden")
    AchDefs(125)=(id="KFG1",DisplayName="'Consider this a warning'",Description="Kill a Husk with Crossbow in 2 seconds after killing another zed with Handcannon",Icon=Texture'ScrnAch_T.Achievements.Stupid',MaxProgress=1,DataSize=1)
    AchDefs(126)=(id="KFG2",DisplayName="'Aimbot detected'",Description="Survive Wave 10 with at least 10% headshot accuracy",Icon=Texture'ScrnAch_T.Achievements.Stupid',MaxProgress=1,DataSize=1)
    AchDefs(127)=(id="AchReset",DisplayName="Achievement Reset",Description="Reset your achievements (all but maps) by executing 'AchReset' console command.",Icon=Texture'ScrnAch_T.Achievements.AchReset',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(128)=(id="MeleeKillMidairCrawlers",DisplayName="My Kung Fu is Awesome",Description="Melee-hit %c Crawlers in midair without taking damage",Icon=Texture'ScrnAch_T.Achievements.MeleeCrawler',MaxProgress=50,DataSize=6,Group="MASTER")
    AchDefs(129)=(id="GunslingerSC",DisplayName="Two Bloody Handsome",Description="Kill %c Scrakes with Dual HC/.44 without taking damage",Icon=Texture'ScrnAch_T.Master.GunslingerSC',MaxProgress=50,DataSize=6,Group="MASTER")
    AchDefs(130)=(id="ProNailer",DisplayName="Pro-Nailer",Description="Decapitate zed with nail ricochet",Icon=Texture'ScrnAch_T.Master.ProNailer',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(131)=(id="TW_NoHeadshots",DisplayName="Hitboxes Are TOTALLY Overrated",Description="Survive 2+player game without scoring any headshot",Icon=Texture'ScrnAch_T.Teamwork.NoobAlert',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(132)=(id="TW_SkullCrackers",DisplayName="SkullCrackers",Description="Survive 2+player game by only using weapons that are capable of doing headshots (no nades, fire, etc.)",Icon=Texture'ScrnAch_T.Teamwork.SkullCrackers',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(133)=(id="OP_Medic",DisplayName="Is Medic OP?",Description="Survive 3+player game where everybody is playing Medic",Icon=Texture'ScrnAch_T.Teamwork.OP_Medic',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(134)=(id="OP_Support",DisplayName="Is Support OP?",Description="Survive 3+player game where everybody is playing Support",Icon=Texture'ScrnAch_T.Teamwork.OP_Support',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(135)=(id="OP_Sharpshooter",DisplayName="Is Sharpshooter OP?",Description="Survive 3+player game where everybody is playing Sharpshooter",Icon=Texture'ScrnAch_T.Teamwork.OP_Sharpshooter',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(136)=(id="OP_Commando",DisplayName="Is Commando OP?",Description="Survive 3+player game where everybody is playing Commando",Icon=Texture'ScrnAch_T.Teamwork.OP_Commando',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(137)=(id="OP_Berserker",DisplayName="Is Berserker OP?",Description="Survive 3+player game where everybody is playing Berserker",Icon=Texture'ScrnAch_T.Teamwork.OP_Berserker',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(138)=(id="OP_Firebug",DisplayName="Is Firebug OP?",Description="Survive 3+player game where everybody is playing Firebug",Icon=Texture'ScrnAch_T.Teamwork.OP_Firebug',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(139)=(id="OP_Demo",DisplayName="Is Demo OP?",Description="Survive 3+player game where everybody is playing Demolition",Icon=Texture'ScrnAch_T.Teamwork.OP_Demo',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(140)=(id="OP_Gunslinger",DisplayName="Is Gunslinger OP?",Description="Survive 3+player game where everybody is playing Gunslinger",Icon=Texture'ScrnAch_T.Teamwork.OP_Gunslinger',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(141)=(id="MacheteKillMidairCrawler",DisplayName="Machete Master",Description="Use Machete to melee-kill Crawler in midair without taking damage",Icon=Texture'ScrnAch_T.Master.MacheteCrawlerCut',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(142)=(id="MacheteStunSC",DisplayName="Machete Stuns!",Description="Stun Scrake with Machete",Icon=Texture'ScrnAch_T.Master.MacheteScrake',MaxProgress=1,DataSize=1,Group="MASTER",Group="Hidden")
    AchDefs(143)=(id="MacheteWalker",DisplayName="Machete Marathon",Description="Perform 'Machete-sprint': drop/pickup Machete 422 times while running in a single game",Icon=Texture'ScrnAch_T.Achievements.MacheteWalker',MaxProgress=1,DataSize=1,bForceShow=True,Group="Hidden")
    AchDefs(144)=(id="EvilDeadCombo",DisplayName="Evil Dead Combo",Description="Solo-kill %c Scrakes with Chainsaw+Boomstick without taking damage",Icon=Texture'ScrnAch_T.Achievements.Ash',MaxProgress=15,DataSize=4,Group="MASTER")

    DisplayName0="Curious"
    DisplayName1="Wanderer"
    DisplayName2="Explorer"
    DisplayName3="Piece of Cake"
    DisplayName4="Pound Cake"
    DisplayName5="Cyanide Cake"
    DisplayName6="Devil Cake"
    DisplayName7="Death to the Super Scientist"
    DisplayName8="Merry Men"
    DisplayName9="Merry Men .50"
    DisplayName10="Thin-Ice Pirouette"
    DisplayName11="OMG, We Have Kenny!"
    DisplayName12="Favorite Perk"
    DisplayName13="Perfect Balance"
    DisplayName14="Mr. Golden Perky"
    DisplayName15="Wow, a Green Medal!"
    DisplayName16="Blue Gold"
    DisplayName17="Purple Reign"
    DisplayName18="Nothing Rhymes with Orange"
    DisplayName19="Junior Zed Exterminator"
    DisplayName20="Zed Slayer"
    DisplayName21="Killing Machine"
    DisplayName22="Old-School Kiting"
    DisplayName23="Suicide Bomber"
    DisplayName24="Sharpening Scrakes"
    DisplayName25="Bringing the LAW"
    DisplayName26="Fast Shot"
    DisplayName27="Napalm Strike"
    DisplayName28="One Bloody Handsome"
    DisplayName29="Double Penetration"
    DisplayName30="Penetration is for Pussies"
    DisplayName31="Brutal Men"
    DisplayName32="Brutal Dot"
    DisplayName33="Brutally SCAR'd"
    DisplayName34="Pound This"
    DisplayName35="Nail'd"
    DisplayName36="Fly High"
    DisplayName37="Teleported Back"
    DisplayName38="True Cowboy"
    DisplayName39="Mad Cowboy"
    DisplayName40="#1 In Trash Cleaning"
    DisplayName41="Ain't Looking For Easy Ways"
    DisplayName42="Explosion of Love"
    DisplayName43="Power of iDoT"
    DisplayName44="Unassisted"
    DisplayName45="TeamWork: When Size Matters"
    DisplayName46="TeamWork: Instant Kill"
    DisplayName47="TeamWork: No Big Guns on Skinny Bitches"
    DisplayName48="TeamWork: Grilled Shiver Brains"
    DisplayName49="TeamWork: Stunning Shot, Mate!"
    DisplayName50="TeamWork: Sharpened Flesh"
    DisplayName51="TeamWork: Sniper Blow"
    DisplayName52="Scrake Nader"
    DisplayName53="Why the Hell Are You Nading Scrakes?!"
    DisplayName54="Touch of Savior"
    DisplayName55="I Heal, You - Shoot!"
    DisplayName56="Combat Medic"
    DisplayName57="My Kung Fu is Better"
    DisplayName58="My Kung Fu is Stronger"
    DisplayName59="My Kung Fu Doesn't Make You Puke"
    DisplayName60="Tribute to Ash Williams"
    DisplayName61="Overkill"
    DisplayName62="Block THIS!"
    DisplayName63="Burning Irony"
    DisplayName64="Horzine Fried Crawler"
    DisplayName65="Let Me Carve a Roast"
    DisplayName66="Dot of Doom"
    DisplayName67="I Need DOSH!"
    DisplayName68="Welcome to ScrN Balance!"
    DisplayName69="Medic of Doom"
    DisplayName70="+25 Clot kills"
    DisplayName71="I said get off my Lawn!"
    DisplayName72="Accuracy"
    DisplayName73="Steampunk Sniper"
    DisplayName74="Melee God"
    DisplayName75="Weird but usefull"
    DisplayName76="Impressive"
    DisplayName77="Grim Reaper"
    DisplayName78="Mind-Blowing Sacrifice"
    DisplayName79="Premature Detonation"
    DisplayName80="Hitboxes Are Overrated"
    DisplayName81="Bitter Irony"
    DisplayName82="Balls of Steel"
    DisplayName83="Out of the Gum"
    DisplayName84="Good Defence Is NOT a Good Offence"
    DisplayName85="I Love Rocket Blow"
    DisplayName86="Saving Resources"
    DisplayName87="Gunslingophobia"
    DisplayName88="Old Gangster"
    DisplayName89="TeamWork: Hold On, The Big One! Take a Present."
    DisplayName90="TeamWork: Taking From Behind"
    DisplayName91="There is no I in the TEAM"
    DisplayName92="We Don't Give a **** About The Radial Attack"
    DisplayName93="Peashooters"
    DisplayName94="Hunting the Prey"
    DisplayName95="Perfect Wave"
    DisplayName96="Perfect Game"
    DisplayName97="Speedrun Bronze"
    DisplayName98="Speedrun Silver"
    DisplayName99="Speedrun Gold"
    DisplayName100="Acute Case of Fecalphilia"
    DisplayName101="Self-Criticism Approved"
    DisplayName102="You Guys Suck"
    DisplayName103="Conductor of the Poop Train"
    DisplayName104="KillWhore"
    DisplayName105="Come at Me, Bro!"
    DisplayName106="Friday the 13th"
    DisplayName107="Clot Hater"
    DisplayName108="Made in China"
    DisplayName109="Fast Vengeance"
    DisplayName110="Overkill vol.1"
    DisplayName111="Overkill vol.2"
    DisplayName112="Overkill vol.3"
    DisplayName113="Savings For a Luxury Funeral"
    DisplayName114="All Your Cookies Belong To Me"
    DisplayName115="Eye for an Eye"
    DisplayName116="Milking Cow"
    DisplayName117="Spare Change for Homeless"
    DisplayName118="Want Dosh? Sell THIS!"
    DisplayName119="I Can Smell Ghosts"
    DisplayName120="Ghostbuster"
    DisplayName121="Tesla Bomber"
    DisplayName122="Nikola Tesla and You"
    DisplayName123="Chain Reaction"
    DisplayName124="TSC Tournament Member"
    DisplayName125="'Consider this a warning'"
    DisplayName126="'Aimbot detected'"
    DisplayName127="Achievement Reset"
    DisplayName128="My Kung Fu is Awesome"
    DisplayName129="Two Bloody Handsome"
    DisplayName130="Pro-Nailer"
    DisplayName131="Hitboxes Are TOTALLY Overrated"
    DisplayName132="SkullCrackers"
    DisplayName133="Is Medic OP?"
    DisplayName134="Is Support OP?"
    DisplayName135="Is Sharpshooter OP?"
    DisplayName136="Is Commando OP?"
    DisplayName137="Is Berserker OP?"
    DisplayName138="Is Firebug OP?"
    DisplayName139="Is Demo OP?"
    DisplayName140="Is Gunslinger OP?"
    DisplayName141="Machete Master"
    DisplayName142="Machete Stuns!"
    DisplayName143="Machete Marathon"
    DisplayName144="Evil Dead Combo"

    Description0="Survive on %c community-made maps"
    Description1="Survive on %c community-made maps"
    Description2="Survive on %c community-made maps"
    Description3="Survive on %c community-made maps in any ScrN Balance game"
    Description4="Survive on %c community-made maps against Super/Custom specimens and Hardcore Level 5+"
    Description5="Survive on %c community-made maps in Turbo/Nightmare/SocIso/Custom game and HL 10+"
    Description6="Survive on %c community-made maps in FTG/XCM/Nightmare/Doom3 game and HL 15+"
    Description7="Defeat the Hard or Super Patriarch"
    Description8="Kill the Patriarch when everyone is ONLY using Crossbows"
    Description9="Kill the Patriarch when everyone is ONLY using M99"
    Description10="Complete %c waves when the rest of your team has died (3+ players)"
    Description11="Having one of you dying almost every wave (5+ waves)"
    Description12="Survive a game from beginning till the end without changing your perk"
    Description13="Survive 6+ player game having 1 player per perk"
    Description14="Unlock Gold Medal for ALL perks"
    Description15="Unlock Green Perk Medal"
    Description16="Unlock Blue Perk Medal"
    Description17="Unlock Purple Perk Medal"
    Description18="Unlock Orange Perk Medal"
    Description19="Kill 1,000 Specimens"
    Description20="Kill 10,000 Specimens"
    Description21="Kill 100,000 Specimens"
    Description22="Kill 15 Fleshpounds with an Axe"
    Description23="Detonate grenade in your hands, killing at least 5 zeds with it"
    Description24="Kill %c Scrakes with Sharpshooter's weapons"
    Description25="Kill 100 Big Zeds with L.A.W."
    Description26="Stun&Kill 100 Husks before they hurt anyone"
    Description27="Kill 20 specimens with a single napalm blow"
    Description28="Kill 4 specimens with a single shot of a Handcannon"
    Description29="Kill 12 specimens with Magnum .44 without reloading"
    Description30="Kills 12 specimens with headshots from MK23 without reloading"
    Description31="Kill %c Brutes with Crossbow or M99 without taking a damage"
    Description32="Kill %c Brutes with M14 without taking a damage"
    Description33="Kill %c Brutes with SCAR/FNFAL without taking a damage"
    Description34="Kill %c Fleshpounds with explosives"
    Description35="Nail %c alive zeds to walls"
    Description36="Push %c zeds at least 100m away with Nailgun"
    Description37="Push back headless Shiver with Nailgun"
    Description38="Spend an entire wave in Cowboy Mode"
    Description39="Kill 8 zeds with Machine Pistols without releasing a trigger"
    Description40="Kill 40 zeds in one wave with M4-203 SE"
    Description41="Kill %c Raged Scrakes with M99 headshots (Sui+)"
    Description42="Heal 4 players with one medic grenade"
    Description43="Reach 300dps incremental Damage over Time (iDoT) with flares"
    Description44="Solo-kill 6p HoE Fleshpound"
    Description45="Finish %c LAW-stunned Scrakes with Hunting or Combat Shotgun"
    Description46="Kill %c Scrakes with two simultaneous Crossbow/M99 headshots"
    Description47="Kill %c Sirens with Pistols + Assault Rifles"
    Description48="Decapitate %c burning Shivers with Assault Rifles"
    Description49="Finish %c stunned Husks with Shotguns"
    Description50="Headshot-kill %c Fleshpounds by 2+ Sharpshooters"
    Description51="Rage %c Fleshpounds directly on a pipebomb with Crossbow/M99"
    Description52="Rage %c stunned Scrakes with hand grenades"
    Description53="Kill %c naded Scrakes with sniper weapons, before they do any damage to your retarded teammates."
    Description54="Make %c heals, saving player from a death"
    Description55="Be the only healing person in 3+player team for %c waves (200+hp)"
    Description56="Heal %c players and kill their enemies too"
    Description57="Melee-kill %c Crawlers without taking a damage"
    Description58="Melee-hit %c zeds from behind"
    Description59="Decapitate %c Bloats with melee weapons without getting puked"
    Description60="Kill 40 zeds in a wave with Boomstick and Chainsaw (10+ kills each). Do not use any other weapons!"
    Description61="Shoot a Crawler in the head with M99"
    Description62="Kill %c Brutes with explosive damage"
    Description63="Kill %c Husks with Husk Cannon"
    Description64="Recipe: Burn %c Crawlers at temp. below 80C until they die."
    Description65="Kill %c crispified zeds with melee weapons."
    Description66="Get 25 headshots in a row with the M14EBR."
    Description67="Start a wave having 10,000 pounds of cash"
    Description68="Welcome to the ScrN Total Game Balance Community! Enjoy the best modification for Killing Floor!"
    Description69="Kill 15 zeds with M4-203M Medic Rifle without reloading."
    Description70="Kill 25 clots having less than 4 seconds between subsequent kills."
    Description71="Kill %c Fleshpounds with the Boomstick or Combat Shotgun."
    Description72="Finish %c waves with 75% headshot accuracy. At least 30 decapitations required per wave."
    Description73="Score 10 headshots in a row with Musket. Do it %c times."
    Description74="Kill %c Scrakes with only head-hits from melee weapons. Buzzsaw Bow excluding."
    Description75="Kill %c Scrakes with the Husk Gun."
    Description76="Score 5 headshots in a row %c times."
    Description77="Kill %c zeds with Scythe."
    Description78="Kill %c Fleshpounds by blocking them on own pipes."
    Description79="Kill %c zeds with undetonated grenades or rockets."
    Description80="Kill %c big zeds without landing any headshot and taking damage."
    Description81="Kill %c Scrakes with a Chainsaw."
    Description82="Survive an entire game without wearing heavy armor, damage resistance and dying."
    Description83="Kill 30 specimens with bullets, having less than 5 seconds between subsequent kills."
    Description84="Survive %c times after taking a heavy damage, thanks to wearing a Horzine Armor."
    Description85="Kill 10 specimens with a single rocket blow. Liked it? Then do it %c times."
    Description86="Save %c pipebombs from Bloats or Sirens."
    Description87="One-shot kill %c Crawlers with pistols."
    Description88="Kill 5 zeds without releasing the trigger of your Tommy Gun (drum mag.)"
    Description89="Block %c  big zeds on pipebombs without taking significant damage."
    Description90="Attract %c Scrakes on yourself, allowing teammate to backstab him."
    Description91="Finish the wave, where all (3+) players have almost the same kill count (+/-10%)."
    Description92="Kill Patriarch with melee weapons only."
    Description93="Kill End Game Boss with 9mm pistols only."
    Description94="Hunt the Patriarch during his heal-runs and kill him in 2:00 without focusing on other specimens."
    Description95="Survive %c waves without anybody taking a damage. Wave 1 excluding."
    Description96="Survive 2+ player game without a single player death."
    Description97="Win a long game in 45 minutes. Map should have at least 3 traders."
    Description98="Win a long game in 40 minutes. Map should have at least 3 traders."
    Description99="Win a long game in 33 minutes. Map should have at least 3 traders."
    Description100="Blame 55 things. Make a good reason for doing that."
    Description101="Blame yourself. Make a good reason for doing that."
    Description102="Blame your team. Make a good reason for doing that."
    Description103="Get blamed 5 times in one game."
    Description104="Get 2.5x more kills than any other player in your team (3+p)."
    Description105="Kill a Jason with a Machete."
    Description106="Survive the wave after 2 of your teammates got killed by Jason Voorhees."
    Description107="Kill 15 Clots in a row. Do it %c times. Cuz you really hate them."
    Description108="Get blown up by your own Pipebomb."
    Description109="Kill a zed within 5 seconds of it killed a teammate."
    Description110="Kill a Crawler with a headshot from fully-charged Husk Gun."
    Description111="Kill a Crawler with a headshot from undetonated rocket."
    Description112="Blow up your own pipe, which kills only a single Crawler."
    Description113="Your teammate was greedy. He had a lot of money to share but he'd choosen to save... for the own funeral."
    Description114="Kill %c zeds with weapons picked up from dead player corpses."
    Description115="Kill a specimen, who killed your teamate, with a weapon, picked up from his body."
    Description116="Spare $2000 cash with your teammates without receiving it back."
    Description117="Spare $1 with your poor teammate, who has at least 10x less money than you (including donations)."
    Description118="Blame a player who is begging for money."
    Description119="Decapitate %c Ghosts with Sharpshooter's weapons from 20+ meters"
    Description120="As Commando, kill %c Stalkers or Ghosts within detection range without taking a damage."
    Description121="Kill %c ZEDs with Tesla Husks's self-destruct explosion."
    Description122="Kill %c Tesla Husks with close-combat weapons (melee or shotguns). But take some electrical damage before!"
    Description123="Get connected to 2 other players with Tesla Beams"
    Description124="Participate in TSC Tournement and get into the Playoffs"
    Description125="Kill a Husk with Crossbow in 2 seconds after killing another zed with Handcannon"
    Description126="Survive Wave 10 with at least 10% headshot accuracy"
    Description127="Reset your achievements (all but maps) by executing 'AchReset' console command."
    Description128="Melee-hit %c Crawlers in midair without taking damage"
    Description129="Kill %c Scrakes with Dual HC/.44 without taking damage"
    Description130="Decapitate zed with nail ricochet"
    Description131="Survive 2+player game without scoring any headshot"
    Description132="Survive 2+player game by only using weapons that are capable of doing headshots (no nades, fire, etc.)"
    Description133="Survive 3+player game where everybody is playing Medic"
    Description134="Survive 3+player game where everybody is playing Support"
    Description135="Survive 3+player game where everybody is playing Sharpshooter"
    Description136="Survive 3+player game where everybody is playing Commando"
    Description137="Survive 3+player game where everybody is playing Berserker"
    Description138="Survive 3+player game where everybody is playing Firebug"
    Description139="Survive 3+player game where everybody is playing Demolition"
    Description140="Survive 3+player game where everybody is playing Gunslinger"
    Description141="Use Machete to melee-kill Crawler in midair without taking damage"
    Description142="Stun Scrake with Machete"
    Description143="Perform 'Machete-sprint': drop/pickup Machete 422 times while running in a single game"
    Description144="Solo-kill %c Scrakes with Chainsaw+Boomstick without taking damage"
}
