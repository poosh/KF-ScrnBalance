class ScrnFrag extends Frag;

var transient float CookExplodeTimer;
var transient bool bCooking, bThrowingCooked;
var transient bool bBlewInHands; //client didn't throw nade - it blew up in his hands
//var float CookThrowRate; //how faster we throwing a cooked nade comparing with regular throw

replication
{
	reliable if(Role < ROLE_Authority)
		ServerCookNade;

	reliable if(Role == ROLE_Authority)
		ClientThrowCooked;
}

//executed on client-side only
simulated function CookNade()
{
    if( !Instigator.IsLocallyControlled() ) return;
    
	HandleSleeveSwapping(); // use proper arms
	
    ServerCookNade();
    if( Role < ROLE_Authority ) {
        CookExplodeTimer = Level.TimeSeconds + class'ScrnBalanceSrv.ScrnNade'.default.ExplodeTimer;
        bCooking = true;
        bThrowingCooked = false;
    }
    KFPawn(Instigator).SecondaryItem = self; //it'll be replicated
    PlayAnim(TossAnim, 10, 0.0, 0);
    FreezeAnimAt(4.8, 0);
}

//server
function ServerCookNade()
{
    CookExplodeTimer = Level.TimeSeconds + class'ScrnBalanceSrv.ScrnNade'.default.ExplodeTimer;
    bCooking = true;
    bThrowingCooked = false;
    bBlewInHands = false;
}

function Tick( float DeltaTime )
{
    super.Tick(DeltaTime);

    //server: tell client to throw nade, when countdown reached
    if (bCooking && !bThrowingCooked && Level.TimeSeconds >= CookExplodeTimer) {
        bBlewInHands = true;
        ClientThrowCooked();
    }
}


simulated function ClientThrowCooked() 
{
    if( !Instigator.IsLocallyControlled() )
        return;
        
    bThrowingCooked = true;
    StartThrow();
    if( Role < ROLE_Authority )
        bCooking = false; //set here to immediately hide progress bar from the HUD
}


simulated function StartThrow()
{
    if (bCooking && !bThrowingCooked)
        return; //can't throw nade while cooking
    
    HandleSleeveSwapping(); // use proper arms
	
    super.StartThrow();
} 

function ServerStartThrow()
{
    if( !Instigator.IsLocallyControlled() ) {
        bThrowingCooked = bCooking;
    }
    super.ServerStartThrow();
}

defaultproperties
{
     Weight=0.000000
     FireModeClass(0)=Class'ScrnBalanceSrv.ScrnFragFire'
     PickupClass=Class'ScrnBalanceSrv.ScrnFragPickup'
     ItemName="Frag Grenade SE"
     bAlwaysRelevant=True
}
