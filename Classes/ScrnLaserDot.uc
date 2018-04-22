// This class is deprecated and kept only for compatibility reasons.
// Please migrate to ScrnLaserWeaponAttachment.
// (c) PooSH
class ScrnLaserDot extends LaserDot;

#exec OBJ LOAD FILE=ScrnTex.utx

enum ELaserColor {
    LASER_None,
    LASER_Red,
    LASER_Green,
    LASER_Blue,
    LASER_Orange,
    LASER_Destroyed,
};
var ELaserColor LaserColor;


static function color GetLaserColor(ELaserColor aLaserType)
{
    switch (aLaserType) {
        case LASER_Green:
            return class'Canvas'.static.MakeColor(0, 255, 0);
        case LASER_Blue:
            // original blue is too dark, so make it a bit lighter 
            return class'Canvas'.static.MakeColor(0, 150, 255);
        case LASER_Orange:
            return class'Canvas'.static.MakeColor(255, 150, 0);

    }
    return class'Canvas'.static.MakeColor(255, 0, 0); //red
}

simulated function SetLaserColor(ELaserColor NewLaserColor)
{
    LaserColor = NewLaserColor;
    
    switch (NewLaserColor) {
        case LASER_Red: case LASER_Destroyed:
            ProjTexture=Texture'ScrnTex.Laser.Laser_Dot_Red';
            break;
        case LASER_Green:
            ProjTexture=Texture'ScrnTex.Laser.Laser_Dot_Green';
            break;
        case LASER_Blue:
            ProjTexture=Texture'ScrnTex.Laser.Laser_Dot_Blue';
            break;
        case LASER_Orange:
            ProjTexture=Texture'ScrnTex.Laser.Laser_Dot_Orange';
            break;
    }
}

// both ToggleDot() and SetValid() are deprecated. Use SetLaserColor() instead
simulated function ToggleDot()
{
     if( ProjTexture== default.ProjTexture )
     {
        ProjTexture = Texture'ScrnTex.Laser.Laser_Dot_Green';
     }
     else
     {
        ProjTexture = Texture'ScrnTex.Laser.Laser_Dot_Red';
     }
}
simulated function SetValid(bool bNewValid)
{
    
    if (bNewValid)
        SetLaserColor(LASER_Green); 
    else 
        SetLaserColor(LASER_Red); 
}

defaultproperties
{
     ProjTexture=Texture'ScrnTex.Laser.Laser_Dot_Blue'
     RemoteRole=ROLE_None
}
