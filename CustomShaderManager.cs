using System.Collections.Generic;
using UnityEngine;

namespace SphereOpt
{
    public static class CustomShaderManager
    {
        private static AssetBundle bundle;
        private static readonly List<Shader> bundleShaders = new List<Shader>();

        private static readonly Dictionary<string, CustomShaderDesc> shortNameMap =
            new Dictionary<string, CustomShaderDesc>();

        private static readonly Dictionary<string, CustomShaderDesc> autoReplaceShaderMap =
            new Dictionary<string, CustomShaderDesc>();

        private static readonly Dictionary<CustomShaderDesc, List<Material>> shaderReplacedOnMaterialsMap =
            new Dictionary<CustomShaderDesc, List<Material>>();

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
            return bundle?.LoadAsset<ComputeShader>(name);
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
            CustomShaderDesc shaderDesc = new CustomShaderDesc(shortName, shaderName);
            if(alwaysReplaceShaderName != null) autoReplaceShaderMap.Add(alwaysReplaceShaderName, shaderDesc);
            shortNameMap.Add(shaderDesc.shortName, shaderDesc);
        }

        public static bool ReplaceShaderIfAvailable(Material mat)
        {
            if (!autoReplaceShaderMap.TryGetValue(mat.shader.name, out var customShaderDesc)) return false;

            ApplyCustomShaderToMaterial(mat, customShaderDesc);
            return true;
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
            SphereOpt.logger.LogInfo($"replacing shader on: {mat.name} > {replacementShader.shader.name}");
            mat.shader = replacementShader.shader;

            if(!shaderReplacedOnMaterialsMap.TryGetValue(replacementShader, out var matList))
            {
                matList = new List<Material>();
                shaderReplacedOnMaterialsMap.Add(replacementShader, matList);
            }

            matList.Add(mat);
        }
    }
}