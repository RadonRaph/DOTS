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

    struct Ray
    {
        float3 origin;
        float3 dir;
        float3 invdir;
        int sign[3];
    };

    Ray CreateRay(float3 origin, float3 dir)
    {
        Ray r;
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

    
    bool BoxIntersection(Box b, Ray r) {
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

        return tmax >= tmin;
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

    
    bool SphereIntersection(Sphere s, Ray r)
    {
        float3 L = r.origin - s.center; 
        float a = dot(r.dir, r.dir);
        float b = 2 * dot(r.dir, L);
        float c = dot(L, L) - s.radius2;

        float discr = b * b - 4 * a * c;

        if (discr < 0) return false;

        return true;
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

        
        Ray r = CreateRay(_WorldSpaceCameraPos,  viewDirection);

        //bool yellow = SphereIntersection(s, r);

        bool yellow = false;
        bool red = false;

        if (BoxIntersection(b, r)){
            for (int i = 0; i < sphereCount; i++)
            {
                Sphere s = CreateSphere(spherePos[i]-_WorldSpaceCameraPos, 5);
                if (SphereIntersection(s, r))
                    yellow = true;
            }
            red = true;
        }

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
            color = float4(1,1,0,1);
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
