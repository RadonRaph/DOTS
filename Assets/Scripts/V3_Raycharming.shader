Shader "FullScreen/V3_Raycharming"
{
    Properties
    {
        _smoothness ("Smoothness", float) = 15
        _lightDir ("Light Dir", vector) = (30,30,30)
    }
    
    HLSLINCLUDE

    #pragma vertex Vert

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/RenderPass/CustomPass/CustomPassCommon.hlsl"

    // The PositionInputs struct allow you to retrieve a lot of useful information for your fullScreenShader:
    // struct PositionInputs
    // {
    //     float3 positionWS;  // World space position (could be camera-relative)
    //     float2 positionNDC; // Normalized screen coordinates within the viewport    : [0, 1) (with the half-pixel offset)
    //     uint2  positionSS;  // Screen space pixel coordinates                       : [0, NumPixels)
    //     uint2  tileCoord;   // Screen tile coordinates                              : [0, NumTiles)
    //     float  deviceDepth; // Depth from the depth buffer                          : [0, 1] (typically reversed)
    //     float  linearDepth; // View space Z coordinate                              : [Near, Far]
    // };

    // To sample custom buffers, you have access to these functions:
    // But be careful, on most platforms you can't sample to the bound color buffer. It means that you
    // can't use the SampleCustomColor when the pass color buffer is set to custom (and same for camera the buffer).
    // float4 CustomPassSampleCustomColor(float2 uv);
    // float4 CustomPassLoadCustomColor(uint2 pixelCoords);
    // float LoadCustomDepth(uint2 pixelCoords);
    // float SampleCustomDepth(float2 uv);

    // There are also a lot of utility function you can use inside Common.hlsl and Color.hlsl,
    // you can check them out in the source code of the core SRP package.
        struct CustomRay
    {
        float3 origin;
        float3 dir;
        float3 invdir;
        int sign[3];
    };

    CustomRay CreateRay(float3 origin, float3 dir)
    {
        CustomRay r;
        r.origin = origin;
        r.dir = dir;
        r.invdir = 1/dir;

        r.sign[0] = r.invdir.x < 0;
        r.sign[1] = r.invdir.y < 0;
        r.sign[2] = r.invdir.z < 0;

        return r;
    }

        struct Sphere
    {
        float3 center;
        float radius;
        float radius2;
    };

    Sphere CreateSphere(float3 c, float r)
    {
        Sphere s;
        s.center = c;
        s.radius = r;
        s.radius2 = r*r;
        return  s;
    }
    

    struct SphereIntersectionResult
    {
        bool Intersect;
        float3 point1;
        float3 point2;
    };

    
    SphereIntersectionResult SphereIntersection(Sphere s, CustomRay r)
    {
        SphereIntersectionResult result;
        
        float3 L = r.origin - s.center; 
        float a = dot(r.dir, r.dir);
        float b = 2 * dot(r.dir, L);
        float c = dot(L, L) - s.radius2;

        float discr = b * b - 4 * a * c;

        if (discr < 0){
            result.Intersect = false;
        }else if (discr == 0)
        {
            float v = 0.5*b/a;
            result.point1 = r.origin+r.dir*v;
            result.point2 = r.origin+r.dir*v;

            result.Intersect = true;
        }
        else
        {
            float q = (b > 0) ? -0.5 * (b+sqrt(discr)) : -0.5 * (b-sqrt(discr));

            float x0 = q/a;
            float x1 = c/q;
            
            result.point1 = r.origin+r.dir * min(x0,x1);
            result.point2 = r.origin+r.dir* max(x0,x1);

            result.Intersect = true;
        }

        

        return result;
    }

     int sphereCount = 0;
    Buffer<float3> spherePos;
    Buffer<float> sphereRadius;

    float _smoothness = 20;

    float3 _lightDir;

    float3 nearestPointOnLine(float3 lineA, float3 lineDir, float3 targetPoint)
    {
        float3 v = targetPoint-lineA;
        float d = dot(v, lineDir);
        return lineA+lineDir*d;
    }


    float3 GetClosestPoint(CustomRay r, Sphere s)
    {
        SphereIntersectionResult result = SphereIntersection(s,r);

        if (result.Intersect)
        {
            return result.point1;
        }else{
            return nearestPointOnLine(r.origin, r.dir, s.center);
        }
        
    }
    float oldGetDistanceMetaball(float3 p)
    {
        float sumDensity = 0;
        float sumRi = 0;
        float minDistance = 100000;
        for (int i = 0; i < sphereCount; ++i)
        {
            float3 center = spherePos[i];
            float radius =  sphereRadius[i];
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

     float GetDistanceMetaball(float3 p)
    {

        float minDistance = 100000;
        float minSum =0;
        float minCount = 0;
        
        for (int i = 0; i < sphereCount; ++i)
        {
            float3 center = spherePos[i];
            float radius = max( sphereRadius[i],1);
            float r = length(center - p);
            float d = distance(center,p) - radius;

            minDistance = min(minDistance, d);

            if (d <= 0)
            {
                minCount++;
                minSum+=d;
            }

        }

        if (minCount == 0)
        {
            return minDistance;
        }else
        {
            return minSum/minCount;
        }
        //return max(minDistance, 0);
    }

    float3 FindClosestPoint(CustomRay ray)
    {
        float minDist = 9999;
        float3 result = float3(0,0,0);
        for (int i = 0; i < sphereCount; i++)
        {
            Sphere s = CreateSphere(spherePos[i], spherePos[i]);

            float3 closestPoint = GetClosestPoint(ray,s);
//C DEBILE ça
            float d = distance(closestPoint, s.center)-s.radius;

            if (d < minDist)
            {
                minDist= d;
                result = closestPoint;
            }
        }

        return result;
    }

    float3 CalculateNormalMetaball(float3 from)
    {
        float delta = 0.001;
        float3 normal = float3(
            GetDistanceMetaball(from + float3(delta, 0, 0)) - GetDistanceMetaball(from + float3(-delta, 0, 0)),
            GetDistanceMetaball(from + float3(0, delta, 0)) - GetDistanceMetaball(from + float3(-0, -delta, 0)),
            GetDistanceMetaball(from + float3(0, 0, delta)) - GetDistanceMetaball(from + float3(0, 0, -delta))
        );
        return normalize(normal);
    }
    
    
    float4 FullScreenPass(Varyings varyings) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(varyings);
        float depth = LoadCameraDepth(varyings.positionCS.xy);
        PositionInputs posInput = GetPositionInput(varyings.positionCS.xy, _ScreenSize.zw, depth, UNITY_MATRIX_I_VP, UNITY_MATRIX_V);
        float3 viewDirection = GetWorldSpaceNormalizeViewDir(posInput.positionWS);
        float4 color = float4(0.0, 0.0, 0.0, 0.0);

        // Load the camera color buffer at the mip 0 if we're not at the before rendering injection point
        if (_CustomPassInjectionPoint != CUSTOMPASSINJECTIONPOINT_BEFORE_RENDERING)
            color = float4(CustomPassLoadCameraColor(varyings.positionCS.xy, 0), 1);

        

        float3 from = _WorldSpaceCameraPos;
        float3 dir = viewDirection;

        CustomRay ray = CreateRay(from, dir);

        float3 closestPoint = FindClosestPoint(ray);

        float d = GetDistanceMetaball(closestPoint);
        float3 normal = CalculateNormalMetaball(closestPoint);

       // color = float4(normal.xyz, 1);

        color.rgb = 1;
        color.a = d <= 0;
        



        float f = 1 - abs(_FadeValue * 2 - 1);
        return float4(color.rgb + f, color.a);
    }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }
        Pass
        {
            Name "Custom Pass 0"

            ZWrite Off
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            HLSLPROGRAM
                #pragma fragment FullScreenPass
            ENDHLSL
        }
    }
    Fallback Off
}
