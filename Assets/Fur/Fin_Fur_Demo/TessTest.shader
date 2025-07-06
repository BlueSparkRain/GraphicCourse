Shader "Unlit/TessTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TessFactor("TessFactor",Float)=1
        _InsideTessFactor("InsideTessFactor",Float)=1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma  hull hull
            #pragma  domain domain
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                //(可选)
                float2 uv : TEXCOORD0;
                //float3 normalOS:NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                //(可选)
                float2 uv : TEXCOORD0;
                //float3 normalWS:TEXCOORD1;
                //float3 positionWS:TEXCOORD2;
            };
            
            //常量属性区
            CBUFFER_START(unityperMaterial)
            float4 _MainTex_ST;

            float _TessFactor;
            float _InsideTessFactor;
            
            CBUFFER_END
            
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

            Attributes vert (Attributes v)
            {
                // 这里不做任何复杂的变换，直接返回输入。
                // 最终的裁剪空间位置计算将由 Domain Shader 完成。
                return v;
            }

        [domain("tri")]
        [partitioning("integer")]
        [outputtopology("triangle_cw")]
        [patchconstantfunc("hullConst")]
        [outputcontrolpoints(3)]
        Attributes hull(InputPatch<Attributes, 3> input, uint id : SV_OutputControlPointID)
        {
            return input[id];
        }

        struct HsConstantOutput
        {
                float fTessFactor[3]    : SV_TessFactor;//必须有的语义，定义补丁三条边的细分因子
                float fInsideTessFactor : SV_InsideTessFactor;//定义了补丁内部区域的细分因子。它控制了补丁内部的三角形网格的密度
        };

        HsConstantOutput hullConst(InputPatch<Attributes, 3> i)
        {
            HsConstantOutput o = (HsConstantOutput)0;
            o.fTessFactor[0] = o.fTessFactor[1] = o.fTessFactor[2] = _TessFactor;
            o.fInsideTessFactor = _InsideTessFactor;
             return  o;
        }

         [domain("tri")]Varyings domain(
        HsConstantOutput hsConst, 
        const OutputPatch<Attributes, 3> i,
        float3 bary : SV_DomainLocation)
        {
                Varyings o = (Varyings)0;
                // 位置插值位置
                float4 interpolatedPosOS = i[0].positionOS * bary.z +
                                           i[1].positionOS * bary.x +
                                           i[2].positionOS * bary.y;
                // 将位置从对象空间转换到裁剪空间
                o.positionCS = TransformObjectToHClip(interpolatedPosOS);
            
                // 将插值后的对象空间位置转换到世界空间
                //o.positionWS = TransformObjectToWorld(interpolatedPosOS);
            
                // 法线插值：
                // 使用重心坐标对原始控制点的对象空间法线进行线性插值
                /*float3 interpolatedNormalOS = i[0].normalOS * bary.z +
                                              i[1].normalOS * bary.x +
                                              i[2].normalOS * bary.y;
                interpolatedNormalOS = normalize(interpolatedNormalOS); // 归一化法线     */   
            
                // 将插值后的对象空间法线转换到世界空间
                // 法线转换要使用 TransformObjectToWorldNormal，而非 TransformObjectToWorld
                //o.normalWS = TransformObjectToWorldNormal(interpolatedNormalOS);
                return o;
            }
            
            float4 frag (Varyings i) : SV_Target
            {
                //采样纹理
                float4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                return col;
            }
            ENDHLSL
        }
    }
}
