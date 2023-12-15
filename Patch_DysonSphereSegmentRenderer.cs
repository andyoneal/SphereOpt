using HarmonyLib;

namespace SphereOpt
{
    public static class Patch_DysonSphereSegmentRenderer
    {
        /*[HarmonyPatch(typeof(GameCamera), "Logic")]
        [HarmonyPostfix]
        private static void GameCamera_Logic(GameCamera __instance)
        {
            __instance.finalMenu.fov = 2.6f;
        }

        [HarmonyPatch(typeof(DSPGame), "StartDemoGame")]
        [HarmonyPrefix]
        private static bool DSPGame_StartDemoGame(ref int index)
        {
            index = -2;
            return true;
        }*/

        [HarmonyPatch(typeof(DysonSphereSegmentRenderer.Batch), "SetCapacity")]
        [HarmonyPostfix]
        public static void Batch_SetCapacity(DysonSphereSegmentRenderer.Batch __instance, int newCap)
        {
            InstDysonNodeFrameRenderer.instBufferChangedSize = true;
        }

        [HarmonyPatch(typeof(DysonSphereSegmentRenderer), "LoadStatic")]
        [HarmonyPostfix]
        private static void DysonSphereSegmentRenderer_LoadStatic(DysonSphereSegmentRenderer __instance)
        {
            InstDysonNodeFrameRenderer.SetupMeshes();
            InstDysonNodeFrameRenderer.SetupBuffers();
            InstDysonNodeFrameRenderer.SetupLODShader();
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