class ScrnAchHandler extends ScrnAchHandlerBase;

var bool bOnePlayerPerPerk, bAllSamePerk;
var transient class<ScrnVeterancyTypes> SamePerk;
var transient bool bBossXbowOnly, bBossM99Only, bBossMeleeOnly, bBoss9mmOnly, bBossPrey;
var transient float BossSpawnTime, BossLastDamageTime;
var float InstantKillTime; // instant kill counts, if time between shot is less than this
var bool bPerfectWave, bPerfectGame;
var byte PlayersKilledByJason;

var float LastTeslaChainTime;
var int TeslaChainedPlayers;
var ScrnPlayerInfo TeslaChainedP1, TeslaChainedP2;

var int iDoT_Damage;

var bool bNoHeadshots, bAllCanDoHeadshots;

function PlayerDamaged(int Damage, ScrnPlayerInfo VictimSPI, KFMonster InstigatedBy, class<DamageType> DamType)
{
    bPerfectWave = false;

    if ( InstigatedBy != none && InstigatedBy.IsA('TeslaHusk') && GetItemName(string(DamType)) == "DamTypeTesla" ) {
        if ( LastTeslaChainTime == Level.TimeSeconds) {
            TeslaChainedPlayers++;
            switch ( TeslaChainedPlayers ) {
                case 2:
                    TeslaChainedP2 = VictimSPI; // remember player, but need at least 1 more to get ach
                    break;
                case 3:
                    // give ach to first 3 chained players
                    TeslaChainedP1.ProgressAchievement('TeslaChain', 1);
                    TeslaChainedP2.ProgressAchievement('TeslaChain', 1);
                    VictimSPI.ProgressAchievement('TeslaChain', 1);
                    break;
                default:
                    VictimSPI.ProgressAchievement('TeslaChain', 1);  // previously chained players already have this ach

            }
        }
        else {
            LastTeslaChainTime = Level.TimeSeconds;
            TeslaChainedP1 = VictimSPI;
            TeslaChainedP2 = none;
            TeslaChainedPlayers = 1;
        }
    }
}


function PlayerDied(ScrnPlayerInfo DeadPlayerInfo, Controller Killer, class<DamageType> DamType)
{
    bPerfectGame = false;

    if ( DeadPlayerInfo.Deaths >= GameRules.Mut.KF.FinalWave * 0.8 )
        Ach2All('Kenny', 1);

    if ( Killer != none && Killer.Pawn != none && Killer.Pawn.IsA('ZombieJason') )
        PlayersKilledByJason++;

    if ( DeadPlayerInfo.PlayerOwner.PlayerReplicationInfo.Score >= 1000
            && DeadPlayerInfo.PlayerOwner.PlayerReplicationInfo.Score > AverageScore() * 3 ) {
        Ach2Alive('LuxuryFuneral', 1, DeadPlayerInfo);
        DeadPlayerInfo.PlayerOwner.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnFakedAchMsg', 2);
    }

}

function int AverageScore()
{
    local ScrnPlayerInfo SPI;
    local int TotalScore, PlayerCount;

    for ( SPI=GameRules.PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        if ( SPI.PlayerOwner != none && SPI.PlayerOwner.PlayerReplicationInfo != none ) {
            PlayerCount++;
            TotalScore += SPI.PlayerOwner.PlayerReplicationInfo.Score;
        }
    }
    if ( PlayerCount == 0 )
        return 0; // tbs, shouldn't happen

    return TotalScore / PlayerCount;
}

function bool HasGoodWeapon(Pawn Pawn)
{
    local Inventory Inv;
    local KFWeapon Weap;

    for ( Inv = Pawn.Inventory; Inv != none; Inv = Inv.Inventory ) {
        Weap = KFWeapon(Inv);
        if ( Weap != none ) {
            if ( Weap.bIsTier3Weapon || Crossbow(Weap) != none || Weap.SellValue >= 450 )
                return true;
        }
    }
    return false;
}



function WaveStarted(byte WaveNum)
{
    local int i;
    local ScrnPlayerInfo SPI;
    local class<ScrnVeterancyTypes> Perk;
    local array< class<ScrnVeterancyTypes> > UsedPerks;
    local int TotalPlayers;

    PlayersKilledByJason = 0;

    for ( SPI=GameRules.PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        TotalPlayers++;
        if ( SPI.PlayerOwner.PlayerReplicationInfo.Score >= 10000 )
            SPI.ProgressAchievement('Money10k', 1);

        if ( bOnePlayerPerPerk || bAllSamePerk ) {
            if ( KFPlayerReplicationInfo(SPI.PlayerOwner.PlayerReplicationInfo) != none )
                Perk = class<ScrnVeterancyTypes>( KFPlayerReplicationInfo(SPI.PlayerOwner.PlayerReplicationInfo).ClientVeteranSkill );

            if ( Perk == none ) {
                bOnePlayerPerPerk = false; // no perk = no balance
                bAllSamePerk = false;
            }
            else {
                if ( bAllSamePerk ) {
                    if ( SamePerk == none )
                        SamePerk = Perk;
                    else if ( SamePerk.default.SamePerkAch != Perk.default.SamePerkAch )
                        bAllSamePerk = false;
                }
                for ( i = 0; i < UsedPerks.length; ++i ) {
                    if ( UsedPerks[i] == Perk ) {
                        bOnePlayerPerPerk = false;
                        break;
                    }
                }
                if ( bOnePlayerPerPerk )
                    UsedPerks[i] = Perk;
            }
        }
    }

    if ( WaveNum == 0 ) {
        // game started
        bPerfectGame = true;
    }
    else {
        bPerfectGame = bPerfectGame && TotalPlayers >= 2; // each wave must have 2+ players for perfect game
        bPerfectWave = WaveNum > 0; // can't score perfect wave in wave 1
    }
}

function WaveEnded(byte WaveNum)
{
    local ScrnPlayerInfo SPI, OnlyHealerSPI, LastAliveSPI, TopKillsSPI;
    local bool bCheckOnlyHealed;
    local int TotalPlayers, AlivePlayers;
    local int i;
    local bool bAsh;
    local int ChainsawKills, BoomstickKills, M4Kills, MinKills, MaxKills, SecondPlaceKills;

    bCheckOnlyHealed = true;
    MinKills = 0x7FFFFFFF; // max int
    for ( SPI=GameRules.PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        if ( SPI.PlayerOwner == none )
            continue; // player disconnected

        TotalPlayers++;
        if ( !SPI.bDied ) {
            LastAliveSPI = SPI;
            AlivePlayers++;
            if ( ScrnPlayerController(SPI.PlayerOwner) != none ) {
                if ( ScrnPlayerController(SPI.PlayerOwner).bCowboyForWave )
                    SPI.ProgressAchievement('TrueCowboy', 1);
            }
        }

        if ( bCheckOnlyHealed && SPI.HealedPointsInWave > 0 ) {
            if ( OnlyHealerSPI != none || SPI.HealedPointsInWave < 200 ) {
                OnlyHealerSPI = none;
                bCheckOnlyHealed = false;
            }
            else
                OnlyHealerSPI = SPI;
        }

        if ( SPI.DecapsPerWave >= 30 && SPI.GetAccuracyWave() >= 0.75 )
            SPI.ProgressAchievement('Accuracy', 1);
        if ( WaveNum == 9 && SPI.DecapsPerWave >= 30 && SPI.GetAccuracyWave() >= 0.10 )
            SPI.ProgressAchievement('KFG2', 1);

        if ( SPI.KillsPerWave < MinKills )
            MinKills = SPI.KillsPerWave;
        if ( SPI.KillsPerWave > MaxKills ) {
            TopKillsSPI = SPI;
            SecondPlaceKills = MaxKills;
            MaxKills = SPI.KillsPerWave;
        }
        else if ( SPI.KillsPerWave > SecondPlaceKills )
            SecondPlaceKills = SPI.KillsPerWave;

        bAsh = true;
        ChainsawKills = 0;
        BoomstickKills = 0;
        M4Kills = 0;
        for ( i=0; i<SPI.WeapInfos.length; ++i ) {
            if ( bAsh ) {
                if ( ClassIsChildOf(SPI.WeapInfos[i].DamType, Class'DamTypeDBShotgun') )
                    BoomstickKills += SPI.WeapInfos[i].KillsPerWave;
                else if ( ClassIsChildOf(SPI.WeapInfos[i].DamType, Class'DamTypeChainsaw') )
                    ChainsawKills += SPI.WeapInfos[i].KillsPerWave;
                else if ( SPI.WeapInfos[i].KillsPerWave > 0 )
                    bAsh = false;
            }
            if ( ClassIsChildOf(SPI.WeapInfos[i].DamType, Class'ScrnDamTypeM4AssaultRifle')
                || ClassIsChildOf(SPI.WeapInfos[i].DamType, Class'DamTypeM203Grenade')
                || ClassIsChildOf(SPI.WeapInfos[i].DamType, Class'ScrnDamTypeM4203M') )
            {
                M4Kills += SPI.WeapInfos[i].KillsPerWave;
            }
        }
        if ( bAsh && ChainsawKills >= 10 && BoomstickKills >= 10 && ChainsawKills + BoomstickKills >= 40 )
            SPI.ProgressAchievement('Ash', 1);
        else if ( M4Kills >= 40 )
            SPI.ProgressAchievement('M4203Kill50Zeds', 1);

    }

    if ( OnlyHealerSPI != none && TotalPlayers >= 4 )
        OnlyHealerSPI.ProgressAchievement('OnlyHealer', 1);
    if ( AlivePlayers == 1 && TotalPlayers >= 4) {
        LastAliveSPI.ProgressAchievement('ThinIcePirouette', 1);
        KFSteamStatsAndAchievements(SPI.PlayerOwner.SteamStatsAndAchievements).AddOnlySurvivorOfWave();
    }

    if ( TotalPlayers >= 3 && MinKills > max(1, MaxKills * 0.9) )
        Ach2All('NoI', 1);
    if ( TotalPlayers >= 5 && MaxKills > SecondPlaceKills * 2.5 )
        TopKillsSPI.ProgressAchievement('KillWhore', 1);

    if ( bPerfectWave )
        Ach2Alive('PerfectWave', 1);

    if ( PlayersKilledByJason >= 3 )
        Ach2Alive('Friday13', 1);
}

function GameWon(string MapName)
{
    local ScrnPlayerInfo SPI;
    local ScrnPlayerController ScrnPC;
    local TeamInfo WinnerTeam;
    local int PlayerCount;

    WinnerTeam = TeamInfo(Level.GRI.Winner);
    PlayerCount = GameRules.PlayerCountInWave();

    if ( bOnePlayerPerPerk && PlayerCount >= 6 )
        Ach2All('PerfectBalance', 1);
    if ( bNoHeadshots && PlayerCount >= 2 )
        Ach2All('TW_NoHeadshots', 1, none, WinnerTeam);
    if ( bAllCanDoHeadshots && PlayerCount >= 2 )
        Ach2All('TW_SkullCrackers', 1, none, WinnerTeam);

    if ( !GameRules.Mut.bTSCGame ) {
        // boss-related achievements
        if (GameRules.bSuperPat)
            Ach2All('KillSuperPat', 1);
        if ( bBossPrey && Level.TimeSeconds - BossSpawnTime <= 120 )
            Ach2All('PatPrey', 1);
        if (bBossXbowOnly)
            Ach2All('MerryMen', 1);
        else if (bBossM99Only)
            Ach2All('MerryMen50cal', 1);
        else if (bBossMeleeOnly)
            Ach2All('PatMelee', 1);
        else if (bBoss9mmOnly)
            Ach2All('Pat9mm', 1);

        if ( bAllSamePerk && SamePerk != none && PlayerCount >= 3 )
            Ach2All( SamePerk.default.SamePerkAch, 1, none, WinnerTeam );
    }


    for ( SPI=GameRules.PlayerInfo; SPI!=none; SPI=SPI.NextPlayerInfo ) {
        ScrnPC = ScrnPlayerController(SPI.PlayerOwner);
        if ( ScrnPC != none ) {
            if ( SPI.Deaths == 0 && SPI.StartWave <= 1 && !ScrnPC.bHadArmor )
                SPI.ProgressAchievement('BallsOfSteel', 1);
        }
        if ( SPI.StartWave == 0 && !GameRules.Mut.bTSCGame ) {
            if ( bPerfectGame )
                SPI.ProgressAchievement('PerfectGame', 1);

            if ( GameRules.Mut.KF.ShopList.Length >= 3 && Level.Game.GameReplicationInfo.ElapsedTime <= 2700 ) {
                SPI.ProgressAchievement('SpeedrunBronze', 1);
                if ( Level.Game.GameReplicationInfo.ElapsedTime <= 2400) {
                    SPI.ProgressAchievement('SpeedrunSilver', 1);
                    if ( Level.Game.GameReplicationInfo.ElapsedTime <= 1980) {
                        SPI.ProgressAchievement('SpeedrunGold', 1);
                    }
                }
            }
        }
    }
}

function BossSpawned(KFMonster EndGameBoss)
{
    if ( ZombieBoss(EndGameBoss) != none ) {
        bBossXbowOnly = true;
        bBossM99Only = true;
        bBossMeleeOnly = true;

        bBossPrey = true;
    }
    bBoss9mmOnly = true; // avaliable for other bosses as well, e.g. Doom3 bosses
    BossSpawnTime = Level.TimeSeconds;
}

function int RowHeadhots(ScrnPlayerInfo SPI, int Count)
{
    if ( Count >= 5 && SPI.LastDamage > 40 )
        SPI.ProgressAchievement('Impressive', 1); // 5 and subsequent headshots in a row (5,6,7...)
    return 5;
}

function int WRowHeadhots(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count)
{
    if ( ClassIsChildOf(DamType, class'DamTypeM14EBR') ) {
        if ( Count < 25)
            return 25; // need 25 headshots for the achievement
        // if achiemvent is earned - no need to track stat anymore, so return IGNORE_STAT
        SPI.ProgressAchievement('DotOfDoom', 1);
    }
    else if ( ClassIsChildOf(DamType, class'DamTypeSPSniper') ) {
        // Achievement has progress > 1, so need always need to return required value.
        // Function will be called on 15, 16, 17 etc. headshots in a row and there is no way to
        // reset it. But achievement can be earned only every 15 headshots (15, 30, 45 etc).
        if ( Count >= 10 && Count % 10 == 0) {
            if ( !SPI.ProgressAchievement('SteampunkSniper', 1) )
                return IGNORE_STAT; // if achievement already earned, then ProgressAchievement() returns false, meaning no need to track it anymore
        }
        return 10; // need 10 headshots for the achievement
    }
    return IGNORE_STAT;
}

function int WKillsPerShot(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count, float DeltaTime)
{
    if ( DamType.default.bIsExplosive ) {
        if ( !ClassIsChildOf(DamType, class'KFMod.DamTypePipeBomb') ) {
            if ( Count >= 10 && Count % 10 == 0) {
                if ( !SPI.ProgressAchievement('RocketBlow', 1) )
                    return IGNORE_STAT; // if achievement already earned, then ProgressAchievement() returns false, meaning no need to track it anymore
            }
            return 10;
        }
    }
    else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeSPThompson')
                || ClassIsChildOf(DamType, class'KFMod.DamTypeThompsonDrum') )
    {
        if ( Count >= 5 ) { // count 5,6,7 etc.
            if ( !SPI.ProgressAchievement('OldGangster', 1) )
                return IGNORE_STAT; // if achievement already earned, then ProgressAchievement() returns false, meaning no need to track it anymore
        }
        return 5; // need 5 kills for the achievement
    }
    else if ( ClassIsChildOf(DamType, class'ScrnBalanceSrv.ScrnDamTypeHuskGun_Alt') ) {
        if ( Count < 20)
            return 20;
        SPI.ProgressAchievement('NapalmStrike', 1);
    }
    else if ( ClassIsChildOf(DamType, class'ScrnBalanceSrv.ScrnDamTypeDualies') ) {
        if ( Count < 8 )
            return 8;
        SPI.ProgressAchievement('MadCowboy', 1);
    }

    return IGNORE_STAT;
}

function int WDecapsPerShot(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count, float DeltaTime)
{
    if ( ClassIsChildOf(DamType, class'ScrnBalanceSrv.ScrnDamTypeDualies') ) {
        if ( Count < 8 )
            return 8;
        SPI.ProgressAchievement('MadCowboy', 1);
    }

    return IGNORE_STAT;
}

function int WKillsPerMagazine(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count)
{
    if ( ClassIsChildOf(DamType, class'ScrnBalanceSrv.ScrnDamTypeM4203M') ) {
        if ( Count < 15)
            return 15; // need 15 kills for the achievement
        // if achievement is earned - no need to track stat anymore, so return IGNORE_STAT
        SPI.ProgressAchievement('MedicOfDoom', 1);
    }
    else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeDual44Magnum') ) {
        // DamTypeDual44Magnum is a subclass of DamTypeMagnum44Pistol, so it must be checked first
        if ( Count < 18)
            return 18;
        SPI.ProgressAchievement('Magnum12Kills', 1);
    }
    else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeMagnum44Pistol') ) {
        if ( Count < 12)
            return 12;
        SPI.ProgressAchievement('Magnum12Kills', 1);
    }
    else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeDualMK23Pistol') ) {
        // DamTypeDualMK23Pistol is a subclass of DamTypeMK23Pistol, so it must be checked first
        if ( Count < 24)
            return 24;
        SPI.ProgressAchievement('MK23_12Kills', 1);
    }
    else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeMK23Pistol') ) {
        if ( Count < 12)
            return 12;
        SPI.ProgressAchievement('MK23_12Kills', 1);
    }

    return IGNORE_STAT;
}

function int WDecapsPerMagazine(ScrnPlayerInfo SPI, KFWeapon Weapon, class<KFWeaponDamageType> DamType, int Count)
{
    if ( ClassIsChildOf(DamType, class'KFMod.DamTypeDual44Magnum') ) {
        // DamTypeDual44Magnum is a subclass of DamTypeMagnum44Pistol, so it must be checked first
        if ( Count < 18)
            return 18;
        SPI.ProgressAchievement('Magnum12Kills', 1);
    }
    else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeMagnum44Pistol') ) {
        if ( Count < 12)
            return 12;
        SPI.ProgressAchievement('Magnum12Kills', 1);
    }
    else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeDualMK23Pistol') ) {
        // DamTypeDualMK23Pistol is a subclass of DamTypeMK23Pistol, so it must be checked first
        if ( Count < 24)
            return 24;
        SPI.ProgressAchievement('MK23_12Kills', 1);
    }
    else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeMK23Pistol') ) {
        if ( Count < 12)
            return 12;
        SPI.ProgressAchievement('MK23_12Kills', 1);
    }

    return IGNORE_STAT;
}



function MonsterDamaged(int Damage, KFMonster Victim, ScrnPlayerInfo InstigatorInfo,
    class<KFWeaponDamageType> DamType, bool bIsHeadshot, bool bWasDecapitated)
{
    local int index, TotalDamage, df;
    local KFMonsterController MC;

    if ( Victim.Health <= 0 || Victim.IsInState('ZombieDying') )
        return; // don't track damages done to dead bodies

    MC = KFMonsterController(Victim.Controller);
    if ( MC == none )
        return; // wtf?

    bNoHeadshots = bNoHeadshots && !bIsHeadshot;
    bAllCanDoHeadshots = bAllCanDoHeadshots && DamType.default.bCheckForHeadShots;

    index = GameRules.GetMonsterIndex(Victim);

    if ( Damage >= iDoT_Damage && ClassIsChildOf(DamType, class'DamTypeFlareRevolver') ) {
        InstigatorInfo.ProgressAchievement('iDoT', 1);
    }
    else if ( DamType.default.bIsMeleeDamage ) {
        if ( Victim.bBackstabbed )
            InstigatorInfo.ProgressAchievement('MeleeHitBehind', 1);
    }
    else if ( bIsHeadshot && ClassIsChildOf(DamType, class'KFMod.DamTypeDeagle') )
        InstigatorInfo.SetCustomFloat(self, 'LastDeagleHSTime', Level.TimeSeconds);



    if ( ZombieCrawler(Victim) != none ) {
        if ( !Victim.bDamagedAPlayer && DamType.default.bIsMeleeDamage && !ClassIsChildOf(DamType, class'DamTypeCrossbuzzsaw') ) {
            if ( Damage >= Victim.Health )
                InstigatorInfo.ProgressAchievement('MeleeKillCrawlers', 1);
            if ( Victim.Physics == PHYS_Falling ) {
                if ( Damage >= Victim.Health && ClassIsChildOf(DamType, class'KFMod.DamTypeMachete') )
                    InstigatorInfo.ProgressAchievement('MacheteKillMidairCrawler', 1);
                InstigatorInfo.ProgressAchievement('MeleeKillMidairCrawlers', 1);
            }
        }
    }
    else if ( Victim.IsA('ZombieShiver') ) {
        // TeamWork: TeamWork: Grilled Shiver Brains
        // KillAss1 must be set Shiver on fire
        // KillAss2 must decapitate Shiver with commando weapon
        if ( !Victim.bDecapitated && DamType.default.bDealBurningDamage ) {
            if ( GameRules.MonsterInfos[index].DamType1 == none ) {
                GameRules.MonsterInfos[index].KillAss1 = InstigatorInfo;
                GameRules.MonsterInfos[index].DamType1 = DamType;
                GameRules.MonsterInfos[index].DamTime1 = Level.TimeSeconds;
            }
        }
        else if ( Victim.bDecapitated && !bWasDecapitated ) {
            if ( GameRules.MonsterInfos[index].KillAss1 != none && IsAssaultRifleDamage(InstigatorInfo, DamType) ) {
                GameRules.MonsterInfos[index].KillAss2 = InstigatorInfo;
                GameRules.MonsterInfos[index].DamType2 = DamType;
                GameRules.MonsterInfos[index].DamTime2 = Level.TimeSeconds;
                GameRules.MonsterInfos[index].DamageFlags2 = GameRules.DF_DECAP;
            }
            else
                GameRules.MonsterInfos[index].TW_Ach_Failed = true;
        }
    }
    else if ( ZombieStalker(Victim) != none ) {
        if ( Victim.IsA('ZombieGhost') ) {
            if ( bIsHeadshot && Victim.bDecapitated && !bWasDecapitated ) {
                if ( VSizeSquared(Victim.Location - InstigatorInfo.PlayerOwner.Pawn.Location) > 1000000 )
                    InstigatorInfo.ProgressAchievement('GhostSmell', 1);
            }
        }
    }
    else if ( ZombieBloat(Victim) != none ) {
        if ( Victim.bDecapitated && !bWasDecapitated
                && DamType.default.bIsMeleeDamage && !ClassIsChildOf(DamType, class'DamTypeCrossbuzzsaw')
                && !Victim.bDamagedAPlayer && KFPawn(InstigatorInfo.PlayerOwner.Pawn).BileCount <= 0 )
        {
            InstigatorInfo.ProgressAchievement('MeleeDecapBloats', 1);
        }
    }
    else if ( ZombieSiren(Victim) != none ) {
        // TeamWork: No Big Guns on Skinny Bitches
        // Any damage made with pistols or assault rifles counts as assistance.
        // Other damages break the achievement (if deal significant damage).
        if ( !GameRules.MonsterInfos[index].TW_Ach_Failed ) {
            if ( IsPistolDamage(InstigatorInfo, DamType) || IsAssaultRifleDamage(InstigatorInfo, DamType) ) {
                if ( GameRules.MonsterInfos[index].DamType1 == none ) {
                    GameRules.MonsterInfos[index].KillAss1 = InstigatorInfo;
                    GameRules.MonsterInfos[index].DamType1 = DamType;
                    GameRules.MonsterInfos[index].DamTime1 = Level.TimeSeconds;
                }
                else if ( GameRules.MonsterInfos[index].KillAss1 != InstigatorInfo && GameRules.MonsterInfos[index].DamType2 == none ) {
                    GameRules.MonsterInfos[index].KillAss2 = InstigatorInfo;
                    GameRules.MonsterInfos[index].DamType2 = DamType;
                    GameRules.MonsterInfos[index].DamTime2 = Level.TimeSeconds;
                }
            }
            else if ( Damage > 50 || GetTotalDamageMadeC(MC, InstigatorInfo.PlayerOwner) > 100 )
                GameRules.MonsterInfos[index].TW_Ach_Failed = true;
        }
    }
    else if ( ZombieHusk(Victim) != none ) {
        if (  Victim.bDecapitated && !bWasDecapitated && Damage < Victim.Health && Victim.IsA('TeslaHusk') ) {
            GameRules.MonsterInfos[index].KillAss1 = InstigatorInfo;
            GameRules.MonsterInfos[index].DamType1 = DamType;
            GameRules.MonsterInfos[index].DamTime1 = Level.TimeSeconds;
            GameRules.MonsterInfos[index].DamageFlags1 = DF_DECAP;
        }
        else if ( !Victim.bDecapitated && Damage < Victim.Health
                && (Damage > Victim.default.Health/1.5
                    || (Damage > 200 && !Victim.IsA('TeslaHusk')
                        && ( ClassIsChildOf(DamType, class'DamTypeCrossbow')
                            || ClassIsChildOf(DamType, class'DamTypeWinchester')
                            || ClassIsChildOf(DamType, class'DamTypeM14EBR')))) )
        {
            // track only stun damage
            if ( GameRules.MonsterInfos[index].DamType1 == none ) {
                GameRules.MonsterInfos[index].KillAss1 = InstigatorInfo;
                GameRules.MonsterInfos[index].DamType1 = DamType;
                GameRules.MonsterInfos[index].DamTime1 = Level.TimeSeconds;
                GameRules.MonsterInfos[index].DamageFlags1 = DF_STUNNED;
            }
        }
    }
    else if ( ZombieScrake(Victim) != none || Victim.IsA('ZombieJason') ) {
        if ( !Victim.bDecapitated && Damage < Victim.Health && !GameRules.MonsterInfos[index].TW_Ach_Failed ) {
            if ( ClassIsChildOf(GameRules.MonsterInfos[index].DamType1, class'KFMod.DamTypeLAW') ) {
                if ( (ClassIsChildOf(DamType, class'ScrnDamTypeHeavyBase')
                            || DamType == class'KFMod.DamTypeDBShotgun'
                            || DamType == class'KFMod.DamTypeBenelli')
                        && !ClassIsChildOf(GameRules.MonsterInfos[index].DamType2, class'ScrnDamTypeHeavyBase')
                        && GameRules.MonsterInfos[index].DamType2 != class'KFMod.DamTypeDBShotgun'
                        && GameRules.MonsterInfos[index].DamType2 != class'KFMod.DamTypeBenelli' ) {
                    GameRules.MonsterInfos[index].KillAss2 = InstigatorInfo;
                    GameRules.MonsterInfos[index].DamType2 = DamType;
                    GameRules.MonsterInfos[index].DamTime2 = Level.TimeSeconds;
                    GameRules.MonsterInfos[index].DamageFlags2 = 0;
                }
            }
            else if ( Damage >= Victim.default.Health/1.5 ) {
                if ( DamType.default.bIsMeleeDamage && ClassIsChildOf(DamType, class'KFMod.DamTypeMachete') )
                    InstigatorInfo.ProgressAchievement('MacheteStunSC', 1);

                // STUN DAMAGE
                if ( GameRules.MonsterInfos[index].DamType1 == none ) {
                    GameRules.MonsterInfos[index].KillAss1 = InstigatorInfo;
                    GameRules.MonsterInfos[index].DamType1 = DamType;
                    GameRules.MonsterInfos[index].DamTime1 = Level.TimeSeconds;
                    GameRules.MonsterInfos[index].DamageFlags1 = DF_STUNNED;
                    if ( bIsHeadshot )
                        GameRules.MonsterInfos[index].DamageFlags1 = GameRules.MonsterInfos[index].DamageFlags1 | DF_HEADSHOT;
                }
                else if ( GameRules.MonsterInfos[index].DamType1.default.bSniperWeapon ) {
                    // Instant Kill can be achieved by 3 snipers, if they all had shot in the same time
                    if ( DamType.default.bSniperWeapon && bIsHeadshot && Level.TimeSeconds < GameRules.MonsterInfos[index].FirstHitTime + InstantKillTime ) {
                        GameRules.MonsterInfos[index].KillAss2 = InstigatorInfo;
                        GameRules.MonsterInfos[index].DamType2 = DamType;
                        GameRules.MonsterInfos[index].DamageFlags2 = DF_STUNNED | DF_HEADSHOT;
                    }
                    else
                        GameRules.MonsterInfos[index].TW_Ach_Failed = true;
                }
            }
        }
    }
    else if ( ZombieFleshpound(Victim) != none ) {
        if ( Victim.bDecapitated && !bWasDecapitated && ClassIsChildOf(DamType, class'DamTypeAxe') )
            InstigatorInfo.ProgressAchievement('OldSchoolKiting', 1);
        // both TW FP achievements requires first rage shot to be from heavy sniper rifgle: Xbow, M99, HR or 2xSVD
        // Pipe achievement also requires it to be a rage shot.
        // M14 ach allows to shoot already raged FP.
        if ( !Victim.bDecapitated && Damage < Victim.Health && !GameRules.MonsterInfos[index].TW_Ach_Failed ) {
            if ( bIsHeadshot && Damage >= 600 ) {
                df = DF_HEADSHOT;
                // FP can't be stunned, but DF_STUNNED flag is used to differ heavy headshots from other damages
                if ( Damage >= 800 )
                    df = df | DF_STUNNED;

                if ( GameRules.MonsterInfos[index].DamType1 == none ) {
                    GameRules.MonsterInfos[index].KillAss1 = InstigatorInfo;
                    GameRules.MonsterInfos[index].DamType1 = DamType;
                    GameRules.MonsterInfos[index].DamTime1 = Level.TimeSeconds;
                    if ( !ZombieFleshpound(Victim).bChargingPlayer && !ZombieFleshpound(Victim).bFrustrated )
                        df = df | DF_RAGED;
                    GameRules.MonsterInfos[index].DamageFlags1 = df;
                }
                else if ( GameRules.MonsterInfos[index].KillAss1 == InstigatorInfo ) {
                    GameRules.MonsterInfos[index].DamageFlags1 = GameRules.MonsterInfos[index].DamageFlags1 | DF_STUNNED; // in case of 2xSVD
                }
                else if ( GameRules.MonsterInfos[index].KillAss2 == InstigatorInfo ) {
                    GameRules.MonsterInfos[index].DamageFlags2 = GameRules.MonsterInfos[index].DamageFlags2 | DF_STUNNED; // in case of 2xSVD
                }
                else if ( (GameRules.MonsterInfos[index].DamageFlags2 & DF_STUNNED) == 0 ) {
                    // heavy headshots always override other assistances (which don't have DF_STUNNED flag)
                    GameRules.MonsterInfos[index].KillAss2 = InstigatorInfo;
                    GameRules.MonsterInfos[index].DamType2 = DamType;
                    GameRules.MonsterInfos[index].DamTime2 = Level.TimeSeconds;
                    GameRules.MonsterInfos[index].DamageFlags2 = df;
                }
            }
            else if ( GameRules.MonsterInfos[index].DamType1 == none ) {
                // raging FP with other weapons fails TW achievements
                if ( ZombieFleshpound(Victim).bChargingPlayer || ZombieFleshpound(Victim).bFrustrated
                        || Damage + ZombieFleshpound(Victim).TwoSecondDamageTotal > ZombieFleshpound(Victim).RageDamageThreshold )
                    GameRules.MonsterInfos[index].TW_Ach_Failed = true;
            }
            else if ( DamType.Default.bSniperWeapon ) {
                if ( bIsHeadshot && GameRules.MonsterInfos[index].DamType2 == none && Damage >= 200 ) {
                    GameRules.MonsterInfos[index].KillAss2 = InstigatorInfo;
                    GameRules.MonsterInfos[index].DamType2 = DamType;
                    GameRules.MonsterInfos[index].DamTime2 = Level.TimeSeconds;
                    GameRules.MonsterInfos[index].DamageFlags2 = DF_HEADSHOT;
                }
            }
            else {
                TotalDamage = GetTotalDamageMadeC(MC, InstigatorInfo.PlayerOwner);
                if ( TotalDamage > Victim.HealthMax * 0.5 )
                    GameRules.MonsterInfos[index].TW_Ach_Failed = true; // why need teamwork, if this player just spams at FP?
                else if ( GameRules.MonsterInfos[index].DamType2 == none && TotalDamage > Victim.HealthMax * 0.1 ) {
                    GameRules.MonsterInfos[index].KillAss2 = InstigatorInfo;
                    GameRules.MonsterInfos[index].DamType2 = DamType;
                    GameRules.MonsterInfos[index].DamTime2 = Level.TimeSeconds;
                    GameRules.MonsterInfos[index].DamageFlags2 = 0;
                }
            }
        }
    }
    else if ( GameRules.BossClass == Victim.class ) {
        bBossM99Only = bBossM99Only && ClassIsChildOf(DamType, class'DamTypeM99SniperRifle');
        bBossXbowOnly = bBossXbowOnly && ClassIsChildOf(DamType, class'DamTypeCrossbow');
        bBossMeleeOnly = bBossMeleeOnly && DamType.default.bIsMeleeDamage && !ClassIsChildOf(DamType, class'DamTypeCrossbuzzsaw');
        bBoss9mmOnly = bBoss9mmOnly && ClassIsChildOf(DamType, class'DamTypeDualies');
        BossLastDamageTime = Level.TimeSeconds;
    }

    //
    if ( bBossPrey && GameRules.BossClass != Victim.class ) {
        // to get "Hunting The Prey" achievements players must follow Pat all the time without
        // focusing on other zeds. However, players are allowed to damage/kill other zeds too, if
        // players are attacking the Pat at that moment. If Pat ran away, but players are killing
        // other zeds, then ach is failed
        if ( Level.TimeSeconds > BossLastDamageTime + 5.0 )
            bBossPrey = false;
    }

}

function MonsterKilled(KFMonster Victim, ScrnPlayerInfo KillerInfo, class<KFWeaponDamageType> DamType)
{
    local int index;
    local ScrnHumanPawn KillerInfoPawn;
    local KFPlayerReplicationInfo KFPRI;
    local int PipeBombsAround;
    local int w_idx; // current KillerInfo.WeaponInfos index
    local KFMonsterController MC;
    local KFWeapon Weapon;
    local ScrnPlayerInfo AssSPI; // Ass for Assistant ;)


    KillerInfoPawn = ScrnHumanPawn(KillerInfo.PlayerOwner.Pawn);
    KFPRI = KFPlayerReplicationInfo(KillerInfo.PlayerOwner.PlayerReplicationInfo);
    Weapon = KillerInfo.FindWeaponByDamType(DamType);
    w_idx = KillerInfo.FindWeaponInfoByDamType(DamType);
    index = GameRules.GetMonsterIndex(Victim);
    MC = KFMonsterController(Victim.Controller);
    if ( MC == none )
        return; // wtf?


    KillerInfo.ProgressAchievement('Kill1000Zeds', 1); //kill counter, incs all 3 achievements

    if ( Level.TimeSeconds < KillerInfo.LastKillTime + 5.0 ) {
        if ( !DamType.default.bIsMeleeDamage && !DamType.default.bIsExplosive && !DamType.default.bDealBurningDamage
                && KillerInfo.IncCustomValue(self, 'KillsBetween5s', 1) == 30 )
            KillerInfo.ProgressAchievement('OutOfTheGum', 1);
    }
    else
        KillerInfo.SetCustomValue(self, 'KillsBetween5s', 0);

    if ( GameRules.MonsterInfos[index].PlayerKillCounter > 0 && Level.TimeSeconds < GameRules.MonsterInfos[index].PlayerKillTime + 5 )
        KillerInfo.ProgressAchievement('FastVengeance', 1);

    // big zeds
    if ( Victim.default.Health >= 1000 ) {
        if ( ClassIsChildOf(DamType, class'KFMod.DamTypeLAW') )
            KillerInfo.ProgressAchievement('BringingLAW', 1);
        else if ( ClassIsChildOf(DamType, class'KFMod.DamTypePipeBomb') ) {
            // check if somebody is blocking it
            if ( Victim.LastDamageAmount >= 1300 && GameRules.MonsterInfos[index].PlayerKillCounter == 0
                    && GameRules.MonsterInfos[index].DamageCounter < 30 * Victim.DifficultyDamageModifer()
                    && GiveAchToBlockingPlayers(Victim, MC, 'TW_PipeBlock') > 0 )
                KillerInfo.ProgressAchievement('TW_PipeBlock', 1);
        }
        if ( !Victim.bDamagedAPlayer && GameRules.MonsterInfos[index].Headshots == 0 )
            KillerInfo.ProgressAchievement('NoHeadshots', 1);
    }

    if ( DamType.default.bIsMeleeDamage ) {
        if ( Victim.bCrispified )
            KillerInfo.ProgressAchievement('CarveRoast', 1);
        if ( ClassIsChildOf(DamType, class'KFMod.DamTypeScythe')
                || ClassIsChildOf(DamType, class'ScrnBalanceSrv.ScrnDamTypeScythe') )
            KillerInfo.ProgressAchievement('GrimReaper', 1);
    }
    else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeRocketImpact') ) {
        KillerInfo.ProgressAchievement('PrematureDetonation', 1);
    }

    if ( DamType.name == 'DamTypeEMP' ) {
        KillerInfo.ProgressAchievement('TeslaBomber', 1);
    }

    if ( KillerInfoPawn != none) {
        // don't give Combat Medic, if healed person is dead, healed himself, or was healed by another person later
        if ( KillerInfoPawn.IsMedic() && KillerInfoPawn.LastHealed != none && KillerInfoPawn.LastHealed !=KillerInfoPawn
                && KillerInfoPawn.LastHealed.Health > 0
                && KillerInfoPawn.LastHealed.LastHealedBy == KillerInfoPawn ) {
            // medic has 5 seconds to kill a target
            if ( (KillerInfoPawn.LastHealed.CombatMedicTarget == Victim || KillerInfoPawn.LastHealed.LastDamagedBy == Victim)
                    && level.TimeSeconds - KillerInfoPawn.LastHealed.LastHealTime < 5.0 )
                KillerInfo.ProgressAchievement('CombatMedic', 1);
        }
    }

    if ( w_idx != -1 ) {
        if ( KillerInfo.WeapInfos[w_idx].PrevOwner != none && KillerInfo.WeapInfos[w_idx].bPrevOwnerDead
                && KillerInfo.WeapInfos[w_idx].PickupWave == GameRules.Mut.KF.WaveNum )
        {
            AssSPI = GameRules.GetPlayerInfo(KillerInfo.WeapInfos[w_idx].PrevOwner);
            if ( AssSPI != none ) {
                KillerInfo.ProgressAchievement('Cookies', 1);
                if ( AssSPI.LastKilledBy == MC )
                    KillerInfo.ProgressAchievement('EyeForAnEye', 1);
            }
        }
    }

    if ( ZombieClot(Victim) == none )
        KillerInfo.SetCustomValue(self, 'RowClotKills', 0, false);

    if ( ZombieClot(Victim) != none ) {
        if ( KillerInfo.IncCustomValue(self, 'RowClotKills', 1, false) == 15 ) {
            KillerInfo.ProgressAchievement('ClotHater', 1);
            KillerInfo.SetCustomValue(self, 'RowClotKills', 0, false);
        }

        if ( Level.TimeSeconds < KillerInfo.GetCustomFloat(self, 'LastClotKillTime') + 4.0 ) {
            if ( KillerInfo.IncCustomValue(self, 'ClotKills4s', 1, true) == 25 )
                KillerInfo.ProgressAchievement('Plus25Clots', 1);
        }
        else
            KillerInfo.SetCustomValue(self, 'ClotKills4s', 0, true);
        KillerInfo.SetCustomFloat(self, 'LastClotKillTime', Level.TimeSeconds, true);
    }
    else if ( ZombieCrawler(Victim) != none ) {
        if ( Victim.LastDamageAmount < 80 && (DamType == class'DamTypeFlamethrower' || DamType == class'DamTypeBurned') )
            KillerInfo.ProgressAchievement('HFC', 1);
        else if ( IsPistolDamage(KillerInfo, DamType) ) {
            if ( GameRules.MonsterInfos[index].Headshots + GameRules.MonsterInfos[index].Bodyshots == 1 )
                KillerInfo.ProgressAchievement('Gunslingophobia', 1);
        }
        else if ( GameRules.MonsterInfos[index].bHeadshot ) {
            // Overkills
            if (  ClassIsChildOf(DamType, class'KFMod.DamTypeM99HeadShot') )
                KillerInfo.ProgressAchievement('Overkill', 1);
            else if ( Victim.LastDamageAmount > 6950 && ClassIsChildOf(DamType, class'KFMod.DamTypeHuskGunProjectileImpact') )
                KillerInfo.ProgressAchievement('Overkill1', 1);
            else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeLawRocketImpact') )
                KillerInfo.ProgressAchievement('Overkill2', 1);
        }
    }
    else if ( Victim.IsA('ZombieShiver') ) {
        // Firebug (KillAss1) ignites Shiver and makes him unable to teleport
        // Then Commando (KillAss2) - decapitates
        // KillerInfo doesn't get teamwork achievement (the one who killed decapitated body)
        if ( Victim.bDecapitated && !GameRules.MonsterInfos[index].TW_Ach_Failed ) {
            if ( GameRules.MonsterInfos[index].KillAss2 != none )
                GameRules.RewardTeamwork(none, index, 'TW_Shiver'); //KillerInfo took down already decapitated body, so no TW ach for him
            else if ( DamType.default.bCheckForHeadShots && IsAssaultRifleDamage(KillerInfo, DamType) )
                GameRules.RewardTeamwork(KillerInfo, index, 'TW_Shiver'); // Decapitation shot killed the Victim
        }
    }
    else if ( ZombieStalker(Victim) != none ) {
        if ( !Victim.bDamagedAPlayer && KFPRI != none && KFPRI.ClientVeteranSkill.static.ShowStalkers(KFPRI)
                && VSizeSquared(Victim.Location - KillerInfo.PlayerOwner.Pawn.Location)
                    < 360000 * KFPRI.ClientVeteranSkill.static.GetStalkerViewDistanceMulti(KFPRI) )
            KillerInfo.ProgressAchievement('Ghostbuster', 1);
    }
    else if ( ZombieBloat(Victim) != none ) {
        PipeBombsAround = InPipeBombRange(Victim, 600);
        if ( PipeBombsAround > 0 )
            KillerInfo.ProgressAchievement('SavingResources', 1);
    }
    else if ( ZombieSiren(Victim) != none ) {
        PipeBombsAround = InPipeBombRange(Victim, 250);
        if ( PipeBombsAround > 0 )
            KillerInfo.ProgressAchievement('SavingResources', 1);
        if ( !GameRules.MonsterInfos[index].TW_Ach_Failed )
            GameRules.RewardTeamwork(KillerInfo, index, 'TW_Siren');
    }
    else if ( ZombieHusk(Victim) != none ) {
        if ( ClassIsChildOf(DamType, class'DamTypeHuskGun') || ClassIsChildOf(DamType, class'DamTypeHuskGunProjectileImpact') )
            KillerInfo.ProgressAchievement('KillHuskHuskGun', 1);
        else if ( ClassIsChildOf(DamType, class'DamTypeCrossbowHeadShot') ) {
            if ( Level.TimeSeconds - KillerInfo.GetCustomFloat(self, 'LastDeagleHSTime') < 2.0 )
                KillerInfo.ProgressAchievement('KFG1', 1);
        }

        if ( !Victim.bDamagedAPlayer ) {
            // give Fast Shot achievement only if player killed Husk alone
            if ( GameRules.MonsterInfos[index].KillAss1 == KillerInfo )
                KillerInfo.ProgressAchievement('FastShot', 1);
            else if ( DamType.default.bIsPowerWeapon && GameRules.MonsterInfos[index].KillAss1 != none
                        && (GameRules.MonsterInfos[index].DamageFlags1 & DF_STUNNED) > 0 )
            {
                // finishing with shotgun after the stun
                GameRules.RewardTeamwork(KillerInfo, index, 'TW_Husk_Stun');
            }
        }
        else if ( KillerInfoPawn.LastDamagedBy == Victim && (DamType.default.bIsPowerWeapon || DamType.default.bIsMeleeDamage)
                  && Victim.IsA('TeslaHusk') )
        {
            KillerInfo.ProgressAchievement('NikolaTesla', 1);
        }
    }
    else if ( ZombieScrake(Victim) != none || Victim.IsA('ZombieJason') ) {
        if ( Victim.IsA('ZombieJason') && ClassIsChildOf(DamType, class'DamTypeMachete') )
            KillerInfo.ProgressAchievement('ComeatMe', 1);
        //scrake unnader
        if ( !Victim.bDamagedAPlayer && GameRules.MonsterInfos[index].DamType2 == class'KFMod.DamTypeFrag'
                && GameRules.MonsterInfos[index].DamageFlags2 == (DF_RAGED | DF_STUPID) )
            KillerInfo.ProgressAchievement('ScrakeUnnader', 1);

        if ( DamType.default.bSniperWeapon || ClassIsChildOf(DamType, class'KFMod.DamTypeCrossbuzzsawHeadShot') ) {
            KillerInfo.ProgressAchievement('Snipe250SC', 1);
            // Teamwork: InstantKill
            if ( GameRules.MonsterInfos[index].KillAss1 != KillerInfo
                    && GameRules.MonsterInfos[index].DamType1 != none && GameRules.MonsterInfos[index].DamType1.default.bSniperWeapon
                    && (GameRules.MonsterInfos[index].DamageFlags1 & DF_STUNNED) > 0
                    && Level.TimeSeconds - GameRules.MonsterInfos[index].FirstHitTime < InstantKillTime ) {
                GameRules.RewardTeamwork(KillerInfo, index, 'TW_SC_Instant');
            }
        }
        else if ( DamType.default.bIsPowerWeapon ) {
            if ( (ClassIsChildOf(DamType, class'ScrnDamTypeHeavyBase')
                        || DamType == class'KFMod.DamTypeDBShotgun'
                        || DamType == class'KFMod.DamTypeBenelli')
                    && GameRules.MonsterInfos[index].DamType1 != none && GameRules.MonsterInfos[index].DamType1.default.bIsExplosive
                    && ClassIsChildOf(GameRules.MonsterInfos[index].DamType1, class'KFMod.DamTypeLAW')
                    && (GameRules.MonsterInfos[index].DamageFlags1 & DF_STUNNED) > 0 )
            {
                // TeamWork: LAW Stun + HSg finish
                GameRules.RewardTeamwork(KillerInfo, index, 'TW_SC_LAWHSG');
            }
        }
        else if ( DamType.default.bIsMeleeDamage ) {
            if ( GameRules.MonsterInfos[index].BodyShots == 0 && !ClassIsChildOf(DamType, class'KFMod.DamTypeCrossbuzzsaw') )
                KillerInfo.ProgressAchievement('MeleeGod', 1);
            if ( ClassIsChildOf(DamType, class'KFMod.DamTypeChainsaw') )
                KillerInfo.ProgressAchievement('BitterIrony', 1);
            if ( !Victim.bDamagedAPlayer && GameRules.MonsterInfos[index].bWasBackstabbed )
                CheckAchBackstabAttract(Victim, KillerInfo);
        }
        else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeHuskGunProjectileImpact')
                || ClassIsChildOf(DamType, class'KFMod.DamTypeHuskGun') )
            KillerInfo.ProgressAchievement('HuskGunSC', 1);
        else if ( !Victim.bDamagedAPlayer && (ClassIsChildOf(DamType, class'ScrnDamTypeDualDeagle')
                || ClassIsChildOf(DamType, class'ScrnDamTypeDual44Magnum')) )
           KillerInfo.ProgressAchievement('GunslingerSC', 1);
    }
    else if ( ZombieFleshpound(Victim) != none ) {
        if ( DamType.default.bIsExplosive )
            KillerInfo.ProgressAchievement('Kill100FPExplosives', 1);
        else if ( DamType.default.bIsPowerWeapon) {
            if ( DamType == class'KFMod.DamTypeDBShotgun' || DamType == class'KFMod.DamTypeBenelli' )
                KillerInfo.ProgressAchievement('GetOffMyLawn', 1);
        }
        else if ( DamType.default.bIsMeleeDamage) {
            // if Victim is already decapitated, then OldSchoolKiting  is granted on decapitation
            if ( !Victim.bDecapitated && ClassIsChildOf(DamType, class'DamTypeAxe') )
                KillerInfo.ProgressAchievement('OldSchoolKiting', 1);
        }

        if ( (MC.KillAssistants.Length == 0 ||
                    (MC.KillAssistants.Length == 1 && MC.KillAssistants[0].PC == KillerInfo.PlayerOwner))
                && GameRules.AlivePlayerCount() >= 6 )
        {
            KillerInfo.ProgressAchievement('Unassisted', 1);
        }
        else {
            if ( GameRules.MonsterInfos[index].DamType1 != none ) {
                if ( DamType == class'KFMod.DamTypePipeBomb'
                        && (GameRules.MonsterInfos[index].DamageFlags1 & DF_RAGED) != 0 )
                    GameRules.RewardTeamwork(KillerInfo, index, 'TW_FP_Pipe');
                else if ( DamType.default.bSniperWeapon ) {
                    // ensure that second assistant used sniper headshots too
                    if ( (GameRules.MonsterInfos[index].DamageFlags2 & DF_HEADSHOT) == 0 )
                        GameRules.MonsterInfos[index].KillAss2 = none;
                    GameRules.RewardTeamwork(KillerInfo, index, 'TW_FP_Snipe');
                }
            }
        }
    }
    else if ( Victim.IsA('FemaleFP') ) {
        if ( DamType.default.bIsExplosive )
            KillerInfo.ProgressAchievement('Kill100FPExplosives', 1);
        else if ( DamType.default.bIsPowerWeapon) {
            if ( DamType == class'KFMod.DamTypeDBShotgun' || DamType == class'KFMod.DamTypeBenelli' )
                KillerInfo.ProgressAchievement('GetOffMyLawn', 1);
        }
    }
    else if ( Victim.IsA('ZombieBrute') ) {
        if ( DamType.default.bIsExplosive )
            KillerInfo.ProgressAchievement('BruteExplosive', 1);

        if ( !Victim.bDamagedAPlayer ) {
            if ( ClassIsChildOf(DamType, class'KFMod.DamTypeM14EBR') )
                KillerInfo.ProgressAchievement('BruteM14', 1);
            else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeM99HeadShot') || ClassIsChildOf(DamType, class'KFMod.DamTypeCrossbowHeadShot') )
                KillerInfo.ProgressAchievement('BruteXbow', 1);
            else if ( ClassIsChildOf(DamType, class'KFMod.DamTypeSCARMK17AssaultRifle') )
                KillerInfo.ProgressAchievement('BruteSCAR', 1);
        }
    }
}


/**
 * Gives achievement for all players who are blocking the Monster.
 * Player is blocking the Monster if:
 * a) he is 1 meter (50uu) or closer to the Monster's collision cylinder
 * b) he is Monster's current or previous enemy OR he is extremely close to the Monster and can see it
 * c) he is in line of sight of the Monster
 *
 * @param Monster enemy, who is supposed to be blocked
 * @param MC Monster's controller
 * @param AchID achievement ID to progress
 * @return number of players, who gained (or supposed to gain) achievement progress
 */
function int GiveAchToBlockingPlayers(KFMonster Monster, KFMonsterController MC, name AchID)
{
    local KFHumanPawn Pawn;
    local ScrnPlayerInfo SPI;
    local int c;

    if ( Monster == none || MC == none )
        return 0;

    foreach Monster.VisibleCollidingActors( class'KFHumanPawn', Pawn, Monster.CollisionRadius + 50, Monster.Location ) {
        if ( ((Pawn == MC.Enemy || Pawn == MC.VisibleEnemy  || Pawn == MC.OldEnemy)
                || (vsize(Pawn.Location - Monster.Location) < Monster.CollisionRadius + Pawn.CollisionRadius + 10
                    && Pawn.Controller.CanSee(Monster)))
                && mc.CanSee(Pawn) )
        {
            c++;
            SPI = GameRules.GetPlayerInfo(PlayerController(Pawn.Controller));
            if ( SPI != none )
                SPI.ProgressAchievement(AchID, 1);
        }
    }
    return c;
}

function private CheckAchBackstabAttract(KFMonster Monster, ScrnPlayerInfo KillerSPI)
{
    local KFPawn KFP;
    local ScrnPlayerInfo SPI;
    local int i;
    local KFMonsterController MC;
    local bool bGiveAch;
    local float Pawn2MonsterDistanceSquared, Killer2PawnDistanceSquared;

    MC = KFMonsterController(Monster.Controller);

    for ( i = 0; i < MC.KillAssistants.Length; ++i ) {
        if ( MC.KillAssistants[i].PC != none && MC.KillAssistants[i].PC != KillerSPI.PlayerOwner ) {
            KFP = KFPawn(MC.KillAssistants[i].PC.Pawn);
            // attractive pawn and killed must be on opposite sides of monsters, so distance between
            // monster and player must be smaller than distance between 2 players
            Pawn2MonsterDistanceSquared = VSizeSquared(Monster.Location - KFP.Location);
            Killer2PawnDistanceSquared = VSizeSquared(KillerSPI.PlayerOwner.Pawn.Location - KFP.Location);
            // attractive person and monster must be within 5m range and see each other
            // only God knows where Scrake is looking during stun animation, so don't use CanSee() here
            if ( KFP != none && Pawn2MonsterDistanceSquared < 62500 && Pawn2MonsterDistanceSquared < Killer2PawnDistanceSquared )
                    // && KFP.Controller.CanSee(Monster) && (MC.LineOfSightTo(KFP) || KillerSPI.PlayerOwner.LineOfSightTo(KF)) )
            {
                bGiveAch = true;
                SPI = GameRules.GetPlayerInfo(PlayerController(KFP.Controller));
                if ( SPI != none )
                    SPI.ProgressAchievement('TW_BackstabSC', 1);
            }
        }
    }
    if ( bGiveAch )
        KillerSPI.ProgressAchievement('TW_BackstabSC', 1);
}

function PickedCash(int CashAmount, ScrnPlayerInfo ReceiverInfo, ScrnPlayerInfo DonatorInfo, bool bDroppedCash)
{
    if ( bDroppedCash && DonatorInfo != none && DonatorInfo.PlayerOwner != none ) {
        if ( CashAmount == 1 && DonatorInfo.PlayerOwner.PlayerReplicationInfo.Score >=
                max(500, 10 * (ReceiverInfo.PlayerOwner.PlayerReplicationInfo.Score + ReceiverInfo.CashDonated)) )
            DonatorInfo.ProgressAchievement('SpareChange', 1);
        if ( DonatorInfo.CashDonated - DonatorInfo.CashReceived - DonatorInfo.CashFound >= 2000 )
            DonatorInfo.ProgressAchievement('MilkingCow', 1);
    }
}

function PickedWeapon(ScrnPlayerInfo SPI, KFWeaponPickup WeaponPickup)
{
    if ( MachetePickup(WeaponPickup ) != none ) {
        if ( SPI.IncCustomValue(none, 'MacheteWalker', 1) == 422 )
            SPI.ProgressAchievement('MacheteWalker', 1);
    }
}


defaultproperties
{
    iDoT_Damage=300
    bOnePlayerPerPerk=true
    bAllSamePerk=true
    InstantKillTime=0.70
    bNoHeadshots=True
    bAllCanDoHeadshots=True
}
