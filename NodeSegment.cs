using UnityEngine;

namespace SphereOpt
{
    public struct NodeSegment
    {
        public uint layer;

        public uint state;

        public Vector3 pos0;

        public Vector3 pos1;

        public float progress0;

        public float progress1;

        public Color32 color;

        public const int dataLen = 44;
    }
}