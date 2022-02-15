Class ScrnUserGameLength extends ScrnGameLength
    PerObjectConfig
    Config(ScrnUserGames);

var config bool bUserWaves, bUserZeds;

function LoadGame(ScrnGameType MyGame)
{
    if (bUserWaves) {
        WaveInfoClass = class'ScrnUserWaveInfo';
    }
    if (bUserZeds) {
        ZedInfoClass = class'ScrnUserZedInfo';
    }
    super.LoadGame(MyGame);
}
