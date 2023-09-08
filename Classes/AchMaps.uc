// shorted class name - less bytes needs to send as custom stat
Class AchMaps extends ScrnMapAchievements;

#exec OBJ LOAD FILE=ScrnAch_T.utx

// The engine limits the size of a localized string to 4096.
// That's why we need to do the copy-paste crap below to bypass the limitaion.
var localized string DisplayName0;
var localized string DisplayName1;
var localized string DisplayName2;
var localized string DisplayName3;
var localized string DisplayName4;
var localized string DisplayName5;
var localized string DisplayName6;
var localized string DisplayName7;
var localized string DisplayName8;
var localized string DisplayName9;
var localized string DisplayName10;
var localized string DisplayName11;
var localized string DisplayName12;
var localized string DisplayName13;
var localized string DisplayName14;
var localized string DisplayName15;
var localized string DisplayName16;
var localized string DisplayName17;
var localized string DisplayName18;
var localized string DisplayName19;
var localized string DisplayName20;
var localized string DisplayName21;
var localized string DisplayName22;
var localized string DisplayName23;
var localized string DisplayName24;
var localized string DisplayName25;
var localized string DisplayName26;
var localized string DisplayName27;
var localized string DisplayName28;
var localized string DisplayName29;
var localized string DisplayName30;
var localized string DisplayName31;
var localized string DisplayName32;
var localized string DisplayName33;
var localized string DisplayName34;
var localized string DisplayName35;
var localized string DisplayName36;
var localized string DisplayName37;
var localized string DisplayName38;
var localized string DisplayName39;
var localized string DisplayName40;
var localized string DisplayName41;
var localized string DisplayName42;
var localized string DisplayName43;
var localized string DisplayName44;
var localized string DisplayName45;
var localized string DisplayName46;
var localized string DisplayName47;
var localized string DisplayName48;
var localized string DisplayName49;
var localized string DisplayName50;
var localized string DisplayName51;
var localized string DisplayName52;
var localized string DisplayName53;
var localized string DisplayName54;
var localized string DisplayName55;
var localized string DisplayName56;
var localized string DisplayName57;
var localized string DisplayName58;
var localized string DisplayName59;
var localized string DisplayName60;
var localized string DisplayName61;
var localized string DisplayName62;
var localized string DisplayName63;
var localized string DisplayName64;
var localized string DisplayName65;
var localized string DisplayName66;
var localized string DisplayName67;
var localized string DisplayName68;
var localized string DisplayName69;
var localized string DisplayName70;
var localized string DisplayName71;
var localized string DisplayName72;
var localized string DisplayName73;
var localized string DisplayName74;
var localized string DisplayName75;
var localized string DisplayName76;
var localized string DisplayName77;
var localized string DisplayName78;
var localized string DisplayName79;
var localized string DisplayName80;
var localized string DisplayName81;
var localized string DisplayName82;
var localized string DisplayName83;
var localized string DisplayName84;
var localized string DisplayName85;
var localized string DisplayName86;
var localized string DisplayName87;
var localized string DisplayName88;
var localized string DisplayName89;
var localized string DisplayName90;
var localized string DisplayName91;
var localized string DisplayName92;
var localized string DisplayName93;
var localized string DisplayName94;
var localized string DisplayName95;
var localized string DisplayName96;
var localized string DisplayName97;
var localized string DisplayName98;
var localized string DisplayName99;
var localized string DisplayName100;
var localized string DisplayName101;
var localized string DisplayName102;
var localized string DisplayName103;
var localized string DisplayName104;
var localized string DisplayName105;
var localized string DisplayName106;
var localized string DisplayName107;
var localized string DisplayName108;
var localized string DisplayName109;
var localized string DisplayName110;
var localized string DisplayName111;
var localized string DisplayName112;
var localized string DisplayName113;
var localized string DisplayName114;
var localized string DisplayName115;
var localized string DisplayName116;
var localized string DisplayName117;
var localized string DisplayName118;
var localized string DisplayName119;
var localized string DisplayName120;
var localized string DisplayName121;
var localized string DisplayName122;
var localized string DisplayName123;
var localized string DisplayName124;
var localized string DisplayName125;
var localized string DisplayName126;
var localized string DisplayName127;
var localized string DisplayName128;
var localized string DisplayName129;
var localized string DisplayName130;
var localized string DisplayName131;
var localized string DisplayName132;
var localized string DisplayName133;
var localized string DisplayName134;
var localized string DisplayName135;
var localized string DisplayName136;
var localized string DisplayName137;
var localized string DisplayName138;
var localized string DisplayName139;
var localized string DisplayName140;
var localized string DisplayName141;
var localized string DisplayName142;
var localized string DisplayName143;
var localized string DisplayName144;
var localized string DisplayName145;
var localized string DisplayName146;
var localized string DisplayName147;
var localized string DisplayName148;
var localized string DisplayName149;
var localized string DisplayName150;
var localized string DisplayName151;
var localized string DisplayName152;
var localized string DisplayName153;
var localized string DisplayName154;
var localized string DisplayName155;
var localized string DisplayName156;
var localized string DisplayName157;
var localized string DisplayName158;
var localized string DisplayName159;
var localized string DisplayName160;
var localized string DisplayName161;
var localized string DisplayName162;
var localized string DisplayName163;
var localized string DisplayName164;
var localized string DisplayName165;
var localized string DisplayName166;
var localized string DisplayName167;
var localized string DisplayName168;
var localized string DisplayName169;
var localized string DisplayName170;
var localized string DisplayName171;
var localized string DisplayName172;
var localized string DisplayName173;
var localized string DisplayName174;
var localized string DisplayName175;
var localized string DisplayName176;
var localized string DisplayName177;
var localized string DisplayName178;
var localized string DisplayName179;
var localized string DisplayName180;
var localized string DisplayName181;
var localized string DisplayName182;
var localized string DisplayName183;
var localized string DisplayName184;
var localized string DisplayName185;
var localized string DisplayName186;
var localized string DisplayName187;
var localized string DisplayName188;
var localized string DisplayName189;
var localized string DisplayName190;
var localized string DisplayName191;
var localized string DisplayName192;
var localized string DisplayName193;
var localized string DisplayName194;
var localized string DisplayName195;
var localized string DisplayName196;
var localized string DisplayName197;
var localized string DisplayName198;
var localized string DisplayName199;
var localized string DisplayName200;
var localized string DisplayName201;
var localized string DisplayName202;
var localized string DisplayName203;
var localized string DisplayName204;
var localized string DisplayName205;
var localized string DisplayName206;
var localized string DisplayName207;
var localized string DisplayName208;
var localized string DisplayName209;
var localized string DisplayName210;
var localized string DisplayName211;
var localized string DisplayName212;
var localized string DisplayName213;
var localized string DisplayName214;
var localized string DisplayName215;


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
    AchDefs[145].DisplayName = DisplayName145;
    AchDefs[146].DisplayName = DisplayName146;
    AchDefs[147].DisplayName = DisplayName147;
    AchDefs[148].DisplayName = DisplayName148;
    AchDefs[149].DisplayName = DisplayName149;
    AchDefs[150].DisplayName = DisplayName150;
    AchDefs[151].DisplayName = DisplayName151;
    AchDefs[152].DisplayName = DisplayName152;
    AchDefs[153].DisplayName = DisplayName153;
    AchDefs[154].DisplayName = DisplayName154;
    AchDefs[155].DisplayName = DisplayName155;
    AchDefs[156].DisplayName = DisplayName156;
    AchDefs[157].DisplayName = DisplayName157;
    AchDefs[158].DisplayName = DisplayName158;
    AchDefs[159].DisplayName = DisplayName159;
    AchDefs[160].DisplayName = DisplayName160;
    AchDefs[161].DisplayName = DisplayName161;
    AchDefs[162].DisplayName = DisplayName162;
    AchDefs[163].DisplayName = DisplayName163;
    AchDefs[164].DisplayName = DisplayName164;
    AchDefs[165].DisplayName = DisplayName165;
    AchDefs[166].DisplayName = DisplayName166;
    AchDefs[167].DisplayName = DisplayName167;
    AchDefs[168].DisplayName = DisplayName168;
    AchDefs[169].DisplayName = DisplayName169;
    AchDefs[170].DisplayName = DisplayName170;
    AchDefs[171].DisplayName = DisplayName171;
    AchDefs[172].DisplayName = DisplayName172;
    AchDefs[173].DisplayName = DisplayName173;
    AchDefs[174].DisplayName = DisplayName174;
    AchDefs[175].DisplayName = DisplayName175;
    AchDefs[176].DisplayName = DisplayName176;
    AchDefs[177].DisplayName = DisplayName177;
    AchDefs[178].DisplayName = DisplayName178;
    AchDefs[179].DisplayName = DisplayName179;
    AchDefs[180].DisplayName = DisplayName180;
    AchDefs[181].DisplayName = DisplayName181;
    AchDefs[182].DisplayName = DisplayName182;
    AchDefs[183].DisplayName = DisplayName183;
    AchDefs[184].DisplayName = DisplayName184;
    AchDefs[185].DisplayName = DisplayName185;
    AchDefs[186].DisplayName = DisplayName186;
    AchDefs[187].DisplayName = DisplayName187;
    AchDefs[188].DisplayName = DisplayName188;
    AchDefs[189].DisplayName = DisplayName189;
    AchDefs[190].DisplayName = DisplayName190;
    AchDefs[191].DisplayName = DisplayName191;
    AchDefs[192].DisplayName = DisplayName192;
    AchDefs[193].DisplayName = DisplayName193;
    AchDefs[194].DisplayName = DisplayName194;
    AchDefs[195].DisplayName = DisplayName195;
    AchDefs[196].DisplayName = DisplayName196;
    AchDefs[197].DisplayName = DisplayName197;
    AchDefs[198].DisplayName = DisplayName198;
    AchDefs[199].DisplayName = DisplayName199;
    AchDefs[200].DisplayName = DisplayName200;
    AchDefs[201].DisplayName = DisplayName201;
    AchDefs[202].DisplayName = DisplayName202;
    AchDefs[203].DisplayName = DisplayName203;
    AchDefs[204].DisplayName = DisplayName204;
    AchDefs[205].DisplayName = DisplayName205;
    AchDefs[206].DisplayName = DisplayName206;
    AchDefs[207].DisplayName = DisplayName207;
    AchDefs[208].DisplayName = DisplayName208;
    AchDefs[209].DisplayName = DisplayName209;
    AchDefs[210].DisplayName = DisplayName210;
    AchDefs[211].DisplayName = DisplayName211;
    AchDefs[212].DisplayName = DisplayName212;
    AchDefs[213].DisplayName = DisplayName213;
    AchDefs[214].DisplayName = DisplayName214;
    AchDefs[215].DisplayName = DisplayName215;

    super.SetDefaultAchievementData();
}


defaultproperties
{
     ProgressName="Map Achievements"

     AchDefs(0)=(id="KF-WestLondon",DisplayName="Pub Crawl",Description="West London",Icon=Texture'KillingFloorHUD.Achievements.Achievement_0')
     AchDefs(1)=(id="KF-WestLondonHard",DisplayName="Hard Pub Crawl",Description="West London",Icon=Texture'KillingFloorHUD.Achievements.Achievement_6')
     AchDefs(2)=(id="KF-WestLondonSui",DisplayName="Suicidal Pub Crawl",Description="West London",Icon=Texture'KillingFloorHUD.Achievements.Achievement_12')
     AchDefs(3)=(id="KF-WestLondonHoe",DisplayName="Hellish Pub Crawl",Description="West London",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_65')
     AchDefs(4)=(id="KF-Manor",DisplayName="Lord of the Manor",Description="Manor",Icon=Texture'KillingFloorHUD.Achievements.Achievement_1')
     AchDefs(5)=(id="KF-ManorHard",DisplayName="Duke of the Manor",Description="Manor",Icon=Texture'KillingFloorHUD.Achievements.Achievement_7')
     AchDefs(6)=(id="KF-ManorSui",DisplayName="Emperor of the Manor",Description="Manor",Icon=Texture'KillingFloorHUD.Achievements.Achievement_13')
     AchDefs(7)=(id="KF-ManorHoe",DisplayName="Demonic King of the Manor",Description="Manor",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_66')
     AchDefs(8)=(id="KF-Farm",DisplayName="Chicken Farmer",Description="Farm",Icon=Texture'KillingFloorHUD.Achievements.Achievement_2')
     AchDefs(9)=(id="KF-FarmHard",DisplayName="Cattle Farmer",Description="Farm",Icon=Texture'KillingFloorHUD.Achievements.Achievement_8')
     AchDefs(10)=(id="KF-FarmSui",DisplayName="Alligator Farmer",Description="Farm",Icon=Texture'KillingFloorHUD.Achievements.Achievement_14')
     AchDefs(11)=(id="KF-FarmHoe",DisplayName="Demon Farmer",Description="Farm",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_67')
     AchDefs(12)=(id="KF-Offices",DisplayName="The Boss",Description="Offices",Icon=Texture'KillingFloorHUD.Achievements.Achievement_3')
     AchDefs(13)=(id="KF-OfficesHard",DisplayName="Hard Boss",Description="Offices",Icon=Texture'KillingFloorHUD.Achievements.Achievement_9')
     AchDefs(14)=(id="KF-OfficesSui",DisplayName="Mad Boss",Description="Offices",Icon=Texture'KillingFloorHUD.Achievements.Achievement_15')
     AchDefs(15)=(id="KF-OfficesHoe",DisplayName="Boss from Hell",Description="Offices",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_68')
     AchDefs(16)=(id="KF-BioticsLab",DisplayName="Lab Cleaner",Description="Biotics Lab",Icon=Texture'KillingFloorHUD.Achievements.Achievement_4')
     AchDefs(17)=(id="KF-BioticsLabHard",DisplayName="Lab Assistant",Description="Biotics Lab",Icon=Texture'KillingFloorHUD.Achievements.Achievement_10')
     AchDefs(18)=(id="KF-BioticsLabSui",DisplayName="Lab Professor",Description="Biotics Lab",Icon=Texture'KillingFloorHUD.Achievements.Achievement_16')
     AchDefs(19)=(id="KF-BioticsLabHoe",DisplayName="Scientist from Hell",Description="Biotics Lab",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_69')
     AchDefs(20)=(id="KF-Foundry",DisplayName="Tin Man",Description="Foundry",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_44')
     AchDefs(21)=(id="KF-FoundryHard",DisplayName="Steel Worker",Description="Foundry",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_45')
     AchDefs(22)=(id="KF-FoundrySui",DisplayName="Man of Steel",Description="Foundry",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_46')
     AchDefs(23)=(id="KF-FoundryHoe",DisplayName="Diablo Steel Man",Description="Foundry",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_70')
     AchDefs(24)=(id="KF-Bedlam",DisplayName="A Bit Barmy",Description="Bedlam",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_47')
     AchDefs(25)=(id="KF-BedlamHard",DisplayName="Gone Mental",Description="Bedlam",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_48')
     AchDefs(26)=(id="KF-BedlamSui",DisplayName="Complete Barking",Description="Bedlam",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_49')
     AchDefs(27)=(id="KF-BedlamHoe",DisplayName="Commit-ed for life",Description="Bedlam",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_71')
     AchDefs(28)=(id="KF-Wyre",DisplayName="Squirrel King of the Dark Forest",Description="Wyre",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_50')
     AchDefs(29)=(id="KF-WyreHard",DisplayName="Raccoon King of the Dark Forest",Description="Wyre",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_51')
     AchDefs(30)=(id="KF-WyreSui",DisplayName="Bear King of the Dark Forest",Description="Wyre",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_52')
     AchDefs(31)=(id="KF-WyreHoe",DisplayName="Wolf King of the Dark Forest",Description="Wyre",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_72')
     AchDefs(32)=(id="KF-Biohazard",DisplayName="Waste Disposal",Description="Biohazard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_73')
     AchDefs(33)=(id="KF-BiohazardHard",DisplayName="Waste Land",Description="Biohazard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_74')
     AchDefs(34)=(id="KF-BiohazardSui",DisplayName="Waste of Space",Description="Biohazard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_75')
     AchDefs(35)=(id="KF-BiohazardHoe",DisplayName="Wasted",Description="Biohazard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_76')
     AchDefs(36)=(id="KF-Crash",DisplayName="Warehouse Janitor",Description="Crash",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_77')
     AchDefs(37)=(id="KF-CrashHard",DisplayName="Warehouse Forklift Operator",Description="Crash",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_78')
     AchDefs(38)=(id="KF-CrashSui",DisplayName="Warehouse Foreman",Description="Crash",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_79')
     AchDefs(39)=(id="KF-CrashHoe",DisplayName="Warehouse Manager",Description="Crash",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_80')
     AchDefs(40)=(id="KF-Departed",DisplayName="Departure Gallery",Description="Departed",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_81')
     AchDefs(41)=(id="KF-DepartedHard",DisplayName="Departure Lounge",Description="Departed",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_82')
     AchDefs(42)=(id="KF-DepartedSui",DisplayName="Departure Gate",Description="Departed",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_83')
     AchDefs(43)=(id="KF-DepartedHoe",DisplayName="Dear Departed",Description="Departed",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_84')
     AchDefs(44)=(id="KF-FilthsCross",DisplayName="Running Late",Description="Filths Cross",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_85')
     AchDefs(45)=(id="KF-FilthsCrossHard",DisplayName="Missed Connection",Description="Filths Cross",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_86')
     AchDefs(46)=(id="KF-FilthsCrossSui",DisplayName="Train Wreck",Description="Filths Cross",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_87')
     AchDefs(47)=(id="KF-FilthsCrossHoe",DisplayName="Pile Up",Description="Filths Cross",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_88')
     AchDefs(48)=(id="KF-HospitalHorrors",DisplayName="Gimme a Plaster!",Description="Hospital Horrors",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_89')
     AchDefs(49)=(id="KF-HospitalHorrorsHard",DisplayName="That Bloody Well Hurts!",Description="Hospital Horrors",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_90')
     AchDefs(50)=(id="KF-HospitalHorrorsSui",DisplayName="I'm Dying Here!",Description="Hospital Horrors",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_91')
     AchDefs(51)=(id="KF-HospitalHorrorsHoe",DisplayName="Not Dead Yet!",Description="Hospital Horrors",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_92')
     AchDefs(52)=(id="KF-Icebreaker",DisplayName="Ice Cube",Description="Icebreaker",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_93')
     AchDefs(53)=(id="KF-IcebreakerHard",DisplayName="Crushed Ice",Description="Icebreaker",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_94')
     AchDefs(54)=(id="KF-IcebreakerSui",DisplayName="Iceberg",Description="Icebreaker",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_95')
     AchDefs(55)=(id="KF-IcebreakerHoe",DisplayName="Comet",Description="Icebreaker",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_96')
     AchDefs(56)=(id="KF-MountainPass",DisplayName="Daytrip",Description="Mountain Pass",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_97')
     AchDefs(57)=(id="KF-MountainPassHard",DisplayName="Gone Camping",Description="Mountain Pass",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_98')
     AchDefs(58)=(id="KF-MountainPassSui",DisplayName="Mountaineer",Description="Mountain Pass",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_99')
     AchDefs(59)=(id="KF-MountainPassHoe",DisplayName="Park Ranger",Description="Mountain Pass",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_100')
     AchDefs(60)=(id="KF-Suburbia",DisplayName="Park Ranger",Description="Suburbia",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_101')
     AchDefs(61)=(id="KF-SuburbiaHard",DisplayName="Private Security",Description="Suburbia",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_102')
     AchDefs(62)=(id="KF-SuburbiaSui",DisplayName="Vigilante",Description="Suburbia",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_103')
     AchDefs(63)=(id="KF-SuburbiaHoe",DisplayName="SWAT",Description="Suburbia",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_104')
     AchDefs(64)=(id="KF-Waterworks",DisplayName="Slight Drip",Description="Waterworks",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_105')
     AchDefs(65)=(id="KF-WaterworksHard",DisplayName="Burst Pipe",Description="Waterworks",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_106')
     AchDefs(66)=(id="KF-WaterworksSui",DisplayName="Pressure Failure",Description="Waterworks",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_107')
     AchDefs(67)=(id="KF-WaterworksHoe",DisplayName="Floodgate to Hell",Description="Waterworks",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_108')
     AchDefs(68)=(id="KF-EvilSantasLair",DisplayName="Walking in A Winter Horror Land",Description="EvilSantasLair",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_114')
     AchDefs(69)=(id="KF-EvilSantasLairHard",DisplayName="Silent Night, Evil Night",Description="EvilSantasLair",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_115')
     AchDefs(70)=(id="KF-EvilSantasLairSui",DisplayName="I'm Dreaming of a Red Christmas",Description="EvilSantasLair",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_116')
     AchDefs(71)=(id="KF-EvilSantasLairHoe",DisplayName="Grandma got Eaten by a Reindeer",Description="EvilSantasLair",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_117')
     AchDefs(72)=(id="KF-Aperture",DisplayName="Science Got Done",Description="Aperture",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_133')
     AchDefs(73)=(id="KF-ApertureHard",DisplayName="Still Alive",Description="Aperture",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_134')
     AchDefs(74)=(id="KF-ApertureSui",DisplayName="This is a Triumph",Description="Aperture",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_135')
     AchDefs(75)=(id="KF-ApertureHoe",DisplayName="I'm Making a Note Here, Huge Success",Description="Aperture",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_136')
     AchDefs(76)=(id="KF-AbusementPark",DisplayName="Flea Circus",Description="Abusement Park",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_138')
     AchDefs(77)=(id="KF-AbusementParkHard",DisplayName="Dog and Pony Show",Description="Abusement Park",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_139')
     AchDefs(78)=(id="KF-AbusementParkSui",DisplayName="3 Ring Circus",Description="Abusement Park",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_140')
     AchDefs(79)=(id="KF-AbusementParkHoe",DisplayName="On Top of the Big Top",Description="Abusement Park",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_141')
     AchDefs(80)=(id="KF-IceCave",DisplayName="Snow Cone",Description="Ice Cave",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_171')
     AchDefs(81)=(id="KF-IceCaveHard",DisplayName="Stay Frosty",Description="Ice Cave",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_172')
     AchDefs(82)=(id="KF-IceCaveSui",DisplayName="On the Rocks",Description="Ice Cave",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_173')
     AchDefs(83)=(id="KF-IceCaveHoe",DisplayName="Anti Freeze",Description="Ice Cave",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_174')
     AchDefs(84)=(id="KF-Hellride",DisplayName="Highway to Heaven",Description="Hellride",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_181')
     AchDefs(85)=(id="KF-HellrideHard",DisplayName="Stuck in Limbo",Description="Hellride",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_182')
     AchDefs(86)=(id="KF-HellrideSui",DisplayName="Demonic Road",Description="Hellride",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_183')
     AchDefs(87)=(id="KF-HellrideHoe",DisplayName="Devil's Co-pilot",Description="Hellride",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_184')
     AchDefs(88)=(id="KF-HillbillyHorror",DisplayName="Third Cousins",Description="Hillbilly Horror",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_97')
     AchDefs(89)=(id="KF-HillbillyHorrorHard",DisplayName="Second Cousins",Description="Hillbilly Horror",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_98')
     AchDefs(90)=(id="KF-HillbillyHorrorSui",DisplayName="First Cousins",Description="Hillbilly Horror",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_99')
     AchDefs(91)=(id="KF-HillbillyHorrorHoe",DisplayName="Zeroth Cousins",Description="Hillbilly Horror",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_100')
     AchDefs(92)=(id="KF-MoonBase",DisplayName="Here is to us",Description="Moon Base",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_204')
     AchDefs(93)=(id="KF-MoonBaseHard",DisplayName="Attempting Re-entry",Description="Moon Base",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_205')
     AchDefs(94)=(id="KF-MoonBaseSui",DisplayName="Amusing Death",Description="Moon Base",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_206')
     AchDefs(95)=(id="KF-MoonBaseHoe",DisplayName="One Giant Leap (Back) for Mankind",Description="Moon Base",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_207')
     AchDefs(96)=(id="KF-Aventine",DisplayName="Lord of Aventive",Description="Aventine",Icon=Texture'ScrnAch_T.Maps.Aventine_0')
     AchDefs(97)=(id="KF-AventineHard",DisplayName="Duke of Aventine",Description="Aventine",Icon=Texture'ScrnAch_T.Maps.Aventine_1')
     AchDefs(98)=(id="KF-AventineSui",DisplayName="Emperor of Aventine",Description="Aventine",Icon=Texture'ScrnAch_T.Maps.Aventine_2')
     AchDefs(99)=(id="KF-AventineHoE",DisplayName="Demonic King of Aventine",Description="Aventine",Icon=Texture'ScrnAch_T.Maps.Aventine_3')
     AchDefs(100)=(id="KF-Constriction",DisplayName="Rats in the Wall",Description="Constriction",Icon=Texture'ScrnAch_T.Maps.Constriction_0')
     AchDefs(101)=(id="KF-ConstrictionHard",DisplayName="Barking Dogs Outside",Description="Constriction",Icon=Texture'ScrnAch_T.Maps.Constriction_1')
     AchDefs(102)=(id="KF-ConstrictionSui",DisplayName="Screaming Maidens",Description="Constriction",Icon=Texture'ScrnAch_T.Maps.Constriction_2')
     AchDefs(103)=(id="KF-ConstrictionHoE",DisplayName="...and the Crazed Lord of the Manor died - again",Description="Constriction",Icon=Texture'ScrnAch_T.Maps.Constriction_3')
     AchDefs(104)=(id="KF-CornerMarket_v3",DisplayName="Barrow Boy",Description="Corner Market",Icon=Texture'ScrnAch_T.Maps.CornerMarket_0')
     AchDefs(105)=(id="KF-CornerMarket_v3Hard",DisplayName="Supermarket Manager",Description="Corner Market",Icon=Texture'ScrnAch_T.Maps.CornerMarket_1')
     AchDefs(106)=(id="KF-CornerMarket_v3Sui",DisplayName="BestBuy's Director",Description="Corner Market",Icon=Texture'ScrnAch_T.Maps.CornerMarket_2')
     AchDefs(107)=(id="KF-CornerMarket_v3HoE",DisplayName="HellBuy's Director",Description="Corner Market",Icon=Texture'ScrnAch_T.Maps.CornerMarket_3')
     AchDefs(108)=(id="KF-Corruption",DisplayName="Bug in the System",Description="Corruption",Icon=Texture'ScrnAch_T.Maps.Corruption_0')
     AchDefs(109)=(id="KF-CorruptionHard",DisplayName="Infected System",Description="Corruption",Icon=Texture'ScrnAch_T.Maps.Corruption_1')
     AchDefs(110)=(id="KF-CorruptionSui",DisplayName="Critical System Failure",Description="Corruption",Icon=Texture'ScrnAch_T.Maps.Corruption_2')
     AchDefs(111)=(id="KF-CorruptionHoE",DisplayName="The Blue Screen",Description="Corruption",Icon=Texture'ScrnAch_T.Maps.Corruption_3')
     AchDefs(112)=(id="KF-HarbourV3",DisplayName="Sailor",Description="Harbour",Icon=Texture'ScrnAch_T.Maps.Harbour_0')
     AchDefs(113)=(id="KF-HarbourV3Hard",DisplayName="Boatswain",Description="Harbour",Icon=Texture'ScrnAch_T.Maps.Harbour_1')
     AchDefs(114)=(id="KF-HarbourV3Sui",DisplayName="Maritime Pilot",Description="Harbour",Icon=Texture'ScrnAch_T.Maps.Harbour_2')
     AchDefs(115)=(id="KF-HarbourV3HoE",DisplayName="Demonic Captain",Description="Harbour",Icon=Texture'ScrnAch_T.Maps.Harbour_3')
     AchDefs(116)=(id="Kf-Hell",DisplayName="Imp",Description="Hell",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_243')
     AchDefs(117)=(id="Kf-HellHard",DisplayName="Mancubus",Description="Hell",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_244')
     AchDefs(118)=(id="Kf-HellSui",DisplayName="Hell Knight",Description="Hell",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_245')
     AchDefs(119)=(id="Kf-HellHoE",DisplayName="Cyberdemon",Description="Hell",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_246')
     AchDefs(120)=(id="KF-HellGate",DisplayName="Knock, knock. Who's there?",Description="Hell Gate",Icon=Texture'ScrnAch_T.Maps.HellGate_0')
     AchDefs(121)=(id="KF-HellGateHard",DisplayName="Gate Keeper",Description="Hell Gate",Icon=Texture'ScrnAch_T.Maps.HellGate_1')
     AchDefs(122)=(id="KF-HellGateSui",DisplayName="Free Sauna Inside",Description="Hell Gate",Icon=Texture'ScrnAch_T.Maps.HellGate_2')
     AchDefs(123)=(id="KF-HellGateHoE",DisplayName="Open up! It's me - Satan.",Description="Hell Gate",Icon=Texture'ScrnAch_T.Maps.HellGate_3')
     AchDefs(124)=(id="KF-OldCity",DisplayName="Survivor of the Deserted City",Description="Old City",Icon=Texture'ScrnAch_T.Maps.OldCity_0')
     AchDefs(125)=(id="KF-OldCityHard",DisplayName="Survivor of the Lost City",Description="Old City",Icon=Texture'ScrnAch_T.Maps.OldCity_1')
     AchDefs(126)=(id="KF-OldCitySui",DisplayName="Survivor of the Dead City",Description="Old City",Icon=Texture'ScrnAch_T.Maps.OldCity_2')
     AchDefs(127)=(id="KF-OldCityHoE",DisplayName="Survivor of the UnDead City",Description="Old City",Icon=Texture'ScrnAch_T.Maps.OldCity_3')
     AchDefs(128)=(id="KF-SilentHill",DisplayName="Silent Hill",Description="Silent Hill",Icon=Texture'ScrnAch_T.Maps.SilentHill_0')
     AchDefs(129)=(id="KF-SilentHillHard",DisplayName="Hard Hill",Description="Silent Hill",Icon=Texture'ScrnAch_T.Maps.SilentHill_1')
     AchDefs(130)=(id="KF-SilentHillSui",DisplayName="Suicidal Hill",Description="Silent Hill",Icon=Texture'ScrnAch_T.Maps.SilentHill_2')
     AchDefs(131)=(id="KF-SilentHillHoE",DisplayName="Otherworld",Description="Silent Hill",Icon=Texture'ScrnAch_T.Maps.SilentHill_3')
     AchDefs(132)=(id="KF-SunnyLandSanitarium",DisplayName="Hallucinations",Description="Sunny Land Sanitarium",Icon=Texture'ScrnAch_T.Maps.SunnyLandSanitarium_0')
     AchDefs(133)=(id="KF-SunnyLandSanitariumHard",DisplayName="Delirium Tremens",Description="Sunny Land Sanitarium",Icon=Texture'ScrnAch_T.Maps.SunnyLandSanitarium_1')
     AchDefs(134)=(id="KF-SunnyLandSanitariumSui",DisplayName="Schizophrenia",Description="Sunny Land Sanitarium",Icon=Texture'ScrnAch_T.Maps.SunnyLandSanitarium_2')
     AchDefs(135)=(id="KF-SunnyLandSanitariumHoE",DisplayName="Diabolical Obsession",Description="Sunny Land Sanitarium",Icon=Texture'ScrnAch_T.Maps.SunnyLandSanitarium_3')
     AchDefs(136)=(id="KF-Swamp",DisplayName="This is My Swamp!",Description="Swamp",Icon=Texture'ScrnAch_T.Maps.Swamp_0')
     AchDefs(137)=(id="KF-SwampHard",DisplayName="Give Me Back My Swamp!",Description="Swamp",Icon=Texture'ScrnAch_T.Maps.Swamp_1')
     AchDefs(138)=(id="KF-SwampSui",DisplayName="I'll Die For My Swamp",Description="Swamp",Icon=Texture'ScrnAch_T.Maps.Swamp_2')
     AchDefs(139)=(id="KF-SwampHoE",DisplayName="Hellish Swamp",Description="Swamp",Icon=Texture'ScrnAch_T.Maps.Swamp_3')
     AchDefs(140)=(id="KF-TheLongDarkRoad",DisplayName="Long, Dark Road",Description="Long Dark Road",Icon=Texture'ScrnAch_T.Maps.LongDarkRoad_0')
     AchDefs(141)=(id="KF-TheLongDarkRoadHard",DisplayName="Long, Hard Road",Description="Long Dark Road",Icon=Texture'ScrnAch_T.Maps.LongDarkRoad_1')
     AchDefs(142)=(id="KF-TheLongDarkRoadSui",DisplayName="Path of the Ahmed",Description="Long Dark Road",Icon=Texture'ScrnAch_T.Maps.LongDarkRoad_2')
     AchDefs(143)=(id="KF-TheLongDarkRoadHoE",DisplayName="Road to Hell",Description="Long Dark Road",Icon=Texture'ScrnAch_T.Maps.LongDarkRoad_3')
     AchDefs(144)=(id="KF-BigSunrise",DisplayName="iPLAY",Description="Big Sunrise",Icon=Texture'ScrnAch_T.Maps.BigSunrise_0')
     AchDefs(145)=(id="KF-BigSunriseHard",DisplayName="iROCK",Description="Big Sunrise",Icon=Texture'ScrnAch_T.Maps.BigSunrise_1')
     AchDefs(146)=(id="KF-BigSunriseSui",DisplayName="iDIE",Description="Big Sunrise",Icon=Texture'ScrnAch_T.Maps.BigSunrise_2')
     AchDefs(147)=(id="KF-BigSunriseHoE",DisplayName="iKILL",Description="Big Sunrise",Icon=Texture'ScrnAch_T.Maps.BigSunrise_3')
     AchDefs(148)=(id="KF-SantasRetreat",DisplayName="Rudolf in the Sky",Description="Santa's Retreat",Icon=Texture'ScrnAch_T.Maps.SantasPad_0')
     AchDefs(149)=(id="KF-SantasRetreatHard",DisplayName="I See Dead Reindeers",Description="Santa's Retreat",Icon=Texture'ScrnAch_T.Maps.SantasPad_1')
     AchDefs(150)=(id="KF-SantasRetreatSui",DisplayName="Rudolf the Suicide Reindeer",Description="Santa's Retreat",Icon=Texture'ScrnAch_T.Maps.SantasPad_2')
     AchDefs(151)=(id="KF-SantasRetreatHoE",DisplayName="Sending Deer to Hell",Description="Santa's Retreat",Icon=Texture'ScrnAch_T.Maps.SantasPad_3')
     AchDefs(152)=(id="KF-ZedDisco",DisplayName="Backing Dancer",Description="ZED Disco",Icon=Texture'ScrnAch_T.Maps.ZedDisco_0')
     AchDefs(153)=(id="KF-ZedDiscoHard",DisplayName="DJ Skully",Description="ZED Disco",Icon=Texture'ScrnAch_T.Maps.ZedDisco_1')
     AchDefs(154)=(id="KF-ZedDiscoSui",DisplayName="King of the Dance Floor",Description="ZED Disco",Icon=Texture'ScrnAch_T.Maps.ZedDisco_2')
     AchDefs(155)=(id="KF-ZedDiscoHoE",DisplayName="Devil Dance",Description="ZED Disco",Icon=Texture'ScrnAch_T.Maps.ZedDisco_3')
     AchDefs(156)=(id="KF-CountyJail",DisplayName="Drunken Farmer Jail",Description="County Jail",Icon=Texture'ScrnAch_T.Maps.CountyJail_0')
     AchDefs(157)=(id="KF-CountyJailHard",DisplayName="Maximum Security Prison",Description="County Jail",Icon=Texture'ScrnAch_T.Maps.CountyJail_1')
     AchDefs(158)=(id="KF-CountyJailSui",DisplayName="Death Row",Description="County Jail",Icon=Texture'ScrnAch_T.Maps.CountyJail_2')
     AchDefs(159)=(id="KF-CountyJailHoE",DisplayName="Prison Break",Description="County Jail",Icon=Texture'ScrnAch_T.Maps.CountyJail_3')
     AchDefs(160)=(id="KF-Steamland",DisplayName="Astro Buffer Afficiando",Description="Steamland",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_209')
     AchDefs(161)=(id="KF-SteamlandHard",DisplayName="Modified Psychoacceleration Achiever",Description="Steamland",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_210')
     AchDefs(162)=(id="KF-SteamlandSui",DisplayName="Fractional Neutron Activator",Description="Steamland",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_211')
     AchDefs(163)=(id="KF-SteamlandHoe",DisplayName="Advanced Omega Wave Resonance Explorer",Description="Steamland",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_212')
     AchDefs(164)=(id="KF-FrightYard",DisplayName="Longshorman",Description="Fright Yard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_228')
     AchDefs(165)=(id="KF-FrightYardHard",DisplayName="Gang Crew",Description="Fright Yard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_229')
     AchDefs(166)=(id="KF-FrightYardSui",DisplayName="Stevedore",Description="Fright Yard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_230')
     AchDefs(167)=(id="KF-FrightYardHoe",DisplayName="Wharfinger",Description="Fright Yard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_231')
     AchDefs(168)=(id="KF-Forgotten",DisplayName="Brain Fart",Description="Forgotten",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_247')
     AchDefs(169)=(id="KF-ForgottenHard",DisplayName="Agnosia",Description="Forgotten",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_248')
     AchDefs(170)=(id="KF-ForgottenSui",DisplayName="Amnesia",Description="Forgotten",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_249')
     AchDefs(171)=(id="KF-ForgottenHoe",DisplayName="Dementia",Description="Forgotten",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_250')
     AchDefs(172)=(id="KF-SirensBelch",DisplayName="Home Brewer",Description="Siren's Belch",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_252')
     AchDefs(173)=(id="KF-SirensBelchHard",DisplayName="Micro Brewer",Description="Siren's Belch",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_253')
     AchDefs(174)=(id="KF-SirensBelchSui",DisplayName="Master Brewer",Description="Siren's Belch",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_254')
     AchDefs(175)=(id="KF-SirensBelchHoe",DisplayName="Trappist Monk",Description="Siren's Belch",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_255')
     AchDefs(176)=(id="KF-Stronghold",DisplayName="Peasant",Description="Stronghold",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_256')
     AchDefs(177)=(id="KF-StrongholdHard",DisplayName="Squire",Description="Stronghold",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_257')
     AchDefs(178)=(id="KF-StrongholdSui",DisplayName="Prince",Description="Stronghold",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_258')
     AchDefs(179)=(id="KF-StrongholdHoe",DisplayName="King",Description="Stronghold",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_259')
     AchDefs(180)=(id="KF-Transit",DisplayName="Cattle Class",Description="Transit",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_260')
     AchDefs(181)=(id="KF-TransitHard",DisplayName="Economy Comfort",Description="Transit",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_261')
     AchDefs(182)=(id="KF-TransitSui",DisplayName="Business Class",Description="Transit",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_262')
     AchDefs(183)=(id="KF-TransitHoe",DisplayName="First Class",Description="Transit",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_263')
     AchDefs(184)=(id="KF-Clandestine",DisplayName="Gone clubbing",Description="Clandestine",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_275')
     AchDefs(185)=(id="KF-ClandestineHard",DisplayName="Rack 'em up",Description="Clandestine",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_276')
     AchDefs(186)=(id="KF-ClandestineSui",DisplayName="Burned out",Description="Clandestine",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_277')
     AchDefs(187)=(id="KF-ClandestineHoe",DisplayName="Hangover from Hell",Description="Clandestine",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_278')
     AchDefs(188)=(id="KF-ThrillsChills",DisplayName="Cave of Wonder",Description="Thrills Chills",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_280')
     AchDefs(189)=(id="KF-ThrillsChillsHard",DisplayName="Cavern of Pain",Description="Thrills Chills",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_281')
     AchDefs(190)=(id="KF-ThrillsChillsSui",DisplayName="Grotto of Terror",Description="Thrills Chills",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_282')
     AchDefs(191)=(id="KF-ThrillsChillsHoe",DisplayName="Hollow of Horror",Description="Thrills Chills",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_283')
     AchDefs(192)=(id="KF-TheGreatPyramid-Arena",DisplayName="The First Encounter",Description="Great Pyramid",Icon=Texture'ScrnAch_T.Maps.Pyramid_0')
     AchDefs(193)=(id="KF-TheGreatPyramid-ArenaHard",DisplayName="The First Encounter: HD",Description="Great Pyramid",Icon=Texture'ScrnAch_T.Maps.Pyramid_1')
     AchDefs(194)=(id="KF-TheGreatPyramid-ArenaSui",DisplayName="Are You SERIOUS?",Description="Great Pyramid",Icon=Texture'ScrnAch_T.Maps.Pyramid_2')
     AchDefs(195)=(id="KF-TheGreatPyramid-ArenaHoe",DisplayName="Mental",Description="Great Pyramid",Icon=Texture'ScrnAch_T.Maps.Pyramid_3')
     AchDefs(196)=(id="KF-PandorasBox",DisplayName="Baby Box",Description="Pandora's Box",Icon=Texture'ScrnAch_T.Maps.Pandora_0')
     AchDefs(197)=(id="KF-PandorasBoxHard",DisplayName="Hard Box",Description="Pandora's Box",Icon=Texture'ScrnAch_T.Maps.Pandora_1')
     AchDefs(198)=(id="KF-PandorasBoxSui",DisplayName="Opening the Pandora's Box",Description="Pandora's Box",Icon=Texture'ScrnAch_T.Maps.Pandora_2')
     AchDefs(199)=(id="KF-PandorasBoxHoe",DisplayName="Unleashing Evil into Devil",Description="Pandora's Box",Icon=Texture'ScrnAch_T.Maps.Pandora_3')
     AchDefs(200)=(id="KF-ScrapHeap",DisplayName="Scrap Metal Merchant",Description="Scrap Heap",Icon=Texture'ScrnAch_T.Maps.ScrapHeap_0')
     AchDefs(201)=(id="KF-ScrapHeapHard",DisplayName="Underground Boxer",Description="Scrap Heap",Icon=Texture'ScrnAch_T.Maps.ScrapHeap_1')
     AchDefs(202)=(id="KF-ScrapHeapSui",DisplayName="King of the Box Ring",Description="Scrap Heap",Icon=Texture'ScrnAch_T.Maps.ScrapHeap_2')
     AchDefs(203)=(id="KF-ScrapHeapHoe",DisplayName="Knocking Down the Satan",Description="Scrap Heap",Icon=Texture'ScrnAch_T.Maps.ScrapHeap_3')
     AchDefs(204)=(id="KF-Train",DisplayName="Choo-Choo Train",Description="Train",Icon=Texture'ScrnAch_T.Maps.Train_0')
     AchDefs(205)=(id="KF-TrainHard",DisplayName="Poo-Poo Train",Description="Train",Icon=Texture'ScrnAch_T.Maps.Train_1')
     AchDefs(206)=(id="KF-TrainSui",DisplayName="Suicidal Train Driver",Description="Train",Icon=Texture'ScrnAch_T.Maps.Train_2')
     AchDefs(207)=(id="KF-TrainHoe",DisplayName="Baron of Hell",Description="Train",Icon=Texture'ScrnAch_T.Maps.Train_3')
     AchDefs(208)=(id="KF-WickedCity",DisplayName="Homeless resident of Wicked City",Description="Wicked City",Icon=Texture'ScrnAch_T.Maps.WickedCity_0')
     AchDefs(209)=(id="KF-WickedCityHard",DisplayName="Citizen of Wicked City",Description="Wicked City",Icon=Texture'ScrnAch_T.Maps.WickedCity_1')
     AchDefs(210)=(id="KF-WickedCitySui",DisplayName="Wicked City's First Maniac",Description="Wicked City",Icon=Texture'ScrnAch_T.Maps.WickedCity_2')
     AchDefs(211)=(id="KF-WickedCityHoe",DisplayName="Wicked Hell",Description="Wicked City",Icon=Texture'ScrnAch_T.Maps.WickedCity_3')
     AchDefs(212)=(id="KF-NightAngkor-SE",DisplayName="Entering Ancient Ruins",Description="Night Angkor",Icon=Texture'ScrnAch_T.Maps.NightAngkor_0')
     AchDefs(213)=(id="KF-NightAngkor-SEHard",DisplayName="Hardcore Anthropologist",Description="Night Angkor",Icon=Texture'ScrnAch_T.Maps.NightAngkor_1')
     AchDefs(214)=(id="KF-NightAngkor-SESui",DisplayName="Trampoline Jumper",Description="Night Angkor",Icon=Texture'ScrnAch_T.Maps.NightAngkor_2')
     AchDefs(215)=(id="KF-NightAngkor-SEHoe",DisplayName="Demon's Paradise",Description="Night Angkor",Icon=Texture'ScrnAch_T.Maps.NightAngkor_3')

     DisplayName0="Pub Crawl"
     DisplayName1="Hard Pub Crawl"
     DisplayName2="Suicidal Pub Crawl"
     DisplayName3="Hellish Pub Crawl"
     DisplayName4="Lord of the Manor"
     DisplayName5="Duke of the Manor"
     DisplayName6="Emperor of the Manor"
     DisplayName7="Demonic King of the Manor"
     DisplayName8="Chicken Farmer"
     DisplayName9="Cattle Farmer"
     DisplayName10="Alligator Farmer"
     DisplayName11="Demon Farmer"
     DisplayName12="The Boss"
     DisplayName13="Hard Boss"
     DisplayName14="Mad Boss"
     DisplayName15="Boss from Hell"
     DisplayName16="Lab Cleaner"
     DisplayName17="Lab Assistant"
     DisplayName18="Lab Professor"
     DisplayName19="Scientist from Hell"
     DisplayName20="Tin Man"
     DisplayName21="Steel Worker"
     DisplayName22="Man of Steel"
     DisplayName23="Diablo Steel Man"
     DisplayName24="A Bit Barmy"
     DisplayName25="Gone Mental"
     DisplayName26="Complete Barking"
     DisplayName27="Commit-ed for life"
     DisplayName28="Squirrel King of the Dark Forest"
     DisplayName29="Raccoon King of the Dark Forest"
     DisplayName30="Bear King of the Dark Forest"
     DisplayName31="Wolf King of the Dark Forest"
     DisplayName32="Waste Disposal"
     DisplayName33="Waste Land"
     DisplayName34="Waste of Space"
     DisplayName35="Wasted"
     DisplayName36="Warehouse Janitor"
     DisplayName37="Warehouse Forklift Operator"
     DisplayName38="Warehouse Foreman"
     DisplayName39="Warehouse Manager"
     DisplayName40="Departure Gallery"
     DisplayName41="Departure Lounge"
     DisplayName42="Departure Gate"
     DisplayName43="Dear Departed"
     DisplayName44="Running Late"
     DisplayName45="Missed Connection"
     DisplayName46="Train Wreck"
     DisplayName47="Pile Up"
     DisplayName48="Gimme a Plaster!"
     DisplayName49="That Bloody Well Hurts!"
     DisplayName50="I'm Dying Here!"
     DisplayName51="Not Dead Yet!"
     DisplayName52="Ice Cube"
     DisplayName53="Crushed Ice"
     DisplayName54="Iceberg"
     DisplayName55="Comet"
     DisplayName56="Daytrip"
     DisplayName57="Gone Camping"
     DisplayName58="Mountaineer"
     DisplayName59="Park Ranger"
     DisplayName60="Park Ranger"
     DisplayName61="Private Security"
     DisplayName62="Vigilante"
     DisplayName63="SWAT"
     DisplayName64="Slight Drip"
     DisplayName65="Burst Pipe"
     DisplayName66="Pressure Failure"
     DisplayName67="Floodgate to Hell"
     DisplayName68="Walking in A Winter Horror Land"
     DisplayName69="Silent Night, Evil Night"
     DisplayName70="I'm Dreaming of a Red Christmas"
     DisplayName71="Grandma got Eaten by a Reindeer"
     DisplayName72="Science Got Done"
     DisplayName73="Still Alive"
     DisplayName74="This is a Triumph"
     DisplayName75="I'm Making a Note Here, Huge Success"
     DisplayName76="Flea Circus"
     DisplayName77="Dog and Pony Show"
     DisplayName78="3 Ring Circus"
     DisplayName79="On Top of the Big Top"
     DisplayName80="Snow Cone"
     DisplayName81="Stay Frosty"
     DisplayName82="On the Rocks"
     DisplayName83="Anti Freeze"
     DisplayName84="Highway to Heaven"
     DisplayName85="Stuck in Limbo"
     DisplayName86="Demonic Road"
     DisplayName87="Devil's Co-pilot"
     DisplayName88="Third Cousins"
     DisplayName89="Second Cousins"
     DisplayName90="First Cousins"
     DisplayName91="Zeroth Cousins"
     DisplayName92="Here is to us"
     DisplayName93="Attempting Re-entry"
     DisplayName94="Amusing Death"
     DisplayName95="One Giant Leap (Back) for Mankind"
     DisplayName96="Lord of Aventive"
     DisplayName97="Duke of Aventine"
     DisplayName98="Emperor of Aventine"
     DisplayName99="Demonic King of Aventine"
     DisplayName100="Rats in the Wall"
     DisplayName101="Barking Dogs Outside"
     DisplayName102="Screaming Maidens"
     DisplayName103="...and the Crazed Lord of the Manor died - again"
     DisplayName104="Barrow Boy"
     DisplayName105="Supermarket Manager"
     DisplayName106="BestBuy's Director"
     DisplayName107="HellBuy's Director"
     DisplayName108="Bug in the System"
     DisplayName109="Infected System"
     DisplayName110="Critical System Failure"
     DisplayName111="The Blue Screen"
     DisplayName112="Sailor"
     DisplayName113="Boatswain"
     DisplayName114="Maritime Pilot"
     DisplayName115="Demonic Captain"
     DisplayName116="Imp"
     DisplayName117="Mancubus"
     DisplayName118="Hell Knight"
     DisplayName119="Cyberdemon"
     DisplayName120="Knock, knock. Who's there?"
     DisplayName121="Gate Keeper"
     DisplayName122="Free Sauna Inside"
     DisplayName123="Open up! It's me - Satan."
     DisplayName124="Survivor of the Deserted City"
     DisplayName125="Survivor of the Lost City"
     DisplayName126="Survivor of the Dead City"
     DisplayName127="Survivor of the UnDead City"
     DisplayName128="Silent Hill"
     DisplayName129="Hard Hill"
     DisplayName130="Suicidal Hill"
     DisplayName131="Otherworld"
     DisplayName132="Hallucinations"
     DisplayName133="Delirium Tremens"
     DisplayName134="Schizophrenia"
     DisplayName135="Diabolical Obsession"
     DisplayName136="This is My Swamp!"
     DisplayName137="Give Me Back My Swamp!"
     DisplayName138="I'll Die For My Swamp"
     DisplayName139="Hellish Swamp"
     DisplayName140="Long, Dark Road"
     DisplayName141="Long, Hard Road"
     DisplayName142="Path of the Ahmed"
     DisplayName143="Road to Hell"
     DisplayName144="iPLAY"
     DisplayName145="iROCK"
     DisplayName146="iDIE"
     DisplayName147="iKILL"
     DisplayName148="Rudolf in the Sky"
     DisplayName149="I See Dead Reindeers"
     DisplayName150="Rudolf the Suicide Reindeer"
     DisplayName151="Sending Deer to Hell"
     DisplayName152="Backing Dancer"
     DisplayName153="DJ Skully"
     DisplayName154="King of the Dance Floor"
     DisplayName155="Devil Dance"
     DisplayName156="Drunken Farmer Jail"
     DisplayName157="Maximum Security Prison"
     DisplayName158="Death Row"
     DisplayName159="Prison Break"
     DisplayName160="Astro Buffer Afficiando"
     DisplayName161="Modified Psychoacceleration Achiever"
     DisplayName162="Fractional Neutron Activator"
     DisplayName163="Advanced Omega Wave Resonance Explorer"
     DisplayName164="Longshorman"
     DisplayName165="Gang Crew"
     DisplayName166="Stevedore"
     DisplayName167="Wharfinger"
     DisplayName168="Brain Fart"
     DisplayName169="Agnosia"
     DisplayName170="Amnesia"
     DisplayName171="Dementia"
     DisplayName172="Home Brewer"
     DisplayName173="Micro Brewer"
     DisplayName174="Master Brewer"
     DisplayName175="Trappist Monk"
     DisplayName176="Peasant"
     DisplayName177="Squire"
     DisplayName178="Prince"
     DisplayName179="King"
     DisplayName180="Cattle Class"
     DisplayName181="Economy Comfort"
     DisplayName182="Business Class"
     DisplayName183="First Class"
     DisplayName184="Gone clubbing"
     DisplayName185="Rack 'em up"
     DisplayName186="Burned out"
     DisplayName187="Hangover from Hell"
     DisplayName188="Cave of Wonder"
     DisplayName189="Cavern of Pain"
     DisplayName190="Grotto of Terror"
     DisplayName191="Hollow of Horror"
     DisplayName192="The First Encounter"
     DisplayName193="The First Encounter: HD"
     DisplayName194="Are You SERIOUS?"
     DisplayName195="Mental"
     DisplayName196="Baby Box"
     DisplayName197="Hard Box"
     DisplayName198="Opening the Pandora's Box"
     DisplayName199="Unleashing Evil into Devil"
     DisplayName200="Scrap Metal Merchant"
     DisplayName201="Underground Boxer"
     DisplayName202="King of the Box Ring"
     DisplayName203="Knocking Down the Satan"
     DisplayName204="Choo-Choo Train"
     DisplayName205="Poo-Poo Train"
     DisplayName206="Suicidal Train Driver"
     DisplayName207="Baron of Hell"
     DisplayName208="Homeless resident of Wicked City"
     DisplayName209="Citizen of Wicked City"
     DisplayName210="Wicked City's First Maniac"
     DisplayName211="Wicked Hell"
     DisplayName212="Entering Ancient Ruins"
     DisplayName213="Hardcore Anthropologist"
     DisplayName214="Trampoline Jumper"
     DisplayName215="Demon's Paradise"
}
