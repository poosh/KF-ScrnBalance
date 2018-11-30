class ScrnLAWattachment extends LAWAttachment;

var name AttachmentFlashBoneName;

simulated function DoFlashEmitter()
{
    if (mMuzFlash3rd == None)
    {
        mMuzFlash3rd = Spawn(mMuzFlashClass);
        AttachToBone(mMuzFlash3rd, AttachmentFlashBoneName);
    }
    if(mMuzFlash3rd != None)
        mMuzFlash3rd.SpawnParticle(1);
}

defaultproperties
{
    mMuzFlashClass=Class'ScrnBalanceSrv.ScrnLAWBackblast'
    AttachmentFlashBoneName="ShellPort"
}
