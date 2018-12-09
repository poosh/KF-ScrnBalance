class TheGuardian extends TSCBaseGuardian
    abstract;

var localized string strBlame;

function PawnBaseDied()
{
    local vector base_loc;
    if ( Pawn(Base) != none ) {
        base_loc = Base.Location;
        Base.DetachFromBone(self);
        SetBase(none);
        SetLocation( base_loc + vect(0, 0, 20) );
        Velocity = PhysicsVolume.Gravity;
        if ( KFGameType(Level.Game).bWaveBossInProgress )
            GotoState('SettingUp');
        else
            GotoState('Dropped');
    }
}

function BaseSetupFailed()
{
    local TscGame game;

    game = TscGame(Level.Game);

    if ( LastHolder != none ) {
        game.ScrnBalanceMut.BlamePlayer(LastHolder, strBlame);
    }
    else if ( ScrnPlayerController(GetBaseSetter()) != none ) {
        game.ScrnBalanceMut.BlamePlayer(ScrnPlayerController(GetBaseSetter()), strBlame);
    }

    if ( TSCGRI.bWaveInProgress ) {
        game.BootShopPlayers();
    }

    MoveToShop(MyShop); // teleport next to shop
    Score();

    if ( !bActive ) {
        log( "Base setup failed", class.name );
        SendHome();
    }
}

auto state Home
{
    function BeginState()
    {
        local StinkyController SC;

        super.BeginState();

        if ( Team != none )
            SC = FTGGame(Level.Game).StinkyControllers[Team.TeamIndex];
        if ( SC != none )
            SC.Pawn.Suicide();
    }
}

state Guarding
{
    ignores TakeDamage;

    function bool ValidHolder(Actor other)
    {
        return StinkyClot(other) != none; // only StinkyClot can grab the guardian while guarding
    }

    function EndState()
    {
        if ( Holder != none ) {
            // make sure that Stinky Clot is not holding me
            Holder.DetachFromBone(self);
            SetBase(none);
        }
        Holder = none;
        bHeld = false;

        super.EndState();
    }

    function bool ShouldWipeOnBaseLost()
    {
        return WipeOnBaseLost != none && ( TSCGRI.MaxMonsters > 10 || KFGameType(Level.Game).bWaveBossInProgress );
    }
}

defaultproperties
{
    GameObjBone="CHR_RArmPalm"
    GameObjOffset=(X=5,Y=-10,Z=-10)
    GameObjRot=(Pitch=0,Yaw=0,Roll=0)

    WipeOnBaseLost=class'DamTypeEnemyBase'
    bSkipActorPropertyReplication=false
    bReplicateMovement=true
    CollisionHeight=12
    DrawScale=0.5
    PrePivot=(Z=23)
    SameTeamCounter=25
    Damage=2 // do less damage to enemies due to moving

    strBlame="%p blamed for base setup failure"
}
