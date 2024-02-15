using HarmonyLib;

namespace SphereOpt
{
    public static class Patch_DysonSphereSegmentRenderer
    {
        [HarmonyPatch(typeof(DysonSphereSegmentRenderer), "LoadStatic")]
        [HarmonyPostfix]
        private static void DysonSphereSegmentRenderer_LoadStatic(DysonSphereSegmentRenderer __instance)
        {
            InstDysonNodeFrameRenderer.SetupBatches();
            InstDysonNodeFrameRenderer.SetupLODShader();
        }

        [HarmonyPatch(typeof(DysonSphereSegmentRenderer), "RebuildModels")]
        [HarmonyPostfix]
        private static void DysonSphereSegmentRenderer_RebuildModels(DysonSphereSegmentRenderer __instance)
        {
            InstDysonNodeFrameRenderer.RebuildFrameModels();
        }

        [HarmonyPatch(typeof(DysonSphereSegmentRenderer), "DrawModels")]
        [HarmonyPrefix]
        private static bool DysonSphereSegmentRenderer_DrawModels(DysonSphereSegmentRenderer __instance, ERenderPlace place, int editorMask, int gameMask)
        {
            InstDysonNodeFrameRenderer.Render(__instance, place, editorMask, gameMask);
            SphereOpt.getInstDysonShellRendererForSphere(__instance.dysonSphere).RenderShells(place, editorMask, gameMask);
            return false;
        }
    }
}