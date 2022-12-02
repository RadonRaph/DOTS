
int sphereCount = 0;
Buffer<float3> spherePos;
Buffer<float> sphereRadius;

float GetDistanceMetaball(float3 p)
{
    float sumDensity = 0;
    float sumRi = 0;
    float minDistance = 100000;
    for (int i = 0; i < sphereCount; ++i)
    {
        float3 center = spherePos[i];
        float radius = 0.3 * sphereRadius[i];
        float r = length(center - p);
        if (r <= radius)
        {
            sumDensity += 2 * (r * r * r) / (radius * radius * radius) - 3 * (r * r) / (radius * radius) + 1;
        }
        minDistance = min(minDistance, r - radius);
        sumRi += radius;
    }

    return max(minDistance, (0.2 - sumDensity) / (3 / 2.0 * sumRi));
}

float3 CalculateNormalMetaball(float3 from)
{
    float delta = 10e-5;
    float3 normal = float3(
        GetDistanceMetaball(from + float3(delta, 0, 0)) - GetDistanceMetaball(from + float3(-delta, 0, 0)),
        GetDistanceMetaball(from + float3(0, delta, 0)) - GetDistanceMetaball(from + float3(-0, -delta, 0)),
        GetDistanceMetaball(from + float3(0, 0, delta)) - GetDistanceMetaball(from + float3(0, 0, -delta))
    );
    return normalize(normal);
}

void SphereTraceMetaballs_float(float3 camPos,float3 viewDir, out float Alpha, out float3 NormalWS)
{
    #if defined(SHADERGRAPH_PREVIEW)
    Alpha = 1;
    NormalWS = float3(0, 0, 0);
    #else
    float maxDistance = 100;
    float threshold = 0.00001;
    float t = 0;
    int numSteps = 0;
    
    float outAlpha = 0;
    

    while (t < maxDistance)
    {
        float minDistance = 1000000;
        float3 from = camPos + t * viewDir;
        float d = GetDistanceMetaball(from);
        if (d < minDistance)
        {
            minDistance = d;
        }
    
        if (minDistance <= threshold * t)
        {
            outAlpha = 1;
            NormalWS = CalculateNormalMetaball(from);
            break;
        }
    
        t += minDistance;
        ++numSteps;
    }
    
    Alpha = outAlpha;
    #endif
}