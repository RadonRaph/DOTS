         struct CustomRay
    {
        float3 origin;
        float3 dir;
        float3 invdir;
        int sign[3];
    };

    CustomRay CustomCreateRay(float3 origin, float3 dir)
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

        
        
        float tx1 = (b.min.x - r.origin.x)*r.invdir.x;
        float tx2 = (b.max.x - r.origin.x)*r.invdir.x;

        float tmin = min(tx1, tx2);
        float tmax = max(tx1, tx2);

        float ty1 = (b.min.y - r.origin.y)*r.invdir.y;
        float ty2 = (b.max.y - r.origin.y)*r.invdir.y;

        tmin = max(tmin, min(ty1, ty2));
        tmax = min(tmax, max(ty1, ty2));

        float tz1 = (b.min.z - r.origin.z)*r.invdir.z;
        float tz2 = (b.max.z- r.origin.z)*r.invdir.z;

        tmin = max(tmin, min(tz1, tz2));
        tmax = min(tmax, max(tz1, tz2));

        result.intersect = tmax >= tmin;
        result.pointMin = r.origin+r.dir*tmin;
        result.pointMax = r.origin+r.dir*tmax;

        if (tmax >= 0)
            result.intersect = false;

       
        
        return result;
    }


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



//Texture3D<float4> AmountTex;
//float3 _WSpos;
//float3 _dir;
//SamplerState samplerSt;


void Raymarch_float(Texture3D<float4> AmountTex, float3 _CamWSpos, float3 _dir, SamplerState samplerSt,float3 boxPos, float3 boxSize, out float4 color, out float3 normal){

        // Add your custom pass code here
        #if defined(SHADERGRAPH_PREVIEW)
        color = float4(0,0,0,0);
        normal = float3(0, 0, 0);
        #else

        Box b = CreateBox(boxPos-_CamWSpos, boxSize);
        CustomRay r = CustomCreateRay(_CamWSpos,  _dir);
        color=float4(0,0,0,0);
        normal = float3(0,0,0);

        
    

        BoxIntersectionResult boxResult = BoxIntersection(b, r);

        if (boxResult.intersect){
            color += float4(0.1,0,0,0);

            float3 startPos = WSToTexSpace(boxResult.pointMin, b);
            float3 endPos = WSToTexSpace(boxResult.pointMax, b);




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

            float delta = 0.001f;
            float cumulatedAlpha = 0;
            
            for(float t = 0; t < 1; t+=0.1f)
            {

                float3 currentPos = lerp(startPos, endPos, t);

                float3 pos_PX = currentPos + float3(delta, 0,0); 
                float3 pos_MX = currentPos + float3(-delta, 0,0); 

                float3 pos_PY = currentPos + float3(0,delta,0); 
                float3 pos_MY = currentPos + float3(0,-delta, 0);

                float3 pos_PZ = currentPos + float3(0,0,delta); 
                float3 pos_MZ = currentPos + float3(0,0,-delta); 
                
                
                float4 v = AmountTex.Sample(samplerSt, currentPos);
                

                
                v_PX = BlendUnder(AmountTex.Sample(samplerSt, pos_PX), v_PX);
                v_MX = BlendUnder( AmountTex.Sample(samplerSt, pos_MX), v_MX);

                v_PY = BlendUnder( AmountTex.Sample(samplerSt, pos_PY), v_PY);
                v_MY = BlendUnder( AmountTex.Sample(samplerSt, pos_MY), v_MY);

                v_PZ = BlendUnder( AmountTex.Sample(samplerSt, pos_PZ), v_PZ);
                v_MZ = BlendUnder( AmountTex.Sample(samplerSt, pos_MZ), v_MZ);


             



                
                mixedColor += v;
                maxA = max(maxA, v.w);
                maxColor = max(maxColor, v);
                count++;


                blendedColor = BlendUnder(v, blendedColor);

                cumulatedAlpha += v.w;

                if (cumulatedAlpha > 1)
                {
                  //  break;
                }
                
            }

            dist_X = v_PX.w-v_MX.w;
            dist_Y = v_PY.w-v_MY.w;
            dist_Z = v_PZ.w-v_MZ.w;


            float3 viewNormal = normalize(float3(dist_X, dist_Y, dist_Z));
            float4x4 viewTranspose = transpose(UNITY_MATRIX_V);
            normal = mul(viewTranspose, float4(viewNormal.xyz, 0)).xyz;
            normal = float3(dist_X, dist_Y, dist_Z);


          

            float3 light = float3(45,0,0);

            float lightW =  dot(normal, -light);

            float c= 0.5+(lightW*blendedColor.w);
            color = float4( c,c,c, blendedColor.w);

        }

        #endif

        
}