Shader "LSQ/Render Style/Hair/ScheuermannHair"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		_SpecularTex("Specular", 2D) = "white" {}
		
		_ShiftValue1("shift 1", Range(-1, 1)) = 0.5
		_SpecColor1 ("SpecColor 1", Color) = (1,1,1,1)		
		_Gloss1("Gloss 1", Range(1, 256)) = 1
		_Specular1("Specular 1", Range(0, 2)) = 0

		_ShiftValue2("shift 2", Range(-1, 1))=0.5
		_SpecColor2 ("SpecColor 2", Color) = (1,1,1,1)
		_Gloss2("Gloss 2", Range(1, 256)) = 1
		_Specular2("Specular 2", Range(0, 2)) = 0
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
				float3 worldTangent : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;				
				float3 worldPos : TEXCOORD3;	
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _SpecularTex;
			float4 _SpecularTex_ST;

			half4 _SpecColor1;
			float _ShiftValue1;
			float _Gloss1;
			float _Specular1;

			half4 _SpecColor2;
			float _ShiftValue2;
			float _Gloss2;
			float _Specular2;

			half3 shiftTangent (half3 T, half3 N, float Shift)
			{
				half3 ShiftT = T + N * Shift;
				return normalize(ShiftT);
			}

			half StrandSpecular (half3 T, half3 V, half3 L, float Exponent, float Strength)
			{
				half3 H = normalize(L + V);
				half dotTH = dot(T, H);
				half sinTH = sqrt(1 - dotTH * dotTH);
				half dirAtten = smoothstep(-1, 0, dotTH);
				return dirAtten * pow(sinTH, Exponent) * Strength;
			}
 
			Varyings vert ( Attributes v )
			{
				Varyings o;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				half3 worldTangent = UnityObjectToWorldDir(v.tangent);
				o.worldTangent = cross(o.worldNormal, worldTangent) * v.tangent.w;
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);		
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _SpecularTex);		
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}
 
			half4 frag (Varyings i ) : SV_Target
			{			
				half4 albedo = tex2D( _MainTex, i.uv.xy);

				half3 N = normalize(i.worldNormal);
				half3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				half3 L = normalize(_WorldSpaceLightPos0.xyz);
				half3 T = normalize(i.worldTangent);	

				// Test
				//half3 H = normalize(L + V);
				//return pow(dot(N,H), 10);
				//return pow(dot(shiftTangent (T,  N, _ShiftValue1), H), 50);

				// diffuse
				float NdotL = saturate(dot(N,L));
				float3 diff = saturate(lerp(0.25, 1.0, NdotL)) * _LightColor0 * albedo.rgb;

				// anis spec
				float4 spectex = tex2D(_SpecularTex, i.uv.zw);
				float shift1 = spectex.r - 0.5 + _ShiftValue1;
				float shift2 = spectex.r - 0.5 + _ShiftValue2;
				float3 T1 = shiftTangent(T, N, shift1);
				float3 T2 = shiftTangent(T, N, shift2);
				float3 anisSpec = StrandSpecular(T1, V, L, _Gloss1, _Specular1) * _SpecColor1;
				anisSpec = anisSpec + StrandSpecular(T2, V, L, _Gloss2, _Specular2) * _SpecColor2;					
 
				half4 col;
				col.rgb = diff + anisSpec;
				col.a = albedo.a;
				return col;
			}
			ENDCG
		}
	}
}