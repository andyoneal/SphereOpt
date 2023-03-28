using System.Collections.Generic;
using UnityEngine;

namespace SphereOpt
{
    internal class InstDysonShellLayer
    {
        public struct HexProgressData
        {
            public float progress;
        };

        public struct HexData
        {
            public Vector3 pos;
            public int shellIndex;
            public int nodeIndex;
            public float vertFillOrder;
            public int polygonIndex;
            public int axialCoords_x;
            public int axialCoords_y;
        };

        public struct ShellData
        {
            public int color;
            public uint state; 
            public int progressBaseIndex;
            public bool clockwise;
            public int layerId;
            public int polyCount;
            public Vector3 t0axis;
            public Vector3 t1axis;
            public Vector3 t2axis;
            public float radius;
            public int scale;
        };

        private int layerId;

        public List<InstDysonShellLayer.HexProgressData> hexProgressPool;
        public List<InstDysonShellLayer.HexData> hexPool;
        public List<InstDysonShellLayer.ShellData> shellPool;

        public int progressBaseCursor = 0;
        public uint hexCount = 0;
        public int cachedHexCount = -1;

        private ComputeBuffer hexProgressBuffer;
        private ComputeBuffer hexBuffer;
        private ComputeBuffer shellBuffer;

        public bool hexProgressBufferIsDirty = true;
        public bool hexBufferIsDirty = true;
        public bool shellBufferIsDirty = true;

        public void SyncBufferData()
        {
            if (hexProgressBufferIsDirty)
            {
                if (hexProgressBuffer == null || hexProgressBuffer.count != hexProgressPool.Count)
                {
                    hexProgressBuffer?.Release();
                    hexProgressBuffer = new ComputeBuffer(hexProgressPool.Count, 4);
                }

                hexProgressBuffer.SetData(hexProgressPool);
            }
            hexProgressBufferIsDirty = false;

            if (hexBufferIsDirty)
            {
                if (hexBuffer == null || hexBuffer.count != hexPool.Count)
                {
                    hexBuffer?.Release();
                    hexBuffer = new ComputeBuffer(hexPool.Count, 36);
                }

                hexBuffer.SetData(hexPool);
            }
            hexBufferIsDirty = false;

            if (shellBufferIsDirty)
            {
                if (shellBuffer == null || shellBuffer.count != shellPool.Count)
                {
                    shellBuffer?.Release();
                    shellBuffer = new ComputeBuffer(shellPool.Count, 68);
                }

                shellBuffer.SetData(shellPool);
            }
            shellBufferIsDirty = false;

            if (cachedHexCount != hexCount)
            {
                InstDysonShell.UpdateLayerArgs(layerId, hexCount);
                cachedHexCount = (int)hexCount;
            }
        }

        public void Init(int layerId)
        {
            this.layerId = layerId;
            hexProgressPool = new List<HexProgressData>();
            hexPool = new List<HexData>();
            shellPool = new List<ShellData>();
            SyncBufferData();
        }
    }
}
