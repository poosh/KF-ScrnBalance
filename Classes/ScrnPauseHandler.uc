class ScrnPauseHandler extends Info;

var ScrnBalance Mut;
var int PauseTimeRemaining;
var localized string strGamePaused, strSecondsLeft, strGameResumed;

state GamePaused
{
Begin:
    sleep(0.01);
    if (Level.Pauser != none) {
        Mut.BroadcastMessage(Repl(strGamePaused, "%s", string(PauseTimeRemaining)), true);
        // wait for pause time ends or game resumes by other source (e.g. admin)
        while (PauseTimeRemaining > 0 && Level.Pauser != none) {
            if (PauseTimeRemaining <= 5) {
                Mut.BroadcastMessage(String(PauseTimeRemaining));
            }
            else if ((PauseTimeRemaining%30 == 0) || (PauseTimeRemaining < 30 && PauseTimeRemaining%10 == 0)) {
                Mut.BroadcastMessage(Repl(strSecondsLeft, "%s", string(PauseTimeRemaining)));
            }
            sleep(1.0);
            --PauseTimeRemaining;
        }
        // resume game after pause time ends
        if (Level.Pauser != none) {
            Level.Pauser = none;
        }
        Mut.BroadcastMessage(strGameResumed, true);
    }
    Mut.GameResumed();
    GotoState('');
}


defaultproperties
{
    bAlwaysTick = true;
    PauseTimeRemaining=60
    strGamePaused="Game paused for %s seconds"
    strSecondsLeft="%s seconds left"
    strGameResumed="Game resumed"
}