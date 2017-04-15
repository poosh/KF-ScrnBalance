Class ScrnGameLength extends Object
    dependson(ScrnWaveInfo)
	PerObjectConfig
	Config(ScrnWaves);

var ScrnGameType Game;

var config float BountyScale;
var config int StartingCashBonus;
var config array<string> Waves;
var config array<string> Zeds;
var config bool bLogStats;

var class<KFMonster> FallbackZed;
var array<ScrnZedInfo> ZedInfos;
var array<string> ZedVotes;

struct SSpawnCandidate {
    var class<KFMonster> ZedClass;
    var float Chance;
};

struct SActiveZed {
    var string Alias;
    var array<SSpawnCandidate> Candidates;
    var int WaveSpawns, TotalSpawns;
};
var array<SActiveZed> ActiveZeds;

// per-wave data
struct SSquadMember {
    var int ActiveZedIndex; // item index in ActiveZeds array
    var int Count;
};

struct SSquad {
    var byte MinPlayers;
    var byte MaxPlayers;
    var array<SSquadMember> Members;
};
var array<SSquad> Squads;
var array<SSquad> SpecialSquads;
var array<int> PendingSquads;
var array<int> PendingSpecialSquads;

var ScrnWaveInfo Wave;
var transient int ZedsBeforeSpecial;
var transient bool bLoadedSpecial;

var float WaveEndTime;
var int WaveCounter;

function LoadGame(ScrnGameType MyGame)
{
    local int i, j;
    local ScrnZedInfo zi;
    local class<KFMonster> zedc;

    Game = MyGame;

    ZedInfos.length = Zeds.length;
    for ( i = 0; i < Zeds.length; ++i ) {
        zi = new(none, Zeds[i]) class'ScrnZedInfo';

        for ( j = 0; j < zi.Zeds.length; ++j ) {
            if ( zi.Zeds[j].bDisabled )
                continue;

            zedc = class<KFMonster>(DynamicLoadObject(zi.Zeds[j].ZedClass, class'Class'));
            if ( zedc == none ) {
                log("Unable to load zed class '" $ zi.Zeds[j].ZedClass $ "' for " $ zi.Zeds[j].Alias, 'ScrnBalance');
                continue;
            }

            if ( zedc.outer.name != 'KFChar' ) {
                Game.AddToPackageMap(string(zedc.outer.name));
                if ( zi.Zeds[j].Package != "" )
                    Game.AddToPackageMap(zi.Zeds[j].Package);
            }

            if ( zi.Zeds[j].Vote != "" )
                AddZedVote(zi.Zeds[j].Vote);

            AddActiveZed(zi.Zeds[j].Alias, zedc, zi.Zeds[j].Pct);
        }

        // store zed info for config save after voting
        ZedInfos[i] = zi;
    }
    RecalculateSpawnChances();

    for ( i = 0; i < ActiveZeds.length; ++i ) {
        for ( j = 0; j < ActiveZeds[i].Candidates.length; ++j ) {
            ActiveZeds[i].Candidates[j].ZedClass.static.PreCacheAssets(Game.Level);
        }
    }

    if ( ZedVotes.length > 0 )
        AddVoting();
}

function AddVoting()
{
    local ScrnVotingHandlerMut VH;
    local ScrnZedVoting VO;

    VH = class'ScrnVotingHandlerMut'.static.GetVotingHandler(Game);
    if ( VH != none ) {
        Game.AddMutator(string(class'ScrnVotingHandlerMut'), false);
        VH = class'ScrnVotingHandlerMut'.static.GetVotingHandler(Game);
    }
    if ( VH == none ) {
        log("Unable to spawn voting handler mutator", class.name);
        return;
    }

    VO = ScrnZedVoting(VH.AddVotingOptions(class'ScrnBalanceSrv.ScrnZedVoting'));
    if ( VO != none ) {
        VO.GL = self;
    }
}

// allows admins to control zed infos via MUTATE ZED <cmd>
function ZedCmd(PlayerController Sender, string cmd)
{
    local array<string> args;
    local int search_idx, cur_idx; // starts with 1
    local int BoolValue;
    local int i, j;
    local bool bChanged;
    local color c;
    local float Pct;
    local bool bSetPct;

    BoolValue = -1;
    c.B = 1;

    Split(cmd, " ", args);
    if ( args.length == 0 || args[0] == "" ) {
        Sender.ClientMessage("MUTATE ZED LIST|(<alias> [<index> [ON|OFF] [PCT <val>]])");
        return;
    }

    if ( args[0] ~= "LIST" ) {
        PrintAliases(Sender);
        return;
    }


    if ( args.length >= 2 ) {
        search_idx = int(args[1]);

        for ( i = 2; i < args.length - 1; ++i ) {
            if ( args[i] ~= "PCT" ) {
                bSetPct = true;
                Pct = float(args[i+1]);
                args.remove(i,2);
                break;
            }
        }

        if ( args.length >= 3 ) {
            BoolValue = class'ScrnVotingOptions'.static.TryStrToBoolStatic(args[2]);
        }
    }

    Sender.ClientMessage("INDEX / STATUS / SPAWN CHANCE / ZED CLASS");
    Sender.ClientMessage("=========================================================");
    for ( i = 0; i < ZedInfos.length; ++i ) {
        bChanged = false;
        for ( j = 0; j < ZedInfos[i].Zeds.length; ++j ) {
            if ( ZedInfos[i].Zeds[j].Alias == args[0] ) {
                ++cur_idx;
                if ( ZedInfos[i].Zeds[j].bDisabled ) {
                    c.R = 255;
                    c.G = 1;
                }
                else {
                    c.R = 1;
                    c.G = 255;
                }
                if ( cur_idx == search_idx ) {
                    if ( BoolValue != -1 ) {
                        ZedInfos[i].Zeds[j].bDisabled = !bool(BoolValue);
                        bChanged = true;
                    }
                    if ( bSetPct) {
                        ZedInfos[i].Zeds[j].Pct = Pct;
                        bChanged = true;
                    }
                    c.R = 255;
                    c.G = 255;
                }
                Sender.ClientMessage(class'ScrnBalance'.static.ColorStringC(
                    class'ScrnFunctions'.static.LPad(string(cur_idx), 3)
                        @ class'ScrnFunctions'.static.RPad(eval(ZedInfos[i].Zeds[j].bDisabled, "OFF", "ON"), 5)
                        @ class'ScrnFunctions'.static.LPad(eval(ZedInfos[i].Zeds[j].Pct == 0, "AUTO", string(ZedInfos[i].Zeds[j].Pct)), 7)
                        @ ZedInfos[i].Zeds[j].ZedClass
                    , c ));
            }
        }
        if ( bChanged )
            ZedInfos[i].SaveConfig();
    }
    if ( cur_idx == 0 ) {
        Sender.ClientMessage("No zeds with alias '"$args[0]$"' found!");
    }
}

function PrintAliases(PlayerController Sender)
{
    local array<string> aliases;
    local array<int> count;
    local int i, j, k;

    Sender.ClientMessage("Zed aliases (candidate count):");
    for ( i = 0; i < ZedInfos.length; ++i ) {
        for ( j = 0; j < ZedInfos[i].Zeds.length; ++j ) {
            for ( k = 0; k < aliases.length; ++k ) {
                if ( ZedInfos[i].Zeds[j].Alias == aliases[k] )
                    break;
            }
            if ( k == aliases.length ) {
                aliases[k] = ZedInfos[i].Zeds[j].Alias;
                count[k] = 1;
            }
            else {
                ++count[k];
            }
        }
    }

    for ( k = 0; k < aliases.length; ++k ) {
        Sender.ClientMessage(aliases[k] $ " ("$count[k]$")");
    }
}

function bool LoadWave(int WaveNum)
{
    local int i;
    local SSquad squad;
    local Controller C;
    local KFPlayerController KFPC;

    ZedsBeforeSpecial = 0;
    PendingSquads.length = 0;
    PendingSpecialSquads.length = 0;
    Squads.length = 0;
    SpecialSquads.length = 0;

    if ( bLogStats && Wave != none )
        LogStats();

    if ( WaveNum >= Waves.length ) {
        warn("ScrnGameLength: Illegal wave number: " $ WaveNum);
        if (Wave == none ) {
            log("Using fallback wave info", 'ScrnBalance');
            Wave = new(none, "Wave1") class'ScrnWaveInfo';
        }
        return false;
    }

    Wave = new(none, Waves[WaveNum]) class'ScrnWaveInfo';

    for ( i = 0; i < ActiveZeds.length; ++i ) {
        ActiveZeds[i].WaveSpawns = 0;
    }

    for ( i = 0; i < Wave.Squads.length; ++i ) {
        if ( ParseSquad(Wave.Squads[i], squad) ) {
            Squads[Squads.length] = squad;
        }
    }
    if ( Squads.length == 0 ) {
        log("No squads in wave", 'ScrnBalance');
        return false;
    }

    for ( i = 0; i < Wave.SpecialSquads.length; ++i ) {
        if ( ParseSquad(Wave.SpecialSquads[i], squad) ) {
            SpecialSquads[SpecialSquads.length] = squad;
        }
    }

    Game.ScrnGRI.WaveEndRule = Wave.EndRule;
    SetWaveInfo();

    if ( Wave.TraderMessage != "" ) {
        for ( C = Game.Level.ControllerList; C != none; C = C.NextController ) {
            KFPC = KFPlayerController(C);
            if ( C.PlayerReplicationInfo != none && KFPC != none ) {
                // this is needed to show a trader portrait
                KFPC.ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', 0);
                KFPC.TeamMessage(C.PlayerReplicationInfo, Wave.TraderMessage, 'TRADER');
            }
        }
    }

    return true;
}



function RunWave()
{
    local string s;

    SetWaveInfo();
    if ( Game.ScrnGRI.WaveTitle != "" || Game.ScrnGRI.WaveMessage != "" ) {
        s = Game.ScrnBalanceMut.ColorString(Game.ScrnGRI.WaveTitle, 255, 204, 1);
        if ( Game.ScrnGRI.WaveMessage != "" )
            s $= ": " $ Game.ScrnGRI.WaveMessage;
        Game.Broadcast(Game, s);
    }
}

function SetWaveInfo()
{
    WaveCounter = Wave.Counter * ( 1.0 + Wave.PerPlayerMult * (min(5, Game.WavePlayerCount-1)) );
    WaveEndTime = Game.Level.TimeSeconds + WaveCounter;

    Game.ScrnGRI.WaveTitle = Wave.Title;
    Game.ScrnGRI.WaveMessage = Wave.Message;
    ReplaceText(Game.ScrnGRI.WaveMessage, "%c", string(WaveCounter));
}

function WaveTimer()
{
    if ( Wave.EndRule == RULE_Timeout ) {
        Game.WaveEndTime = WaveEndTime;
        Game.ScrnGRI.TimeToNextWave = WaveEndTime - Game.Level.TimeSeconds;
    }
}

function LogStats()
{
    local int i, total;

    for ( i = 0; i < ActiveZeds.length; ++i )
        total += ActiveZeds[i].WaveSpawns;
    if ( total == 0 )
        return;

    log("Spawn Stats for " $ string(Wave.name) $ ":", 'ScrnBalance');
    for ( i = 0; i < ActiveZeds.length; ++i ) {
        if ( ActiveZeds[i].WaveSpawns > 0 )
            log(ActiveZeds[i].Alias $ ": " $ ActiveZeds[i].WaveSpawns $ " / "
                    $ string(ActiveZeds[i].WaveSpawns * 100.0 / total) $ "%");
    }
}

function bool CheckWaveEnd()
{
    local int i;

    switch ( Wave.EndRule ) {
        case RULE_KillEmAll:
            return Game.TotalMaxMonsters <= 0 && Game.NumMonsters <= 0;
        case RULE_SpawnEmAll:
            return Game.TotalMaxMonsters <= 0;
        case RULE_KillBoss:
            if ( Game.bBossSpawned && Game.Bosses.length > 0 ) {
                for ( i = 0; i < Game.Bosses.length; ++i ) {
                    if ( Game.Bosses[i] != none && Game.Bosses[i].Health > 0 )
                        return false; // boss is alive
                }
                return true; // all bosses are dead
            }
            break;
        case RULE_Timeout:
            return Game.Level.TimeSeconds >= WaveEndTime;
        case RULE_EarnDosh:
            return max(Game.Teams[0].Score, Game.Teams[1].Score) >= WaveCounter;
    }

    // fallback scenario
    return Game.Level.TimeSeconds >= Game.WaveEndTime
            || (Game.TotalMaxMonsters <= 0 && Game.NumMonsters <= 0);
}

function int GetWaveZedCount()
{
    switch ( Wave.EndRule ) {
        case RULE_KillBoss:
            return 1;
        case RULE_Timeout:
        case RULE_EarnDosh:
            return Game.ScrnBalanceMut.MaxWaveSize;
    }
    return Wave.Counter;
}

function float GetWaveEndTime()
{
    switch ( Wave.EndRule ) {
        case RULE_Timeout:
            return WaveEndTime;
    }
    return Game.Level.TimeSeconds + 60;
}

function AdjustNextSpawnTime(float NextSpawnTime)
{
    NextSpawnTime *= Wave.SpawnRateMod;
}

function LoadNextSpawnSquad(out array < class<KFMonster> > NextSpawnSquad)
{
    if ( ZedsBeforeSpecial <= 0 && SpecialSquads.length > 0 ) {
        LoadNextSpawnSquadInternal(NextSpawnSquad, SpecialSquads, PendingSpecialSquads, true);
        ZedsBeforeSpecial = Wave.ZedsPerSpecialSquad * (0.85 + 0.3*frand());
        bLoadedSpecial = true;
    }
    else {
        LoadNextSpawnSquadInternal(NextSpawnSquad, Squads, PendingSquads, Wave.EndRule != RULE_KillBoss);
        ZedsBeforeSpecial -= NextSpawnSquad.length;
        bLoadedSpecial = false;
    }
}

protected function LoadNextSpawnSquadInternal(out array < class<KFMonster> > NextSpawnSquad,
        out array<SSquad> AllSquads, out array<int> Pending, bool bRandom, optional int Recursions)
{
    local int i, j, r;

    if ( AllSquads.length == 0 ) {
        NextSpawnSquad.length = 1;
        NextSpawnSquad[0] = FallbackZed;
        return;
    }

    NextSpawnSquad.length = 0;
    if ( Pending.length == 0 ) {
        Pending.length = AllSquads.length;
        for ( i = 0; i < Pending.length; ++i ) {
            Pending[i] = i;
        }
    }
    if (bRandom)
        i = rand(Pending.length);
    else
        i = 0;
    r = Pending[i];
    Pending.remove(i, 1);

    if ( Game.WavePlayerCount >= AllSquads[r].MinPlayers
        && (Game.WavePlayerCount <= AllSquads[r].MaxPlayers || AllSquads[r].MaxPlayers == 0) )
    {
        for ( i = 0; i < AllSquads[r].Members.length; ++i ) {
            for ( j = 0; j < AllSquads[r].Members[i].Count; ++j ) {
                NextSpawnSquad[NextSpawnSquad.length] = ActivateZed(AllSquads[r].Members[i].ActiveZedIndex);
            }
        }
    }
    else if ( Recursions < 10 ){
        // squad didn't passed player count restriction - pick another squad
        LoadNextSpawnSquadInternal(NextSpawnSquad, AllSquads, Pending, bRandom, Recursions + 1);
    }
}

function class<KFMonster> ActivateZed(int idx)
{
    local float r;
    local int i;

    ActiveZeds[idx].WaveSpawns++;
    ActiveZeds[idx].TotalSpawns++;

    if ( ActiveZeds[idx].Candidates.length == 1 )
        return ActiveZeds[idx].Candidates[0].ZedClass;

    r = frand();
    for ( i = 0; r > ActiveZeds[idx].Candidates[i].Chance && i < ActiveZeds[idx].Candidates.length - 1; ++i ) {
        r -= ActiveZeds[idx].Candidates[i].Chance;
    }
    return ActiveZeds[idx].Candidates[i].ZedClass;
}

function bool ParseSquad(string SquadDef, out SSquad Squad)
{
    local int i, j, idx, count;
    local array<string> parts;
    local string s, count_str, alias, fallback;

    Squad.Members.length = 0;
    Squad.MinPlayers = 0;
    Squad.MaxPlayers = 0;

    // format example: 0-6: 2*CL/GF + BR/TH/HU + BL

    // get rid of spaces
    s = Repl(SquadDef, " ", "", true);

    Divide(s, ":", count_str, s);
    if ( count_str != "" ) {
        Divide(count_str, "-", count_str, fallback);
        Squad.MinPlayers = int(count_str);
        Squad.MaxPlayers = int(fallback);
    }

    Split(s, "+", parts);
    for ( i = 0; i < parts.length; ++i ) {
        s = parts[i];
        do {
            if ( !Divide(s, "/", alias, fallback) ) {
                alias = s;
                fallback = "";
            }
            s = alias;
            if ( !Divide(s, "*", count_str, alias) ) {
                count = 1;
                alias = s;
            }
            else {
                count = int(count_str);
            }
            idx = FindActiveZed(alias);
            s = fallback;
        } until ( idx != -1 || fallback == "" );

        if ( idx == -1 ) {
            log("No zeds available to fit " $ parts[i] $ " in " $ SquadDef, 'ScrnBalance');
            Squad.Members.length = 0;
            return false;
        }
        else {
            j = Squad.Members.length;
            Squad.Members.insert(j, 1);
            Squad.Members[j].ActiveZedIndex = idx;
            Squad.Members[j].Count = count;
        }
    }
    return true;
}

function int FindActiveZed(string alias)
{
    local int i;

    for ( i = 0; i < ActiveZeds.length; ++i ) {
        if ( ActiveZeds[i].Alias == alias )
            return i;
    }
    log("Zed with alias '"$alias$"' not found", 'ScrnBalance');
    return -1;
}

function AddZedVote(string VoteString)
{
    local int i;

    for ( i = 0; i < ZedVotes.length; ++i ) {
        if ( VoteString == ZedVotes[i] )
            return; // already added
        else if ( VoteString < ZedVotes[i])
            break; // sort alphabetically
    }
    ZedVotes.insert(i, 1);
    ZedVotes[i] = VoteString;
}

function AddActiveZed(string Alias, class<KFMonster> ZedClass, optional float Chance)
{
    local int i, j;

    for ( i = 0; i < ActiveZeds.length; ++i ) {
        if ( ActiveZeds[i].Alias == Alias )
            break;
    }
    if ( i == ActiveZeds.length ) {
        ActiveZeds.insert(i, 1);
        ActiveZeds[i].Alias = Alias;
    }

    j = ActiveZeds[i].Candidates.length;
    ActiveZeds[i].Candidates.insert(j, 1);
    ActiveZeds[i].Candidates[j].ZedClass = ZedClass;
    ActiveZeds[i].Candidates[j].Chance = Chance;
}

// Recalculate spawn chances, removes records that have zero chance to spawn.
function RecalculateSpawnChances()
{
    local int i, j;
    local float chance;
    local int AutoChanceCount;

    for ( i = 0; i < ActiveZeds.length; ++i ) {
        if ( ActiveZeds[i].Candidates.length == 0 ) {
            log("Alias " $ ActiveZeds[i].Alias $ " has no zeds", 'ScrnBalance');
            ActiveZeds[i].Candidates.remove(i--, 1);
            continue;
        }

        chance = 0;
        AutoChanceCount = 0;
        for ( j = 0; j < ActiveZeds[i].Candidates.length; ++j ) {
            if ( ActiveZeds[i].Candidates[j].Chance == 0.0 )
                ++AutoChanceCount;
            else
                chance += ActiveZeds[i].Candidates[j].Chance;
        }

        if ( AutoChanceCount > 0 ) {
            // split remaining change equally on remaining records
            chance = (1.0 - chance) / AutoChanceCount;
            for ( j = 0; j < ActiveZeds[i].Candidates.length; ++j ) {
                if ( ActiveZeds[i].Candidates[j].Chance == 0.0 ) {
                    if ( chance > 0.0 )
                        ActiveZeds[i].Candidates[j].Chance = chance;
                    else
                        ActiveZeds[i].Candidates.remove(j--, 1);
                }
            }
        }
        else if ( abs(chance) - 1.0 > 0.01 ) {
            // modify all records to have total chance = 1.0
            chance = 1.0 / chance;
            for ( j = 0; j < ActiveZeds[i].Candidates.length; ++j ) {
                ActiveZeds[i].Candidates[j].Chance *= chance;
            }
        }
    }
}

defaultproperties
{
    Waves(0)="Wave1"
    Zeds(0)="NormalZeds"
    FallbackZed=class'KFChar.ZombieClot_STANDARD'
    BountyScale=1.0
    bLogStats=true
}