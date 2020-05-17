class SocIsoMut extends Mutator;

var float VirusSpreadDist;
var float IncubationTimeMin, IncubationTimeMax;
var float SickTimeMin, SickTimeMax;

var bool bRevealSymptoms;

var SocHandler SocHandler;
var SocIsoReplicationInfo ReplInfo;

function PostBeginPlay()
{
    class'ScrnAchCtrl'.static.RegisterAchievements(class'SocAch');
    SocHandler = Level.Game.Spawn(class'SocHandler');
    SocHandler.Mut = self;
    SocHandler.VirusSpreadDistSq = VirusSpreadDist ** 2;

    ReplInfo = spawn(class'SocIsoReplicationInfo');
    ReplInfo.VirusSpreadDist = VirusSpreadDist;
}

function ModifyPlayer(Pawn Other)
{
    local ScrnHumanPawn P;

    if ( NextMutator != None )
        NextMutator.ModifyPlayer(Other);

    P = ScrnHumanPawn(Other);
    if (P != none) {
        P.CreateInventoryVeterancy(string(class'ToiletPaper'), 0);
    }
}

function Mutate(string MutateString, PlayerController Sender)
{
    local string Value;
    local ScrnPlayerInfo SPI;
    local VirusInfo Virus;
    local float f;
    local ScrnGameRules GameRules;

    super.Mutate(MutateString, Sender);

    Divide(MutateString, " ", MutateString, Value);
    if ( caps(MutateString) != "VIRUS" )
        return;

    GameRules = SocHandler.FindGameRules();
    if ( GameRules == none )
        return;

    MutateString = Value;
    Divide(MutateString, " ", MutateString, Value);
    MutateString = caps(MutateString);

    SPI = GameRules.GetPlayerInfo(Sender);

    if ( MutateString == "STAT" ) {
        if (SPI == none) {
            Sender.ClientMessage("No SPI");
            return;
        }
        Virus = VirusInfo(SPI.CustomInfo(class'VirusInfo'));
        if (Virus == none) {
            Sender.ClientMessage("No Virus");
            return;
        }
        if (Virus.bCured) {
            Sender.ClientMessage("Cured");
        }
        else if (Virus.bInfected) {
            if (Virus.Damage == 0) {
                Sender.ClientMessage("Asymptomatic");
            }
            else {
                Sender.ClientMessage("Infected with damage " $ Virus.Damage
                        $ ". Current phase: " $ Virus.GetStateName()
                        $ ". Next phase in " $ string(Virus.NextStateTime - Level.TimeSeconds));
            }
        }
        else {
            Sender.ClientMessage("Healthy");
        }
    }
    else if ( left(MutateString, 4) == "SICK" ) {
        if ( !GameRules.Mut.CheckAdmin(Sender) )
            return;

        f = float(Value);
        if ( f == 0.0 )
            f = frand();
        SPI = GameRules.CreatePlayerInfo(Sender);
        Virus = VirusInfo(SPI.CustomInfo(class'VirusInfo', true));
        Virus.Mut = self;
        Virus.Infect(f);
        if ( MutateString == "SICK1" ) {
            Virus.GotoState('SickPhase1');
        }
        else if ( MutateString == "SICK2" ) {
            Virus.GotoState('SickPhase2');
        }
        else if ( MutateString == "SICK3" ) {
            Virus.GotoState('SickPhase3');
        }
        else if ( MutateString == "SICK4" ) {
            Virus.GotoState('SickPhase4');
        }
        else if ( MutateString == "SICK5" ) {
            Virus.GotoState('SickPhase5');
        }
        Mutate("VIRUS STAT", Sender);
    }
    else if ( MutateString == "REVEAL" ) {
        if ( !GameRules.Mut.CheckAdmin(Sender) )
            return;

        bRevealSymptoms = true;
        Sender.ClientMessage("Symptoms revealed");
    }
    else if ( MutateString == "HEALTHY" ) {
        if ( !GameRules.Mut.CheckAdmin(Sender) )
            return;

        SPI = GameRules.CreatePlayerInfo(Sender);
        Virus = VirusInfo(SPI.CustomInfo(class'VirusInfo', true));
        Virus.Mut = self;
        Virus.GotoState('Healthy');
        Mutate("VIRUS STAT", Sender);
    }
}


defaultproperties
{
    GroupName="KF-SocIso"
    FriendlyName="Social Isolation"
    Description="The year 2020. While the Specimen Outbreak is still in progress, the second threat broke through - The Virus. The source of The Virus is still unidentified. Rumors say it is the latest experiment of Horzine labs. Others say a bat f****d a snake, and then got eaten by the Stinky Clot! 30% of the human population got infected, and the number is growing. There is no cure, no vaccine. The only way to survive is social isolation. Keep the distance to stop The Virus spreading but stay together to fight the Zeds."

    VirusSpreadDist=250  // 5m
    IncubationTimeMin=30
    IncubationTimeMax=300
    SickTimeMin=900
    SickTimeMax=2700
}
