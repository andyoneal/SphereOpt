using System;
using System.Collections.Generic;
using UnityEngine;

namespace SphereOpt
{
    public class InstDysonShellLayer
    {
        public struct HexProgressData
        {
            public float progress;
        }
        public static int HEXPROGRESSDATA_STRIDE = 4;

        public struct PolygonData {
            public Vector3 pos;
            public Vector3 normal;
        }
        public static int POLYGONDATA_STRIDE = 24;

        public struct HexData
        {
            public Vector3 pos;
            public int shellIndex;
            public int nodeIndex;
            public float vertFillOrder;
            public int closestPolygon;
            public uint axialCoords_xy;
        }
        public static int HEXDATA_STRIDE = 32;

        public struct ShellData
        {
            public int color;
            public uint state;
            public int progressBaseIndex;
            public int polyCount;
            public int polygonIndex;
            public Vector3 center;
            public int protoId;
        }
        public static int SHELLDATA_STRIDE = 36;

        public int layerId;

        public HexProgressData[] hexProgressPool;
        public List<HexData> hexPool;
        public ShellData[] shellPool;
        public PolygonData[] polygonPool;

        public float gridSize;
        public int gridScale;
        public float radius;

        public int progressBaseCursor;
        public int polygonCursor;
        public int cachedHexCount = -1;

        private ComputeBuffer hexProgressBuffer;
        private ComputeBuffer hexBuffer;
        private ComputeBuffer shellBuffer;
        private ComputeBuffer polygonBuffer;

        public bool hexProgressBufferIsDirty = true;
        public bool hexBufferIsDirty = true;
        public bool shellBufferIsDirty = true;
        public bool polygonBufferIsDirty = true;

        public MaterialPropertyBlock props = new MaterialPropertyBlock();
        private static readonly int Radius = Shader.PropertyToID("_Radius");
        private static readonly int Scale = Shader.PropertyToID("_Scale");
        private static readonly int GridSize = Shader.PropertyToID("_GridSize");
        private static readonly int CellSize = Shader.PropertyToID("_CellSize");
        private static readonly int LayerId = Shader.PropertyToID("_LayerId");
        private static readonly int HexBuffer = Shader.PropertyToID("_HexBuffer");
        private static readonly int HexProgressBuffer = Shader.PropertyToID("_HexProgressBuffer");
        private static readonly int ShellBuffer = Shader.PropertyToID("_ShellBuffer");
        private static readonly int PolygonBuffer = Shader.PropertyToID("_PolygonBuffer");

        public InstDysonShellLayer(int layerId)
        {
            this.layerId = layerId;
            hexProgressPool = new HexProgressData[64];
            hexPool = new List<HexData>();
            shellPool = new ShellData[11];
            polygonPool = new PolygonData[64];
            hexProgressBuffer = new ComputeBuffer(64, HEXPROGRESSDATA_STRIDE);
            shellBuffer = new ComputeBuffer(11, SHELLDATA_STRIDE);
            polygonBuffer = new ComputeBuffer(64, POLYGONDATA_STRIDE);
            SetProps();
        }

        public void Free()
        {
            if (polygonBuffer != null)
            {
                polygonBuffer.Release();
                polygonBuffer = null;
            }
            polygonPool = null;

            if (hexProgressBuffer != null)
            {
                hexProgressBuffer.Release();
                hexProgressBuffer = null;
            }
            hexProgressPool = null;

            if (shellBuffer != null)
            {
                shellBuffer.Release();
                shellBuffer = null;
            }
            shellPool = null;

            if (hexBuffer != null)
            {
                hexBuffer.Release();
                hexBuffer = null;
            }
            hexPool.Clear();
            hexPool = null;

            progressBaseCursor = 0;
            polygonCursor = 0;
            cachedHexCount = -1;

            props = null;
            layerId = 0;
        }

        public void SetCapacityPolygonPool(int nextCount)
        {
            var newCap = polygonPool.Length + nextCount * 32;
            var destinationArray = new PolygonData[newCap];

            if (polygonPool != null)
            {
                Array.Copy(polygonPool, destinationArray, polygonPool.Length);
            }
            polygonPool = destinationArray;
            polygonBuffer?.Release();
            polygonBuffer = new ComputeBuffer(newCap, POLYGONDATA_STRIDE);
            props.SetBuffer(PolygonBuffer, polygonBuffer);
            polygonBufferIsDirty = true;
        }

        public int AddPolygonData(List<VectorLF3> polygon, VectorLF3[] polyn, bool clockwise) {
            if (polygonCursor + polygon.Count >= polygonPool.Length) SetCapacityPolygonPool(polygon.Count);
            for (var i = 0; i < polygon.Count; i++)
            { 
                polygonPool[polygonCursor + i].pos = polygon[i];
                polygonPool[polygonCursor + i].normal = polyn[i];
            }

            if (!clockwise)
            {
                Array.Reverse(polygonPool, polygonCursor, polygon.Count);
                for (int i = 0; i < polygon.Count; i++)
                {
                    Vector3 vector = polygonPool[polygonCursor + i].pos;
                    Vector3 vector2 = polygonPool[polygonCursor + (i + 1) % polygon.Count].pos;
                    polygonPool[polygonCursor + i].normal = VectorLF3.Cross(vector, vector2).normalized;
                }
            }

            polygonBufferIsDirty = true;

            var polyIndex = polygonCursor;
            polygonCursor += polygon.Count;
            return polyIndex;
        }

        public void SetCapacityShellPool(int newCap)
        {
            var destinationArray = new ShellData[newCap];
            if (shellPool != null)
            {
                Array.Copy(shellPool, destinationArray, shellPool.Length);
            }
            shellPool = destinationArray;
            shellBuffer?.Release();
            shellBuffer = new ComputeBuffer(newCap, SHELLDATA_STRIDE);
            props.SetBuffer(ShellBuffer, shellBuffer);
            shellBufferIsDirty = true;
        }

        public void AddShellData(int shellId, ShellData shellData)
        {
            if (shellId >= shellPool.Length) SetCapacityShellPool(shellId + 16);
            shellPool[shellId] = shellData;
            shellBufferIsDirty = true;
        }

        public void SetCapacityHexProgressPool(int newCap)
        {
            var destinationArray = new HexProgressData[newCap];
            if (hexProgressPool != null)
            {
                Array.Copy(hexProgressPool, destinationArray, hexProgressPool.Length);
            }
            hexProgressPool = destinationArray;
            hexProgressBuffer?.Release();
            hexProgressBuffer = new ComputeBuffer(newCap, HEXPROGRESSDATA_STRIDE);
            props.SetBuffer(HexProgressBuffer, hexProgressBuffer);
            hexProgressBufferIsDirty = true;
        }

        public void AddHexProgressData(int hexProgressIndex, HexProgressData hexProgressData)
        {
            if (hexProgressIndex >= hexProgressPool.Length) SetCapacityHexProgressPool(hexProgressIndex + 128);
            hexProgressPool[hexProgressIndex] = hexProgressData;
            hexProgressBufferIsDirty = true;
        }

        public void UpdateHexProgress(int shellIndex, int nodeIndex, float progress)
        {
            hexProgressPool[shellPool[shellIndex].progressBaseIndex + nodeIndex].progress = progress;
            hexProgressBufferIsDirty = true;
        }

        public void SyncBufferData()
        {
            if (hexProgressBufferIsDirty)
            {
                hexProgressBuffer.SetData(hexProgressPool);
                hexProgressBufferIsDirty = false;
            }

            if (hexBufferIsDirty)
            {
                if (hexBuffer == null || hexBuffer.count != hexPool.Count)
                {
                    hexBuffer?.Release();
                    hexBuffer = new ComputeBuffer(hexPool.Count, HEXDATA_STRIDE);
                    props.SetBuffer(HexBuffer, hexBuffer);
                }

                hexBuffer.SetData(hexPool);
                hexBufferIsDirty = false;
            }

            if (shellBufferIsDirty)
            {
                shellBuffer.SetData(shellPool);
                shellBufferIsDirty = false;
            }

            if (polygonBufferIsDirty)
            {
                polygonBuffer.SetData(polygonPool);
                polygonBufferIsDirty = false;
            }
        }

        public void SetProps()
        {
            props.SetFloat(Radius, radius);
            props.SetFloat(Scale, gridScale);
            props.SetFloat(GridSize, gridSize);
            props.SetFloat(CellSize, 0.94f);
            props.SetFloat(LayerId, layerId);
            props.SetBuffer(HexBuffer, hexBuffer);
            props.SetBuffer(HexProgressBuffer, hexProgressBuffer);
            props.SetBuffer(ShellBuffer, shellBuffer);
            props.SetBuffer(PolygonBuffer, polygonBuffer);
        }

        public void RemoveDysonShell(int shellId)
        {
            hexPool.RemoveAll(x => x.shellIndex == shellId);

            hexBufferIsDirty = true;
            hexProgressBufferIsDirty = true;


            var pbi = shellPool[shellId].polygonIndex;
            for (int i = 0; i < shellPool[shellId].polyCount; i++)
            {
                polygonPool[pbi + i].pos = Vector3.zero;
                polygonPool[pbi + i].normal = Vector3.zero;
            }
            polygonBufferIsDirty = true;

            //TODO: shouldn't have to do this? leave as is?
            shellPool[shellId].center = Vector3.zero;
            shellPool[shellId].state = 0;
            shellPool[shellId].color = 0;
            shellPool[shellId].polyCount = 0;
            shellPool[shellId].progressBaseIndex = 0;
            shellPool[shellId].polygonIndex = 0;
            shellBufferIsDirty = true;
        }

        public void UpdateState(int shellId, uint shellState)
        {
            shellPool[shellId].state = shellState;
            shellBufferIsDirty = true;
        }
    }
}
