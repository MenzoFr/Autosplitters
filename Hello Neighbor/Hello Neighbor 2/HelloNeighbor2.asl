// Only works for Beta Playtest for now
state("HelloNeighbor2-Win64-Shipping"){}

startup 
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Hello Neighbor 2";
    
    Assembly.Load(File.ReadAllBytes("Components/uhara9")).CreateInstance("Main");
    vars.Uhara.EnableDebug();
    
    vars.OnTriggeredCalled = false;
}

init 
{
    switch (modules.First().ModuleMemorySize)
    {
        case (91025408):
            version = "Beta Playtest";
            break;
        default:
            version = "Unknown";
            break;
    }
    
    if (version == "Unknown")
    {
        return;
    }

    IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 05 ???????? 48 3B C? 48 0F 44 C? 48 89 05 ???????? E8");
    IntPtr fNames = vars.Helper.ScanRel(3, "48 8d 05 ???????? eb ?? 48 8d 0d ???????? e8 ???????? c6 05");
    IntPtr gSyncLoadCount = vars.Helper.ScanRel(5, "89 43 60 8B 05 ?? ?? ?? ??");

    vars.Helper["GWorldName"] = vars.Helper.Make<ulong>(gWorld, 0x18);
    vars.Helper["SyncLoadCount"] = vars.Helper.Make<int>(gSyncLoadCount);

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
    
    IntPtr CutsceneFinishedPtr = Tool.FunctionFlag("BP_StartGameCutscene_C", "BP_StartGameCutscene", "OnCutsceneFinished");
    vars.Resolver.Watch<ulong>("CutsceneFinished", CutsceneFinishedPtr);
    
    IntPtr OnTriggeredPtr = Tool.FunctionFlag("BP_StartGameCutscene_C", "BP_StartGameCutscene", "OnTriggered");
    vars.Resolver.Watch<ulong>("OnTriggered", OnTriggeredPtr);
    
    IntPtr RestartCutscenePtr = Tool.FunctionFlag("BP_TriggerRestart_C", "BP_TriggerRestart", "OnStartCutscene_Event");
    vars.Resolver.Watch<ulong>("RestartCutscene", RestartCutscenePtr);
}

update
{
    if (version == "Unknown")
    {
        return false;
    }
    
    vars.Helper.Update();
    vars.Helper.MapPointers();

    var world = vars.FNameToString(current.GWorldName);
    if (!string.IsNullOrEmpty(world) && world != "None") 
    {
        current.World = world;
    }
    
    if (current.World != old.World)
    {
        print("Current World: " + current.World);
    }
    
    vars.Uhara.Update();
    
    if (current.OnTriggered != old.OnTriggered && current.OnTriggered != 0)
    {
        vars.OnTriggeredCalled = true;
    }
}

start
{
    if (version != "Beta Playtest")
    {
        return false;
    }
    
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
    
    return false;
}

split
{
    if (version != "Beta Playtest")
    {
        return false;
    }
    
    return current.World == "RavenBrooks_New_P" && 
           current.RestartCutscene != old.RestartCutscene && 
           current.RestartCutscene != 0;
}

reset
{
    if (version != "Beta Playtest")
    {
        return false;
    }
    
    if (current.World == "MenuMap_P" && old.World != "MenuMap_P")
    {
        vars.OnTriggeredCalled = false;
        return true;
    }
    
    return false;
}
