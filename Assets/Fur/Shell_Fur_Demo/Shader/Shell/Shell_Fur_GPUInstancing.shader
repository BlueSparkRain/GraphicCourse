Shader "Unlit/Shell_Fur_GPUInstancing"
{
    Properties
    {
        _MainTex("Fur Texture", 2D) = "white" {}
        _BumpTex("Normal Map", 2D) = "bump" {}
        _BumpIntensity("Bump Intensity",Range(0,2))=1
        _FurLength("Fur Length", Float) = 0.2
        _ShellCount("Shell Count", Float) = 16
        _WindStrength("Wind Strength", Float) = 0.02
        [HDR]_FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        _FresnelPower("Fresnel Power", Float) = 5
        _FurAlphaPow("Fur AlphaPow", Range(0,4)) = 1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200
        ZWrite Off
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "FurPass"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

           
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            TEXTURE2D(_BumpTex); SAMPLER(sampler_BumpTex);
            float4 _BumpTex_ST;
            float _FurLength;
            float _ShellCount;
            float _WindStrength;
            float4 _FresnelColor;
            float _FresnelPower;
            float _FurAlphaPow;

            /*UNITY_INSTANCING_BUFFER_START(Props)
                 UNITY_DEFINE_INSTANCED_PROP(float, _ShellIndex)
            UNITY_INSTANCING_BUFFER_END(Props)*/

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                //UNITY_VERTEX_INPUT_INSTANCE_ID
               
            };

            struct Varyings
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float shellIndex : TEXCOORD3;
                
                //UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            float _ShellIndex;

            Varyings vert(Attributes v)
            {
                //UNITY_SETUP_INSTANCE_ID(v);

                //float shellIndex =   UNITY_ACCESS_INSTANCED_PROP(Props, _ShellIndex);
                float shellIndex = _ShellIndex;
                float shellFrac = shellIndex / _ShellCount;
                Varyings o;
                //UNITY_TRANSFER_INSTANCE_ID(v, o);
                
                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);

                float windOffset = sin(worldPos.x * 5 + _Time.y * 2 + shellIndex) * _WindStrength;
                worldPos += worldNormal * (_FurLength * shellFrac + windOffset);

                o.pos = TransformWorldToHClip(worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
                o.worldNormal = worldNormal;
                o.shellIndex = shellIndex;
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float shellFrac = i.shellIndex / _ShellCount;
                float mask = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).r;

                float alpha= saturate(mask - pow(shellFrac,_FurAlphaPow));

                float3 bump = UnpackNormal(SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, i.uv));
                float3 normalWS = normalize(i.worldNormal + bump * 0.5);
                float fresnel = pow(1.0 - saturate(dot(i.viewDir, normalWS)), _FresnelPower);

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                col.a = alpha;
                col.rgb += _FresnelColor.rgb * fresnel * alpha;
                return col;
          
            }
            ENDHLSL
        }
    }
    
}
