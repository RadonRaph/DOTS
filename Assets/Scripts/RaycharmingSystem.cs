using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using Unity.Entities;
using Unity.Jobs;
using UnityEngine;
using Unity.Mathematics;
using Unity.Transforms;
using UnityEngine.Rendering;
using Random = UnityEngine.Random;

public partial class RaycharmingSystem : SystemBase
{

    public ComputeShader ComputeShader;
    public Vector3Int Size = new Vector3Int(16, 8, 16);
    public RenderTexture Texture;


    private bool _init = false;
    private int _kernel;
    
    
    private World _world;
    private EntityManager _manager;
    private EntityCommandBuffer _ecb;
    private Entity _prototype;

    public float[] amountVals;

    protected override void OnCreate()
    {
        base.OnCreate();
        Texture = new RenderTexture(Size.x, Size.y, 0, RenderTextureFormat.ARGBFloat);
        Texture.width = Size.x;
        Texture.height = Size.y;
        Texture.volumeDepth = Size.z;
        Texture.dimension = TextureDimension.Tex3D;
        Texture.enableRandomWrite = true;
        Texture.Create();


        
        
    }

    public void Init()
    {
        _kernel = ComputeShader.FindKernel("CSMain");
        ComputeShader.SetTexture(_kernel, "Result", Texture);
        ComputeShader.SetInts("size", Size.x, Size.y, Size.z);
        
        _world = World.DefaultGameObjectInjectionWorld;
        _manager = _world.EntityManager;
       // CreateEntities();

        _init = true;
    }

    protected override void OnUpdate()
    {
        if (!_init)
            return;
        
        int3 size = new int3(Size.x, Size.y, Size.z);
        int count = size.x * size.y * size.z;
        
        NativeArray<float> vals = new NativeArray<float>(count, Allocator.TempJob);
        NativeArray<float3> debug = new NativeArray<float3>(count, Allocator.TempJob);

        float dt = _world.Time.DeltaTime;
        
        
        JobHandle handle = Entities.WithAll<RaycharmingParticle>().ForEach((int entityInQueryIndex, ref RaycharmingParticle cell) =>
        {
            float3 pos = cell.Position;

            
            pos.x = math.remap(-size.x/2f, size.x/2f, 0, size.x, pos.x);
            pos.x = math.clamp(pos.x, 0, size.x);
            
            pos.y = math.remap(-size.y/2f, size.y/2f, 0, size.y, pos.y);
            pos.y = math.clamp(pos.y, 0, size.y);
            
            pos.z = math.remap(-size.z/2f, size.z/2f, 0, size.z, pos.z);
            pos.z = math.clamp(pos.z, 0, size.z);
            
            
            int index = Raccoonlabs.ArrayExtends.ToLinearIndex(pos, size.x, size.y, size.z);
            index = math.clamp(index, 0, count-1);
            vals[index] += cell.Amount;
            cell.Velocity *= 0.97f;
            cell.Velocity += new float3(0, -0.2f, 0);
            cell.Position += cell.Velocity * dt;

            if (cell.Position.y < -size.y)
            {
                cell.Amount = 0;
            }

            debug[entityInQueryIndex] = cell.Position;

        }).Schedule(Dependency);

        handle.Complete();

        for (int i = 0; i < count; i++)
        {
            if ((debug[i] != float3.zero).x)
            {
                Debug.DrawRay(debug[i], Vector3.down, Color.red);
            }
        }
        

        ComputeBuffer buffer = new ComputeBuffer(count, sizeof(float));
        buffer.SetData(vals);
        
        
        ComputeShader.SetBuffer(_kernel, "Input", buffer);
        ComputeShader.Dispatch(_kernel, Size.x, Size.y, Size.z);
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
