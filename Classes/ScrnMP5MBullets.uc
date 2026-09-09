//loads skeletalmesh instead of static mesh for shiny bullets
class ScrnMP5MBullets extends ScrnFakedProjectile;

var(Display) string MeshRef;

static function PreloadAssets()
{
    if( default.MeshRef != "" )
        UpdateDefaultMesh(Mesh(DynamicLoadObject(default.MeshRef, class'Mesh', true)));
}

static function bool UnloadAssets()
{
    if( default.MeshRef != "" )
        UpdateDefaultMesh(none);

    return true;
} 

//this doesn't seem to work but I'll leave it here anyway
function HandleBulletScale(int MagAmmoRemaining)
{
    if (MagAmmoRemaining == 1)
    {
        SetBoneScale(0, 0.0, 'bullet01');
        SetBoneScale(1, 0.0, 'bullet02');
    }
    else if (MagAmmoRemaining == 2)
    {
        SetBoneScale(0, 1.0, 'bullet01');
        SetBoneScale(1, 0.0, 'bullet02');
    }    
    else if (MagAmmoRemaining > 2)
    {
        SetBoneScale(0, 1.0, 'bullet01');
        SetBoneScale(1, 1.0, 'bullet02');
    }         
}


defaultproperties
{
    Mesh=SkeletalMesh'ScrnAnims.mp5m_bullets'
    MeshRef="ScrnAnims.mp5m_bullets"
    DrawType=DT_Mesh
}
