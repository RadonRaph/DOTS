using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Entities;
using Unity.Mathematics;

public struct RaycharmingParticle : IComponentData
{

    public float3 Velocity;
    public float3 Position;
    public float Amount;
}

