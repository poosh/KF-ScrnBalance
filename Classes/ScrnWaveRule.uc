class ScrnWaveRule extends Info
    dependson(ScrnTypes)
    dependson(ScrnWaveInfo)
    abstract;

var ScrnWaveHandler WH;

function Load();
function Run();
function WaveTimer();
function bool CheckWaveEnd() { return true; }