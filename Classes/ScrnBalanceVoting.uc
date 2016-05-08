class ScrnBalanceVoting extends ScrnVotingOptions;

var ScrnBalance Mut;

const VOTE_PERKLOCK  = 0;
const VOTE_PERKUNLOCK= 1;
const VOTE_PAUSE     = 2;
const VOTE_ENDTRADE  = 3;
const VOTE_BLAME  	 = 4;
const VOTE_KICK  	 = 5;
const VOTE_BORING  	 = 6;
const VOTE_SPAWN  	 = 7;
const VOTE_ENDWAVE   = 8;
const VOTE_SPEC      = 9;
const VOTE_READY     =  10;
const VOTE_UNREADY   =  11;

var localized string strCantEndTrade;
var localized string strTooLate;
var localized string strGamePaused, strSecondsLeft, strGameUnPaused, strPauseTraderOnly;
var localized string viResume, viEndTrade;
var localized string strZedSpawnsDoubled;
var localized string strSquadNotFound, strCantSpawnSquadNow, strSquadList;
var localized string strNotInStoryMode;
var localized string strCantEndWaveNow, strEndWavePenalty;

//variables for GamePaused state
var int PauseTime;
var transient bool bPauseable;
var transient string msgPause;

var string Reason; // reason why voting was started (e.g. kick player for being noob)

var transient float LastBlameVoteTime;

function class<ScrnVeterancyTypes> FindPerkByName(PlayerController Sender, string VeterancyName)
{
    local int i;
    local ClientPerkRepLink L;
    local class<ScrnVeterancyTypes> Perk;
    local string s1, s2;
    
    // log("FindPerkByName("$Sender$", "$VeterancyName$")", class.outer.name);
    
    if ( Sender == none || VeterancyName == "" || SRStatsBase(Sender.SteamStatsAndAchievements) == none )
        return none;
    L = SRStatsBase(Sender.SteamStatsAndAchievements).Rep;
    if ( L == none )
        return none;
        
    // log("CachePerks.Length="$L.CachePerks.Length, class.outer.name);
    for ( i = 0; i < L.CachePerks.Length; ++i ) {
        Perk = class<ScrnVeterancyTypes>(L.CachePerks[i].PerkClass);
        if ( Perk != none ) {
            // log(GetItemName(String(Perk.class)) @ Perk.default.VeterancyName, class.outer.name);
            if ( GetItemName(String(Perk.class)) ~= VeterancyName || Perk.default.VeterancyName ~= VeterancyName 
                    || (Divide(Perk.default.VeterancyName, " ", s1, s2) && (VeterancyName ~= s1 || VeterancyName ~= s2)) )
                return Perk;
        }
    }    
    
    return none;
}


function SendSquadList(PlayerController Sender)
{
	local int i;
	local string s;
	
	if ( Mut.Squads.Length == 0 ) {
		Sender.ClientMessage(strOptionDisabled);
		return;
	}

	s = strSquadList @ Mut.Squads[0].SquadName;
	for ( i=1; i<Mut.Squads.Length; ++i ) {
		s = s $ ", " $ Mut.Squads[i].SquadName;
	}
	
	Sender.ClientMessage(s);
}


function int GetVoteIndex(PlayerController Sender, string Key, out string Value, out string VoteInfo)
{
    local int result, v;
    local class<ScrnVeterancyTypes> Perk;
    
    if ( Key == "LOCKPERK" ) {
		if ( !Mut.bAllowLockPerkVote ) {
			Sender.ClientMessage(strOptionDisabled);
			return VOTE_NOEFECT;
		}	
        Perk = FindPerkByName(Sender, Value);
        if ( Perk == none )
            return VOTE_ILLEGAL;
        if ( Perk.default.bLocked )
            return VOTE_NOEFECT;
            
        result = VOTE_PERKLOCK;
        Value = Perk.default.VeterancyName;
    }
    else if ( Key == "UNLOCKPERK" ) {
        Perk = FindPerkByName(Sender, Value);
        if ( Perk == none )
            return VOTE_ILLEGAL;
        if ( !Perk.default.bLocked )
            return VOTE_NOEFECT;

        result = VOTE_PERKUNLOCK;
        Value = Perk.default.VeterancyName;
    }
    else if ( Key == "PAUSE" || (Level.Pauser != none && Key == "RESUME") ) {
		if ( !Mut.bAllowPauseVote ) {
			Sender.ClientMessage(strOptionDisabled);
			return VOTE_NOEFECT;
		}		
        if ( Mut.bPauseTraderOnly && !Mut.KF.bTradingDoorsOpen && Mut.KF.IsInState('MatchInProgress') ) {
            Sender.ClientMessage(strPauseTraderOnly);
            return VOTE_NOEFECT;
        }    
        result = VOTE_PAUSE;
        if ( Value == "" )
            Value = "60";
        else {
            v = int(Value);
            if ( v <= 0 ) 
                v = 60;
            Value = string(v);
        }
        if ( Level.Pauser != none )
            VoteInfo = viResume;
    }       
    else if ( Key == "ENDTRADE" || (Key == "END" && Value == "TRADE") ) {
		if ( Mut.bStoryMode ) {
            Sender.ClientMessage(strNotInStoryMode);
            return VOTE_NOEFECT;		
		}
        if ( !Mut.KF.bTradingDoorsOpen || Mut.KF.WaveCountDown < 10 || Mut.SkippedTradeTimeMult < 0 ) {
            Sender.ClientMessage(strCantEndTrade);
            return VOTE_NOEFECT;
        }
        result = VOTE_ENDTRADE;
        Value = "";
        VoteInfo = viEndTrade;
    }  
	else if ( Key == "BLAME" ) {
		if ( !Mut.bAllowBlameVote ) {
			Sender.ClientMessage(strOptionDisabled);
			return VOTE_NOEFECT;
		}
        if ( Level.TimeSeconds - LastBlameVoteTime < Mut.BlameVoteCoolDown ) {
            Sender.ClientMessage(strNotAvaliableATM);
            return VOTE_LOCAL;
        }
		
		if ( Value == "" ) {
			SendPlayerList(Sender);
			return VOTE_LOCAL;
		}
		
		Reason = "";
		if ( Left(Value, 1) == "\"" ) {
			// don't look for player in quoted string - just blame it :)
			VotingHandler.VotedPlayer = none;
			Value = Mid(Value, 1);
			Divide(Value, "\"", Value, Reason);
		}
		else {
			Divide(Value, " ", Value, Reason);
			if ( Value ~= "ALL" || Value ~= "TEAM" ) {
				Value = "TEAM";
				VoteInfo = "Blame Team";
				VotingHandler.VotedPlayer = none;
			}
			else {
				if ( Value ~= "ME" )
					VotingHandler.VotedPlayer = Sender;
				else
					VotingHandler.VotedPlayer = FindPlayer(Value);
				if ( VotingHandler.VotedPlayer == none ) {
					Sender.ClientMessage(strPlayerNotFound);
					SendPlayerList(Sender);
					return VOTE_ILLEGAL;
				}
				Value = Mut.ColoredPlayerName(VotingHandler.VotedPlayer.PlayerReplicationInfo);
				VoteInfo = "Blame " $ Value;
			}
		}
        LastBlameVoteTime = Level.TimeSeconds;
		result = VOTE_BLAME;
	}
	else if ( Key == "SPEC" ) {
		if ( !Mut.bAllowKickVote || Level.Game.AccessControl == none 
                || Level.Game.NumSpectators > Level.Game.MaxSpectators ) 
        {
			Sender.ClientMessage(strOptionDisabled);
			return VOTE_NOEFECT;
		}
		
		if ( Value == "" ) {
			SendPlayerList(Sender);
			return VOTE_LOCAL;
		}
		
		Reason = "";
		Divide(Value, " ", Value, Reason);
		VotingHandler.VotedPlayer = FindPlayer(Value);
		if ( VotingHandler.VotedPlayer == none ) {
			Sender.ClientMessage(strPlayerNotFound);
			SendPlayerList(Sender);
			return VOTE_ILLEGAL;
		}
		Value = Mut.ColoredPlayerName(VotingHandler.VotedPlayer.PlayerReplicationInfo);
		VoteInfo = "Spectate " $ Value;
		result = VOTE_SPEC;
	}    
	else if ( Key == "KICK" ) {
		if ( !Mut.bAllowKickVote || Level.Game.AccessControl == none ) {
			Sender.ClientMessage(strOptionDisabled);
			return VOTE_NOEFECT;
		}
		
		if ( Value == "" ) {
			SendPlayerList(Sender);
			return VOTE_LOCAL;
		}
		
		Reason = "";
		Divide(Value, " ", Value, Reason);
		VotingHandler.VotedPlayer = FindPlayer(Value);
		if ( VotingHandler.VotedPlayer == none ) {
			Sender.ClientMessage(strPlayerNotFound);
			SendPlayerList(Sender);
			return VOTE_ILLEGAL;
		}
		Value = Mut.ColoredPlayerName(VotingHandler.VotedPlayer.PlayerReplicationInfo);
		VoteInfo = "Kick " $ Value;
		result = VOTE_KICK;
	}
	else if ( Key == "BORING" ) {
		if ( Mut.bStoryMode ) {
            Sender.ClientMessage(strNotInStoryMode);
            return VOTE_LOCAL;		
		}	
		else if ( !Mut.bAllowBoringVote ) {
			Sender.ClientMessage(strOptionDisabled);
			return VOTE_LOCAL;
		}	
        else if ( Mut.KF.KFLRules.WaveSpawnPeriod < 0.5 ) {
			Sender.ClientMessage(strNotAvaliableATM);
			return VOTE_LOCAL;        
        }
        
       
		Value = "";
		VoteInfo = "Game is BORING";
		result = VOTE_BORING;
	}
	else if ( Key == "SPAWN" ) {
		if ( Mut.bStoryMode && !Mut.bBeta ) {
            Sender.ClientMessage(strNotInStoryMode);
            return VOTE_NOEFECT;		
		}	
		if ( Mut.Squads.Length == 0 ) {
			Sender.ClientMessage(strOptionDisabled);
			return VOTE_NOEFECT;
		}	
		if ( Value == "" ) {
			SendSquadList(Sender);
			return VOTE_LOCAL;
		}
		if ( Mut.FindSquad(Value) == -1 ) {
			Sender.ClientMessage(strSquadNotFound);
			return VOTE_ILLEGAL;
		}		
		if ( Mut.KF.TotalMaxMonsters < 10 ) {
			Sender.ClientMessage(strCantSpawnSquadNow);
			return VOTE_NOEFECT;
		}		
		result = VOTE_SPAWN;
	}
	else if ( Key == "ENDWAVE" || (Key == "END" && Value == "WAVE") ) {
		VotingHandler.VotedTeam = Sender.PlayerReplicationInfo.Team;
		if ( VotingHandler.VotedTeam == none )
			return VOTE_ILLEGAL;
		
		if ( Mut.KF.NumMonsters == 0 )
			return VOTE_NOEFECT;		
			
		if ( Mut.MaxVoteKillMonsters == 0 ) {
			Sender.ClientMessage(strOptionDisabled);
			return VOTE_NOEFECT;		
		}
		if ( Mut.KF.TotalMaxMonsters > 0 || Mut.KF.NumMonsters > Mut.MaxVoteKillMonsters 
				|| Mut.GameRules.bFinalWave || !CanEndWave() ) 
		{
			Sender.ClientMessage(strCantEndWaveNow);
			return VOTE_NOEFECT;			
		}
		return VOTE_ENDWAVE;
	}
    else if ( Key == "READY" ) {
        if ( !Level.Game.bWaitingToStartMatch )
            return VOTE_NOEFECT;
            
        return VOTE_READY;
    }
    else if ( Key == "UNREADY" ) {
        if ( !Level.Game.bWaitingToStartMatch )
            return VOTE_NOEFECT;
            
        return VOTE_UNREADY;
    }    
    else
        return VOTE_UNKNOWN;

    return result;
}


function ApplyVoteValue(int VoteIndex, string VoteValue)
{
    local class<ScrnVeterancyTypes> Perk;
    local ScrnCustomPRI ScrnPRI;
    
    switch ( VoteIndex ) {
        case VOTE_PERKLOCK: case VOTE_PERKUNLOCK:
            Perk = FindPerkByName(VotingHandler.VoteInitiator, VoteValue);
            if ( Perk != none ) {
                Mut.LockPerk(Perk, VoteIndex == VOTE_PERKLOCK);
            }
            break;
        case VOTE_PAUSE:
            if (Level.Pauser == none ) {
                //pause game
                if ( Mut.bPauseTraderOnly && !Mut.KF.bTradingDoorsOpen && Mut.KF.IsInState('MatchInProgress') ) {
                    VotingHandler.BroadcastMessage(strPauseTraderOnly);
                    return;
                }
                PauseTime = int(VoteValue);
                if ( PauseTime <= 0 )
                    PauseTime = 60;
                GotoState('GamePaused', 'Begin');  
                //Enable('Tick');
            }
            else {
                //resume game
                Level.Pauser = none;
                VotingHandler.BroadcastMessage(strGameUnpaused);
                //Disable('Tick');
            }
            break;
        case VOTE_ENDTRADE:
            if ( !Mut.KF.bTradingDoorsOpen || Mut.KF.WaveCountDown < 6 ) {
                VotingHandler.BroadcastMessage(strTooLate);
                return;
            }
            Mut.TradeTimeAddSeconds = max(float(Mut.KF.WaveCountDown - 5) * Mut.SkippedTradeTimeMult, 0);
            Mut.KF.WaveCountDown = 6; // need to left at least 6 to execute kfgametype.timer() events
            break;  
		case VOTE_BLAME:
            LastBlameVoteTime = Level.TimeSeconds;
			if ( Reason == "" )
				VotingHandler.BroadcastMessage(VoteValue $ " blamed");
			else
				VotingHandler.BroadcastMessage(VoteValue $ " blamed for " $Reason);

			//achievement
			if ( IsGoodReason() && VotingHandler.VoteInitiator != none 
					&& SRStatsBase(VotingHandler.VoteInitiator.SteamStatsAndAchievements) != none ) 
			{
				class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(
					SRStatsBase(VotingHandler.VoteInitiator.SteamStatsAndAchievements).Rep, 'Blame55p', 1);
				if ( VotingHandler.VotedPlayer == VotingHandler.VoteInitiator )
					class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(
						SRStatsBase(VotingHandler.VoteInitiator.SteamStatsAndAchievements).Rep, 'BlameMe', 1);	
				else if ( ScrnPlayerController(VotingHandler.VotedPlayer) != none && ScrnPlayerController(VotingHandler.VotedPlayer).BeggingForMoney >= 3 ) 
				{
					class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(
						SRStatsBase(VotingHandler.VoteInitiator.SteamStatsAndAchievements).Rep, 'SellCrap', 1);	
					VotingHandler.VotedPlayer.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnFakedAchMsg', 1);
					ScrnPlayerController(VotingHandler.VotedPlayer).BeggingForMoney = 0;
				}
			}

            
			if ( VotingHandler.VotedPlayer != none ) {
                ScrnPRI = class'ScrnPlayerController'.static.FindScrnCustomPRI(VotingHandler.VotedPlayer.PlayerReplicationInfo);
				if ( ScrnPRI != none ) {
					VotingHandler.VotedPlayer.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnBlamedMsg', ScrnPRI.BlameCounter++); // more blame = bigger shit
                    
					//achievement
					if ( ScrnPRI.BlameCounter == 5 
							&& SRStatsBase(VotingHandler.VotedPlayer.SteamStatsAndAchievements) != none )
						class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(
							SRStatsBase(VotingHandler.VotedPlayer.SteamStatsAndAchievements).Rep, 'MaxBlame', 1);	
				}
				else 
					VotingHandler.VotedPlayer.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnBlamedMsg');
			}
			
			if ( VoteValue ~= "TEAM" || VoteValue ~= "ALL" ) {
				BlameAll();
				//achievement
				if ( IsGoodReason() && VotingHandler.VoteInitiator != none 
						&& SRStatsBase(VotingHandler.VoteInitiator.SteamStatsAndAchievements) != none )
					class'ScrnBalanceSrv.ScrnAchievements'.static.ProgressAchievementByID(
						SRStatsBase(VotingHandler.VoteInitiator.SteamStatsAndAchievements).Rep, 'BlameTeam', 1);
			}
			else if ( VoteValue ~= "Baron" || (VotingHandler.VotedPlayer != none && VotingHandler.VotedPlayer.GetPlayerIDHash() == "76561198006289592") ) {
				Mut.BroadcastFakedAchievement(0); // blame Baron :)
			}
			else if ( VoteValue ~= "TWI" || VoteValue ~= "Tripwire" || VoteValue ~= "Tripwire Interactive" ) {
				Mut.BroadcastFakedAchievement(3); // blame Tripwire :)
			}
			else 
				BlameMonster(VoteValue);
				
			break;
		case VOTE_SPEC:
			if ( VotingHandler.VotedPlayer != none && !VotingHandler.VotedPlayer.PlayerReplicationInfo.bAdmin ) {
                VotingHandler.VotedPlayer.BecomeSpectator();
            }
			break;            
		case VOTE_KICK:
			if ( VotingHandler.VotedPlayer != none && !VotingHandler.VotedPlayer.PlayerReplicationInfo.bAdmin && NetConnection(VotingHandler.VotedPlayer.Player)!=None ) {
				if ( Reason == "" ) {
					VotingHandler.BroadcastMessage(VoteValue $ " kicked");
					VotingHandler.VotedPlayer.ClientNetworkMessage("AC_Kicked", "Team Vote");
				}
				else {
					VotingHandler.BroadcastMessage(VoteValue $ " kicked for " $Reason);
					VotingHandler.VotedPlayer.ClientNetworkMessage("AC_Kicked", Reason);
				}
				
				if (VotingHandler.VotedPlayer.Pawn != none && Vehicle(VotingHandler.VotedPlayer.Pawn) == none)
					VotingHandler.VotedPlayer.Pawn.Destroy();
				if (VotingHandler.VotedPlayer != None)
					VotingHandler.VotedPlayer.Destroy();				
			}
			break;
		case VOTE_BORING:
			Mut.KF.KFLRules.WaveSpawnPeriod *= 0.5;
			VotingHandler.BroadcastMessage(strZedSpawnsDoubled $ " ("$Mut.KF.KFLRules.WaveSpawnPeriod$")");
			break;
			
		case VOTE_SPAWN:
			Mut.SpawnSquad(VoteValue);
			break;
			
		case VOTE_ENDWAVE:
			if ( Mut.KF.TotalMaxMonsters > 0 || Mut.KF.NumMonsters > Mut.MaxVoteKillMonsters 
					|| Mut.GameRules.bFinalWave ) 
			{
				return;
			}
			DoEndWave();
			break;
        case VOTE_READY:
            SetReady(VotingHandler.VotedTeam.TeamIndex, true);
            break;
        case VOTE_UNREADY:
            SetReady(VotingHandler.VotedTeam.TeamIndex, false);
            break;            
    }
}

function SetReady(byte TeamIndex, bool bReady)
{
    local Controller C;
    
    for ( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if ( C.PlayerReplicationInfo != none && C.bIsPlayer && PlayerController(C) != none
                && C.PlayerReplicationInfo.Team != none
                && C.PlayerReplicationInfo.bWaitingPlayer && !C.PlayerReplicationInfo.bOnlySpectator )
        {
            C.PlayerReplicationInfo.bReadyToPlay = bReady;
        }
    }
}

function class<KFMonster> Str2Monster(string MonsterName)
{
	MonsterName = caps(MonsterName);
	
	if ( MonsterName == "CLOT" )
		return class'ZombieClot';
	if ( MonsterName == "CRAWLER" )
		return class'ZombieCrawler';	
	if ( MonsterName == "STALKER" )
		return class'ZombieStalker';
	if ( MonsterName == "BLOAT" )
		return class'ZombieBloat';
	if ( MonsterName == "GOREFAST" )
		return class'ZombieGorefast';
	if ( MonsterName == "SIREN" )
		return class'ZombieSiren';		
	if ( MonsterName == "HUSK" )
		return class'ZombieHusk';	
	if ( MonsterName == "SCRAKE" || MonsterName == "SC" )
		return class'ZombieScrake';	
	if ( MonsterName == "FLESHPOUND" || MonsterName == "FP" )
		return class'ZombieFleshpound';	
	if ( MonsterName == "PAT" || MonsterName == "PATRIARCH" || MonsterName == "BOSS" )
		return class'ZombieBoss';	
		
	return none;
}

function BlameAll()
{
    local Controller P;
    local ScrnPlayerController Player;
    local ScrnCustomPRI ScrnPRI;

    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        Player = ScrnPlayerController(P);
        if ( Player != none ) {
            ScrnPRI = Player.FindScrnCustomPRI(Player.PlayerReplicationInfo);
			if ( ScrnPRI != none ) {    
                Player.ReceiveLocalizedMessage(class'ScrnBalanceSrv.ScrnBlamedMsg', ScrnPRI.BlameCounter++); // more blame = bigger shit
                if ( Player.PlayerReplicationInfo != none && Player.PlayerReplicationInfo.PlayerName ~= "Baron" )
                    Mut.BroadcastFakedAchievement(0); // blame Baron :)
            }
        }
    }
}


// returns false if monster not found or can't be blamed
function bool BlameMonster(String MonsterName)
{
	local class<KFMonster> MC;
    local Controller P;
    local ScrnPlayerController Player;

	MC = Str2Monster(MonsterName);
	// don't blame Stalkers and Patriarch, because shit on their head could reveal
	// their positions
	if ( MC == none || MC == class'ZombieStalker' ||  MC == class'ZombieBoss' )
		return false;
	
    for ( P = Level.ControllerList; P != none; P = P.nextController ) {
        Player = ScrnPlayerController(P);
        if ( Player != none ) {
			Player.ClientMonsterBlamed(MC);
        }
    }
	return true;
}

function bool IsGoodReason()
{
	local string a, b;
	
	// good reason contains from at least 2 words, one of them is at least 6 character long
	// "n00b" and "screw you" aren't good reasons :)
	return Divide(Reason, " ", a, b) && ( len(a) >= 6 || len(b) >= 6); 
}

function bool CanEndWave()
{
	local Controller C;
	local MonsterController MC;
	local Monster M;
	local KFHumanPawn P;
	local int TotalHP;
	
	for ( C = Level.ControllerList; C != None; C = C.NextController ) {
		MC = MonsterController(C);
		M = Monster(C.Pawn);
		if ( MC==none || M == none )
			continue;

		TotalHP += M.default.Health;
		
		if ( Mut.bVoteKillCheckVisibility ) {
			foreach VisibleCollidingActors(class'KFHumanPawn', P, 1000) {
				if ( P.Health > 0 && P.Controller != none && P.Controller.bIsPlayer && KF_StoryNPC(P) == none && MC.CanSee(P) )
					return false;
			}
		}
	}
	return TotalHP < Mut.MaxVoteKillHP;
}

function DoEndWave()
{
	local Monster M;
	local int Penalty, TotalPenalty;
	
	foreach DynamicActors(class'Monster', M) {
		Penalty = max(M.ScoringValue * Mut.VoteKillPenaltyMult, 0);
		VotingHandler.VotedTeam.Score -= Penalty;
		TotalPenalty += Penalty;
		M.KilledBy(M);
	}
	if ( TotalPenalty > 0 )
		VotingHandler.BroadcastMessage(strEndWavePenalty $ TotalPenalty);
}

state GamePaused
{
Begin:
    Level.Pauser = VotingHandler.VoteInitiator.PlayerReplicationInfo;
    
    if ( Level.Pauser != none ) {
        // tell players that game is paused
        msgPause = strGamePaused;
        ReplaceText(msgPause, "%s", string(PauseTime));
        VotingHandler.BroadcastMessage(msgPause);
            
        // wait for pause time ends or game resumes by other source (e.g. admin)
        while ( PauseTime > 0 && Level.Pauser != none ) {
            if ( PauseTime <= 5 )
                VotingHandler.BroadcastMessage(String(PauseTime));
            else if ( (PauseTime%30 == 0) || (PauseTime < 30 && PauseTime%10 == 0) )
                VotingHandler.BroadcastMessage(PauseTime @ strSecondsLeft);
            //log(Level.TimeSeconds @ "Sleep", class.outer.name);
            sleep(1.0);
            PauseTime--;
        }
        // resume game after pause time ends    
        if ( Level.Pauser != none ) {
            Level.Pauser = none;
            VotingHandler.BroadcastMessage(strGameUnpaused);    
        }
    }
    GotoState('');
}

defaultproperties
{
    bAlwaysTick=True // tick during game pause

    HelpInfo(0)="%gLOCKPERK %y<perk_name> %w Disable perk at the end of the wave"
    HelpInfo(1)="%gUNLOCKPERK %y<perk_name> %w Enable perk at the end of the wave"
    HelpInfo(2)="%gPAUSE %yX %w Pause the game for X seconds"
    HelpInfo(3)="%gEND TRADE %w Immediately end current trader time and start next wave"
    HelpInfo(4)="%gEND WAVE %w Kills last stuck zeds to end the wave"
    HelpInfo(5)="%gBLAME %y<player_name> %b[<reason>] %w Blame player [for the <reason>]"
    HelpInfo(6)="%gSPEC %y<player_name> %b[<reason>] %w Move player to spectators"
    HelpInfo(7)="%gKICK %y<player_name> %b[<reason>] %w Kick player [for the <reason>]"
    HelpInfo(8)="%gBORING %w Doubles ZED spawn rate"
    HelpInfo(9)="%gSPAWN %y<squad_name> %w Spawns zed squad"
    HelpInfo(10)="%gREADY%w|%gUNREADY %w Makes everybody ready/unready to play"
    
    strCantEndTrade="Can not end trade time at the current moment"
    strTooLate="Too late"
    strGamePaused="Game paused for %s seconds"
    strSecondsLeft="seconds left"
    strGameUnpaused="Game resumed"
    strPauseTraderOnly="Game can be paused only during trader time!"
	strZedSpawnsDoubled="ZED spawn rate doubled!"
	strSquadNotFound="Monster squad with a given name not found"
	strCantSpawnSquadNow="Can not spawn monsters at this moment"
	strSquadList="Avaliable Squads:"
	strNotInStoryMode="Not avaliable in Story Mode"
	strCantEndWaveNow="Can't end the wave now"
	strEndWavePenalty="Team charged for premature wave end with $"

    viResume="RESUME GAME"
    viEndTrade="END TRADER TIME"    
}