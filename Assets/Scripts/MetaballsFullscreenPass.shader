Shader "FullScreen/MetaballsFullscreenPass"
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

    float3 CalculateNormalMetaball(float3 from)
    {
        float delta = 0.1;
        float3 normal = float3(
            GetDistanceMetaball(from + float3(delta, 0, 0)) - GetDistanceMetaball(from + float3(-delta, 0, 0)),
            GetDistanceMetaball(from + float3(0, delta, 0)) - GetDistanceMetaball(from + float3(-0, -delta, 0)),
            GetDistanceMetaball(from + float3(0, 0, delta)) - GetDistanceMetaball(from + float3(0, 0, -delta))
        );
        return normalize(normal);
    }



    void SphereTraceMetaballs_float(float3 camPos,float3 viewDir, out float Alpha, out float3 NormalWS)
    {

        float maxDistance = 100;
        float threshold = 0.00001;
        float t = 0;
        int numSteps = 0;
        
        float outAlpha = 0;
        

        while (t < maxDistance && numSteps < 1000)
        {
            float minDistance = 1000000;
            float3 from = camPos + t * -viewDir;
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

        float3 WSNormal = float3(0,0,0);
        float r_alpha = 0;

        SphereTraceMetaballs_float(_WorldSpaceCameraPos, viewDirection, r_alpha, WSNormal);

        float3 out_color = WSNormal;

        // Add your custom pass code here

        // Fade value allow you to increase the strength of the effect while the camera gets closer to the custom pass volume
        return float4(lerp(color.rgb, out_color, r_alpha), 1);
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
