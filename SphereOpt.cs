using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using System.IO;
using System.Reflection;
using UnityEngine;

namespace SphereOpt;

[BepInPlugin(PluginInfo.PLUGIN_GUID, PluginInfo.PLUGIN_NAME, PluginInfo.PLUGIN_VERSION)]
public class SphereOpt : BaseUnityPlugin
{
    public static ManualLogSource logger;
    private static AssetBundle bundle;
    private static readonly string AssemblyPath = Path.GetDirectoryName(Assembly.GetAssembly(typeof(SphereOpt)).Location);

    public static InstDysonShellRenderer instRenderer;

    public static int intersectionsFound = 0;

    private static AssetBundle Bundle
    {
        get
        {
            if (bundle == null)
            {
                var path = Path.Combine(AssemblyPath, "sphereopt-bundle");
                if (File.Exists(path))
                {
                    bundle = AssetBundle.LoadFromFile(path);
                }
                else
                {
                    logger.LogError("Failed to load AssetBundle!".Translate());
                    return null;
                }
            }
            return bundle;
        }
    }

    public static bool OneRun = false;

    private void Awake()
    {
        logger = Logger;

        CustomShaderManager.InitWithBundle(Bundle);

        CustomShaderManager.AddCustomShaderDesc(
            "dysonshell-max",
            "VF Shaders/Dyson Sphere/Dyson Shell Unlit REPLACE"
        );

        CustomShaderManager.AddCustomShaderDesc(
            "dysonshell-small",
            "VF Shaders/Dyson Sphere/Dyson Shell Unlit REPLACE Small"
        );

        CustomShaderManager.AddCustomShaderDesc(
            "dysonshell-large",
            "VF Shaders/Dyson Sphere/Dyson Shell Unlit REPLACE Large"
        );

        CustomShaderManager.AddCustomShaderDesc(
            "dysonshell-huge",
            "VF Shaders/Dyson Sphere/Dyson Shell Unlit REPLACE Huge"
        );

        CustomShaderManager.AddCustomShaderDesc(
            "dysonshell-inst",
            "VF Shaders/Dyson Sphere/Dyson Shell Unlit Instanced"
        );

        CustomShaderManager.AddCustomShaderDesc(
            "dysonframe",
            "VF Shaders/Dyson Sphere/Frame Inst REPLACE",
            "VF Shaders/Dyson Sphere/Frame Inst"
        );

        CustomShaderManager.AddCustomShaderDesc(
            "dysonnode",
            "VF Shaders/Dyson Sphere/Node Inst REPLACE",
            "VF Shaders/Dyson Sphere/Node Inst"
        );


        Harmony.CreateAndPatchAll(typeof(Patch_VFPreload));
        Harmony.CreateAndPatchAll(typeof(Patch_DysonShell));
    }

    public static InstDysonShellRenderer getInstDysonShellRendererForStar(DysonSphere ds)
    {
        //TODO: Make this work for multiple dyson spheres
        if (instRenderer == null || instRenderer.dysonSphere != ds) instRenderer = new InstDysonShellRenderer(ds);
        return instRenderer;
    }
}