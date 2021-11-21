class ScrnAchMutator extends ScrnMutator
    abstract;

var bool bKillMe;
var class<ScrnAchievements> AchClass;
var class<ScrnAchHandlerBase> AchHandler;


function PostBeginPlay()
{
    super.PostBeginPlay();
    if ( bDeleteMe )
        return;

    class'ScrnAchCtrl'.static.RegisterAchievements(AchClass);
    if ( AchHandler != none ) {
        Level.Game.Spawn(AchHandler);
    }
    if ( bKillMe ) {
        RegisterPostMortem();
    }
}


defaultproperties
{
    bAddToServerPackages=true
    bKillMe=true
}
