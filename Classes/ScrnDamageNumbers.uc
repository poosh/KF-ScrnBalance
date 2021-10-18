// server-side only. Delayed damame number handler
class ScrnDamageNumbers extends Info;

var ScrnPlayerController PC;

var float ComboDamageAckDelay;  // delay damage ack to client to combine more damages
struct SDamageAck {
    var Pawn Victim;
    var class<DamageType> DamType;
    var byte DamTypeNum;
    var int Damage;
    var vector HitLocation;
    var float NetTime;
};
var transient array<SDamageAck> PendingDamakeAcks;


function DamageMade(int Damage, vector HitLocation, byte DamTypeNum, Pawn Victim, class<DamageType> DamType)
{
    local int i;

    for ( i = 0; i < PendingDamakeAcks.length; ++i ) {
        if ( PendingDamakeAcks[i].Victim == Victim && PendingDamakeAcks[i].DamType == DamType
                &&  (PendingDamakeAcks[i].DamTypeNum == DamTypeNum
                    || (DamTypeNum == 3 && PendingDamakeAcks[i].DamTypeNum == 1)) )  // headshot + headless
        {
            PendingDamakeAcks[i].Damage += Damage;
            return;
        }
    }

    PendingDamakeAcks.insert(i, 1);
    PendingDamakeAcks[i].Victim = Victim;
    PendingDamakeAcks[i].DamType = DamType;
    PendingDamakeAcks[i].DamTypeNum = DamTypeNum;
    PendingDamakeAcks[i].Damage = Damage;
    PendingDamakeAcks[i].HitLocation = HitLocation;
    PendingDamakeAcks[i].NetTime = Level.TimeSeconds + ComboDamageAckDelay;
    Enable('Tick');
}

function Tick( float DeltaTime )
{
    if ( PendingDamakeAcks.length == 0 ) {
        Disable('Tick');
        return;
    }

    while ( PendingDamakeAcks.length > 0 &&  Level.TimeSeconds > PendingDamakeAcks[0].NetTime ) {
        PC.SendDamageAck(PendingDamakeAcks[0].Damage, PendingDamakeAcks[0].HitLocation, PendingDamakeAcks[0].DamTypeNum);
        PendingDamakeAcks.remove(0, 1);
    }
}


defaultproperties
{
    ComboDamageAckDelay=0.1
}
