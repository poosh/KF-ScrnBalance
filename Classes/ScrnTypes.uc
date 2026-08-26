class ScrnTypes extends Object abstract;

// Ensure the enum values are synced with ScrnBalance!
enum EZedTimeTrigger {
    ZT_Default,
    ZT_Random,
    ZT_Bucket,
    ZT_HiddenBucket,
    ZT_Disabled,
    ZT_Custom
};

struct ZVolLink {
    var ZombieVolume Src;
    var KFDoorMover Door;
};

struct ZVolInfo {
    var ZombieVolume ZVol;
    var array<ZVolLink> Links;
    var bool bBoss;  // TODO
    var bool bStaired;
    var bool bElevated;
    var vector Location;
    var float ExtraDistance;

    // temporary values during zed spawn
    var float tScore;
};
