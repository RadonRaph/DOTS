Shader "FullScreen/RayMetaballs"
{
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

    /*
    bool SphereIntersection(Sphere s, Ray r)
    {
        float L = r.origin-s.center;
        float tc = dot(L, r.dir);

        if (tc < 0.0) return false;

        float d2 = dot(L, L)-(tc*tc);
        
        if (d2 > s.radius2) return false;

        float thc = sqrt(s.radius2-d2);

        float t0 = tc - thc; 
        float t1 = tc + thc;

        if (t0 < 0) { 
            t0 = t1;  //if t0 is negative, let's use t1 instead 
            if (t0 < 0) return false;  //both t0 and t1 are negative 
        } 

        return true;
    }*/

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

    float3 nearestPointOnLine(float3 lineA, float3 lineDir, float3 targetPoint)
    {
        float3 v = targetPoint-lineA;
        float d = dot(v, lineDir);
        return lineA+lineDir*d;
    }

    float GetDist(float3 from, float3 dir, int sphereI)
    {
        float3 c = spherePos[sphereI];
        return distance( nearestPointOnLine(from, dir, c), c) -sphereRadius[sphereI];

    }

    float GetMinDist(float3 from, float3 dir)
    {
        float minDist = 9999;
        for (int i = 0; i < sphereCount; i++)
        {
            float3 c = spherePos[i];
            float d = distance( nearestPointOnLine(from, dir, c), c) -sphereRadius[i];

            minDist = min(d, minDist);
        }
        return minDist;
    }

    float GetAvgDist(float3 from, float3 dir)
    {
        float dist = 0;
        int count = 0;
        for (int i = 0; i < sphereCount; i++)
        {
            float3 c = spherePos[i];
            float d = distance( nearestPointOnLine(from, dir, c), c) -sphereRadius[i];

            if (d < 0)
            {
                dist+=d;
                count++;
            }
        }
        return dist;
    }

    float3 GetNormal(float3 from, float3 dir)
    {
        float delta =0.001f;
        float powRatio = 1;

        float3 normalSum = float3(0,0,0);
        int sumCount =0 ;


        


            float dist_PX = GetMinDist(from + float3(delta, 0,0), dir);
          //  dist_PX = pow(1-dist_PX, powRatio);
            float dist_MX = GetMinDist(from + float3(-delta, 0,0), dir);
          //  dist_MX = pow(1-dist_MX, powRatio);

            float dist_PY = GetMinDist(from + float3(0,delta, 0), dir);
        //    dist_PY = pow(1-dist_PY, powRatio);
            float dist_MY = GetMinDist(from + float3(0,-delta, 0), dir);
         //   dist_MY = pow(1-dist_MY, powRatio);

            float dist_PZ = GetMinDist(from + float3(0,0,delta), dir);
          //  dist_PZ = pow(1-dist_PZ, powRatio);
            float dist_MZ = GetMinDist(from + float3(0,0,-delta), dir);
          //  dist_MZ = pow(1-dist_MZ, powRatio);

            float distX = dist_PX-dist_MX;
            float distY = dist_PY-dist_MY;
            float distZ = dist_PZ-dist_MZ;

            float3 n = normalize(float3(distX, distY, distZ));
            normalSum += n;
            sumCount++;

        

        return normalSum/sumCount;
    }

    float3 GetAllNormal(float3 from, float3 dir)
    {
        float delta =0.001f;
        float powRatio = 1;

        float3 normalSum = float3(0,0,0);
        int sumCount =0 ;

        float minDist = GetMinDist(from, dir);
        
        for (int i = 0; i < sphereCount; i++)
        {

            float d = GetDist(from, dir, i);
            if (d > 0.01* minDist)
            {
                continue;
            }

            float dist_PX = GetDist(from + float3(delta, 0,0), dir, i);
          //  dist_PX = pow(1-dist_PX, powRatio);
            float dist_MX = GetDist(from + float3(-delta, 0,0), dir, i);
          //  dist_MX = pow(1-dist_MX, powRatio);

            float dist_PY = GetDist(from + float3(0,delta, 0), dir, i);
        //    dist_PY = pow(1-dist_PY, powRatio);
            float dist_MY = GetDist(from + float3(0,-delta, 0), dir, i);
         //   dist_MY = pow(1-dist_MY, powRatio);

            float dist_PZ = GetDist(from + float3(0,0,delta), dir, i);
          //  dist_PZ = pow(1-dist_PZ, powRatio);
            float dist_MZ = GetDist(from + float3(0,0,-delta), dir, i);
          //  dist_MZ = pow(1-dist_MZ, powRatio);

            float distX = dist_PX-dist_MX;
            float distY = dist_PY-dist_MY;
            float distZ = dist_PZ-dist_MZ;

            float3 n = normalize(float3(distX, distY, distZ));
            normalSum += n;
            sumCount++;

        }

        return normalSum/sumCount;
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

        float d = GetMinDist(from, dir);
        //float3 normal = GetNormal(from, dir);
        //float3 allNormal = GetAllNormal(from, dir);

        //normal = lerp(normal, allNormal, 0.9f);
        float3 viewNormal = GetAllNormal(from, dir);
        float3 normal = TransformViewToWorldNormal(viewNormal);




        color.rgb =  pow(1-d, 0.9);

        float a = d < 0;
        color.rgb = 0.5+clamp(dot(normal, float3(30,30,0)),0,1);
        //color.rgb = normal;
        color.a = a;
/*
        float3 v = normalize(p);
        CustomRay r = CreateRay(_WorldSpaceCameraPos,  viewDirection);
        Sphere s1 = CreateSphere(float3(0,0,0), 5);
        Sphere s2 = CreateSphere(p, 1);

        SphereIntersectionResult sr1 = SphereIntersection(s1,r);
        SphereIntersectionResult sr2 = SphereIntersection(s2,r);

        if (sr1.Intersect)
            color.r += 0.1;

        color.rgb += v*0.5;*/
        

        //color = float4(d,d,d,1);


        // Add your custom pass code here

        // Fade value allow you to increase the strength of the effect while the camera gets closer to the custom pass volume
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
