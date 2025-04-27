class ScrnCustomFontMsg extends CriticalEventPlus;

static function Font GetFont(ScrnHUD myHUD, Canvas C, int Switch, PlayerReplicationInfo RelatedPRI1,
        PlayerReplicationInfo RelatedPRI2, PlayerReplicationInfo LocalPlayer )
{
    return myHUD.GetFontSizeIndex(C, static.GetFontSize(Switch, RelatedPRI1, RelatedPRI2, LocalPlayer));
}
