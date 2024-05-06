// this class holds all contributors icons and info
class ScrnHighlyDecorated extends object;


struct SSpecialPlayers
{
    var int SteamID32;
    var string AvatarRef, ClanIconRef, PreNameIconRef, PostNameIconRef;
    var Material Avatar, ClanIcon, PreNameIcon, PostNameIcon;
    var Color PrefixIconColor, PostfixIconColor;
    var int Playoffs, TourneyWon;
};
var const private array<SSpecialPlayers> HighlyDecorated;


final static function bool GetHighlyDecorated(int SteamID32,
    out material Avatar, out material ClanIcon,
    out material PreNameIcon, out Color PrefixIconColor, out material PostNameIcon, out Color PostfixIconColor,
    out int Playoffs, out int TourneyWon)
{
    local int start, end, i;

    start = 0;
    end = default.HighlyDecorated.length;

    while ( start < end )
    {
        i = start + ((end - start)>>1);
        if ( SteamID32 == default.HighlyDecorated[i].SteamID32 )
        {
            if ( default.HighlyDecorated[i].Avatar == none && default.HighlyDecorated[i].AvatarRef != "" )
                default.HighlyDecorated[i].Avatar = Material(DynamicLoadObject(default.HighlyDecorated[i].AvatarRef, class'Material'));
            if ( default.HighlyDecorated[i].ClanIcon == none && default.HighlyDecorated[i].ClanIconRef != "" )
                default.HighlyDecorated[i].ClanIcon = Material(DynamicLoadObject(default.HighlyDecorated[i].ClanIconRef, class'Material'));
            if ( default.HighlyDecorated[i].PreNameIcon == none && default.HighlyDecorated[i].PreNameIconRef != "" )
                default.HighlyDecorated[i].PreNameIcon = Material(DynamicLoadObject(default.HighlyDecorated[i].PreNameIconRef, class'Material'));
            if ( default.HighlyDecorated[i].PostNameIcon == none && default.HighlyDecorated[i].PostNameIconRef != "" )
                default.HighlyDecorated[i].PostNameIcon = Material(DynamicLoadObject(default.HighlyDecorated[i].PostNameIconRef, class'Material'));
            Avatar = default.HighlyDecorated[i].Avatar;
            ClanIcon = default.HighlyDecorated[i].ClanIcon;
            PreNameIcon = default.HighlyDecorated[i].PreNameIcon;
            PrefixIconColor = default.HighlyDecorated[i].PrefixIconColor;
            PostNameIcon = default.HighlyDecorated[i].PostNameIcon;
            PostfixIconColor = default.HighlyDecorated[i].PostfixIconColor;
            Playoffs = default.HighlyDecorated[i].Playoffs;
            TourneyWon = default.HighlyDecorated[i].TourneyWon;
            return true;
        }
        else if ( SteamID32 < default.HighlyDecorated[i].SteamID32 )
            end = i;
        else
            start = i + 1;
    }
    Avatar = none;
    ClanIcon = none;
    PreNameIcon = none;
    PostNameIcon = none;
    Playoffs = 0;
    TourneyWon = 0;

    return false;
}


defaultproperties
{
    HighlyDecorated(0)=(SteamID32=3907835,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(1)=(SteamID32=4787302,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(2)=(SteamID32=15243342,ClanIconRef="ScrnTex.Players.Code",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Medic_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(3)=(SteamID32=18524053,AvatarRef="ScrnTex.Players.FabZen",ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Commander_Grey",PostNameIconRef="KillingFloor2HUD.PerkReset.PReset_Commander_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(4)=(SteamID32=18871148,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Berserker_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(5)=(SteamID32=20530727,AvatarRef="ScrnTex.Players.LazyBunta",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(6)=(SteamID32=21825964,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(7)=(SteamID32=25188900,AvatarRef="ScrnTex.Players.Scuddles",PreNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PostNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(8)=(SteamID32=26505257,Playoffs=1,AvatarRef="ScrnTex.Players.Duckbuster",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(9)=(SteamID32=27263782,Playoffs=1,AvatarRef="ScrnTex.Players.Termcat",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(10)=(SteamID32=27784497,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(11)=(SteamID32=32271863,AvatarRef="ScrnTex.Players.PooSH",PreNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PostNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(12)=(SteamID32=32279441,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(13)=(SteamID32=32708029,ClanIconRef="ScrnTex.Players.Dosh",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Firebug_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(14)=(SteamID32=32779545,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(15)=(SteamID32=32976519,Playoffs=1,ClanIconRef="ScrnTex.Players.Dosh",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(16)=(SteamID32=34308728,AvatarRef="ScrnTex.Players.Janitor",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Firebug_Grey",PostNameIconRef="KillingFloor2HUD.PerkReset.PReset_Firebug_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(17)=(SteamID32=37444251,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(18)=(SteamID32=41734606,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(19)=(SteamID32=43087787,Playoffs=1,AvatarRef="ScrnTex.Players.Chaos",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(20)=(SteamID32=43944237,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(21)=(SteamID32=44141219,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(22)=(SteamID32=44328745,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(23)=(SteamID32=44388687,AvatarRef="ScrnTex.Players.Aze",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Commander_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(24)=(SteamID32=45006648,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(25)=(SteamID32=45088649,Playoffs=1,AvatarRef="ScrnTex.Players.Joe",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Berserker_Grey",PrefixIconColor=(R=255,G=255,B=255,A=0),PostfixIconColor=(A=0))
    HighlyDecorated(26)=(SteamID32=45352894,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(27)=(SteamID32=45594574,AvatarRef="ScrnTex.Players.CodeReaper",PreNameIconRef="ScrnTex.Players.BowieKnifeLeft",PostNameIconRef="ScrnTex.Players.BowieKnifeRight",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(28)=(SteamID32=46023864,AvatarRef="ScrnTex.Players.Baron",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Medic_Grey",PostNameIconRef="ScrnAch_T.Achievements.Baron",PrefixIconColor=(A=0),PostfixIconColor=(R=255,G=255,B=255,A=255))
    HighlyDecorated(29)=(SteamID32=47199674,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(30)=(SteamID32=47820768,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(31)=(SteamID32=49361376,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(32)=(SteamID32=51667940,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(33)=(SteamID32=52109233,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(34)=(SteamID32=53781980,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(35)=(SteamID32=54179805,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(36)=(SteamID32=54471316,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(37)=(SteamID32=57193815,ClanIconRef="ScrnTex.Players.Dosh",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(38)=(SteamID32=58813412,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(39)=(SteamID32=59018230,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(40)=(SteamID32=59344954,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(41)=(SteamID32=59865355,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(42)=(SteamID32=61480134,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(43)=(SteamID32=61647562,ClanIconRef="ScrnTex.Players.Dosh",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Demolition_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(44)=(SteamID32=63358796,AvatarRef="ScrnTex.Players.FishFlop",PreNameIconRef="ScrnTex.Players.InvertedCross",PostNameIconRef="ScrnTex.Players.Medal_chicken",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(45)=(SteamID32=63934831,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(46)=(SteamID32=64861994,Playoffs=1,AvatarRef="ScrnTex.Players.dkanus",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(47)=(SteamID32=66725591,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Medic_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(48)=(SteamID32=66767874,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(49)=(SteamID32=67141366,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(50)=(SteamID32=68703215,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(51)=(SteamID32=68932148,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(52)=(SteamID32=70606615,AvatarRef="ScrnTex.Players.aaa",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(53)=(SteamID32=71427768,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(54)=(SteamID32=71462150,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(55)=(SteamID32=71776568,AvatarRef="ScrnTex.Players.tanks",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Commander_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(56)=(SteamID32=72523409,AvatarRef="ScrnTex.Players.Candybee",PreNameIconRef="ScrnTex.Players.Mudflapgirl_left",PostNameIconRef="ScrnTex.Players.Mudflapgirl_right",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(57)=(SteamID32=75600845,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(58)=(SteamID32=76661591,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(59)=(SteamID32=77967745,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Demolition_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(60)=(SteamID32=80719207,AvatarRef="ScrnTex.Players.eternalbruhmeister",PreNameIconRef="ScrnTex.Players.eternalbruhmeister_nameicon",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(61)=(SteamID32=81279347,ClanIconRef="ScrnTex.Players.Dosh",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(62)=(SteamID32=81947447,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(63)=(SteamID32=82239578,AvatarRef="ScrnTex.Players.Toaste",PreNameIconRef="ScrnTex.Players.Yinyang",PostNameIconRef="ScrnTex.Players.Yinyang",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(64)=(SteamID32=83417929,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(65)=(SteamID32=84050600,AvatarRef="ScrnTex.Players.NikC",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Demolition_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(66)=(SteamID32=84652399,AvatarRef="ScrnTex.Players.Droop",PreNameIconRef="ScrnTex.Players.Batman",PostNameIconRef="ScrnTex.Players.Batman",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(67)=(SteamID32=85142081,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(68)=(SteamID32=87647886,ClanIconRef="ScrnTex.Players.Dosh",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(69)=(SteamID32=89323130,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(70)=(SteamID32=89425889,AvatarRef="ScrnTex.Players.faithfulness",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(71)=(SteamID32=93919492,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(72)=(SteamID32=95752287,AvatarRef="ScrnTex.Players.FosterKF2",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PostNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=1),PostfixIconColor=(A=0))
    HighlyDecorated(73)=(SteamID32=99293732,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(74)=(SteamID32=102203653,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_chicken",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(75)=(SteamID32=102496714,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(76)=(SteamID32=106835439,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(77)=(SteamID32=107039826,Playoffs=1,AvatarRef="ScrnTex.Players.Seely",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(78)=(SteamID32=109654784,AvatarRef="ScrnTex.Players.BertieDastard",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Support_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(79)=(SteamID32=110496233,AvatarRef="ScrnTex.Players.VP",ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_dragon",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(80)=(SteamID32=112564543,ClanIconRef="ScrnTex.Players.Dosh",PreNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PostNameIconRef="ScrnTex.Perks.Hud_Perk_Star_Gray",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(81)=(SteamID32=113961551,Playoffs=1,AvatarRef="ScrnTex.Players.Baffi",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Demolition_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(82)=(SteamID32=114826433,Playoffs=1,AvatarRef="ScrnTex.Players.nmm",ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(83)=(SteamID32=121550025,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(84)=(SteamID32=124874371,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(85)=(SteamID32=127624729,AvatarRef="ScrnTex.Players.Scrublord",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(86)=(SteamID32=128107383,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(87)=(SteamID32=128199891,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(88)=(SteamID32=129035696,AvatarRef="ScrnTex.Players.blackstallion",PreNameIconRef="ScrnTex.Players.blackstallion_nameicon",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(89)=(SteamID32=134825301,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(90)=(SteamID32=136078273,ClanIconRef="ScrnTex.Players.SALTY",PreNameIconRef="KillingFloor2HUD.PerkReset.PReset_Firebug_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(91)=(SteamID32=139723798,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(92)=(SteamID32=143999622,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(93)=(SteamID32=150832205,AvatarRef="ScrnTex.Players.Taloril",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(94)=(SteamID32=152138369,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(95)=(SteamID32=152983683,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(96)=(SteamID32=153788974,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(97)=(SteamID32=160715546,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(98)=(SteamID32=162712343,Playoffs=1,ClanIcon=Texture'ScrnTex.Tourney.TourneyMember',PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(99)=(SteamID32=173722095,AvatarRef="ScrnTex.Players.catcat",PreNameIconRef="ScrnTex.Players.RadioActive",PostNameIconRef="ScrnTex.Players.RadioActive",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(100)=(SteamID32=182247922,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_kom",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(101)=(SteamID32=190669364,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_doll",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(102)=(SteamID32=192070782,Playoffs=1,TourneyWon=1,ClanIconRef="ScrnTex.Tourney.TBN",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(103)=(SteamID32=319278244,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_doll",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(104)=(SteamID32=359866000,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_kom",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(105)=(SteamID32=374934166,AvatarRef="ScrnTex.Players.Bligiet",PreNameIconRef="ScrnTex.Players.BowieKnifeLeft",PostNameIconRef="ScrnTex.Players.BowieKnifeRight",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(106)=(SteamID32=378534555,AvatarRef="ScrnTex.Players.BossRoss",PreNameIconRef="ScrnTex.Players.BossRossNameIcon",PostNameIconRef="ScrnTex.Players.BossRossNameIcon",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(107)=(SteamID32=389474897,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_homer",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(108)=(SteamID32=391528064,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_doll",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(109)=(SteamID32=397272710,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_doll",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(110)=(SteamID32=403136595,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="ScrnTex.Players.Medal_f",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(111)=(SteamID32=405312393,ClanIconRef="ScrnTex.Players.VP",PreNameIconRef="ScrnTex.Players.Medal_VP",PostNameIconRef="KillingFloor2HUD.PerkReset.PReset_Sharpshooter_Grey",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
    HighlyDecorated(112)=(SteamID32=1018902788,AvatarRef="ScrnTex.Players.metal",PreNameIconRef="ScrnTex.Players.BowieKnifeLeft",PostNameIconRef="ScrnTex.Players.BowieKnifeRight",PrefixIconColor=(A=0),PostfixIconColor=(A=0))
}