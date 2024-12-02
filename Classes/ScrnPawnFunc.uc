class ScrnPawnFunc extends Object;


static function float AssessThreatTo(ScrnHumanPawn ScrnPawn, KFMonsterController MC)
{
    local KFMonster Zed;
    local float DistancePart, RandomPart, TacticalPart;
    local float Distance;
    local bool bAttacker, bSeeMe;

    Zed = KFMonster(MC.Pawn);

    Distance = VSize(Zed.Location - ScrnPawn.Location) - Zed.CollisionRadius - ScrnPawn.CollisionRadius;
    bSeeMe = Distance < 1250 && MC.CanSee(ScrnPawn); // check line of sight only withing 25 meters
    bAttacker = bSeeMe && Zed.LastDamagedBy == ScrnPawn;

    // v7.52: if MC is on different floor (5+ meters), then give additional 20 meters of distance
    if (!bSeeMe && abs(MC.Pawn.Location.Z - ScrnPawn.Location.Z) > 250) {
        Distance += 1000;
    }

    if (Distance < Zed.MeleeRange) {
        // extra +10% to players in the melee range
        DistancePart = 50.0;
    }
    else if (Distance <= 500.0) {
        // lose 2 DP/m withing 10m
        DistancePart = 40.0 - Distance / 25.0;
    }
    else  if (Distance <= 1500.0) {
        // lose 1 DP/m after 10m
        DistancePart = 30.0 - Distance / 50.0;
    }

    // more chance to attack the same enemy multiple times
    if (MC.Enemy == ScrnPawn || MC.Target == ScrnPawn) {
        if (bAttacker) {
            TacticalPart = 50.0;
        }
        else if (bSeeMe) {
            TacticalPart = 35.0;
        }
        else {
            TacticalPart = 15.0;
        }
    }
    else if (bAttacker) {
        TacticalPart = 45.0;
    }
    else if (bSeeMe) {
        TacticalPart = 25.0;
    }

    RandomPart = frand() * fclamp(100.0 - DistancePart - TacticalPart, 0.0, 20.0);

    return DistancePart + TacticalPart + RandomPart;
}
