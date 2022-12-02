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
    

    private ComputeBuffer _computeBuffer;
    private NativeArray<float> _lastVals;

    private EntityQuery _query;

    public NativeArray<RaycharmingParticle> particles;

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
        int count = Size.x * Size.y * Size.z;
       _computeBuffer = new ComputeBuffer(count, sizeof(float));

       _query = new EntityQueryBuilder(Allocator.Persistent).WithAll<RaycharmingParticle>().Build(this);


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

        Unity.Mathematics.Random random = new Unity.Mathematics.Random((uint)this.GetHashCode());


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
            cell.Velocity += new float3(0, -5f, 0);
            cell.Position += cell.Velocity * dt;

            if (cell.Position.y < -size.y/2f)
            {
                float t = cell.Amount/cell.BaseAmount;
                t *= math.pow(t - 0.05f, 0.1f);

                cell.Amount = t*cell.BaseAmount;
                cell.Position.y = -size.y/2f;
                float3 dir = random.NextFloat3Direction()*5;
                dir.y = 20;
                cell.Velocity += dir;
            }

            if (cell.Amount <= 0.1f)
            {
                wtr.DestroyEntity(entityInQueryIndex,e);
            }
        }).ScheduleParallel(Dependency);
        
        Dependency = JobHandle.CombineDependencies(Dependency, updateParticleHandle);
        
        JobHandle handle = Entities.WithName("Particle_Amount_Transfer").WithAll<RaycharmingParticle>().ForEach((ref RaycharmingParticle cell) =>
        {
            vals[cell.lastIndex] += cell.Amount;

        }).Schedule(Dependency);

        handle.Complete();
        ecb.Playback(_manager);
        
        ecb.Dispose();

        particles = _query.ToComponentDataArray<RaycharmingParticle>(Allocator.Persistent);

        /*
        k_BufferMarker.Begin();
            _computeBuffer.SetData(vals);
        k_BufferMarker.End();
        
        k_BufferSendMarker.Begin();
            ComputeShader.SetBuffer(_kernel, "Input", _computeBuffer);
        k_BufferSendMarker.End();
        
        k_DispatchMarker.Begin();
         ComputeShader.Dispatch(_kernel, Size.x, Size.y, Size.z);
        k_DispatchMarker.End();*/

        vals.Dispose();


    }

    protected override void OnDestroy()
    {
        base.OnDestroy();
        _computeBuffer.Dispose();
    }



}
