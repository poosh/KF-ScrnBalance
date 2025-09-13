class ScrnFuelFlame extends FuelFlame;

simulated function PostNetBeginPlay()
{
    local ScrnFuelFlame Other;
    local float DistSq, MinDistSq;

    Super.PostNetBeginPlay();

    if (Level.NetMode == NM_DedicatedServer || !bDynamicLight)
        return;

    //  Level.DetailMode = "World Detail" in the game settings
    if (Level.bDropDetail || Level.DetailMode == DM_Low) {
        bDynamicLight = false;
        LightType = LT_None;
        return;
    }

    if (Level.DetailMode == DM_SuperHigh) {
        MinDistSq = 2500;  // 1m
    }
    else {
        MinDistSq = 22500;  // 3m
    }

    foreach DynamicActors(class'ScrnFuelFlame', Other) {
        if (Other == self || !Other.bDynamicLight)
            continue;

        DistSq = VSizeSquared(Other.Location - Location);
        if (DistSq < 200) {
            // overlapping effect - destroy duplicate
            Other.Kill();
            Other.bDynamicLight = false;
            Other.LightType = LT_None;
        }
        else if (Other.bDynamicLight && DistSq < MinDistSq) {
            Other.bDynamicLight = false;
            Other.LightType = LT_None;
        }
    }
}
