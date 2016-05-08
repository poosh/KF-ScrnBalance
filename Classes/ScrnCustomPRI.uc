class ScrnCustomPRI extends LinkedReplicationInfo;

var int BlameCounter;

replication
{
	reliable if ( bNetDirty && Role == Role_Authority )
        BlameCounter;
}     

defaultproperties
{
    NetUpdateFrequency=1.0
}