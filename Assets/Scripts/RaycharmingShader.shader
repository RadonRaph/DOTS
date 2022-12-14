Shader "FullScreen/RaycharmingShader"
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

    struct Box
    {
        float3 center;
        float3 half_extends;
        float3 min;
        float3 max;
    };

    Box CreateBox(float3 center, float3 halfExtends)
    {
        Box b;
        b.center = center;
        b.half_extends = halfExtends;
        b.min = center-halfExtends;
        b.max = center+halfExtends;

        return b;
    }

    struct BoxIntersectionResult
    {
        bool intersect;
        float3 pointMin;
        float3 pointMax;
    };

    
    BoxIntersectionResult BoxIntersection(Box b, CustomRay r) {
        BoxIntersectionResult result;
        
        double tx1 = (b.min.x - r.origin.x)*r.invdir.x;
        double tx2 = (b.max.x - r.origin.x)*r.invdir.x;

        double tmin = min(tx1, tx2);
        double tmax = max(tx1, tx2);

        double ty1 = (b.min.y - r.origin.y)*r.invdir.y;
        double ty2 = (b.max.y - r.origin.y)*r.invdir.y;

        tmin = max(tmin, min(ty1, ty2));
        tmax = min(tmax, max(ty1, ty2));

        double tz1 = (b.min.z - r.origin.z)*r.invdir.z;
        double tz2 = (b.max.z- r.origin.z)*r.invdir.z;

        tmin = max(tmin, min(tz1, tz2));
        tmax = min(tmax, max(tz1, tz2));

        result.intersect = tmax >= tmin;
        result.pointMin = r.origin+r.dir*tmin;
        result.pointMax = r.origin+r.dir*tmax;
        return result;
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

    float3 nearestPointOnLine(float3 lineA, float3 lineB, float3 targetPoint)
    {
        float3 lineDir = normalize(lineB-lineA);
        float3 v = targetPoint-lineA;
        float d = dot(v, lineDir);
        return lineA+lineDir*d;
    }

    

    bool BoxContains(Box b, float3 pos)
    {
        bool x = pos.x > b.min.x && pos.x< b.max.x;
        bool y = pos.y > b.min.y && pos.y< b.max.y;
        bool z = pos.z > b.min.z && pos.z< b.max.z;

        return x&&y&&z;
    }

    int sphereCount = 0;
    Buffer<float3> spherePos;
    Buffer<float> sphereRadius;

    float CalculateDistance(Sphere s, float3 p)
    {
       return   (distance(p, s.center)-s.radius);
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

        // Add your custom pass code here
        Box b = CreateBox(float3(0,0,0)-_WorldSpaceCameraPos, float3(40,32,40));
        

        
       float3 dir = GetWorldSpaceViewDir(posInput.positionWS);

        
        CustomRay r = CreateRay(_WorldSpaceCameraPos,  viewDirection);

        //bool yellow = SphereIntersection(s, r);

        bool yellow = false;
        bool red = false;

        float dist = 9999;
        
        float dist_MX = 0;
        float dist_PX = 0;

        float dist_MY = 0;
        float dist_PY = 0;

        float dist_MZ = 0;
        float dist_PZ = 0;

        float delta = 0.001;
        
        float distCount = 0;

        float sumDensity = 0;
        float sumRi = 0;
        float minDistance = 100000;

        dist = 0;

        BoxIntersectionResult boxResult = BoxIntersection(b, r);
        if (boxResult.intersect){
            for (int i = 0; i < sphereCount; i++)
            {
                Sphere s = CreateSphere(spherePos[i]-_WorldSpaceCameraPos,  sphereRadius[i]);
             //   SphereIntersectionResult result = SphereIntersection(s,r);
               
                float3 cp = nearestPointOnLine(boxResult.pointMin, boxResult.pointMax, s.center);

                float3 cp_MX = cp + float3(-delta,0,0);
                float3 cp_PX = cp + float3(delta,0,0);

                float3 cp_MY = cp + float3(0,-delta,0);
                float3 cp_PY = cp + float3(0, delta,0);
                
                float3 cp_MZ = cp + float3(0,0,-delta);
                float3 cp_PZ = cp + float3(0, 0,delta);

                dist += clamp(1-CalculateDistance(s, cp),0,1);
                distCount++;

                dist_MX +=  CalculateDistance(s, cp_MX);
                dist_PX +=  CalculateDistance(s, cp_PX);

                dist_MY += CalculateDistance(s, cp_MY);
                dist_PY += CalculateDistance(s, cp_PY);

                dist_MZ += CalculateDistance(s, cp_MZ);
                dist_PZ += CalculateDistance(s, cp_PZ);

                
            }
            red = true;
            yellow = true;
        }

        dist = clamp(dist, 0,1);
        //dist /= distCount;
       // dist_MX/=distCount;
       // dist_PX/=distCount;

        //dist_MY/=distCount;
        //dist_PY/=distCount;

        //dist_MZ/=distCount;
        //dist_PZ/=distCount;
/*
        dist = pow(dist, 0.9);

        dist_MX = pow(dist_MX, 0.9);
        dist_PX = pow(dist_PX, 0.9);

        dist_MY = pow(dist_MY, 0.9);
        dist_PY = pow(dist_PY, 0.9);

        dist_MZ = pow(dist_MZ, 0.9);
        dist_PZ = pow(dist_PZ, 0.9);*/


        float dist_X = dist_PX-dist_MX;
        float dist_Y = dist_PY-dist_MY;
        float dist_Z = dist_PZ-dist_MZ;

        float3 normal = normalize(float3(dist_X, dist_Y, dist_Z)*dist);
       // float4x4 viewTranspose = transpose(UNITY_MATRIX_V);
       // normal = mul(viewTranspose, float4(normal.xyz, 0)).xyz;

        float3 light = float3(15,45,0);

        float lightW = dot(normal, light);

      //  dist/=distCount;
      //  dist*=0.5;

        //bool yellow = BoxIntersection(b, r);

       // float3 o = _WorldSpaceCameraPos;
       // float3 t = posInput.positionWS;

        /*
        bool yellow = false;

        for (float i = 0; i < 1; i+=0.01)
        {
            float3 pos = lerp(o,t, i);
            if (Contains(b, pos))
                yellow = true;
        }
*/

        if (red)
        {
            color.x += 0.1;
        }
        
        if (yellow)
        {

            float c = lightW+1;
          //  c= dist;
            color = float4(c,c,c,dist);
          //  color = float4(normal.xyz,dist);
            //color = float4(,1);
        }

       // color = float4(posInput.positionWS,1);
        

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
