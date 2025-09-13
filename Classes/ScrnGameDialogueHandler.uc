class ScrnGameDialogueHandler extends Info;

var ScrnGameType Game;

var array<string> Dialogues;
var int Index;
var transient bool bRunning;
var transient float NextDialogueTime;

var transient bool bPrevOK;
var transient bool bOptional, bKeepWithPrev;
var transient int Duration;
var transient byte DialogueType;
var transient PlayerReplicationInfo PRI;
var transient string Text;

function bool Load(out array<string> NewDialogues)
{
    EndDialogue();
    Dialogues = NewDialogues;
    if (Dialogues.length == 0)
        return false;

    // log("Loaded " $ Dialogues.length $ " dialogues", class.name);

    Index = -1;
    return LoadNext();
}

function bool IsRunning()
{
    return bRunning;
}

// Format: "attr:speaker:text" or "duration"
// , where attr: "?^duration"
protected function bool LoadNext()
{
    local string attr, speaker, s;
    local PlayerReplicationInfo LastPRI;

    if (++Index >= Dialogues.Length) {
        return false;
    }

    Duration = 0;
    DialogueType = Game.ScrnGRI.DT_NONE;
    LastPRI = PRI;
    PRI = none;
    Text = "";
    bKeepWithPrev = false;
    bOptional = false;


    if (!Divide(Dialogues[Index], ":", attr, speaker)) {
        // "Dialogue=duration" for pause between dialogues
        Duration = int(Dialogues[Index]);
        if (Duration > 0) {
            ScheduleNext();
            return true;
        }
        LogBad();
        return false;
    }

    if (!Divide(speaker, ":", speaker, Text) || speaker == "" || Text == "") {
        LogBad();
        return false;
    }

    while (attr != "") {
        s = Left(attr, 1);
        if (s == "?") {
            bOptional = true;
        }
        else if (s == "^") {
            bKeepWithPrev = true;
            bOptional = true;
        }
        else {
            Duration = int(attr);
            if (Duration <= 0) {
                LogBad("Bad attribute: " $ attr);
                return false;
            }
            break;
        }
        attr = Mid(attr, 1);
    }

    if (bKeepWithPrev && !bPrevOK){
        return LoadNext();
    }

    if (Duration <= 0) {
        Duration = clamp(class'ScrnFunctions'.static.TextReadTime(Text), 5, 30);
    }

    speaker = caps(speaker);
    if (speaker == "TRADER") {
        DialogueType = Game.ScrnGRI.DT_TRADER;
    }
    else if (Left(speaker, 6) == "PLAYER") {
        DialogueType = Game.ScrnGRI.DT_PLAYER;
        PRI = Game.ScrnBalanceMut.GameRules.FindDialoguePlayer(int(Mid(speaker, 6)), LastPRI);
        if (PRI == none) {
            log(speaker $ " not found", class.name);
            bPrevOK = false;
            if (bOptional) {
                return LoadNext();
            }
            return false;
        }
    }
    else {
        LogBad();
        return false;
    }

    bPrevOK = true;
    Game.ScrnGRI.DisplayDialogue(DialogueType, Text, PRI, Duration);
    ScheduleNext();
    return true;
}

function LogBad(optional string s)
{
    log("Bad dialogue line #" $ Index $ ": '" $ Dialogues[Index] $ "'. " $ s, class.name);
}

protected function ScheduleNext()
{
    // log("Dialog line #" $ Index $ "' scheduled for " $ Duration $ "s: '" $ Dialogues[Index] , class.name);
    bRunning = true;
    NextDialogueTime = Level.TimeSeconds + Duration;
    SetTimer(Duration, false);
}

function Timer()
{
    if (!LoadNext()) {
        EndDialogue();
    }
}

function EndDialogue()
{
    // log("EndDialogue", class.name);
    PRI = none;
    bRunning = false;
    bPrevOK = false;
    SetTimer(0, false);
    Game.ScrnGRI.ClearDialogue();
}
