// Extention class for game rules
class ScrnGameRulesExt extends Info
    abstract;

var protected ScrnGameRules GameRules;

function PostBeginPlay()
{
    FindGameRules();
}

function FindGameRules()
{
    local GameRules G;

    if ( GameRules != none )
        return;

    for ( G = Level.Game.GameRulesModifiers; G != none; G = G.NextGameRules ) {
        GameRules = ScrnGameRules(G);
        if ( GameRules != none ) {
            ApplyGameRules();
            return;
        }
    }
    log("Unable to find ScrnGameRules. Trying again in 5 seconds...", class.name);
    SetTimer(5.0, false);
}

function ScrnGameRules GetGameRules()
{
    return GameRules;
}

function Timer()
{
    FindGameRules();
}

// gets called once GameRules is set
function ApplyGameRules() { }
