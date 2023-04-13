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
        };

        public struct HexCutoutData
        {
            public Vector2 cutoutPoint;
            public float angleToCutoutDirOne;
            public float angleToCutoutDirTwo;
        };

        /*public struct HexData
        {
            public Vector3 pos;
            public int shellIndex;
            public int nodeIndex;
            public float vertFillOrder;
            public int polygonIndex;
            public uint axialCoords_xy;
        };

        public struct ShellData
        {
            public int color;
            public uint state; 
            public int progressBaseIndex;
            public int clockwise;
            public uint polyCount;
            public Vector3 center;
        };*/

        public struct HexData
        {
            public Vector3 pos;
            public int shellIndex;
            public int nodeIndex;
            public float vertFillOrder;
            //public int polygonIndex;
            public int cutoutIndex;
            public uint axialCoords_xy;
        };

        public struct ShellData
        {
            public int color;
            public uint state; 
            public int progressBaseIndex;
            //public int clockwise;
            //public uint polyCount;
            public Vector3 center;
        };

        private int layerId;

        public HexProgressData[] hexProgressPool;
        public HexCutoutData[] hexCutoutPool;
        public List<HexData> hexPool;
        public ShellData[] shellPool;

        public float gridSize;
        public int gridScale;
        public float radius;

        public int progressBaseCursor = 0;
        public int cutoutCursor = 1;
        public uint hexCount = 0;
        public int cachedHexCount = -1;

        private ComputeBuffer hexProgressBuffer;
        private ComputeBuffer hexCutoutBuffer;
        private ComputeBuffer hexBuffer;
        private ComputeBuffer shellBuffer;

        public bool hexProgressBufferIsDirty = true;
        public bool hexCutoutBufferIsDirty = true;
        public bool hexBufferIsDirty = true;
        public bool shellBufferIsDirty = true;

        public MaterialPropertyBlock props = new();
        private bool propsAreDirty = true;

        public InstDysonShellLayer(int layerId)
        {
            this.layerId = layerId;
            hexProgressPool = new HexProgressData[64];
            hexPool = new List<HexData>();
            shellPool = new ShellData[11];
            hexCutoutPool = new HexCutoutData[16];
            hexCutoutPool[0].cutoutPoint = Vector2.zero;
            hexCutoutPool[0].angleToCutoutDirOne = 0f;
            hexCutoutPool[0].angleToCutoutDirTwo = 0f;
            hexCutoutBuffer = new ComputeBuffer(16, 16);
            hexProgressBuffer = new ComputeBuffer(64, 4);
            shellBuffer = new ComputeBuffer(11, 24);
            SetProps();
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
            shellBuffer = new ComputeBuffer(newCap, 24);
            props.SetBuffer("_ShellBuffer", shellBuffer);
            shellBufferIsDirty = true;
        }

        public void AddShellData(int shellId, ShellData shellData)
        {
            if (shellId >= shellPool.Length) SetCapacityShellPool(shellId + 10);
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
            hexProgressBuffer = new ComputeBuffer(newCap, 4);
            props.SetBuffer("_HexProgressBuffer", shellBuffer);
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

        public void SetCapacityCutoutPool(int newCap)
        {
            var destinationArray = new HexCutoutData[newCap];
            if (hexCutoutPool != null)
            {
                Array.Copy(hexCutoutPool, destinationArray, hexCutoutPool.Length);
            }
            hexCutoutPool = destinationArray;
            hexCutoutBuffer?.Release();
            hexCutoutBuffer = new ComputeBuffer(newCap, 16);
            props.SetBuffer("_HexCutoutBuffer", hexCutoutBuffer);
            hexCutoutBufferIsDirty = true;
        }

        public void AddCutoutData(int hexCutoutIndex, HexCutoutData cutoutData)
        {
            if (hexCutoutIndex >= hexCutoutPool.Length) SetCapacityCutoutPool(hexCutoutIndex + 16);
            hexCutoutPool[hexCutoutIndex] = cutoutData;
            hexCutoutBufferIsDirty = true;
        }

        public void SyncBufferData()
        {
            if (hexProgressBufferIsDirty)
            {
                hexProgressBuffer.SetData(hexProgressPool);
                hexProgressBufferIsDirty = false;
            }

            if (hexCutoutBufferIsDirty)
            {
                hexCutoutBuffer.SetData(hexCutoutPool);
                hexCutoutBufferIsDirty = false;
            }

            if (hexBufferIsDirty)
            {
                if (hexBuffer == null || hexBuffer.count != hexPool.Count)
                {
                    hexBuffer?.Release();
                    hexBuffer = new ComputeBuffer(hexPool.Count, 32);
                    props.SetBuffer("_HexBuffer", hexBuffer);
                }

                hexBuffer.SetData(hexPool);
                hexBufferIsDirty = false;
            }

            if (shellBufferIsDirty)
            {
                shellBuffer.SetData(shellPool);
                shellBufferIsDirty = false;
            }
        }

        public void SetProps()
        {
            if (true)
            {
                props.SetFloat("_Radius", radius);
                props.SetFloat("_Scale", gridScale);
                props.SetFloat("_GridSize", gridSize);
                props.SetFloat("_CellSize", 0.94f);
                props.SetFloat("_LayerId", layerId);
                props.SetBuffer("_HexBuffer", hexBuffer);
                props.SetBuffer("_HexProgressBuffer", hexProgressBuffer);
                props.SetBuffer("_HexCutoutBuffer", hexCutoutBuffer);
                props.SetBuffer("_ShellBuffer", shellBuffer);

                propsAreDirty = false;
            }
        }

        public void RemoveDysonShell(int shellId)
        {
            for (var i=0; i < hexPool.Count; i++)
            {
                if (hexPool[i].shellIndex == shellId)
                {
                    var hpi = shellPool[shellId].progressBaseIndex + hexPool[i].nodeIndex;
                    hexProgressPool[hpi].progress = -1f; //TODO: the next shell that uses this shellId may have a different number of nodes. Or, shouldn't have to do this but buffer will keep growing.
                    hexPool.RemoveAt(i);
                }
            }

            hexBufferIsDirty = true;

            //var pbi = shellPool[shellId].progressBaseIndex;


            //TODO: shouldn't have to do this? leave as is?
            shellPool[shellId].center = Vector3.zero;
            shellPool[shellId].state = 0;
            //shellPool[shellId].clockwise = 1;
            shellPool[shellId].color = 0;
            //shellPool[shellId].polyCount = 0;
            shellPool[shellId].progressBaseIndex = 0;
        }

        public void UpdateState(int shellId, uint shellState)
        {
            shellPool[shellId].state = shellState;
            shellBufferIsDirty = true;
        }

        
    }
}
