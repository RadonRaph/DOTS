using System;
using System.Collections;
using System.Collections.Generic;
using Raccoonlabs;
using UnityEngine;
using Unity.Entities;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;

public class RaycharmingMonobehaviour : MonoBehaviour
{
    private World _world;
    private RaycharmingSystem _raycharmingSystem;

    public ComputeShader computeShader;
    public RenderTexture Texture;
    public Vector3 size;
    public Vector3 sizeScale;

    public float[] vals;

    private int _kernel;

    public LocalVolumetricFog fog;

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(transform.position, size.Mul(sizeScale));
    }

    // Start is called before the first frame update
    void Start()
    {
        _world = World.DefaultGameObjectInjectionWorld;
        _raycharmingSystem = _world.GetExistingSystemManaged<RaycharmingSystem>();
        

        _raycharmingSystem.ComputeShader = computeShader;
        _raycharmingSystem.Size = Raccoonlabs.MathExtends.ToV3IntCeiled(size);
        _raycharmingSystem.sizeScale = sizeScale;
        fog.parameters.size = size.Mul(sizeScale);
        
      //  _raycharmingSystem.Texture = texture;
        _raycharmingSystem.Init();
        
        /*
        
        Texture = new RenderTexture(16, 8, 0, RenderTextureFormat.ARGBFloat);
        Texture.width = 16;
        Texture.height = 8;
        Texture.volumeDepth = 16;
        Texture.dimension = TextureDimension.Tex3D;
        Texture.enableRandomWrite = true;
        Texture.Create();

        _kernel = computeShader.FindKernel("CSMain");
        
        computeShader.SetInts(_kernel, 16,8,16);
        computeShader.SetTexture(_kernel, "Result", Texture);
        computeShader.Dispatch(_kernel, 16,8,16);*/
    }

    public void Update()
    {
        Texture = _raycharmingSystem.Texture;
        fog.parameters.volumeMask = Texture;
        // vals = _raycharmingSystem.amountVals;
    }
}
