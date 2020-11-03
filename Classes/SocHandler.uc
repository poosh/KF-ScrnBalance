class SocHandler extends ScrnAchHandlerBase;

var SocIsoMut Mut;

var float VirusSpreadDistSq;

var transient array<VirusInfo> Healthy;
var transient array<VirusInfo> Infected;
var transient int SpreadCounter;

function WaveStarted(byte WaveNum)
{
    local ScrnPlayerInfo SPI;
    local VirusInfo Virus;
    local int CuredCount;
    local int i, count;

    Infected.length = 0;
    Healthy.length = 0;
    for ( SPI = GameRules.PlayerInfo; SPI != none; SPI = SPI.NextPlayerInfo ) {
        Virus = VirusInfo(SPI.CustomInfo(class'VirusInfo', true));
        Virus.Mut = Mut;
        if ( Virus.bInfected ) {
            Infected[Infected.length] = Virus;
        }
        else if ( Virus.bCured ) {
            ++CuredCount;
        }
        else {
            Healthy[Healthy.length] = Virus;
        }
    }

    count = GameRules.PlayerCountInWave();
    if ( count <= 1 ) {
        // Do nothing. The mod not suited for solo play.
    }
    else if ( count == 2 ) {
        // infect one of the players with very light symphoms
        if ( Infected.length == 0 && CuredCount == 0 ) {
            InfectRand(0.5 * frand());
        }
    }
    else {
        // infect every third person
        count = count/3 - Infected.length - CuredCount;
        if (count > 0) {
            for ( i = 0; i < count; ++i ) {
                InfectRand(frand());
            }

            count = GameRules.PlayerCountInWave() % 3;
            if ( count > 0 ) {
                // if there is the remainder, then infect one one person with light symptoms, e..g:
                // in 4p game, there will be one fully infected + one with 40% of virus damage;
                // in 5p game: one full + one with 80% sick damage;
                // in 6p game: two fully infected;
                // etc.
                InfectRand(0.4 * count * frand());
            }
        }
    }
    SetTimer(1.0, true);
}

function WaveEnded(byte WaveNum)
{
    local int i;
    local VirusInfo Virus;

    // reveal symptoms at the end of wave 2
    if ( !Mut.bRevealSymptoms && WaveNum >= 1 ) {
        Mut.bRevealSymptoms = true;
        // randomize start of the symptoms
        for ( i = 0; i < Infected.Length; ++i ) {
            Virus = Infected[i];
            if ( Virus.IsInState('Incubation') && Virus.NextStateTime < Level.TimeSeconds ) {
                Virus.NextStateTime = Level.TimeSeconds + 120.0*frand();
            }
        }
    }
}

function GameWon(string MapName)
{
    local TeamInfo WinnerTeam;
    local ScrnPlayerInfo SPI;
    local VirusInfo Virus;
    local int PlayerCount;

    WinnerTeam = TeamInfo(Level.Game.GameReplicationInfo.Winner);
    PlayerCount = GameRules.PlayerCountInWave();

    if ( PlayerCount <= 1 )
        return;  // no achievements for soloers

    Ach2All('DoubleOutbreak', 1, none, WinnerTeam);
    if ( GameRules.GameDoom3Kills > 0 && Level.Game.GameDifficulty >= 7 ) {
        Ach2All('TripleInvasion', 1, none, WinnerTeam);
    }
    if ( SpreadCounter == 0 && PlayerCount >= 3 ) {
        Ach2All('TW_Isolation', 1);
    }
    if ( GameRules.Mut.BlameCounter == 0 && PlayerCount >= 6 ) {
        Ach2All('NoShit', 1, none, WinnerTeam);
    }

    for ( SPI = GameRules.PlayerInfo; SPI != none; SPI = SPI.NextPlayerInfo ) {
        Virus = VirusInfo(SPI.CustomInfo(class'VirusInfo', false));
        if ( Virus != none ) {
            if ( Virus.InfectionCounter < 120 && Virus.SpreadCounter == 0 ) {
                SPI.ProgressAchievement('SelfIsolation', 1);
            }
        }
    }

    GotoState('Win');
}

function GameEnded()
{
    local ScrnPlayerInfo SPI;
    local VirusInfo Virus;
    local String s;

    SetTimer(0, false);

    for ( SPI = GameRules.PlayerInfo; SPI != none; SPI = SPI.NextPlayerInfo ) {
        Virus = VirusInfo(SPI.CustomInfo(class'VirusInfo', false));
        if ( Virus == none )
            continue;
        if ( Virus.IsInState('Asymptomatic') )
                SPI.ProgressAchievement('Asymptomatic', 1);

        s = SPI.PlayerName @ Virus.GetStateName();
        if ( Virus.bInfected || Virus.bCured ) {
            if ( Virus.InfectedBy != none ) {
                s $= ". Infected at " $ GameRules.Mut.FormatTime(Virus.InfectGameTime);
                s $= " by " $ Virus.InfectedBy.SPI.PlayerName;
            }
        }
        if ( SPI.StartWave > 0 ) {
            s $= ". Joined at wave " $ string(SPI.StartWave + 1);
        }
        GameRules.Mut.BroadcastMessage(s, true);
    }
}

function Timer()
{
    local int i, j;
    local ScrnHumanPawn PH, PI;
    local bool bVirusSpread;
    local VirusInfo Virus, VirusInf;

    for ( i = 0; i < Healthy.length; ++i ) {
        bVirusSpread = false;
        Virus = Healthy[i];
        PH = Virus.SPI.AlivePawn();
        if ( PH == none )
            continue;

        for ( j = 0; j < Infected.length; ++j ) {
            VirusInf = Infected[j];
            PI = VirusInf.SPI.AlivePawn();
            if ( PI != none && VSizeSquared(PH.Location - PI.Location) < VirusSpreadDistSq
                    && Virus.SPI.PlayerOwner.LineOfSightTo(PI) )
            {
                bVirusSpread = true;
                Virus.InfectionCounterRapid++;
                Virus.InfectionCounter++;
                VirusInf.InfectionCounter++;
                if ( Virus.InfectionCounterRapid >= Virus.InfectionThreshholdRapid
                        || Virus.InfectionCounter >= Virus.InfectionThreshhold ) {
                    Infect(i, frand());
                    if (Virus.bInfected) {
                        SpreadCounter++;
                        Virus.SpreadCounter++;
                        VirusInf.SpreadCounter++;
                        Virus.InfectedBy = VirusInf;
                        return;
                    }
                }
            }
        }

        if ( !bVirusSpread ) {
            Virus.InfectionCounterRapid--;
        }
    }
}

function Infect(int HealthyIndex, float InfectionRate)
{
    local VirusInfo Virus;

    Virus = Healthy[HealthyIndex];
    Virus.Infect(InfectionRate);
    if (Virus.bInfected) {
        Healthy.remove(HealthyIndex, 1);
        Infected[Infected.length] = Virus;
    }
}

function InfectRand(float InfectionRate)
{
    if ( Healthy.length > 0 ) {
        Infect(rand(Healthy.length), InfectionRate);
    }
}

function PlayerSick(VirusInfo Virus)
{
    local ScrnHumanPawn P;
    local Inventory Inv;
    local int i;
    local bool bRevealCovidiots;

    P = Virus.SPI.AlivePawn();
    if ( P != none && Virus.Damage > 0 ) {
        for ( Inv = P.Inventory; Inv != none && ++i < 1000; Inv = Inv.Inventory ) {
            if ( Inv.Class == class'ToiletPaperAmmo' ) {
                if ( ToiletPaperAmmo(Inv).AmmoAmount >= 100 ) {
                    Virus.SPI.ProgressAchievement('CovidiotD', 1);
                }
                break;
            }
        }
    }

    if ( Virus.InfectedBy != none ) {
        if ( Virus.InfectedBy.SpreadCounter >= 3 && !Virus.InfectedBy.bCovidiotSocial ) {
            Virus.InfectedBy.bCovidiotSocial = true;
            Virus.InfectedBy.SPI.ProgressAchievement('CovidiotS', 1);
        }
    }

    if ( Healthy.length == 0 && GameRules.PlayerCountInWave() >= 3 ) {
        bRevealCovidiots = true;
        // do not show CovidiotParty achievement until all players had symptoms
        for ( i = 0; i < Infected.length; ++i ) {
            if ( Infected[i].IsInState('Incubation') ) {
                bRevealCovidiots = false;
                break;
            }
        }
        if ( bRevealCovidiots )
            Ach2All('CovidiotParty', 1);
    }
}

function PlayerCoughed(VirusInfo SickVirus, int Damage)
{
    local VirusInfo VictimVirus;
    local ScrnHumanPawn Sick, Victim;
    local int i;

    Sick = SickVirus.SPI.AlivePawn();
    if ( Sick == none )
        return;

    for ( i = 0; i < Healthy.length; ++i ) {
        VictimVirus = Healthy[i];
        Victim = VictimVirus.SPI.AlivePawn();
        if ( Victim != none
                && VSizeSquared(Victim.Location - Sick.Location) < VirusSpreadDistSq
                && SickVirus.SPI.PlayerOwner.CanSee(Victim) )
        {
            // significantly raise the chance of infection when coughing on other players
            VictimVirus.InfectionCounterRapid += 10;
            VictimVirus.InfectionCounter += 50;
            SickVirus.InfectionCounter += 50;
        }
    }

    for ( i = 0; i < Infected.length; ++i ) {
        VictimVirus = Infected[i];
        Victim = VictimVirus.SPI.AlivePawn();
        if ( Victim != none && Victim != Sick
                && VSizeSquared(Victim.Location - Sick.Location) < VirusSpreadDistSq
                && SickVirus.SPI.PlayerOwner.CanSee(Victim) )
        {
            // coughing on sick players makes them cough more often
            VictimVirus.HealthSample(max(1, VictimVirus.MinHealth * 0.9));
        }
    }
}

state Win
{
    function TPFirewarks()
    {
        local ScrnPlayerInfo SPI;
        local ScrnHumanPawn ScrnPawn;

        for ( SPI = GameRules.PlayerInfo; SPI != none; SPI = SPI.NextPlayerInfo ) {
            ScrnPawn = SPI.AlivePawn();
            if ( ScrnPawn != none ) {
                ScrnPawn.DropAllTP();
            }
        }
    }

Begin:
    sleep(5.0);
    TPFirewarks();
}


defaultproperties
{
    VirusSpreadDistSq=62500  // 5m squared
}
