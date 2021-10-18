class ScrnSuicideBomb extends ScrnPipeBombProjectile;

var name AttBone;
var vector AttOffset;
var rotator AttRot;


static function ScrnSuicideBomb MakeSuicideBomber(Pawn Instigator)
{
    local ScrnSuicideBomb bomb;

    if ( Instigator == none || Instigator.Health <= 0 )
        return none;

    bomb = Instigator.Spawn(default.class, Instigator);
    if ( bomb != none ) {
        bomb.Instigator = Instigator;
        bomb.AttachToInstigator();
        bomb.ArmingCountDown = 0;
        bomb.SetTimer(1.0, true);
    }
    return bomb;
}

static function ExplodeAll(LevelInfo Level)
{
    local ScrnSuicideBomb bomb;

    foreach Level.DynamicActors(class'ScrnSuicideBomb', bomb) {
        bomb.ActivateExplosion();
    }
}

static function DisintegrateAll(LevelInfo Level)
{
    local ScrnSuicideBomb bomb;

    foreach Level.DynamicActors(class'ScrnSuicideBomb', bomb) {
        bomb.Disintegrate(bomb.Location, vector(bomb.Rotation));
    }
}

simulated function PostBeginPlay()
{
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType, optional int HitIndex)
{
}

function Timer()
{
    super.Timer();
    if ( (Instigator == none || Instigator.Health <= 0) && !bHidden && !bTriggered ) {
        Disintegrate(Location, vector(Rotation));
    }
}

function ActivateExplosion()
{
    if ( bHidden || bTriggered || bEnemyDetected )
        return;

    bEnemyDetected = true;
    SetTimer(0.15, true);
}

simulated function AttachToInstigator()
{
    if ( Instigator == none ) {
        bHidden = true;
        return;
    }

    bHidden = false;
    SetLocation(Instigator.Location);
    Instigator.AttachToBone(self, Instigator.RootBone);
    SetRelativeRotation(AttRot);
    SetRelativeLocation(AttOffset);
}

simulated function Landed( vector HitNormal )
{
}

simulated function ProcessTouch( actor Other, vector HitLocation )
{
}

simulated function HitWall( vector HitNormal, actor Wall )
{
}

defaultproperties
{
    Physics=PHYS_None
    bDetectEnemies=false
    Damage=10000
    bCollideWorld=false
    bCollideActors=false
    bBlockActors=false
    bReplicateInstigator=true
    bSkipActorPropertyReplication=false

    AttBone="CHR_Pelvis"
    AttOffset=(X=-8,Y=5,Z=-3)
    AttRot=(Pitch=0,Yaw=16384,Roll=0)
}
