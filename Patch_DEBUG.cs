using HarmonyLib;
using UnityEngine;

namespace SphereOpt;

public static class Patch_DEBUG
{   
    [HarmonyPatch(typeof(DSPGame), "StartDemoGame")]
    [HarmonyPrefix]
    private static bool DSPGame_StartDemoGame(ref int index)
    {
        if(SphereOpt.configDEBUGSameTitleScreen.Value) index = -2;
        return true;
    }
    
    [HarmonyPatch(typeof(PostEffectController), "Update")]
    [HarmonyPostfix]
    private static void PostEffectController_Update(PostEffectController __instance)
    {
        if(SphereOpt.configDEBUGDisableSunShafts.Value) __instance.sunShaft.enabled = false;
    }

    [HarmonyPatch(typeof(GameLoader), "OnDisable")]
    [HarmonyPostfix]
    private static void GameLoader_OnDisable()
    {
        if (SphereOpt.configDEBUGDisableFlare.Value && Camera.main != null)
        {
            FlareLayer component = Camera.main.GetComponent<FlareLayer>();
            if (component != null)
            {
                component.enabled = false;
            }
        }
    }

    [HarmonyPatch(typeof(MilkyWayLogic), "OnClose")]
    [HarmonyPostfix]
    private static void MilkyWayLogic_OnClose()
    {
        if (SphereOpt.configDEBUGDisableFlare.Value)
        {
            FlareLayer component = Camera.main.GetComponent<FlareLayer>();
            if (component != null)
            {
                component.enabled = false;
            }
        }
    }
    
    
}