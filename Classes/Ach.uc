Class Ach extends ScrnAchievements;

#exec OBJ LOAD FILE=ScrnAch_T.utx

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
    AchDefs(1)=(id="WinCustomMaps1",DisplayName="Wanderer",Description="Survive on %c community-made maps",Icon=Texture'KillingFloorHUD.Achievements.Achievement_11',MaxProgress=25,DataSize=-1,Group="MAP")
    AchDefs(2)=(id="WinCustomMaps2",DisplayName="Explorer",Description="Survive on %c community-made maps",Icon=Texture'KillingFloorHUD.Achievements.Achievement_17',MaxProgress=50,DataSize=-1,Group="MAP")
    AchDefs(3)=(id="WinCustomMapsNormal",DisplayName="Piece of Cake",Description="Survive on %c custom maps in ScrN Balance mode",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_109',MaxProgress=7,DataSize=3,Group="MAP")
    AchDefs(4)=(id="WinCustomMapsHard",DisplayName="Pound Cake",Description="Survive on %c custom maps against Super/Custom specimens",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_110',MaxProgress=5,DataSize=3,Group="MAP",FilterMaskAll=2)
    AchDefs(5)=(id="WinCustomMapsSui",DisplayName="Cyanide Cake",Description="Survive on %c custom maps against Custom end-game Boss",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_111',MaxProgress=5,DataSize=3,Group="MAP",FilterMaskAll=4)
    AchDefs(6)=(id="WinCustomMapsHoE",DisplayName="Devil Cake",Description="Survive on %c custom maps against Doom3 monsters",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_112',MaxProgress=3,DataSize=3,Group="MAP",FilterMaskAll=8)
    AchDefs(7)=(id="KillSuperPat",DisplayName="Death to the Super Scientist",Description="Defeat the Hard or Super Patriarch",Icon=Texture'KillingFloorHUD.Achievements.Achievement_42',MaxProgress=1,DataSize=1,FilterMaskAll=68)
    AchDefs(8)=(id="MerryMen",DisplayName="Merry Men",Description="Kill the Patriarch when everyone is ONLY using Crossbows",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_58',MaxProgress=1,DataSize=1,Group="TW",bForceShow=True)
    AchDefs(9)=(id="MerryMen50cal",DisplayName="Merry Men .50",Description="Kill the Patriarch when everyone is ONLY using M99",Icon=Texture'ScrnAch_T.Achievements.MerryMen50',MaxProgress=1,DataSize=1,Group="TW",bForceShow=True)
    AchDefs(10)=(id="ThinIcePirouette",DisplayName="Thin-Ice Pirouette",Description="Complete %c waves when the rest of your team has died (requires 4+ players)",Icon=Texture'KillingFloorHUD.Achievements.Achievement_36',MaxProgress=10,DataSize=4)
    AchDefs(11)=(id="Kenny",DisplayName="OMG, We Have Kenny!",Description="Having one of you dying almost every wave",Icon=Texture'ScrnAch_T.Achievements.Kenny',MaxProgress=1,DataSize=1)
    AchDefs(12)=(id="PerkFavorite",DisplayName="Favorite Perk",Description="Survive a game from beginning till the end without changing your perk",Icon=Texture'ScrnAch_T.Achievements.PerkFavorite',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(13)=(id="PerfectBalance",DisplayName="Perfect Balance",Description="Survive 6+ player game having 1 player per perk",Icon=Texture'ScrnAch_T.Achievements.PerfectBalance',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(14)=(id="MrPerky",DisplayName="Mr. Golden Perky",Description="Get All of your Perks up to Level 6",Icon=Texture'KillingFloorHUD.Achievements.Achievement_39',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(15)=(id="PerkGreen",DisplayName="Wow, a Green Icon!",Description="Reach Level 11",Icon=Texture'ScrnAch_T.Achievements.PerkGreen',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(16)=(id="PerkBlue",DisplayName="Blue Gold",Description="Reach Level 16",Icon=Texture'ScrnAch_T.Achievements.PerkBlue',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(17)=(id="PerkPurple",DisplayName="Purple Reign",Description="Reach Level 21",Icon=Texture'ScrnAch_T.Achievements.PerkPurple',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(18)=(id="PerkOrange",DisplayName="Nothing Rhymes with Orange",Description="Reach Level 26",Icon=Texture'ScrnAch_T.Achievements.PerkOrange',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(19)=(id="Kill1000Zeds",DisplayName="Hidden Zero in Experimenticenticide",Description="Kill 1,000 Specimens",Icon=Texture'KillingFloorHUD.Achievements.Achievement_18',MaxProgress=1000,DataSize=-2,Group="EXP")
    AchDefs(20)=(id="Kill10000Zeds",DisplayName="Hidden Zero II",Description="Kill 10,000 Specimens",Icon=Texture'KillingFloorHUD.Achievements.Achievement_19',MaxProgress=10000,DataSize=-1,Group="EXP")
    AchDefs(21)=(id="Kill100000Zeds",DisplayName="Hidden Zero III",Description="Kill 100,000 Specimens",Icon=Texture'KillingFloorHUD.Achievements.Achievement_20',MaxProgress=100000,DataSize=-1,Group="EXP")
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
    AchDefs(33)=(id="BruteScar",DisplayName="Brutally SCAR'd",Description="Kill %c Brutes with SCAR without taking a damage",Icon=Texture'ScrnAch_T.Achievements.BruteScar',MaxProgress=15,FilterMaskAll=32,DataSize=4,Group="MASTER")
    AchDefs(34)=(id="Kill100FPExplosives",DisplayName="Pound This",Description="Kill %c Fleshpounds with explosives",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_64',MaxProgress=100,DataSize=7,Group="EXP")
    AchDefs(35)=(id="Nail250Zeds",DisplayName="Nail'd",Description="Nail %c alive zeds to walls",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_186',MaxProgress=250,DataSize=8,Group="EXP")
    AchDefs(36)=(id="NailPush100m",DisplayName="Fly High",Description="Push %c zeds at least 100m away with Nailgun",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_61',MaxProgress=10,DataSize=4,Group="EXP")
    AchDefs(37)=(id="NailPushShiver",DisplayName="Teleported Back",Description="Push back headless Shiver with Nailgun",Icon=Texture'ScrnAch_T.Achievements.Teleport',MaxProgress=1,FilterMaskAll=32,DataSize=1)
    AchDefs(38)=(id="TrueCowboy",DisplayName="True Cowboy",Description="Spend an entire wave in Cowboy Mode",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_170',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(39)=(id="MadCowboy",DisplayName="Mad Cowboy",Description="Kill 8 zeds with Machine Pistols without releasing a trigger",Icon=Texture'ScrnAch_T.Achievements.CrazyCowboy',MaxProgress=1,DataSize=1,Group="MASTER",bForceShow=True)
    AchDefs(40)=(id="M4203Kill50Zeds",DisplayName="#1 In Trash Cleaning",Description="Kill 40 zeds in one wave with M4-203 SE",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_165',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(41)=(id="M99Kill3SC",DisplayName="Ain't Looking For Easy Ways",Description="Kill %c Raged Scrakes with M99 headshots",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_180',MaxProgress=3,DataSize=2)
    AchDefs(42)=(id="ExplosionLove",DisplayName="Explosion of Love",Description="Heal 6 players with one medic grenade",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_187',MaxProgress=1,DataSize=1)
    AchDefs(43)=(id="iDoT",DisplayName="Power of iDoT",Description="Reach 300dps incremental Damage over Time (iDoT) with flares",Icon=Texture'ScrnAch_T.Achievements.iDoT',MaxProgress=1,DataSize=1)
    AchDefs(44)=(id="Unassisted",DisplayName="Unassisted",Description="Solo-kill Fleshpound in 6+ player game",Icon=Texture'ScrnAch_T.Achievements.Unassisted',MaxProgress=1,bForceShow=True,DataSize=1,Group="MASTER")
    AchDefs(45)=(id="TW_SC_LAWHSG",DisplayName="TeamWork: When Size Matters",Description="Finish %c LAW-stunned Scrakes with Hunting or Combat Shotgun",Icon=Texture'ScrnAch_T.Teamwork.SC_LAWHSG',MaxProgress=30,DataSize=5,Group="TW")
    AchDefs(46)=(id="TW_SC_Instant",DisplayName="TeamWork: Instant Kill",Description="Kill %c Scrakes with two simultaneous Crossbow/M99 headshots",Icon=Texture'ScrnAch_T.Teamwork.SC_InstantKill',MaxProgress=30,bForceShow=True,DataSize=5,Group="TW")
    AchDefs(47)=(id="TW_Siren",DisplayName="TeamWork: No Big Guns on Skinny Bitches",Description="Kill %c Sirens with Pistols + Assault Rifles",Icon=Texture'ScrnAch_T.Teamwork.siren',MaxProgress=100,DataSize=7,Group="TW")
    AchDefs(48)=(id="TW_Shiver",DisplayName="TeamWork: Grilled Shiver Brains",Description="Decapitate %c burning Shivers with Assault Rifles",Icon=Texture'ScrnAch_T.Teamwork.Shiver',MaxProgress=250,FilterMaskAll=32,DataSize=8,Group="TW")
    AchDefs(49)=(id="TW_Husk_Stun",DisplayName="TeamWork: Stunning Shot, Mate!",Description="Finish %c stunned Husks with Shotguns",Icon=Texture'ScrnAch_T.Teamwork.Husk_Stun',MaxProgress=30,DataSize=6,Group="TW")
    AchDefs(50)=(id="TW_FP_Snipe",DisplayName="TeamWork: Sharpened Flesh",Description="Headshot-kill %c Fleshpounds by 2+ Sharpshooters",Icon=Texture'ScrnAch_T.Teamwork.FP_XBOWM14',MaxProgress=15,DataSize=4,Group="TW")
    AchDefs(51)=(id="TW_FP_Pipe",DisplayName="TeamWork: Sniper Blow",Description="Rage %c Fleshpounds directly on a pipebomb with Crossbow/M99",Icon=Texture'ScrnAch_T.Teamwork.FP_M99Pipe',MaxProgress=15,DataSize=4,Group="TW")
    AchDefs(52)=(id="ScrakeNader",DisplayName="Scrake Nader",Description="Rage %c stunned Scrakes with hand grenades",Icon=Texture'ScrnAch_T.Achievements.ScrakeNaders',MaxProgress=50,DataSize=8)
    AchDefs(53)=(id="ScrakeUnnader",DisplayName="Why the Hell Are You Nading Scrakes?!",Description="Kill %c naded Scrakes with sniper weapons, before they do any damage to your retarded teammates.",Icon=Texture'ScrnAch_T.Achievements.ScrakeUnnader',MaxProgress=50,DataSize=8)
    AchDefs(54)=(id="TouchOfSavior",DisplayName="Touch of Savior",Description="Make %c heals, saving player from a death",Icon=Texture'ScrnAch_T.Achievements.TouchOfSavior',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(55)=(id="OnlyHealer",DisplayName="I Heal, You - Shoot!",Description="Be the only healing person in 4+player team for %c waves (200+hp)",Icon=Texture'KillingFloorHUD.Achievements.Achievement_35',MaxProgress=10,DataSize=4,Group="EXP")
    AchDefs(56)=(id="CombatMedic",DisplayName="Combat Medic",Description="Heal %c players and kill their enemies too",Icon=Texture'ScrnAch_T.Achievements.CombatMedic',MaxProgress=100,DataSize=8,Group="EXP")
    AchDefs(57)=(id="MeleeKillCrawlers",DisplayName="My Kung Fu is Better",Description="Melee-kill %c Crawlers without taking a damage",Icon=Texture'ScrnAch_T.Achievements.MeleeCrawler',MaxProgress=250,DataSize=8,Group="MASTER")
    AchDefs(58)=(id="MeleeHitBehind",DisplayName="My Kung Fu is Stronger",Description="Melee-hit %c zeds from behind",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_120',MaxProgress=250,DataSize=8,Group="MASTER")
    AchDefs(59)=(id="MeleeDecapBloats",DisplayName="My Kung Fu Doesn't Make You Puke",Description="Decapitate %c Bloats with melee weapons without getting puked",Icon=Texture'KillingFloorHUD.Achievements.Achievement_30',MaxProgress=50,DataSize=6,Group="MASTER")
    AchDefs(60)=(id="Ash",DisplayName="Tribute to Ash Williams",Description="Kill 40 zeds in a wave with Boomstick and Chainsaw. Do not use any other weapons!",Icon=Texture'ScrnAch_T.Achievements.Ash',MaxProgress=1,bForceShow=True,DataSize=1)
    AchDefs(61)=(id="Overkill",DisplayName="Overkill",Description="Shoot a Crawler in the head with M99",Icon=Texture'ScrnAch_T.Achievements.Overkill',MaxProgress=1,DataSize=1)
    AchDefs(62)=(id="BruteExplosive",DisplayName="Block THIS!",Description="Kill %c Brutes with explosive damage",Icon=Texture'ScrnAch_T.Achievements.BruteExplosive',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(63)=(id="KillHuskHuskGun",DisplayName="Burning Irony",Description="Kill %c Husks with Husk Cannon",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_57',MaxProgress=30,DataSize=5,Group="EXP")
    AchDefs(64)=(id="HFC",DisplayName="Horzine Fried Crawler",Description="Recipe: Burn %c Crawlers at temp. below 80C until they die.",Icon=Texture'ScrnAch_T.Achievements.HFC',MaxProgress=999,DataSize=10,Group="EXP")
    AchDefs(65)=(id="CarveRoast",DisplayName="Let Me Carve a Roast",Description="Kill %c crispified zeds with melee weapons.",Icon=Texture'ScrnAch_T.Achievements.CarveRoast',MaxProgress=30,DataSize=6)
    AchDefs(66)=(id="DotOfDoom",DisplayName="Dot of Doom",Description="Get 25 headshots in a row with the M14EBR.",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_60',MaxProgress=1,bForceShow=True,DataSize=1,Group="MASTER")
    AchDefs(67)=(id="Money10k",DisplayName="I Need DOSH!",Description="Start a wave having 10,000 pounds of cash",Icon=Texture'KillingFloorHUD.Achievements.Achievement_37',MaxProgress=1,DataSize=1)

    // new achievements
    AchDefs(68)=(id="Welcome",DisplayName="Welcome to ScrN Balance!",Description="Welcome to the ScrN Total Game Balance Community! Enjoy the best modification for Killing Floor.",Icon=Texture'ScrnAch_T.Achievements.PerfectBalance',MaxProgress=1,DataSize=1)

    AchDefs(69)=(id="MedicOfDoom",DisplayName="Medic of Doom",Description="Kill 15 zeds with M4-203M Medic Rifle without reloading.",Icon=Texture'ScrnAch_T.Master.MedicOfDoom',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(70)=(id="Plus25Clots",DisplayName="+25 Clot kills",Description="Kill 25 clots having less than 4 seconds between subsequent kills.",Icon=Texture'ScrnAch_T.Master.Plus25Clots',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(71)=(id="GetOffMyLawn",DisplayName="I said get off my Lawn!",Description="Kill %c Fleshpounds with the Boomstick or Combat Shotgun.",Icon=Texture'ScrnAch_T.Master.GetOffMyLawn',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(72)=(id="Accuracy",DisplayName="Accuracy",Description="Finish %c waves with 75% headshot accuracy. At least 30 decapitations required per wave.",Icon=Texture'ScrnAch_T.Master.Accuracy',MaxProgress=10,DataSize=4,Group="MASTER")
    AchDefs(73)=(id="SteampunkSniper",DisplayName="Steampunk Sniper",Description="Score 10 headshots in a row with Musket. Do it %c times.",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_224',MaxProgress=4,DataSize=3,Group="MASTER")
    AchDefs(74)=(id="MeleeGod",DisplayName="Melee God",Description="Kill %c Scrakes with only head-hits from melee weapons. Buzzsaw Bow excluding.",Icon=Texture'ScrnAch_T.Master.Gauntlet',MaxProgress=30,DataSize=5,Group="MASTER")

    AchDefs(75)=(id="HuskGunSC",DisplayName="Weird but usefull",Description="Kill %c Scrakes with the Husk Gun.",Icon=Texture'ScrnAch_T.Exp.HuskGunSC',MaxProgress=30,DataSize=5,Group="EXP")
    AchDefs(76)=(id="Impressive",DisplayName="Impressive",Description="Score 5 headshots in a row %c times.",Icon=Texture'ScrnAch_T.Exp.Impressive',MaxProgress=250,DataSize=8,Group="EXP")
    AchDefs(77)=(id="GrimReaper",DisplayName="Grim Reaper",Description="Kill %c zeds with Scythe.",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_193',MaxProgress=250,DataSize=8,Group="EXP")
    AchDefs(78)=(id="MindBlowingSacrifice",DisplayName="Mind-Blowing Sacrifice",Description="Kill %c Fleshpounds by blocking them on own pipes.",Icon=Texture'ScrnAch_T.Exp.MindBlowingSacrifice',MaxProgress=7,DataSize=3,Group="EXP")
    AchDefs(79)=(id="PrematureDetonation",DisplayName="Premature Detonation",Description="Kill %c zeds with undetonated grenades or rockets.",Icon=Texture'ScrnAch_T.Exp.PrematureDetonation',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(80)=(id="NoHeadshots",DisplayName="Hitboxes Are Overrated",Description="Kill %c big zeds without landing any headshot and taking damage.",Icon=Texture'ScrnAch_T.Exp.NoHeadshots',MaxProgress=62,DataSize=6,Group="EXP")
    AchDefs(81)=(id="BitterIrony",DisplayName="Bitter Irony",Description="Kill %c Scrakes with a Chainsaw.",Icon=Texture'KillingFloorHUD.Achievements.Achievement_25',MaxProgress=62,DataSize=6,Group="EXP")
    AchDefs(82)=(id="BallsOfSteel",DisplayName="Balls of Steel",Description="Survive an entire game without wearing heavy armor, damage resistance and dying.",Icon=Texture'ScrnAch_T.Exp.BallsOfSteel',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(83)=(id="OutOfTheGum",DisplayName="Out of the Gum",Description="Kill 30 specimens with bullets, having less than 5 seconds betwen subsequent kills.",Icon=Texture'ScrnAch_T.Exp.OutOfTheGum',MaxProgress=1,DataSize=1,Group="EXP")
    AchDefs(84)=(id="HorzineArmor",DisplayName="Good Defence Is NOT a Good Offence",Description="Survive %c times after taking a heavy damage, thanks to wearing a Horzine Armor.",Icon=Texture'ScrnAch_T.Exp.HorzineArmor',MaxProgress=7,DataSize=3,Group="EXP")
    AchDefs(85)=(id="RocketBlow",DisplayName="I Love Rocket Blow",Description="Kill 10 specimens with a single rocket blow. Liked it? Then do it %c times.",Icon=Texture'ScrnAch_T.Exp.RocketBlow',MaxProgress=30,DataSize=5,Group="EXP")
    AchDefs(86)=(id="SavingResources",DisplayName="Saving Resources",Description="Save %c pipebombs from Bloats or Sirens.",Icon=Texture'ScrnAch_T.Exp.SavingResources',MaxProgress=15,DataSize=4,Group="EXP")
    AchDefs(87)=(id="Gunslingophobia",DisplayName="Gunslingophobia",Description="One-shot kill %c Crawlers with pistols.",Icon=Texture'ScrnAch_T.Exp.Gunslingophobia',MaxProgress=1001,DataSize=10,Group="EXP")
    AchDefs(88)=(id="OldGangster",DisplayName="Old Gangster",Description="Kill 5 zeds without releasing a trigger of your Tommy Gun (drum mag.)",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_227',MaxProgress=55,DataSize=6,Group="EXP")

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
    AchDefs(104)=(id="KillWhore",DisplayName="KillWhore",Description="Get 2.5x more kills than any other player in your team (5+p).",Icon=Texture'ScrnAch_T.Achievements.KillWhore',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(105)=(id="ComeatMe",DisplayName="Come at Me, Bro!",Description="Kill a Jason with a Machete.",Icon=Texture'ScrnAch_T.Achievements.ComeatMe',MaxProgress=1,DataSize=1,FilterMaskAll=32)
    AchDefs(106)=(id="Friday13",DisplayName="Friday the 13th",Description="Survive the wave after 3 of your teammates got killed by Jason Voorhees.",Icon=Texture'ScrnAch_T.Achievements.Friday13',MaxProgress=1,DataSize=1,FilterMaskAll=32)
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
    // v9
    AchDefs(130)=(id="ProNailer",DisplayName="Pro-Nailer",Description="Decapitate zed with nail ricochet",Icon=Texture'ScrnAch_T.Master.ProNailer',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(131)=(id="TW_NoHeadshots",DisplayName="Hitboxes Are TOTALLY Overrated",Description="Survive 2+player game without scoring any headshots",Icon=Texture'ScrnAch_T.Teamwork.NoobAlert',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(132)=(id="TW_SkullCrackers",DisplayName="SkullCrackers",Description="Survive 2+player game by only using weapons that are capable of doing headshots (no nades, fire etc.)",Icon=Texture'ScrnAch_T.Teamwork.SkullCrackers',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(133)=(id="OP_Medic",DisplayName="Is Medic OP?",Description="Survive 3+player game where everybody is playing Medic",Icon=Texture'ScrnAch_T.Teamwork.OP_Medic',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(134)=(id="OP_Support",DisplayName="Is Support OP?",Description="Survive 3+player game where everybody is playing Support",Icon=Texture'ScrnAch_T.Teamwork.OP_Support',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(135)=(id="OP_Sharpshooter",DisplayName="Is Sharpshooter OP?",Description="Survive 3+player game where everybody is playing Sharpshooter",Icon=Texture'ScrnAch_T.Teamwork.OP_Sharpshooter',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(136)=(id="OP_Commando",DisplayName="Is Commando OP?",Description="Survive 3+player game where everybody is playing Commando",Icon=Texture'ScrnAch_T.Teamwork.OP_Commando',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(137)=(id="OP_Berserker",DisplayName="Is Berserker OP?",Description="Survive 3+player game where everybody is playing Berserker",Icon=Texture'ScrnAch_T.Teamwork.OP_Berserker',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(138)=(id="OP_Firebug",DisplayName="Is Firebug OP?",Description="Survive 3+player game where everybody is playing Firebug",Icon=Texture'ScrnAch_T.Teamwork.OP_Firebug',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(139)=(id="OP_Demo",DisplayName="Is Demo OP?",Description="Survive 3+player game where everybody is playing Demolition",Icon=Texture'ScrnAch_T.Teamwork.OP_Demo',MaxProgress=1,DataSize=1,Group="TW")
    AchDefs(140)=(id="OP_Gunslinger",DisplayName="Is Gunslinger OP?",Description="Survive 3+player game where everybody is playing Gunslinger",Icon=Texture'ScrnAch_T.Teamwork.OP_Gunslinger',MaxProgress=1,DataSize=1,Group="TW")
    // v9.10
    AchDefs(141)=(id="MacheteKillMidairCrawler",DisplayName="Machete Master",Description="Use Machete to melee-kill Crawler in midair without taking damage",Icon=Texture'ScrnAch_T.Master.MacheteCrawlerCut',MaxProgress=1,DataSize=1,Group="MASTER")
    AchDefs(142)=(id="MacheteStunSC",DisplayName="Machete Stuns!",Description="Stun Scrake with Machete",Icon=Texture'ScrnAch_T.Master.MacheteScrake',MaxProgress=1,DataSize=1,Group="MASTER",Group="Hidden")
    AchDefs(143)=(id="MacheteWalker",DisplayName="Machete Marathon",Description="Perform 'Machete-sprint': drop/pickup Machete 422 times while running in a single game",Icon=Texture'ScrnAch_T.Achievements.MacheteWalker',MaxProgress=1,DataSize=1,bForceShow=True,Group="Hidden")
}
