class ScrnInit extends Object
    abstract
    Config(ScrnBalanceSrv);


var string DefaultVotingHandler;

var globalconfig bool bVotingHandlerOverride;
var globalconfig string CustomVotingHandler;


defaultproperties
{
    DefaultVotingHandler="KFMapVoteV3SE.KFVotingHandler"
    bVotingHandlerOverride=true
}