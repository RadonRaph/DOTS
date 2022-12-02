Shader "FullScreen/VoxelRaycharmer"
{
    
    Properties
    {
        AmountTex ("Texture", 3D) = "white" {}
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

        if (tmax >= 0)
            result.intersect = false;

       
        
        return result;
    }

    sampler3D AmountTex;
    //int3 AmountTexSize;

    float Remap(float value, float from1, float to1, float from2, float to2)
    {
        return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
    }

    float3 WSToTexSpace(float3 ws, Box b)
    {
        float x = Remap(ws.x, b.min.x, b.max.x, 0, 1);
        float y = Remap(ws.y, b.min.y, b.max.y, 0, 1);
        float z = Remap(ws.z, b.min.z, b.max.z, 0, 1);

        return float3(x,y,z);
    }

                float4 BlendUnder(float4 color, float4 newColor)
            {
                color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
                color.a += (1.0 - color.a) * newColor.a;
                return color;
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
        CustomRay r = CreateRay(_WorldSpaceCameraPos,  viewDirection);

    

        BoxIntersectionResult boxResult = BoxIntersection(b, r);

        if (boxResult.intersect){
            color += float4(0.1,0,0,0);

            float3 startPos = WSToTexSpace(boxResult.pointMin, b);
            float3 endPos = WSToTexSpace(boxResult.pointMax, b);

            int3 dist = endPos-startPos;
            float d = length(dist);
            float3 dir = normalize(dist);

            float3 currentPos = startPos;


            float4 mixedColor = float4(0,0,0,0);
            float4 maxColor = float4(0,0,0,0);
            float4 firstColor = float4(0,0,0,0);
            float4 blendedColor = float4(0,0,0,0);
            float maxA= 0;
            int count = 0;

            float4 v_PX = float4(0,0,0,0);
            float4 v_MX = float4(0,0,0,0);

            float4 v_PY = float4(0,0,0,0);
            float4 v_MY = float4(0,0,0,0);

            float4 v_PZ = float4(0,0,0,0);
            float4 v_MZ = float4(0,0,0,0);
            
            float dist_X = 0;
            float dist_Y = 0;
            float dist_Z = 0;

            float delta = 0.1f;
            for(float t = 0; t < 1; t+=0.1f)
            {

                currentPos = lerp(startPos, endPos, t);

                float3 pos_PX = currentPos + float3(delta, 0,0); 
                float3 pos_MX = currentPos + float3(-delta, 0,0); 

                float3 pos_PY = currentPos + float3(0,delta,0); 
                float3 pos_MY = currentPos + float3(0,-delta, 0);

                float3 pos_PZ = currentPos + float3(0,0,delta); 
                float3 pos_MZ = currentPos + float3(0,0,-delta); 
                
                
                float4 v = tex3D(AmountTex, currentPos);
                

                v_PX = BlendUnder(tex3D(AmountTex, pos_PX), v_PX);
                v_MX = BlendUnder( tex3D(AmountTex, pos_MX), v_MX);

                v_PY = BlendUnder( tex3D(AmountTex, pos_PY), v_PY);
                v_MY = BlendUnder( tex3D(AmountTex, pos_MY), v_MY);

                v_PZ = BlendUnder( tex3D(AmountTex, pos_PZ), v_PZ);
                v_MZ = BlendUnder( tex3D(AmountTex, pos_MZ), v_MZ);





                
                mixedColor += v;
                maxA = max(maxA, v.w);
                maxColor = max(maxColor, v);
                count++;

                if (v.w>0)
                {
                    firstColor = float4(v.xyz, 1);


                    
                }
                blendedColor = BlendUnder(v, blendedColor);
                
            }

            dist_X = v_PX.w-v_MX.w;
            dist_Y = v_PY.w-v_MY.w;
            dist_Z = v_PZ.w-v_MZ.w;

            mixedColor/=count;


            float3 normal = normalize(float3(dist_X, dist_Y, dist_Z));

            float3 light = float3(45,0,0);

            float lightW =  dot(normal, -light);

            float c= 0.5+(lightW*blendedColor.w);
            color = float4( c,c,c, blendedColor.w);
            //color = maxColor;
            //color = firstColor;
            //color = blendedColor;
            //color = float4(a,a,a,1);
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
