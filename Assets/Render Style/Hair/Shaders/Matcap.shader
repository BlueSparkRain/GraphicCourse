Shader "LSQ/Render Style/Hair/Matcap"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		_MatcapMap("Matcap", 2D) = "2D" {}
		_AnisMap("AnisMap", 2D) = "bump" {}
		_AnisScale("Anis Scale", Range(0, 2)) = 1
		_AnisSpecColor("Anis SpecColor", Color) = (1,1,1,1)		
		_AnisGloss("Anis Gloss", Range(0, 2)) = 1
		_AnisSpecular("Anis Specular", Range(0, 2)) = 0
	}
 
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		
		Pass
		{   
		    Tags { "LightMode"="ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fwdbase	
			#pragma target 3.0 
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct Attributes
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;		
				float4 tangent : TANGENT;
			};
 
			struct Varyings
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;  
				float4 TtoW1 : TEXCOORD2;  
				float4 TtoW2 : TEXCOORD3;	
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _MatcapMap;
			float4 _MatcapMap_ST;
			sampler2D _AnisMap;
			float4 _AnisMap_ST;
			fixed4 _AnisSpecColor;
			float _AnisScale;
			float _AnisGloss;
			float _AnisSpecular;

			Varyings vert ( Attributes v )
			{
				Varyings o;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 worldTangent = UnityObjectToWorldDir(v.tangent);
				float3 worldBitangent = cross(worldNormal, worldTangent) * v.tangent.w;

				o.TtoW0 = float4(worldTangent.x, worldBitangent.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBitangent.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBitangent.z, worldNormal.z, worldPos.z);

				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);		
				o.uv.zw = v.texcoord;		
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}
 
			fixed4 frag (Varyings i) : SV_Target
			{			
				fixed4 albedo = tex2D(_MainTex, i.uv.xy);

				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 N = normalize(float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));
				fixed3 V = normalize(_WorldSpaceCameraPos.xyz - worldPos);
				fixed3 L = normalize(_WorldSpaceLightPos0.xyz);
				
				// diffuse
				float NdotL = saturate(dot(N, L));
				float3 diff = saturate(lerp(0.25, 1.0, NdotL)) * _LightColor0 * albedo.rgb;

				// anis spec
				// ��������������ͼ��ȡ����
				fixed3 anisNormalTS = UnpackNormal(tex2D(_AnisMap, TRANSFORM_TEX(i.uv.zw, _AnisMap)));
				anisNormalTS.xy *= _AnisScale;
				anisNormalTS.z = sqrt(1 - saturate(dot(anisNormalTS.xy, anisNormalTS.xy)));
				fixed3 anisNormalWS = normalize(mul(fixed3x3(i.TtoW0.xyz, i.TtoW1.xyz, i.TtoW2.xyz), anisNormalTS));
				// ����ͼ�ռ��÷��߲���MapCap
				fixed3 anisNormalVS = (mul(UNITY_MATRIX_V, float4(anisNormalWS,0))).xyz;
				float2 viewMatCapUV = anisNormalVS.xy * 0.5 + 0.5;
				fixed4 anisMapCap = tex2D(_MatcapMap, TRANSFORM_TEX(viewMatCapUV, _MatcapMap));
				fixed anis = max(max(anisMapCap.r, anisMapCap.g), anisMapCap.b); 
				anis = smoothstep(0.4, 0.5, anis);
				fixed3 anisSpec = pow(anis, _AnisGloss) * _AnisSpecular * _AnisSpecColor;

				fixed4 col;
				col.rgb = diff + anisSpec;
				col.a = albedo.a;
				return col;
			}
			ENDCG
		}
	}
}