Shader "Unlit/Shell_Fur_NonGPUInstancing"
{
    Properties
    {
        _MainTex("Albedo Tex", 2D) = "white" {}
        _FurTex("Fur Tex", 2D) = "white" {}
        [HDR]_FurColor("Fur Color",Color)=(1,1,1,1)
        [HDR]_RootColor("Root Color",Color)=(1,1,1,1)
        _AlbedoSaturate("_AlbedoSaturate",Range(0,3))=1
        _DiffuseSmoothness("_DiffuseSmoothness",Range(0,2))=1
        _BumpTex("Normal Map", 2D) = "white" {}
        _BumpIntensity("Bump Intensity",Range(0,4))=1
        [HDR]_SpecularColor("Speculat Color",Color)=(1,1,1,1)
         _SpecularShiftTex("SpecularShift Tex",2D)="white"{}
        _SpecularShiftIntensity("_SpecularShiftIntensity",Range(0,4))=1
        _specularGloss("Gloss", Range(1, 256)) = 64
        _FurLength("Fur Length", Float) = 0.2
        _ShellCount("Shell Count", Float) = 16

        [Toggle] _UseMovexCurl("Use MovexCurl",Float)=1
        _FurCurlDir("FurCurl Dir",Vector)=(0,0,0,0)
        _FurCurl("FurCurl", Float) = 0.1
        _MoveSpeed("Move Speed", Float) = 1
        _MoveDistance("Move Distance", Float) = 1
        
        [HDR]_FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        _FresnelPower("Fresnel Power", Range(0,6)) = 3
        _FurAlphaPow("Fur AlphaPow", Range(0,4)) = 1
        _ShellRimHardness("ShellRim Hardness", Range(-0.1,1)) = 0.7
        [Toggle] _UseHalfLambert("Use HalfLambert",Float)=1
        _HalfLambertShadowLitness("HLam ShadowLitness",Range(0,1))=0.5
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200
        ZWrite Off
        Cull back
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "FurPass"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma  shader_feature  _USEHALFLAMBERT_ON
            #pragma  shader_feature  _USEMOVEXCURL_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_FurTex); SAMPLER(sampler_FurTex);
            float4 _MainTex_ST;
            float _AlbedoSaturate;
            float _DiffuseSmoothness;
            TEXTURE2D(_BumpTex); SAMPLER(sampler_BumpTex);
            TEXTURE2D(_SpecularShiftTex); SAMPLER(sampler_SpecularShiftTex);
            float4 _FurTex_ST;
            float4 _SpecularShiftTex_ST;
            float4 _RootColor;
            float4 _FurColor;
            float _BumpIntensity;
            float _SpecularShiftIntensity;
            float _specularGloss;
            float4 _SpecularColor;
            float _FurLength;
            float _ShellCount;
            float4 _FurCurlDir;
            float _FurCurl;
            float _MoveSpeed;
            float _MoveDistance;
            float4 _FresnelColor;
            float _FresnelPower;
            float _FurAlphaPow;
            float _HalfLambertShadowLitness;

            float _ShellRimHardness;
            
            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 fur_uv:TEXCOORD1;//xy：fur_uv zw:fur_sshuv
                float3 normal : NORMAL;
                float4 tangent:TANGENT;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;//xy:mainTex_uv 
                float2 fur_uv:TEXCOORD1;//xy：fur_uv 
                float3 wPos:TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float3 wNormal : TEXCOORD4;
                
                float3 wBitangent:TEXCOORD5;
                //切线空间到世界空间的 变换矩阵的3行
                float3 TtoW0:TEXCOORD6;
                float3 TtoW1:TEXCOORD7;
                float3 TtoW2:TEXCOORD8;
                
                float shellIndex : TEXCOORD9;
            };

            float3 AdjustSaturation(float3 color, float saturation)
            {
             // 计算亮度（灰度）
                 float gray = dot(color, float3(0.299, 0.587, 0.114)); // 人眼感知亮度权重
                // 插值：saturation = 0 是灰度，=1 是原始颜色，>1 是增强
            return lerp(gray.xxx, color, saturation);
            }
            
            float _ShellIndex;

            Varyings vert(Attributes v)
            {
                float shellIndex = _ShellIndex;
                float shellFrac = shellIndex / _ShellCount;
                Varyings o;
                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                o.wNormal = worldNormal;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);


                
                #ifdef _USEMOVEXCURL_ON
                  float3 windAngle = sin(_Time.y*_MoveSpeed)* _FurCurlDir.xyz;
                  float3 windOffset = windAngle * _MoveDistance;

                  //毛发卷曲效果（不含位移）
                  worldPos +=  windAngle *  sin(shellFrac * PI*_FurCurl ) * shellFrac ;

                 //实际顶点移动
                worldPos+= windOffset;
                #else

                
                #endif
                

                worldPos += worldNormal * (_FurLength * shellFrac);//[橡皮拉伸动画]+windOffset);

                o.wPos=worldPos;
                float3 wTangent = TransformObjectToWorld(v.tangent.xyz);
                o.wBitangent=cross(worldNormal,wTangent) * v.tangent.w;
                
                o.vertex = TransformWorldToHClip(worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fur_uv.xy=TRANSFORM_TEX(v.fur_uv.xy,_FurTex);
              
                
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
                o.shellIndex = shellIndex;

                 //切线空间（世界）
                o.TtoW0= float3(wTangent.x, o.wBitangent.x,worldNormal.x);
                o.TtoW1= float3(wTangent.y, o.wBitangent.y,worldNormal.y);
                o.TtoW2= float3(wTangent.z, o.wBitangent.z,worldNormal.z);
                return o;
            }

            //漫反射（半兰伯特）
            float3 GetLambertMode(float3 worldNormal)
            {
                float3 lightDir=normalize(_MainLightPosition);
                float NdotL=saturate(dot(worldNormal,lightDir));
                
                float Lambert;
                #ifndef _USEHALFLAMBERT_ON
                Lambert =saturate(pow(NdotL , _DiffuseSmoothness));
                #else
                Lambert =saturate(max(pow(NdotL * 0.5 + _HalfLambertShadowLitness, _DiffuseSmoothness),pow(NdotL , _DiffuseSmoothness)));
                #endif
                
                float3 lambertColor=_MainLightColor * max(0,Lambert);
                return  lambertColor ;
            }
            //各项异高光（Kajiya）
            float3 GetKajiyaSpecularMode(float3 bitangent,float3 viewDir,float3 exponent)
            {
                //计算光照方向
                float3 lightDir=normalize(_MainLightPosition);
                //计算半角向量
                float3 halfDir=normalize(lightDir+viewDir);
                //计算高光角度
                float dotTH= dot(halfDir,bitangent);
                float sinTH=sqrt(1-pow(dotTH,2));
    
                //计算高光颜色
                float dirAtten = smoothstep(-1.0, 0.0, dotTH);

                float3  specularColor=_MainLightColor * dirAtten*pow(sinTH,exponent);
                return  specularColor;
            }

            float3 ShiftTangent(float3 bitangent,float3 wnormal,float shiftValue)
            {
                float3 shiftTan=bitangent+wnormal*shiftValue;
                return normalize(shiftTan);
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 albedoColor=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv);
                //饱和度调整
                albedoColor=AdjustSaturation(albedoColor,_AlbedoSaturate);
                
                float shellFrac = saturate( i.shellIndex / _ShellCount);
                
                float furMask = SAMPLE_TEXTURE2D(_FurTex, sampler_FurTex,  i.fur_uv.xy).r;
                float alpha= saturate(furMask - pow(shellFrac,_FurAlphaPow));
                //AO
                albedoColor*=lerp(_RootColor,_FurColor,shellFrac);

                float3 bump = UnpackNormal(SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, i.uv));
                bump= saturate(pow(bump,_BumpIntensity));

                //将法线贴图中的法线信息转到切线空间
                float3 normalWS = float3(dot( i.TtoW0,bump),dot( i.TtoW1,bump),dot( i.TtoW2,bump));
                //float3 lambert=GetLambertMode(normalWS);
                float3 lambert=GetLambertMode(i.wNormal);
                //漫反射
                float3 lambertColor=albedoColor*lambert;
                //高光
                float  shiftValue=(SAMPLE_TEXTURE2D(_SpecularShiftTex, sampler_SpecularShiftTex, i.uv).r-0.5)*_SpecularShiftIntensity;
                float3 shiftTangent=ShiftTangent(i.wBitangent,normalWS,shiftValue);
                float3 speculatColor= albedoColor* _SpecularColor*GetKajiyaSpecularMode(shiftTangent,i.viewDir,_specularGloss);
                //外发光
                float fresnel = saturate( pow(0.5 * (1.0 - dot(i.viewDir, i.wNormal)), _FresnelPower));
                float3 fresnelColor=_MainLightColor * albedoColor *_FresnelColor.rgb * fresnel;
                
                float4 finalColor;
                finalColor.xyz=UNITY_LIGHTMODEL_AMBIENT+ lambertColor+speculatColor+fresnelColor * alpha;
                //alpha=step(_AlphaClip*shellFrac,alpha);
                alpha= smoothstep(_ShellRimHardness*shellFrac,1*shellFrac,alpha);
                finalColor.a=alpha;
                return finalColor;
            }
            ENDHLSL
        }
    }
    
}
