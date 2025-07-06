Shader "Unlit/Learn"
{
    Properties
    {
        [MaterialToggle]_light ("Light On", int) = 1
        [Toggle]_my ("Toggle MyOn", Float) = 1
        [MaterialToggle]_mY ("MaterialToggle MyOn", int) = 1
        [KeywordEnum(OFF,ON)] _mY("KeywordEnum MyOn",int)=1
        [Toggle]_CustomKeyword_ON ("Toggle MyOn", Float) = 1
        [Toggle]_my ("Toggle MyOn", Float) = 1
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

            #pragma shader_feature _MY_ON
            #pragma  multi_compile _ _LIGHT_ON
            
            #pragma multi_compile_instancing
            #pragma shader_feature _CustomKeyword_ON

            #include "UnityCG.cginc"

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (Varyings i) : SV_Target
            {
                // sample the texture
                fixed4 col = fixed4(1,1,1,1);
                
                #ifdef _MY_ON
                col=  fixed4(1,0,0,1);
                #else
                col=  fixed4(1,1,0,1);
                #endif

                #ifdef _LIGHT_ON
                col += fixed4(0,0.5,0.5,1);
                #else
                col += fixed4(1,0,0,1);
                #endif

              
                
                return  col;
                
            }
            ENDCG
        }
    }
}
