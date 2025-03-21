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
    var array<ZVolLink> Links;
    var bool bBoss;  // TODO
};
