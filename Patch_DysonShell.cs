using HarmonyLib;

namespace SphereOpt;

internal class Patch_DysonShell
{
    [HarmonyPatch(typeof(DysonShell), "SetProtoId")]
    [HarmonyPostfix]
    static void DysonShell_SetProtoId(DysonShell __instance)
    {
        var arraySizeNeeded = __instance.polygon.Count * 3;
        if (arraySizeNeeded > 256) CustomShaderManager.ApplyCustomShaderToMaterial(__instance.material, "dysonshell-max");
        else if (arraySizeNeeded > 128) CustomShaderManager.ApplyCustomShaderToMaterial(__instance.material, "dysonshell-huge");
        else if (arraySizeNeeded > 16) CustomShaderManager.ApplyCustomShaderToMaterial(__instance.material, "dysonshell-large");
        else CustomShaderManager.ApplyCustomShaderToMaterial(__instance.material, "dysonshell-small");
    }
}