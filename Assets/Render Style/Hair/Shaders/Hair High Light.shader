Shader "LSQ/Render Style/Hair/High Light"
{
    Properties
    {
        _LightMap ("Light Map", 2D) = "white" {}
        _LightWidth ("Light Width", float) = 1
        _LightLength ("Light Length", float) = 1
        _LightFeather ("Light Feather", float) = 1
        _LightThreshold ("Light Threshold", float) = 1
        _LightColor_H ("LightColor H", Color) = (1,1,1,1)
        _LightColor_L ("LightColor L", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                half3 normalWS : TEXCOORD2;
            };

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.positionWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normalWS = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            sampler2D _LightMap;
            float4 _LightMap_ST;
            float _LightWidth;
            float _LightLength;
            float _LightFeather;
            float _LightThreshold;
            half4 _LightColor_H;
            half4 _LightColor_L;

            half4 frag (Varyings i) : SV_Target
            {
                float3 L = UnityWorldSpaceLightDir(i.positionWS);
                float3 V = UnityWorldSpaceViewDir(i.positionWS);
                float3 H = normalize(L + V);
                float3 N = normalize(i.normalWS);
		
                float3 NV = mul(UNITY_MATRIX_V, N);
                float3 HV = mul(UNITY_MATRIX_V, H);
		        // ����Y�Ͳ�����Ϊ�ӽǵ����¶�ʧȥ�߹�
                // �������ǿɲ���������yȥTilingAndOffsetƫ����ʹ��
                float NdotH = dot(normalize(NV.xz), normalize(HV.xz));
                NdotH = pow(NdotH, 6) * _LightWidth;		
                NdotH = pow(NdotH, 1 / _LightLength);	
	
                float lightMap = tex2D(_LightMap, TRANSFORM_TEX(i.uv, _LightMap)).r;
                float lightFeather = _LightFeather * NdotH;
                float lightStepMax = saturate(1 - NdotH + lightFeather);
                float lightStepMin = saturate(1 - NdotH - lightFeather);
                float3 lightColor_H = smoothstep(lightStepMin, lightStepMax, clamp(lightMap, 0, 0.99)) * _LightColor_H.rgb;
                float3 lightColor_L = smoothstep(_LightThreshold, 1, lightMap) * _LightColor_L.rgb;
                float3 specularColor = lightColor_H + lightColor_L;

                return half4(specularColor, 1);
            }
            ENDCG
        }
    }
}
