class TSCTeam extends xTeamRoster;

var int ZedKills, Deaths;
var int LastMinKills;       // how many kills team scored, exluding current minute
var int PrevMinKills;       // how many kills team scored, exluding current and previous minute
var int WaveKills;          // how many kills team scored in previous waves

replication
{
    // Variables the server should send to the client.
    reliable if( bNetDirty && (Role==ROLE_Authority) )
        ZedKills, Deaths, LastMinKills, PrevMinKills, WaveKills;
}