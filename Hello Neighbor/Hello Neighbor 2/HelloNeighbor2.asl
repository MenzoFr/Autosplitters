// Supports Beta Playtest and Full Game
state("HelloNeighbor2-Win64-Shipping"){}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Hello Neighbor 2";
    
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    vars.Uhara.EnableDebug();
    
    vars.OnTriggeredCalled = false;
    
    vars.isLoading = false;
    vars.cutsceneFinished = false;
    vars.chapterFinishedCount = 0;
    
    settings.Add("recommendedSplits", true, "Use Recommended Splits (Full Game)");
    settings.Add("splits", false, "Splits (Full Game)");
    settings.Add("singleSplit", false, "Single Split", "splits");
    settings.Add("chapterSplit", true, "Chapter Split", "splits");
    settings.SetToolTip("recommendedSplits", "Automatically sets up split segments based on your split mode selection");
    settings.SetToolTip("singleSplit", "Only splits when the game ends");
    settings.SetToolTip("chapterSplit", "Splits at each chapter completion and at the end");
    
    vars.lastSplitMode = "";
}

init 
{
    switch (modules.First().ModuleMemorySize)
    {
        case (91025408):
            version = "Beta Playtest";
            break;
        default:
            version = "Full Game";
            break;
    }
    


    IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 05 ???????? 48 3B C? 48 0F 44 C? 48 89 05 ???????? E8");
    IntPtr fNames = vars.Helper.ScanRel(3, "48 8d 05 ???????? eb ?? 48 8d 0d ???????? e8 ???????? c6 05");

    vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);

    vars.FNameToString = (Func<ulong, string>)(fName =>
    {
        var nameIdx = (fName & 0x000000000000FFFF) >> 0x00;
        var chunkIdx = (fName & 0x00000000FFFF0000) >> 0x10;
        var number = (fName & 0xFFFFFFFF00000000) >> 0x20;

        IntPtr chunk = vars.Helper.Read<IntPtr>(fNames + 0x10 + (int)chunkIdx * 0x8);
        IntPtr entry = chunk + (int)nameIdx * sizeof(short);

        int length = vars.Helper.Read<short>(entry) >> 6;
        string name = vars.Helper.ReadString(length, ReadStringType.UTF8, entry + sizeof(short));

        return number == 0 ? name : name + "_" + number;
    });
    
    current.World = "";
    old.World = "";
    
    var Tool = vars.Uhara.CreateTool("UnrealEngine", "Events");
    
    if (version == "Beta Playtest")
    {
        IntPtr gSyncLoadCount = vars.Helper.ScanRel(5, "89 43 60 8B 05 ?? ?? ?? ??");
        vars.Helper["SyncLoadCount"] = vars.Helper.Make<int>(gSyncLoadCount);
        
        IntPtr CutsceneFinishedPtr = Tool.FunctionFlag("BP_StartGameCutscene_C", "BP_StartGameCutscene", "OnCutsceneFinished");
        vars.Resolver.Watch<ulong>("CutsceneFinished", CutsceneFinishedPtr);
        
        IntPtr OnTriggeredPtr = Tool.FunctionFlag("BP_StartGameCutscene_C", "BP_StartGameCutscene", "OnTriggered");
        vars.Resolver.Watch<ulong>("OnTriggered", OnTriggeredPtr);
        
        IntPtr RestartCutscenePtr = Tool.FunctionFlag("BP_TriggerRestart_C", "BP_TriggerRestart", "OnStartCutscene_Event");
        vars.Resolver.Watch<ulong>("RestartCutscene", RestartCutscenePtr);
    }
    else if (version == "Full Game")
    {
        IntPtr LoadStartPtr = Tool.FunctionFlag("WBP_LoadingScreen_C", "WBP_LoadingScreen_C", "OnInitialized");
        IntPtr LoadEndPtr = Tool.FunctionFlag("WBP_LoadingScreen_C", "WBP_LoadingScreen_C", "OnAnimationStarted");
        IntPtr CutsceneFinishedPtr = Tool.FunctionFlag("BP_CutsceneLevelManager_C", "BP_CutsceneLevelManager", "OnCutsceneFinished");
        IntPtr ChapterFinishedPtr = Tool.FunctionFlag("PSActivitySubsystem", "PSActivitySubsystem", "OnChapterFinished");
        IntPtr EndGamePtr = Tool.FunctionFlag("BP_TriggerEndGame_C", "BP_TriggerEndGame", "ExecuteUbergraph_BP_TriggerEndGame");
        
        vars.Resolver.Watch<ulong>("LoadStart", LoadStartPtr);
        vars.Resolver.Watch<ulong>("LoadEnd", LoadEndPtr);
        vars.Resolver.Watch<ulong>("CutsceneFinished", CutsceneFinishedPtr);
        vars.Resolver.Watch<ulong>("ChapterFinished", ChapterFinishedPtr);
        vars.Resolver.Watch<ulong>("EndGame", EndGamePtr);
    }
}

update
{
    vars.Helper.Update();
    vars.Helper.MapPointers();

    var world = vars.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None") 
    {
        current.World = world;
    }

    
    vars.Uhara.Update();
    
    if (version == "Beta Playtest")
    {
        if (current.OnTriggered != old.OnTriggered && current.OnTriggered != 0)
        {
            vars.OnTriggeredCalled = true;
        }
    }
    
    if (version == "Full Game")
    {
        if (current.CutsceneFinished != old.CutsceneFinished && current.CutsceneFinished != 0)
        {
            vars.cutsceneFinished = true;
        }
        
        if (current.LoadStart != old.LoadStart && current.LoadStart != 0)
        {
            vars.isLoading = true;
        }
        
        if (current.LoadEnd != old.LoadEnd && current.LoadEnd != 0)
        {
            vars.isLoading = false;
        }
        
        if (current.ChapterFinished != old.ChapterFinished && current.ChapterFinished != 0)
        {
            vars.chapterFinishedCount++;
        }
    }
    
    string currentSplitMode = "";
    bool useRecommendedSplits = settings["recommendedSplits"];
    
    if (settings["splits"])
    {
        if (settings["singleSplit"])
            currentSplitMode = "single";
        else
            currentSplitMode = "chapter";
    }
    else
    {
        currentSplitMode = "chapter";
    }
    
    string currentKey = currentSplitMode + "_" + useRecommendedSplits;
    if (currentKey != vars.lastSplitMode && !string.IsNullOrEmpty(currentSplitMode))
    {
        if (useRecommendedSplits && version == "Full Game")
        {
            if (currentSplitMode == "single")
            {
                timer.Run.Clear();
                timer.Run.Add(new LiveSplit.Model.Segment("Hello Neighbor 2"));
            }
            else if (currentSplitMode == "chapter")
            {
                timer.Run.Clear();
                timer.Run.Add(new LiveSplit.Model.Segment("Tutorial"));
                timer.Run.Add(new LiveSplit.Model.Segment("Policeman"));
                timer.Run.Add(new LiveSplit.Model.Segment("Baker"));
                timer.Run.Add(new LiveSplit.Model.Segment("Taxidermist"));
                timer.Run.Add(new LiveSplit.Model.Segment("Mayor"));
                timer.Run.Add(new LiveSplit.Model.Segment("Neighbor Ending"));
            }
        }
        vars.lastSplitMode = currentKey;
    }
}

start
{
    if (version == "Beta Playtest")
    {
        if (current.World == "RavenBrooks_New_P" && 
            current.CutsceneFinished != old.CutsceneFinished && 
            current.CutsceneFinished != 0)
        {
            return true;
        }
        if (current.World == "RavenBrooks_New_P" && 
            current.SyncLoadCount == 0 && 
            !vars.OnTriggeredCalled)
        {
            return true;
        }
    }
    else if (version == "Full Game")
    {
        if (current.LoadEnd != old.LoadEnd && current.LoadEnd != 0)
        {
            if (vars.cutsceneFinished && current.World == "TestMap_RavenBrooks")
            {
                return true;
            }
        }
    }
    
    return false;
}

split
{
    if (version == "Beta Playtest")
    {
        return current.World == "RavenBrooks_New_P" && 
               current.RestartCutscene != old.RestartCutscene && 
               current.RestartCutscene != 0;
    }
    else if (version == "Full Game")
    {
        string currentSplitMode = "";
        if (settings["splits"])
        {
            if (settings["singleSplit"])
                currentSplitMode = "single";
            else
                currentSplitMode = "chapter";
        }
        else
        {
            currentSplitMode = "chapter";
        }
        
        if (current.EndGame != old.EndGame && current.EndGame != 0)
        {
            return true;
        }
        
        if (currentSplitMode == "chapter")
        {
            if (current.ChapterFinished != old.ChapterFinished && current.ChapterFinished != 0)
            {
                if (vars.chapterFinishedCount % 2 == 1)
                {
                    return true;
                }
            }
        }
    }
    
    return false;
}

reset
{
    if ((current.World == "MenuMap_P" || current.World == "Menu_P") && (old.World != "MenuMap_P" && old.World != "Menu_P"))
    {
        if (version == "Beta Playtest")
        {
            vars.OnTriggeredCalled = false;
        }
        else if (version == "Full Game")
        {
            vars.cutsceneFinished = false;
            vars.chapterFinishedCount = 0;
        }
        return true;
    }
    
    return false;
}

isLoading
{
    if (version == "Full Game")
    {
        return vars.isLoading;
    }
    return false;
}
