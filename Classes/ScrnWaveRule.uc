class ScrnWaveRule extends object
    dependson(ScrnTypes)
    dependson(ScrnWaveInfo)
    abstract;

var ScrnGameLength GL;

function Load();
function Run();
function WaveTimer();
function bool CheckWaveEnd() { return true; }