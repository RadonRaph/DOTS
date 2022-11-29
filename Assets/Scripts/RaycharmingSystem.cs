using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using UnityEngine;
using Unity.Mathematics;
using Unity.Profiling;
using Unity.Transforms;
using UnityEngine.Rendering;
using Random = UnityEngine.Random;

public partial class RaycharmingSystem : SystemBase
{

    public ComputeShader ComputeShader;
    public Vector3Int Size = new Vector3Int(16, 8, 16);
    public Vector3 sizeScale;
    public RenderTexture Texture;


    private bool _init = false;
    private int _kernel;
    
    
    private World _world;
    private EntityManager _manager;
    private EntityCommandBuffer _ecb;
    private Entity _prototype;

    public float[] amountVals;


    private static readonly ProfilerMarker k_BufferMarker = new ProfilerMarker("Raycharming system buffer make");
    private static readonly ProfilerMarker k_BufferSendMarker = new ProfilerMarker("Raycharming system buffer send");
    private static readonly ProfilerMarker k_DispatchMarker = new ProfilerMarker("Raycharming system CS Dispatch");

    protected override void OnCreate()
    {
        base.OnCreate();



        
        
    }

    private ComputeBuffer _computeBuffer;
    private NativeArray<float> _lastVals;

    public void Init()
    {
        _kernel = ComputeShader.FindKernel("CSMain");
        
        
        Texture = new RenderTexture(Size.x, Size.y, 0, RenderTextureFormat.ARGBFloat);
        Texture.width = Size.x;
        Texture.height = Size.y;
        Texture.volumeDepth = Size.z;
        Texture.dimension = TextureDimension.Tex3D;
        Texture.enableRandomWrite = true;
        Texture.Create();
        
        ComputeShader.SetTexture(_kernel, "Result", Texture);
        ComputeShader.SetInts("size", Size.x, Size.y, Size.z);
        
        _world = World.DefaultGameObjectInjectionWorld;
        _manager = _world.EntityManager;
       // CreateEntities();
       int count = Size.x * Size.y * Size.z;
       _computeBuffer = new ComputeBuffer(count, sizeof(float));

      // _lastVals = new NativeArray<float>(count, Allocator.Persistent);

        _init = true;
    }

    protected override void OnUpdate()
    {
        if (!_init)
            return;
        
        int3 size = new int3(Size.x, Size.y, Size.z);
        float3 scale = sizeScale;
        int count = size.x * size.y * size.z;
        
        NativeArray<float> vals = new NativeArray<float>(count, Allocator.TempJob);
       // NativeArray<float3> debug = new NativeArray<float3>(count, Allocator.TempJob);

        float dt = _world.Time.DeltaTime;
        EntityCommandBuffer ecb = new EntityCommandBuffer(Allocator.TempJob);
        EntityCommandBuffer.ParallelWriter wtr = ecb.AsParallelWriter();

        JobHandle updateParticleHandle = Entities.WithName("Raycharming_Particle_parrallel_update").WithAll<RaycharmingParticle>().ForEach((Entity e, int entityInQueryIndex, ref RaycharmingParticle cell) =>
        {
            float3 pos = cell.Position;

            pos.x = pos.x * scale.x;
            pos.x = math.remap(-size.x/2f, size.x/2f, 0, size.x, pos.x);
            pos.x = math.clamp(pos.x, 0, size.x);

            pos.y *= scale.y;
            pos.y = math.remap(-size.y/2f, size.y/2f, 0, size.y, pos.y);
            pos.y = math.clamp(pos.y, 0, size.y);

            pos.z *= scale.z;
            pos.z = math.remap(-size.z/2f, size.z/2f, 0, size.z, pos.z);
            pos.z = math.clamp(pos.z, 0, size.z);
            
            
            int index = Raccoonlabs.ArrayExtends.ToLinearIndex(pos, size.x, size.y, size.z);
            index = math.clamp(index, 0, count-1);
            cell.lastIndex = index;
            
            cell.Velocity *= 0.97f;
            cell.Velocity += new float3(0, -1f, 0);
            cell.Position += cell.Velocity * dt;

            if (cell.Position.y < -size.y)
            {
                cell.Amount = 0;
                wtr.DestroyEntity(entityInQueryIndex,e);
            }
        }).ScheduleParallel(Dependency);
        
        Dependency = JobHandle.CombineDependencies(Dependency, updateParticleHandle);

 //       NativeArray<float> lastVals = new NativeArray<float>(_lastVals, Allocator.TempJob);
        JobHandle handle = Entities.WithName("Particle_Amount_Transfer").WithAll<RaycharmingParticle>().ForEach((ref RaycharmingParticle cell) =>
        {
   //         cell.lastAmount = lastVals[cell.lastIndex];
            vals[cell.lastIndex] += cell.Amount;

        }).Schedule(Dependency);

        handle.Complete();
        ecb.Playback(_manager);
        
        ecb.Dispose();
        

        /*
        for (int i = 0; i < count; i++)
        {
            if ((debug[i] != float3.zero).x)
            {
                Debug.DrawRay(debug[i], Vector3.down, Color.red);
            }
        }*/
        
//CACA
        k_BufferMarker.Begin();

        _computeBuffer.SetData(vals);
     //   _lastVals.CopyFrom(vals);
        k_BufferMarker.End();
        
        k_BufferSendMarker.Begin();
        ComputeShader.SetBuffer(_kernel, "Input", _computeBuffer);
        k_BufferSendMarker.End();
        
        k_DispatchMarker.Begin();
        ComputeShader.Dispatch(_kernel, Size.x, Size.y, Size.z);
        k_DispatchMarker.End();

        vals.Dispose();
     //   lastVals.Dispose();


    }

    protected override void OnDestroy()
    {
        base.OnDestroy();
        _computeBuffer.Dispose();
    }

    /*
    void CreateEntities()
    {
        int count = Size.x * Size.y * Size.z;

        NativeArray<float3> pos = new NativeArray<float3>(count, Allocator.TempJob);
        NativeArray<float> amount = new NativeArray<float>(count, Allocator.TempJob);

        for (int x = 0; x < Size.x; x++)
        {
            for (int y = 0; y < Size.y; y++)
            {
                for (int z = 0; z < Size.z; z++)
                {
                    Vector3 val = new Vector3(x, y, z);
                    int i = Raccoonlabs.ArrayExtends.ToLinearIndex(val, Size.x, Size.y, Size.z);
                    pos[i] = val;
                    amount[i] = Random.value;
                }
            }
        }
        


        _ecb = new EntityCommandBuffer(Allocator.TempJob, PlaybackPolicy.MultiPlayback);

        _prototype = _manager.CreateEntity();

        _manager.AddComponent<RaycharmingParticle>(_prototype);
        
        
        var spawnJob = new SpawnJob()
        {
            Prototype = _prototype,
            Ecb = _ecb.AsParallelWriter(),
            EntityCount = count,
            Pos = pos,
            Val = amount,
        };

        var spawnHandle = spawnJob.Schedule(count, 128);
            
        spawnHandle.Complete();
        _ecb.Playback(_manager);

    }
    
    [GenerateTestsForBurstCompatibility]
    public struct SpawnJob : IJobParallelFor
    {
        public Entity Prototype;
        public int EntityCount;
        public EntityCommandBuffer.ParallelWriter Ecb;
        public NativeArray<float3> Pos;
        public NativeArray<float> Val;

        public void Execute(int index)
        {
            // Clone the Prototype entity to create a new entity.
            RaycharmingParticle particle = new RaycharmingParticle();
            particle.Position = Pos[index];
            particle.Amount = Val[index];
            
            
            Entity e = Ecb.Instantiate(index, Prototype);
            Ecb.SetComponent(index, e, particle);

        }


    }
    */

}
