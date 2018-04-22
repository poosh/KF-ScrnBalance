Class ScrnNailBodyAttacher extends BodyAttacher;

var float MonsterSpeed;
var float MonsterOriginalSpeed;
var EPhysics MonsterPhysics;
    
simulated function PostBeginPlay()
{
    local KFMonster m;

    m = KFMonster(Owner);
    if ( m != none ) {
        MonsterSpeed = m.GroundSpeed;
        MonsterOriginalSpeed = m.OriginalGroundSpeed;
        MonsterPhysics = Owner.Physics;
        m.GroundSpeed = 0;
        m.OriginalGroundSpeed = 0;
    }
    log("ScrnNailBodyAttacher spawned");
    
    SetTimer(1,False);
}

simulated function Destroyed()
{
    local KFMonster m;

    super.Destroyed();

    m = KFMonster(Owner);
    if ( m != none && m.Health > 0 ) {
        m.GroundSpeed = MonsterSpeed;
        m.OriginalGroundSpeed = MonsterOriginalSpeed;
        m.SetPhysics(MonsterPhysics);
    }
    log("ScrnNailBodyAttacher destroyed");
}
    
simulated function Tick( float Delta )
{
    if( Owner==None )
    {
        Destroy();
        Return;
    }
    //Owner.SetLocation(Location);
    if( Physics==PHYS_Karma /* || Owner.Physics!=PHYS_KarmaRagdoll */ )
         Return;
    if( Owner.Physics !=PHYS_KarmaRagdoll  )
         Owner.SetPhysics(PHYS_KarmaRagdoll);
         
    KConstraintActor1 = Owner;
    KPos1 = (Location-AttachEndPoint)/50.f;
    KPos2 = AttachEndPoint/50.f;
    KPriAxis1 = vect(1,0,0);
    KSecAxis1 = vect(0,0,1);
    KPriAxis2 = vect(1,0,0);
    KSecAxis2 = vect(0,0,1);
    
    SetPhysics(PHYS_Karma);

    SetTimer(0,False); //disable auto-destroy
}

defaultproperties
{
}
