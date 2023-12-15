using UnityEngine;

namespace SphereOpt
{
    public class CustomShaderDesc
    {
        public readonly string shortName;
        public readonly Shader shader;

        public CustomShaderDesc (string shortName, string customShaderName)
        {
            shader = CustomShaderManager.GetShader(customShaderName);
            if (shader == null) SphereOpt.logger.LogError($"Could not find shader for name: {customShaderName}");
            this.shortName = shortName;
        }
    }
}