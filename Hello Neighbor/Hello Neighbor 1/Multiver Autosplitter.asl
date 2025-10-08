state("HelloNeighbor-Win64-Shipping", "v1.1.6")
{
    int missionNumber: 0x02D7DB58, 0xF8, 0x70, 0x260;
    int menuStatus: 0x02C1B640, 0x900, 0x7D8;
    int loadStatus: 0x29C2C44;
    int startStatus: 0x02C1B640, 0xCFC;
    bool IsLoading: 0x029C2C44;
}

state("HelloNeighbor-Win64-Shipping", "v0.8")
{
    int missionNumber: 0x037D9490, 0x15C0;
    int menuStatus: 0x0383C0D0, 0x920, 0x550;
    int loadStatus: 0x037DB780, 0xA00;
    int startStatus: 0x0383C0D0, 0xD0C;
    bool IsLoading: 0x037DB780, 0xA00;
}

state("HelloNeighbor-Win64-Shipping", "v1.4")
{
    int missionNumber: 0x028CA4B0, 0x300;
    int menuStatus: 0x02F9C2C0, 0x880, 0x7C8;
    int loadStatus: 0x030DBBE8, 0x54C;
    int startStatus: 0x02D5F7C0, 0x5D0, 0x20, 0xEDC;
    bool IsLoading: 0x030DBBE8, 0x54C;
}

state("HelloNeighborReborn-Win64-Shipping", "Alpha 1")
{
    int startStatus: 0x0238D478, 0x118, 0x130, 0x380, 0x50;
    float xPos: 0x0238D478, 0x118, 0x130, 0x160, 0x124;
    float yPos: 0x0238D478, 0x118, 0x130, 0x160, 0x128;
    float zPos: 0x0238D478, 0x118, 0x130, 0x160, 0x120;
    float csState: 0x0238D478, 0x118, 0xD0, 0x3C8; 
}

init
{
    vars.split = 0;
    vars.vsplit = 0;

    // Determine the correct version based on ModuleMemorySize
    if (modules.First().ModuleMemorySize == 51978240)
        version = "v1.1.6";
    else if (modules.First().ModuleMemorySize == 64610304)
        version = "v0.8";
    else if (modules.First().ModuleMemorySize == 55689216)
        version = "v1.4";
    else if (modules.First().ModuleMemorySize == 40443904)
        version = "Alpha 1";
    else
        version = ""; // Default case if no version matches
}

startup
{
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var mbox = MessageBox.Show(
            "In order to remove the loads, you need to switch to Game Time as a timing method.\nWould you like to switch?",
            "LiveSplit | Hello Neighbor",
            MessageBoxButtons.YesNo);

        if (mbox == DialogResult.Yes)
            timer.CurrentTimingMethod = TimingMethod.GameTime;
    }
}

start
{
    if (version == "v1.1.6")
    {
        if (current.startStatus == 0 && old.startStatus != 0 && current.menuStatus != 3 && current.loadStatus == 1)
        {
            vars.split = 0;
            return true;
        }
    }
    else if (version == "v0.8")
    {
        if(current.startStatus == 0 && old.startStatus != 0 && current.menuStatus != 2 && current.loadStatus == 1)
        {
            vars.split = 0;
            vars.vsplit = 0;
            return true;
        }
    }
    else if (version == "v1.4")
    {
        if (current.startStatus == 1071877691 && current.menuStatus != 4 && current.loadStatus == 1)
        {
            vars.split = 0;
            return true;
        }
    }
    else if (version == "Alpha 1")
    {
        if (current.startStatus == 0 && old.startStatus != 0)
            return true;
    }
    return false;
}

reset
{
    if (version == "v1.1.6")
    {
        if (current.menuStatus == 3 && old.menuStatus != 3)
        {
            return true;
        }
    }
    else if (version == "v0.8")
    {
        if (current.menuStatus == 2 && old.menuStatus != 2)
        {
            return true;
        }
    }
    else if (version == "v1.4")
    {
        if (current.menuStatus == 4 && old.menuStatus != 4)
        {
            return true;
        }
    }
    else if (version == "Alpha 1")
    {
        if (current.xPos > 6200 && current.xPos < 6203
            && current.yPos > 277 && current.yPos < 279
            && current.zPos > 134 && current.zPos < 136
            && current.startStatus == 1 && old.startStatus != 1)
        {
            return true;
        }
    }
    return false;
}

split
{
    if (version == "v1.1.6")
    {
        if ((current.missionNumber == 37 && old.missionNumber != 37 && vars.split == 0) ||
            (current.missionNumber == 94 && old.missionNumber != 94 && vars.split == 1) ||
            (current.missionNumber == 436 && old.missionNumber != 436 && vars.split == 2) ||
            (current.missionNumber == 911 && old.missionNumber != 911 && vars.split == 3) ||
            (current.missionNumber == 5553 && old.missionNumber != 5553 && vars.split == 4) ||
            (current.missionNumber == 911 && old.missionNumber != 911 && vars.split == 5) ||
            (current.missionNumber == 3 && old.missionNumber != 3 && vars.split == 6))
        {
            vars.split++;
            return true;
        }
    }
    else if (version == "v0.8")
    {
        if ((current.missionNumber == 197 && old.missionNumber != 197 && vars.split == 0) ||
            (current.missionNumber == 9128 && old.missionNumber != 9128 && vars.split == 1) ||
            (current.missionNumber == 9 && old.missionNumber != 9 && vars.split == 2) ||
            (current.missionNumber == 52 && old.missionNumber != 52 && vars.split == 3 && vars.vsplit > 1) ||
            (current.missionNumber == 78 && old.missionNumber != 78 && vars.split == 4) ||
            (current.missionNumber == 2 && old.missionNumber != 2 && vars.split == 5) ||
            (current.missionNumber == 1 && old.missionNumber == 9031 && vars.split == 6))
        {
            vars.split++;
            return true;
        }
        
        if (current.missionNumber == 52)
        {
            vars.vsplit += 2;
        }
    }
    else if (version == "v1.4")
    {
        if ((current.missionNumber == 9554 && old.missionNumber != 9554 && vars.split == 0) || 
            (current.missionNumber == 9536 && old.missionNumber != 9536 && vars.split == 1) || 
            (current.missionNumber == 167 && old.missionNumber != 167 && vars.split == 2) || 
            (current.missionNumber == 9545 && old.missionNumber != 9545 && vars.split == 3) || 
            (current.missionNumber == 9828 && old.missionNumber != 9828 && vars.split == 4) || 
            (current.missionNumber == 2 && old.missionNumber != 2 && vars.split == 5) ||
            (current.missionNumber == 1 && old.missionNumber == 9031 && vars.split == 6))
        {
            vars.split++;
            return true;
        }
    }
    else if (version == "Alpha 1")
    {
        if (current.xPos < 1500 && current.csState == 1)
            return true;
    }
    return false;
}

isLoading
{
    if (version == "v1.1.6" || version == "v0.8" || version == "v1.4")
    {
        return !current.IsLoading;
    }
    return false; // For alpha1, isLoading logic isn't defined
}
