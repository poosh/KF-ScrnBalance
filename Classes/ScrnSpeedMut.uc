class ScrnSpeedMut extends ScrnMutator;

var float SpeedMod;

struct SPawnSpeed {
    var class<Pawn> PawnClass;
    var float GroundSpeed;
    var float AirSpeed;
};
var transient array<SPawnSpeed> DefaultSpeeds;

function PostBeginPlay()
{
    super.PostBeginPlay();
    class'ScrnPlayerController'.default.PawnClass = class'ScrnSpeedPawn';
}

function ModifySpeed(Pawn P)
{
    local int i;

    for (i = 0; i < DefaultSpeeds.length; ++i) {
        if (DefaultSpeeds[i].PawnClass == P.class) {
            return;
        }
    }
    // if reached here, this is a new pawn class. Backup the original speed and boost it up.
    DefaultSpeeds.insert(i, 1);
    DefaultSpeeds[i].PawnClass = P.class;
    DefaultSpeeds[i].GroundSpeed = P.default.GroundSpeed;
    DefaultSpeeds[i].AirSpeed = P.default.AirSpeed;

    P.default.GroundSpeed *= SpeedMod;
    P.default.AirSpeed *= SpeedMod;

    P.GroundSpeed *= SpeedMod;
    P.AirSpeed *= SpeedMod;
}


function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local Pawn P;

    P = Pawn(Other);
    if (P != none && !P.IsA('ScrnHumanPawn')) {
        ModifySpeed(P);
    }

    return true;
}

function ServerTraveling(string URL, bool bItems)
{
    local int i;

    if (NextMutator != None)
        NextMutator.ServerTraveling(URL,bItems);

    log("Restore default speeds", class.name);
    class'ScrnPlayerController'.default.PawnClass = class'ScrnHumanPawn';
    // restore the original speeds
    for (i = 0; i < DefaultSpeeds.length; ++i) {
        DefaultSpeeds[i].PawnClass.default.GroundSpeed = DefaultSpeeds[i].GroundSpeed;
        DefaultSpeeds[i].PawnClass.default.AirSpeed = DefaultSpeeds[i].AirSpeed;
    }
    DefaultSpeeds.length = 0;
}


defaultproperties
{
    VersionNumber=96925
    GroupName="KF-Speed"
    FriendlyName="ScrN Speed Boost"
    Description="Boosts movement speed of players and zeds"

    SpeedMod=1.25
}
