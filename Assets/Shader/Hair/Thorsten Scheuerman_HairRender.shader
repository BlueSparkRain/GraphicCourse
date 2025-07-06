Shader "Unlit/Thorsten Scheuerman_HairRender"
{
 
	 Properties
    {
        [Header(Main Settings)]
        _MainTex("Albedo (RGB) Alpha (A)", 2D) = "white" {}
        _Color("Color Tint", Color) = (1,1,1,1)
        _Cutoff("Alpha Cutoff", Range(0,1)) = 0.5
        
        [Header(Specular Settings)]
        _SpecularTex("Specular Shift (R) Gloss (G)", 2D) = "white" {}
        _ShiftValue1("Primary Shift", Range(-2,2)) = 0.2
        _SpecColor1("Primary Spec Color", Color) = (1,1,1,1)
        _Gloss1("Primary Gloss", Range(2,256)) = 50
        _SpecIntensity1("Primary Intensity", Range(0,2)) = 0.5
        
        _ShiftValue2("Secondary Shift", Range(-2,2)) = -0.1
        _SpecColor2("Secondary Spec Color", Color) = (1,0.9,0.8,1)
        _Gloss2("Secondary Gloss", Range(2,256)) = 30
        _SpecIntensity2("Secondary Intensity", Range(0,2)) = 0.2
        
        [Header(Transmission)]
        _TransmissionPower("Transmission Power", Range(0,10)) = 2.0
        _TransmissionColor("Transmission Color", Color) = (1,0.8,0.7,1)
        
        [Header(Edge Enhancement)]
        _EdgeThreshold("Edge Threshold", Range(0,1)) = 0.1
        _EdgeSharpness("Edge Sharpness", Range(1,10)) = 3.0
        _EdgeColor("Edge Color", Color) = (0,0,0,1)
    }
    
    SubShader
    {
        Tags {
            "Queue"="AlphaTest"
            "RenderType"="TransparentCutout"
            "IgnoreProjector"="True"
        }
        LOD 400
        
        // 主光照通道
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            Cull Off  // 双面渲染
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile _ _ALPHATOCOVERAGE_ON
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            
            struct Varyings
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldTangent : TEXCOORD3;
                SHADOW_COORDS(4)
                UNITY_FOG_COORDS(5)
            };
            
            // 纹理属性
            sampler2D _MainTex, _SpecularTex;
            float4 _MainTex_ST;
            
            // 光照属性
            fixed4 _Color, _SpecColor1, _SpecColor2, _TransmissionColor, _EdgeColor;
            float _ShiftValue1, _Gloss1, _SpecIntensity1;
            float _ShiftValue2, _Gloss2, _SpecIntensity2;
            float _TransmissionPower, _Cutoff;
            float _EdgeThreshold, _EdgeSharpness;
            
            // 切线偏移函数
            float3 ShiftTangent(float3 T, float3 N, float shift)
            {
                return normalize(T + shift * N);
            }
            
            // 发丝高光函数
            float StrandSpecular(float3 T, float3 V, float3 L, float exponent)
            {
                float3 H = normalize(L + V);
                float dotTH = dot(T, H);
                float sinTH = sqrt(1.0 - dotTH * dotTH);
                float dirAtten = smoothstep(-1.0, 0.0, dot(T, H));
                return dirAtten * pow(sinTH, exponent);
            }
            
            // 边缘增强函数
            float EdgeEnhancement(float alpha, float threshold, float sharpness)
            {
                float edge = smoothstep(threshold - 0.05, threshold + 0.05, alpha);
                return pow(edge, sharpness);
            }
            
            Varyings vert (Attributes v)
            {
                Varyings o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                
                // 计算副切线（发丝方向）
                o.worldTangent = normalize(cross(o.worldNormal, o.worldTangent) * v.tangent.w);
                
                TRANSFER_SHADOW(o);
                UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }
            
            fixed4 frag (Varyings i) : SV_Target
            {
                // 采样基础纹理
                fixed4 albedo = tex2D(_MainTex, i.uv);
                albedo.rgb *= _Color.rgb;
                
                // Alpha测试 - 实现锐利边缘
                #ifdef _ALPHATEST_ON
                    clip(albedo.a - _Cutoff);
                #endif
                
                // 边缘增强
                float edge = EdgeEnhancement(albedo.a, _EdgeThreshold, _EdgeSharpness);
                
                // 向量准备
                float3 N = normalize(i.worldNormal);
                float3 T = normalize(i.worldTangent);
                float3 V = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 L = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                // 阴影计算
                float shadow = SHADOW_ATTENUATION(i);
                
                // 漫反射光照
                float NdotL = dot(N, L);
                float diff = saturate(NdotL * 0.5 + 0.5); // 半兰伯特
                float3 diffuse = _LightColor0.rgb * albedo.rgb * diff * shadow;
                
                // 环境光照
                float3 ambient = albedo.rgb * UNITY_LIGHTMODEL_AMBIENT.rgb;
                
                // 高光 - 两层
                float4 specTex = tex2D(_SpecularTex, i.uv);
                float shift = specTex.r - 0.5;
                
                float3 T1 = ShiftTangent(T, N, shift + _ShiftValue1);
                float spec1 = StrandSpecular(T1, V, L, _Gloss1) * _SpecIntensity1;
                
                float3 T2 = ShiftTangent(T, N, shift + _ShiftValue2);
                float spec2 = StrandSpecular(T2, V, L, _Gloss2) * _SpecIntensity2;
                
                float3 specular = (spec1 * _SpecColor1.rgb + spec2 * _SpecColor2.rgb) * _LightColor0.rgb * shadow;
                
                // 透射效果
                float3 backL = -L;
                float transDot = pow(saturate(dot(N, backL)), 2.0) * saturate(dot(N, V) * 0.5 + 0.5);
                float3 transmission = transDot * _TransmissionPower * _TransmissionColor.rgb * _LightColor0.rgb * shadow;
                
                // 最终合成
                float3 finalColor = ambient + diffuse + specular + transmission * albedo.rgb;
                
                // 应用边缘增强
                finalColor = lerp(_EdgeColor.rgb, finalColor, edge);
                
                // 雾效
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                
                return fixed4(finalColor, albedo.a);
            }
            ENDCG
        }
        
        // 阴影投射Pass
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile _ _ALPHATEST_ON
            
            #include "UnityCG.cginc"
            
            struct v2f_shadow {
                V2F_SHADOW_CASTER;
                float2 uv : TEXCOORD1;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff;
            
            v2f_shadow vert(appdata_base v)
            {
                v2f_shadow o;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }
            
            float4 frag(v2f_shadow i) : SV_Target
            {
                fixed4 tex = tex2D(_MainTex, i.uv);
                #ifdef _ALPHATEST_ON
                    clip(tex.a - _Cutoff);
                #endif
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
