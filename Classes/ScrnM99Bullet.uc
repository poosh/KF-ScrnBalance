class ScrnM99Bullet extends M99Bullet;

var protected actor LastHitWall;
var float HitVelocityReduction;
var float HitDamageReduction;
var int MinDamage;

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    local vector X;
    local Vector TempHitLocation, HitNormal;
    local array<int>    HitPoints;
    local KFPawn HitPawn;
    local bool bHeadshot;

    if ( Other == none || Other == Instigator || Other.Base == Instigator || !Other.bBlockHitPointTraces || Other==IgnoreImpactPawn )
        return;

    X =  Vector(Rotation);
     if( ROBulletWhipAttachment(Other) != none ) {
        if( Other.Base == none || Other.Base.bDeleteMe)
            return;

        Other = Instigator.HitPointTrace(TempHitLocation, HitNormal, HitLocation + (65535 * X), HitPoints, HitLocation,, 1);
        if( Other == none || Other == IgnoreImpactPawn || HitPoints.Length == 0 )
                return;
        HitPawn = KFPawn(Other);
        if (Role == ROLE_Authority) {
            if ( HitPawn != none ) {

                if( !HitPawn.bDeleteMe )
                    HitPawn.ProcessLocationalDamage(Damage, Instigator, TempHitLocation, MomentumTransfer * X, MyDamageType,HitPoints);
                IgnoreImpactPawn = HitPawn;
            }
        }
    }
    else {
        if ( ExtendedZCollision(Other) != none)
            Other = Other.Owner; // ExtendedZCollision is attached to KFMonster

        if ( Other == IgnoreImpactPawn )
            return; // avoid double hitting the same target

        if ( Pawn(Other) != none )
            IgnoreImpactPawn = Pawn(Other);

        bHeadshot = IgnoreImpactPawn != none && IgnoreImpactPawn.IsHeadShot(HitLocation, X, 1.0);
        if ( KFMonster(IgnoreImpactPawn) != none )
            Damage = AdjustZedDamage(Damage, KFMonster(IgnoreImpactPawn), bHeadshot);

        if ( bHeadshot )
            IgnoreImpactPawn.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, DamageTypeHeadShot);
        else
            Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
    }

    if( Level.NetMode!=NM_Client )
        PlayhitNoise(Pawn(Other)!=none && Pawn(Other).ShieldStrength>0);

    Velocity *= HitVelocityReduction;
    Damage *= HitDamageReduction;
    if ( Damage < MinDamage )
        Destroy();
}

simulated function int AdjustZedDamage( int Damage, KFMonster Victim, bool bHeadshot )
{
    if ( ZombieFleshpound(Victim) != none )
        Damage *= 0.7; // It will be multiplied by 0.5 in ZombieFleshpound.TakeDamage(), ending up with 0.35
    else if (ZombieBoss(Victim) != none )
         Damage *= 0.8; // 20% resistance to Pat
    else if ( Level.Game.GameDifficulty >= 5.0 && ZombieScrake(Victim) != none )
        Damage *= 0.5;
        
    return Damage;
}

simulated function HitWall( vector HitNormal, actor Wall )
{
    if ( LastHitWall != none && LastHitWall == Wall )
        Destroy(); // stuck in door

    LastHitWall = Wall;
    super.HitWall(HitNormal, Wall);
}

defaultproperties
{
    DamageTypeHeadShot=Class'ScrnBalanceSrv.ScrnDamTypeM99HeadShot'
    MyDamageType=Class'ScrnBalanceSrv.ScrnDamTypeM99SniperRifle'
    HeadShotDamageMult=3.000000
    Damage=800.000000
    DamageRadius=0
    MinDamage=30
    HitDamageReduction=0.80
    HitVelocityReduction=0.85
}
