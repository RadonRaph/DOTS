using System;
using System.Collections;
using System.Collections.Generic;
using Raccoonlabs;
using UnityEngine;
using Unity.Entities;
using Unity.Mathematics;
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

    public Material mat;

    public float[] vals;

    private int _kernel;

    public LocalVolumetricFog fog;

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(transform.position, size.Mul(sizeScale));
    }

    private ComputeBuffer spherePos;
    private ComputeBuffer sphereRadius;
    private bool bufferInit = false;
    
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
        
        spherePos = new ComputeBuffer(1000, 3*4);
        sphereRadius = new ComputeBuffer(1000, 4);

    }



    public void Update()
    {
      //  Texture = _raycharmingSystem.Texture;
      //  fog.parameters.volumeMask = Texture;


      var particles = _raycharmingSystem.particles;
/*
      int count = 2;
      float3[] position = new float3[count];
      float[] radius = new float[count];
      
      position[0] = float3.zero;
      radius[0] = 5;

      position[1] = new float3(0, 3, 0);
      radius[1] = 4;
      */
      

      int count = Mathf.Min( particles.Length, 1000);
      float3[] position = new float3[count];
      float[] radius = new float[count];

      for (int i = 0; i < count; i++)
      {
          
          Debug.DrawRay(particles[i].Position, Vector3.up, Color.green);
          position[i] = particles[i].Position;
          radius[i] = particles[i].Amount;
      }
      
      
      spherePos.SetData(position);
      sphereRadius.SetData(radius);
      
      mat.SetInt("sphereCount", count);
      mat.SetBuffer("spherePos", spherePos);
      mat.SetBuffer("sphereRadius", sphereRadius);
    }

    private void OnDestroy()
    {
        spherePos.Dispose();
        sphereRadius.Dispose();
    }
}
