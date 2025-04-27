class ScrnWaitingFontMsg extends ScrnCustomFontMsg;

static function Font GetFont(ScrnHUD myHUD, Canvas C, int Switch, PlayerReplicationInfo RelatedPRI1,
        PlayerReplicationInfo RelatedPRI2, PlayerReplicationInfo LocalPlayer)
{
    return myHUD.LoadWaitingFont(clamp(static.GetFontSize(Switch, RelatedPRI1, RelatedPRI2, LocalPlayer), 0, 1));
}
