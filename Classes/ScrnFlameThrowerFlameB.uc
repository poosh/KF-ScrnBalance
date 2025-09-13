class ScrnFlameThrowerFlameB extends FlameThrowerFlameB;

simulated function PostNetBeginPlay()
{
    local ScrnFlameThrowerFlameB Other;
    local float DistSq;

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
        // each second flame will have DL while holding M1
        DistSq = 62500;  // 5m
    }
    else {
        // each 4th flame will have DL while holding M1
        DistSq = 160000;  // 8m
    }

    foreach DynamicActors(class'ScrnFlameThrowerFlameB', Other) {
        if (Other != self && Other.bDynamicLight && VSizeSquared(Other.Location - Location) < DistSq) {
            bDynamicLight = false;
            LightType = LT_None;
            return;
        }
    }
}

defaultproperties
{
    LightType=LT_Pulse
    LightHue=30
    LightSaturation=100
    LightBrightness=300.000000
    LightRadius=4.000000
    bNoDelete=False
    bDynamicLight=True
}