class ScrnPauser extends PlayerReplicationInfo;

event PostBeginPlay();
simulated event PostNetBeginPlay();
simulated event PostNetReceive();
function Timer();
function SetPlayerName(string S);

defaultproperties
{
    bNetNotify=false
    bBot=true
    bAdmin=true
    bSilentAdmin=true
    PlayerName="ScrN Pauser"
}