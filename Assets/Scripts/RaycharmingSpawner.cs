using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using Unity.Entities;
using Unity.Jobs;
using Unity.Mathematics;
using Random = UnityEngine.Random;

public class RaycharmingSpawner : MonoBehaviour
{

    public int quantity = 5;
    public float radius = 1;
    public Vector2 amount;
    public float delay = 5f;
    public float delayRandomMultiplier = 3;

    private float _d;
    private World _world;
    private EntityManager _manager;
    private EntityCommandBuffer _ecb;
    private Entity _prototype;
    
    // Start is called before the first frame update
    void Start()
    {
        _world = World.DefaultGameObjectInjectionWorld;
        _manager = _world.EntityManager;

        _ecb = new EntityCommandBuffer(Allocator.TempJob, PlaybackPolicy.MultiPlayback);

        _prototype = _manager.CreateEntity();

        _manager.AddComponent<RaycharmingParticle>(_prototype);

        _d = delay * Random.Range(1f, delayRandomMultiplier);
    }

    // Update is called once per frame
    //COLLAPSE ALL SPAWNER IN ONE CALL
    void Update()
    {
        _d -= Time.deltaTime;

        if (_d < 0)
        {
            _d = delay * Random.Range(1f, delayRandomMultiplier);

           // NativeArray<float3> pos = new NativeArray<float3>(quantity, Allocator.TempJob);
            for (int i = 0; i < quantity; i++)
            {
                float3 pos = (transform.localPosition+(Random.insideUnitSphere * radius));

                Entity e = _manager.CreateEntity();
                
                RaycharmingParticle particle = new RaycharmingParticle();
                particle.Position = pos;
                float amt = Random.Range(amount.x, amount.y);
                particle.Amount = amt;
                particle.BaseAmount = amt;

                _manager.AddComponent<RaycharmingParticle>(e);
                _manager.SetComponentData(e, particle);

            }
            
            /*
            var spawnJob = new SpawnJob()
            {
                Prototype = _prototype,
                Ecb = _ecb.AsParallelWriter(),
                EntityCount = quantity,
                pos = pos,
            };

            var spawnHandle = spawnJob.Schedule(quantity, 128);

            spawnHandle.Complete();
            _ecb.Playback(_manager);*/
        }
    }
    
    //PLAYBACK CHELou
    [GenerateTestsForBurstCompatibility]
    public struct SpawnJob : IJobParallelFor
    {
        public Entity Prototype;
        public int EntityCount;
        public EntityCommandBuffer.ParallelWriter Ecb;
        public NativeArray<float3> pos;


        public void Execute(int index)
        {
            // Clone the Prototype entity to create a new entity.
            RaycharmingParticle particle = new RaycharmingParticle();
            particle.Position = pos[index];
            particle.Amount = 1;
            
            Entity e = Ecb.Instantiate(index, Prototype);
            Ecb.SetComponent(index, e, particle);

        }


    }
}
