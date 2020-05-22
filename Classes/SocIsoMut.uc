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

function Destroyed()
{
    ReplInfo.Destroy();
    super.Destroyed();
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

defaultproperties
{
    GroupName="KF-SocIso"
    FriendlyName="Social Isolation"
    Description="The year 2020. While the Specimen Outbreak is still in progress, the second threat broke through - The Virus. The source of The Virus is still unidentified. Rumors say it is the latest experiment of Horzine labs. Others say a bat f****d a snake, and then got eaten by the Stinky Clot! 30% of the human population got infected, and the number is growing. There is no cure, no vaccine. The only way to survive is social isolation. Keep the distance to stop The Virus spreading but stay together to fight the Zeds."

    VirusSpreadDist=250  // 5m
    IncubationTimeMin=30
    IncubationTimeMax=300
    SickTimeMin=1200
    SickTimeMax=3600
}
