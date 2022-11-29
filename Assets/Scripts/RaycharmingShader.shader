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
        float3 bounds[2];
    };

    Box CreateBox(float3 center, float3 halfExtends)
    {
        Box b;
        b.center = center;
        b.half_extends = halfExtends;
        b.bounds[0] = center-halfExtends;
        b.bounds[1] = center+halfExtends;

        return b;
    }

    bool intersect(Box b, Ray r) 
    { 
        float tmin, tmax, tymin, tymax, tzmin, tzmax; 
     
        tmin = (b.bounds[r.sign[0]].x - r.origin.x) * r.invdir.x; 
        tmax = (b.bounds[1-r.sign[0]].x - r.origin.x) * r.invdir.x; 
        tymin = (b.bounds[r.sign[1]].y - r.origin.y) * r.invdir.y; 
        tymax = (b.bounds[1-r.sign[1]].y - r.origin.y) * r.invdir.y; 
     
        if ((tmin > tymax) || (tymin > tmax)) 
            return false; 
     
        if (tymin > tmin) 
            tmin = tymin; 
        if (tymax < tmax) 
            tmax = tymax; 
     
        tzmin = (b.bounds[r.sign[2]].z - r.origin.z) * r.invdir.z; 
        tzmax = (b.bounds[1-r.sign[2]].z - r.origin.z) * r.invdir.z; 
     
        if ((tmin > tzmax) || (tzmin > tmax)) 
            return false; 
     
        if (tzmin > tmin) 
            tmin = tzmin; 
        if (tzmax < tmax) 
            tmax = tzmax; 
     
        return true; 
    }

    bool Contains(Box b, float3 pos)
    {
        bool x = pos.x > b.bounds[0].x && pos.x< b.bounds[1].x;
        bool y = pos.y > b.bounds[0].y && pos.y< b.bounds[1].y;
        bool z = pos.z > b.bounds[0].z && pos.z< b.bounds[1].z;

        return x&&y&&z;
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
        Box b = CreateBox(float3(0,0,10), float3(2,1,2));
        //Ray r = CreateRay(posInput.positionWS, viewDirection);

        float3 o = posInput.positionWS;
        float3 t = o + viewDirection * 100;

        bool yellow = false;

        for (float i = 0; i < 1; i+=0.1)
        {
            float3 pos = lerp(o,t, i);
            if (Contains(b, pos))
                yellow = true;
        }


        if (yellow)
        {
            color = float4(1,1,0,1);
        }

        

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
