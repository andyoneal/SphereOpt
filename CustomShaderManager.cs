using System.Collections.Generic;
using System.IO;
using System.Reflection;
using UnityEngine;

namespace SphereOpt;

public static class CustomShaderManager
{
    private static readonly string AssemblyPath = Path.GetDirectoryName(Assembly.GetAssembly(typeof(SphereOpt)).Location);
    private static AssetBundle bundle;
    private static readonly List<Shader> bundleShaders = new();
    private static readonly List<CustomShaderDesc> customShaderDescs = new();
    private static readonly Dictionary<string, CustomShaderDesc> shortNameMap = new();
    private static readonly Dictionary<string, CustomShaderDesc> autoReplaceShaderMap = new();
    private static readonly Dictionary<CustomShaderDesc, List<Material>> shaderReplacedOnMaterialsMap = new();

    public static void InitWithBundle(string bundleFileName)
    {
        if (bundleShaders.Count > 0)
        {
            SphereOpt.logger.LogError($"CustomShaderManager is already initialized with bundle: {bundle.name}");
            return;
        }
        var path = Path.Combine(AssemblyPath, bundleFileName);
        if (File.Exists(path))
        {
            bundle = AssetBundle.LoadFromFile(path);
            InitWithBundle(bundle);
        }
        else SphereOpt.logger.LogError($"Bundle file not found at: {path}");
    }

    public static void InitWithBundle(AssetBundle assetBundle)
    {
        if (bundleShaders.Count > 0)
        {
            SphereOpt.logger.LogError($"CustomShaderManager is already initialized with bundle: {bundle.name}");
            return;
        }
        bundle = assetBundle;
        if (!LoadShadersFromBundle())
        {
            SphereOpt.logger.LogError("Failed to load custom shaders from bundle.");
        }
    }

    public static ComputeShader LoadComputeShader(string name)
    {
        if (bundle != null)
        {
            return bundle.LoadAsset<ComputeShader>(name);
        }

        return null;
    }

    private static bool LoadShadersFromBundle()
    {
        SphereOpt.logger.LogInfo("Loading custom shaders from bundle.");
        if (bundle != null)
        {
            var shaders = bundle.LoadAllAssets<Shader>();
            foreach (var s in shaders)
            {
                bundleShaders.Add(s);
                SphereOpt.logger.LogInfo($"Loaded custom shader: {s.name}");
            }
        }
        else
        {
            SphereOpt.logger.LogError("Failed to load custom shaders from bundle".Translate());
            return false;
        }

        return true;
    }

    public static void AddCustomShaderDesc(string shortName, string shaderName, string alwaysReplaceShaderName = null)
    {
        CustomShaderDesc shaderDesc = new(shortName, shaderName);
        customShaderDescs.Add(shaderDesc);
        if(alwaysReplaceShaderName != null) autoReplaceShaderMap.Add(alwaysReplaceShaderName, shaderDesc);
        shortNameMap.Add(shaderDesc.shortName, shaderDesc);
    }

    public static bool ReplaceShaderIfAvailable(Material mat)
    {
        if (autoReplaceShaderMap.TryGetValue(mat.shader.name, out var customShaderDesc))
        {
            SphereOpt.logger.LogInfo($"replacing shader on: {mat.name}");
            ApplyCustomShaderToMaterial(mat, customShaderDesc);
            return true;
        }

        return false;
    }

    public static Shader GetShader (string customShaderName)
    {
        foreach (var shader in bundleShaders)
        {
            if (shader.name.Equals(customShaderName)) return shader;
        }
        SphereOpt.logger.LogWarning($"Couldn't find custom shader with name: {customShaderName}");
        return null;
    }

    public static void ApplyCustomShaderToMaterial(Material mat, string shortName)
    {
        if (!shortNameMap.TryGetValue(shortName, out var customShaderDesc))
        {
            SphereOpt.logger.LogWarning($"Couldn't find a CustomShaderDesc with shortname: {shortName}");
            return;
        }
        ApplyCustomShaderToMaterial(mat, customShaderDesc);
    }

    private static void ApplyCustomShaderToMaterial(Material mat, CustomShaderDesc replacementShader)
    {
        mat.shader = replacementShader.shader;

        if(!shaderReplacedOnMaterialsMap.TryGetValue(replacementShader, out var matList))
        {
            matList = new List<Material>();
            shaderReplacedOnMaterialsMap.Add(replacementShader, matList);
        }

        matList.Add(mat);
    }
}